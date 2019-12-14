import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class FilterSelector extends StatelessWidget {
  final Function(img.Image) setFilter;
  final File uploadedImage;

  FilterSelector({Key key, this.setFilter, this.uploadedImage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Uint8List originalBytes = uploadedImage.readAsBytesSync();
    img.Image originalImage = img.decodeImage(originalBytes);

    List<img.Image> filteredImages = <img.Image>[ // need to move this out of the build method
      img.copyResize(originalImage, height: originalImage.height),
      img.sepia(img.copyResize(originalImage, height: originalImage.height)),
      img.sobel(img.copyResize(originalImage, height: originalImage.height)),
      img.vignette(img.copyResize(originalImage, height: originalImage.height)),
      img.pixelate(img.copyResize(originalImage, height: originalImage.height), 5),
      img.gaussianBlur(img.copyResize(originalImage, height: originalImage.height), 5),
    ];

    return Container(
      height: 60.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filteredImages.length,
        itemBuilder: (BuildContext context, int index) => _photoFilterWidget(context, filteredImages[index], index),
      ),
    );
  }

  Widget _photoFilterWidget(BuildContext context, img.Image display, int index) {
    BorderSide side = BorderSide(color: Theme.of(context).primaryColor, width: 2.0);
    return GestureDetector(
      onTap: () {
        setFilter(display);
      },
      child: Container(
        child: Image.memory(
          img.encodePng(display),
          width: 60.0,
          height: 60.0,
          fit: BoxFit.cover,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: side,
            right: side,
            bottom: side,
            left: index == 0 ? side : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
