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

class showVideo2 extends StatefulWidget {
  List<File> listFiles;
  File file;
  showVideo2({Key? key, required this.file, required this.listFiles})
      : super(key: key);

  @override
  _PlayFilmState2 createState() => _PlayFilmState2();
}

class _PlayFilmState2 extends State<showVideo2>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late VideoPlayerController videoPlayerControler = VideoPlayerController.file(
      widget.file,
      videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true));
  late ChewieController chewieController;

  late int currPlayIndex;

  SwiperController swipecontroller = SwiperController();

  bool _showControl = false;

  double currentvolume = 10;

  bool _mute = false;

  Duration _position = const Duration(milliseconds: 0);

  bool _showControl2 = false;

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
    setState(() {
      _showControl = false;
    });
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
    initializePlayer();
/* 
    chewieController = ChewieController(
        videoPlayerController: videoPlayerControler,
        autoInitialize: true,
        //customControls: CustomContr(),
        // systemOverlaysAfterFullScreen: SystemUiOverlay.values,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xfffe2c55),
          // backgroundColor: Colors.red,
          //handleColor: Colors.red,
          //  bufferedColor: Colors.red
        ),
        showControlsOnInitialize: false,
        //hideControlsTimer: const Duration(milliseconds: 10),
        autoPlay: true); */

    videoPlayerControler.addListener(() {
      setState(() {
        if (chewieController.isPlaying) {
          isPlaying = true;
        } else {
          isPlaying = false;
        }
      });

      setState(() {
        print(videoPlayerControler.value.position.toString().split(".")[0]);
        currentTime =
            videoPlayerControler.value.position.toString().split(".")[0];
        completeTime =
            videoPlayerControler.value.duration.toString().split(".")[0];
      });

      if (videoPlayerControler.value.position ==
          videoPlayerControler.value.duration) {
        print('video Ended');
      }
    });
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    videoPlayerControler.dispose();
    chewieController.dispose();
    super.dispose();
  }

  bool isPlaying = false;
  String currentTime = "0:00:00";
  String completeTime = "0:00:00";
  Widget CustomContr() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
            // margin: EdgeInsets.only(top: 50),
            width: MediaQuery.of(context).size.width * .95,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.3),
              borderRadius: BorderRadius.circular(80),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                    icon: Icon(
                      Icons.replay_10,
                      color: Colors.black,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        chewieController.seekTo(
                            videoPlayerControler.value.position -
                                const Duration(seconds: 10));
                      });
                    }),
                IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.black,
                      size: 30,
                    ),
                    onPressed: () {
                      if (isPlaying) {
                        chewieController.pause();

                        setState(() {
                          isPlaying = false;
                        });
                      } else {
                        chewieController.play();
                        setState(() {
                          isPlaying = true;
                        });
                      }
                    }),
                IconButton(
                    icon: Icon(
                      Icons.forward_10,
                      color: Colors.black,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        chewieController.seekTo(
                            videoPlayerControler.value.position +
                                const Duration(seconds: 10));
                      });
                    }),
                /*  IconButton(
                  icon: Icon(
                    Icons.stop,
                    color: Colors.black,
                    size: 25,
                  ),
                  onPressed: () {
                    chewieController.pause();

                    setState(() {
                      isPlaying = false;
                    });
                  },
                ),
             */
                Text(
                  currentTime,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                /* Text(" | "),
                Text(
                  completeTime,
                  style: TextStyle(fontWeight: FontWeight.w300),
                ), */
                IconButton(
                    icon: Icon(
                      _mute ? Icons.volume_off : Icons.volume_mute,
                      color: Colors.black,
                      size: 30,
                    ),
                    onPressed: () async {
                      currentvolume = videoPlayerControler.value.volume;
                      _mute
                          ? await chewieController.setVolume(1.0)
                          : await chewieController.setVolume(0.0);
                      _mute = !_mute;
                      setState(() {
                        print("currentvolume$currentvolume");

                        print("_mute$_mute");
                      });
                    }),
              ],
            )),
        const SizedBox(
          height: 5,
        ),
        GestureDetector(
            //onHorizontalDragStart: ff,
            child: SizedBox(
          width: MediaQuery.of(context).size.width,
          //  height: 80,
          child: SliderTheme(
            data: SliderThemeData(
              thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: 6,
                  pressedElevation: 4,
                  elevation: 2,
                  disabledThumbRadius: 2),
              trackHeight: 4,
              thumbColor: const Color(0xfffe2c55),
              inactiveTrackColor: Colors.white,
              activeTrackColor: const Color(0xfffe2c55),
              overlayColor: const Color(0xfffe2c55),
            ),
            child: Slider(
                autofocus: true,
                value: _position != null
                    ? videoPlayerControler.value.position.inMilliseconds
                        .toDouble()
                    : 0.0,
                min: 0.0,
                max: videoPlayerControler.value.duration != null
                    ? videoPlayerControler.value.duration.inMilliseconds
                        .toDouble()
                    : 0.0,
                onChanged: (double value) async {
                  await videoPlayerControler
                      .seekTo(Duration(milliseconds: value.toInt()));

                  _position = Duration(milliseconds: value.toInt());
                },
                onChangeStart: (double value) async {
                  setState(() {
                    _showControl2 = true;
                  });
                },
                onChangeEnd: (double value) async {
                  setState(() {
                    _showControl2 = false;
                  });
                }),
          ),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12,
      body: Swiper(
        scrollDirection: Axis.vertical,
        physics: _showControl2
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        controller: swipecontroller,
        loop: false,
        index: currPlayIndex == widget.listFiles.length - 1
            ? widget.listFiles.length - 1
            : currPlayIndex,
        //  widget.listFiles            .indexWhere((element) => element.path == widget.file.path),
        onIndexChanged: next2,
        itemBuilder: (BuildContext context, int index) {
          return videoPlayerControler.value.isInitialized
              ? InkWell(
                  onTap: () {
                    setState(() {
                      _showControl = !_showControl;
                    });
                  },
                  child: Stack(
                    children: [
                      Chewie(controller: chewieController),
                      _showControl
                          ? Align(
                              alignment: Alignment.center, child: CustomContr())
                          : SizedBox()
                    ],
                  ))
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

/*   void next(int value) {
    print("valuuue$value");
    print(widget.listFiles[value].path);

    videoPlayerControler = VideoPlayerController.file(widget.listFiles[value]);
    log("${widget.listFiles}");
    videoPlayerControler.addListener(() {});
    chewieController = ChewieController(
        videoPlayerController: videoPlayerControler,
        autoInitialize: true,
        showControls: true,
        showControlsOnInitialize: true,
        hideControlsTimer: const Duration(milliseconds: 10),
        autoPlay: true);
  } */

  Future<void> toggleVideo(int index) async {
    setState(() {
      currPlayIndex = index;
    });

    //

    await initializePlayer();
  }

  Future<void> initializePlayer() async {
    videoPlayerControler =
        VideoPlayerController.file(widget.listFiles[currPlayIndex]);
    chewieController = ChewieController(
        videoPlayerController: videoPlayerControler,
        autoInitialize: true,
        showControls: false,

        //fullScreenByDefault: true,
        //aspectRatio:  ,
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

  void ff(DragStartDetails details) {
    print(details);
  }
}
