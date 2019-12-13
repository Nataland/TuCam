import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:photofilters/photofilters.dart';
import 'package:image/image.dart' as img;

import 'filter_selector.dart';
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
  String photoFrameFileName = PhotoFrameSelectorWidget.photoFrameFileNames[0];
  FrameFilterState frameFilterState = FrameFilterState.CHOOSING_FRAME;
  Filter selectedFilter = NoFilter();
  _PhotoEditorState(this.uploadedImage);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Editor'),
      ),
      body: Column(
        children: <Widget>[
          Stack(
            children: <Widget>[
              AspectRatio(
                child: PhotoFilter(
                  image: img.decodeImage(uploadedImage.readAsBytesSync()),
                  filename: basename(uploadedImage.path),
                  filter: selectedFilter,
                  fit: BoxFit.cover,
                  loader: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    )
                  )
                ),
//                child: imageBytes == null
//                  ? Image.file(uploadedImage)
//                  : Image.memory(imageBytes,),
                aspectRatio: 3/4,
              ),
              Image(
                fit: BoxFit.cover,
                image: AssetImage(photoFrameFileName),
              ),
            ],
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                frameFilterState == FrameFilterState.CHOOSING_FILTER
                  ? PhotoFilterSelectorWidget(uploadedImage: uploadedImage, setFilter: changeFilter,)
                  : PhotoFrameSelectorWidget(setFrame: changeFrame,),
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

  void changeFrame(String filename) {
    setState(() {
      photoFrameFileName = filename;
    });
  }

  void changeFilter(Filter filter) {
    setState(() {
      selectedFilter = filter;

//      imageBytes = applyFilter(
//      <String, dynamic>{
//        "filter": filter,
//        "image": img.decodeImage(imageBytes),
//        "filename": basename(uploadedImage.path)
//      }
//      );
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

