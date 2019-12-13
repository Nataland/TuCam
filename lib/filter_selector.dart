import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:photofilters/photofilters.dart';
import 'package:image/image.dart' as img;

class PhotoFilterSelectorWidget extends StatelessWidget {
  static final numberOfFilters = 29;
  static final filters = presetFiltersList;
  final Function(Filter) setFilter;
  final File uploadedImage;

  PhotoFilterSelectorWidget({Key key, this.setFilter, this.uploadedImage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.0,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          itemBuilder: (BuildContext context, int index) => _photoFilterWidget(context, index)),
    );
  }

  Widget _photoFilterWidget(BuildContext context, int index) {
    Filter currentFilter = filters[index];

    String fileName = 'assets/filters/' + currentFilter.name.replaceAll(RegExp(r"\s+\b|\b\s"), "") + '.jpg';
    BorderSide side = BorderSide(color: Theme.of(context).primaryColor, width: 2.0);
    return GestureDetector(
      onTap: () {
        setFilter(currentFilter);
      },
      child: Container(
        child: Image(
          width: 60.0,
          height: 60.0,
          fit: BoxFit.cover,
          image: AssetImage(fileName),
        ),
        decoration: BoxDecoration(
          border: Border(
            top: side,
            right: side,
            bottom: side,
            left: index == 0 ? side : BorderSide.none,
          )
        ),
      ),
    );
  }
}
