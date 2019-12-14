import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FrameImage extends Image {
  final ValueListenable<String> fileName;

  FrameImage(this.fileName) : super(image: AssetImage(fileName.value), fit: BoxFit.cover);
}
