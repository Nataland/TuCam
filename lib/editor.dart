import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:photofilters/photofilters.dart';
import 'package:image/image.dart' as img;

import 'filter_selector.dart';
import 'frame.dart';
import 'frame_selector.dart';

enum FrameFilterState { CHOOSING_FRAME, CHOOSING_FILTER }

class PhotoEditor extends StatefulWidget {
  final File uploadedImage;

  PhotoEditor(this.uploadedImage);

  @override
  _PhotoEditorState createState() {
    return _PhotoEditorState(uploadedImage);
  }
}

class _PhotoEditorState extends State<PhotoEditor> {
  File uploadedImage;
  Uint8List imageBytes;
  String photoFrameFileName = FrameSelector.photoFrameFileNames[0];
  FrameFilterState frameFilterState = FrameFilterState.CHOOSING_FRAME;
  Filter selectedFilter = NoFilter();
  img.Image imageInDisplay;

  _PhotoEditorState(this.uploadedImage);

  final fileNameNotifier = ValueNotifier(FrameSelector.photoFrameFileNames[0]);

  @override
  Widget build(BuildContext context) {
    if (imageInDisplay == null) {
      imageInDisplay = img.decodeImage(uploadedImage.readAsBytesSync()); // initialize with no filter first
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.check,
              color: Colors.white,
            ),
            onPressed: saveImage,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Stack(
            children: <Widget>[
              AspectRatio(
                child: Image.memory(
                  img.encodePng(imageInDisplay),
                ),
                aspectRatio: 3 / 4,
              ),
              ValueListenableBuilder<String>(
                valueListenable: fileNameNotifier,
                builder: (context, value, child) {
                  return FrameImage(fileNameNotifier);
                },
              ),
            ],
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                frameFilterState == FrameFilterState.CHOOSING_FILTER
                    ? FilterSelector(
                        uploadedImage: uploadedImage,
                        setFilter: changeFilter,
                      )
                    : FrameSelector(
                        setFrame: changeFrame,
                      ),
                IconButton(
                  icon: Icon(
                    frameFilterState == FrameFilterState.CHOOSING_FILTER ? Icons.gradient : Icons.photo_filter,
                  ),
                  onPressed: onToggleFilterOrFrame,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void changeFrame(String frameName) {
    fileNameNotifier.value = frameName;
  }

  void saveImage() async {
    _save() async {
      selectedFilter.apply(uploadedImage.readAsBytesSync());
      var layeredImage = await getLayeredImage();
      ImageGallerySaver.saveImage(layeredImage);
    }

    _save();
  }

  Future<Uint8List> getLayeredImage() async {
    // Load frame and adjust frame
    Uint8List frameData = (await rootBundle.load(photoFrameFileName)).buffer.asUint8List();
    img.Image frameImage = img.decodeImage(frameData);
    frameImage = img.copyResize(frameImage, width: imageInDisplay.width, height: imageInDisplay.height);

    // Draw frame image on top of camera image
    img.drawImage(imageInDisplay, frameImage);
    return img.encodePng(imageInDisplay);
  }

  void changeFilter(img.Image processedImage) {
    setState(() {
      imageInDisplay = processedImage;
    });
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
}
