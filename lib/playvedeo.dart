import 'dart:developer';
import 'dart:io';

import 'package:card_swiper/card_swiper.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/animation/animation_controller.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/ticker_provider.dart';
import 'package:video_player/video_player.dart';

class showVideo extends StatefulWidget {
  List<File> listFiles;
  File file;
  showVideo({Key? key, required this.file, required this.listFiles})
      : super(key: key);

  @override
  _PlayFilmState createState() => _PlayFilmState();
}

class _PlayFilmState extends State<showVideo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late VideoPlayerController videoPlayerControler = VideoPlayerController.file(
      widget.file,
      videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true));
  late ChewieController chewieController;

  late int currPlayIndex;

  SwiperController swipecontroller = SwiperController();

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  List<File> listFiles2 = [];
  late File lastfile;

  @override
  void initState() {
    lastfile = widget.listFiles.last;
    int a = widget.listFiles.indexWhere((e) => e.path == widget.file.path);
    print("aaaa$a");
    for (int i = 1; i < widget.listFiles.length; i++) {
      print("aaa$a");
      listFiles2.add(widget.listFiles[a]);
      if (a == (widget.listFiles.length - 1)) {
        a = 0;
      } else {
        a++;
      }
    }
    setState(() {});
    print("eeee${listFiles2.length}");
    currPlayIndex =
        widget.listFiles.indexWhere((el) => el.path == widget.file.path);
    print("currr$currPlayIndex");
    log("${widget.listFiles}");
    videoPlayerControler.addListener(() {
      setState(() {});
    });
    chewieController = ChewieController(
        videoPlayerController: videoPlayerControler,
        autoInitialize: true,
        systemOverlaysAfterFullScreen: SystemUiOverlay.values,
        showControls: true,
        showControlsOnInitialize: false,
        //hideControlsTimer: const Duration(milliseconds: 10),
        autoPlay: true);
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    videoPlayerControler.dispose();
    chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12,
      body: Swiper(
        controller: swipecontroller,
        loop: false,
        index: currPlayIndex == widget.listFiles.length - 1
            ? widget.listFiles.length - 1
            : currPlayIndex,
        //  widget.listFiles            .indexWhere((element) => element.path == widget.file.path),
        onIndexChanged: next2,
        itemBuilder: (BuildContext context, int index) {
          return videoPlayerControler.value.isInitialized
              ? Chewie(controller: chewieController)
              : const Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.transparent,
                    color: Colors.transparent,
                  ),
                );
        },
        itemCount: widget.listFiles.length,
      ),
    );
  }

  void next(int value) {
    print("valuuue$value");
    print(widget.listFiles[value].path);

    videoPlayerControler = VideoPlayerController.file(widget.listFiles[value]);
    log("${widget.listFiles}");
    videoPlayerControler.addListener(() {});
    chewieController = ChewieController(
        videoPlayerController: videoPlayerControler,
        autoInitialize: true,
        showControls: false,
        showControlsOnInitialize: true,
        hideControlsTimer: const Duration(milliseconds: 10),
        autoPlay: true);
  }

  Future<void> toggleVideo(int index) async {
    setState(() {
      currPlayIndex = index;
    });

    //

    await initializePlayer();
    setState(() {});
  }

  Future<void> initializePlayer() async {
    videoPlayerControler =
        VideoPlayerController.file(widget.listFiles[currPlayIndex]);
    chewieController = ChewieController(
        videoPlayerController: videoPlayerControler,
        autoInitialize: true,
        showControls: true,
        showControlsOnInitialize: false,

        // hideControlsTimer: const Duration(milliseconds: 10),
        autoPlay: true);
    print("indexxx $currPlayIndex");

    /*  await Future.wait([
      videoPlayerControler.initialize(),
    ]); */
    // _createChewieController();
  }

  /* void _createChewieController() {
    int? bufferDelay;
    _chewieController = ChewieController(
        videoPlayerController: videoPlayerControler,
        autoPlay: true,
        looping: true,
        progressIndicatorDelay:
            bufferDelay != null ? Duration(milliseconds: bufferDelay) : null,
        additionalOptions: (context) {
          return <OptionItem>[
            OptionItem(
              onTap: () {},
              iconData: Icons.live_tv_sharp,
              title: 'Toggle Video Src',
            ),
          ];
        });
  }
 */
  void next2(int value) {
    /*  print(
        "truuuuu $value -- ${(listFiles2[value].path == lastfile.path)} -- ${widget.listFiles.length - 1})");
    if (listFiles2[value].path == lastfile.path) {
      //   toggleVideo(value);
      setState(() {
        //   swipecontroller.move(value);

        //  swipecontroller.previous();

        //= widget.listFiles.length - 1;
      });
    } else { */
    toggleVideo(value);
    //}
  }
}
