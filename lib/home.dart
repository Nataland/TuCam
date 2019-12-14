import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'editor.dart';
import 'frame_selector.dart';
import 'frame.dart';
import 'main.dart';

class CameraHome extends StatefulWidget {
  final CameraDescription defaultCamera;

  CameraHome(this.defaultCamera);

  @override
  _CameraHomeState createState() {
    return _CameraHomeState();
  }
}

class _CameraHomeState extends State<CameraHome> with WidgetsBindingObserver {
  CameraController controller;
  String photoFrameFileName = FrameSelector.photoFrameFileNames[0];
  FrameFilterState frameFilterState = FrameFilterState.CHOOSING_FRAME;
  final fileNameNotifier = ValueNotifier(FrameSelector.photoFrameFileNames[0]);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    onNewCameraSelected(defaultCamera);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('土味相机'),
      ),
      body: Column(
        children: <Widget>[
          _cameraPreviewWidget(),
          Expanded(
            child: Column(
              children: <Widget>[
                FrameSelector(setFrame: changeFrame),
                Expanded(
                  child: _captureControlRowWidget(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void changeFrame(String fileName) {
    fileNameNotifier.value = fileName;
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Camera unavailable',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Stack(
        children: <Widget>[
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: FrameImage(fileNameNotifier),
          ),
        ],
      );
    }
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        IconButton(
          icon: Icon(
            Icons.collections,
          ),
          onPressed: onOpenPhotoGallery,
        ),
        RaisedButton(
          padding: const EdgeInsets.all(24.0),
          child: Icon(
            Icons.camera_alt,
            color: Colors.white,
          ),
          shape: CircleBorder(),
          onPressed: controller != null && controller.value.isInitialized && !controller.value.isRecordingVideo
              ? onTakePictureButtonPressed
              : null,
        ),
        IconButton(
          icon: Icon(
            frameFilterState == FrameFilterState.CHOOSING_FILTER ? Icons.gradient : Icons.photo_filter,
          ),
          onPressed: onToggleFilterOrFrame,
        ),
      ],
    );
  }

  Future onOpenPhotoGallery() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);

    // Open photo editor
    if (image != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => PhotoEditor(image)));
    }
  }

  void onToggleFilterOrFrame() {
    setState(() {
      if (frameFilterState == FrameFilterState.CHOOSING_FRAME) {
        frameFilterState = FrameFilterState.CHOOSING_FILTER;
      } else {
        frameFilterState = FrameFilterState.CHOOSING_FRAME;
      }
    });
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onTakePictureButtonPressed() async {
    takePicture().then((String filePath) {
      if (mounted) {
        _save() async {
          var layeredImage = await getLayeredImage(filePath);
          ImageGallerySaver.saveImage(layeredImage);
        }

        _save();
//        if (filePath != null) showInSnackBar('Picture saved to $filePath');
      }
    });
  }

  Future<Uint8List> getLayeredImage(String filePath) async {
    Uint8List frameData = (await rootBundle.load(photoFrameFileName)).buffer.asUint8List();
    Uint8List cameraData = File(filePath).readAsBytesSync();

    // Format camera image
    img.Image cameraImage = img.decodeImage(cameraData);
    cameraImage = img.copyRotate(cameraImage, 90);
    img.flip(cameraImage, img.Flip.horizontal);

    // Format frame image
    img.Image frameImage = img.decodeImage(frameData);
    frameImage = img.copyResize(frameImage, width: cameraImage.width, height: cameraImage.height);

    // Draw frame image on top of camera image
    img.drawImage(cameraImage, frameImage);
    return img.encodePng(cameraImage);
  }

  Future<ui.Image> loadImage(List<int> img) async {
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(img, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  Future<String> takePicture() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}
