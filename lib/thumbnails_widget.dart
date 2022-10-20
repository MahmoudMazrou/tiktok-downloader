import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailWidget extends StatelessWidget {
  final String path;

  const ThumbnailWidget({Key? key, required this.path}) : super(key: key);

  Future<Uint8List?> getBackgroundImage(path) async {
    return await VideoThumbnail.thumbnailData(
      video: path,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 480,
      maxWidth: 360,
      // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
      quality: 100,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: getBackgroundImage(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Shimmer.fromColors(
            baseColor: Colors.black,
            highlightColor: Color.fromARGB(239, 0, 0, 0),
            child: Container(
              //height: height,
              //width: width,
              color: Colors.white,
            ),
          );
        } else {
          return Image.memory(
            snapshot.requireData!,
            filterQuality: FilterQuality.high,
            fit: BoxFit.cover,
          );
        }
      },
    );
  }
}
