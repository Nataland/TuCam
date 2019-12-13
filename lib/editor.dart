import 'dart:io';

import 'package:flutter/material.dart';

import 'frames.dart';

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
  String photoFrameFileName = PhotoFrameSelectorWidget.photoFrameFileNames[0];

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
                child: Image.file(
                  uploadedImage,
                  fit: BoxFit.cover,
                ),
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
                PhotoFrameSelectorWidget(setFrame: changeFrame,),
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
}
