import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:tuwei_camera/main.dart';
import 'package:video_player/video_player.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class CameraHome extends StatefulWidget {
  final CameraDescription defaultCamera;

  CameraHome(this.defaultCamera);

  @override
  _CameraHomeState createState() {
    return _CameraHomeState();
  }
}

class _CameraHomeState extends State<CameraHome>
    with WidgetsBindingObserver {
  static final numberOfFrames = 29;
  static final photoFrameFileNames = List<String>.generate(numberOfFrames, (int index) => 'assets/frame' + index.toString() + '.png');
  CameraController controller;
  String imagePath;
  String videoPath;
  String photoFrameFileName = photoFrameFileNames[0];
  VideoPlayerController videoController;
  VoidCallback videoPlayerListener;
  bool enableAudio = true;

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
        backgroundColor: Colors.pink[100],
        title: const Text('土味相机'),
      ),
      body: Column(
        children: <Widget>[
          _cameraPreviewWidget(),
          Expanded(
              child: Column(
                children: <Widget>[
                  _photoFrameSelectorWidget(),
                  Expanded(
                    child: _captureControlRowWidget(),
                  ),
                ],
              )
          ),
        ],
      ),
    );
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
            child: Image(
              fit: BoxFit.cover,
              image: AssetImage(photoFrameFileName),
            ),
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
        RaisedButton(
          padding: EdgeInsets.all(24.0),
          child: Icon(
            Icons.camera_alt,
            color: Colors.white,
          ),
          shape: CircleBorder(),
          color: Colors.pink[100],
          onPressed: controller != null &&
              controller.value.isInitialized &&
              !controller.value.isRecordingVideo
              ? onTakePictureButtonPressed
              : null,
        ),
      ],
    );
  }

  Widget _photoFrameWidget(String fileName) {
    return GestureDetector(
      onTap: () { setState(() {photoFrameFileName = fileName;});},
      child: Image(
        fit: BoxFit.contain,
        image: AssetImage(fileName),
      ),
    );
  }

  Widget _photoFrameSelectorWidget() {
    return Container(
      height: 60.0,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: numberOfFrames,
          itemBuilder: (BuildContext context, int index) => _photoFrameWidget(photoFrameFileNames[index])
      ),
    );
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
      enableAudio: enableAudio,
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

        setState(() {
          imagePath = filePath;
          videoController?.dispose();
          videoController = null;
        });
        if (filePath != null) showInSnackBar('Picture saved to $filePath');
      }
    });
  }

  Future<Uint8List> getLayeredImage(String filePath) async {
    Offset defaultOffset = Offset(0.0, 0.0);
    Paint defaultPaint = Paint();

    Uint8List frameData = (await rootBundle.load(photoFrameFileName)).buffer.asUint8List();
    File file = File(filePath);
    Uint8List photoData = file.readAsBytesSync();
    ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    Canvas canvas = Canvas(pictureRecorder);
    canvas.drawImage(await loadImage(photoData), defaultOffset, defaultPaint);
    canvas.drawImage(await loadImage(frameData), defaultOffset, defaultPaint);
    var image = await pictureRecorder.endRecording().toImage(1000, 1000);
    ByteData data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data.buffer.asUint8List();
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
