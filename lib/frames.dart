import 'package:flutter/material.dart';

class PhotoFrameSelectorWidget extends StatelessWidget {
  static final numberOfFrames = 29;
  static final photoFrameFileNames =
  List<String>.generate(numberOfFrames, (int index) => 'assets/frame' + index.toString() + '.png');
  final Function(String) setFrame;

  PhotoFrameSelectorWidget({Key key, this.setFrame}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: numberOfFrames,
        itemBuilder: (BuildContext context, int index) => _photoFrameWidget(photoFrameFileNames[index])),
    );
  }

  Widget _photoFrameWidget(String fileName) {
    return GestureDetector(
      onTap: () {
        setFrame(fileName);
      },
      child: Image(
        fit: BoxFit.contain,
        image: AssetImage(fileName),
      ),
    );
  }
}
