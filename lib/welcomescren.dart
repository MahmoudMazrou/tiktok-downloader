import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:disk_space/disk_space.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:new_app/dialogue/download_warning_dialogue.dart';
import 'package:new_app/local/cache_helper.dart';
import 'package:new_app/single_video.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'models/video.dart';
import 'dart:async';
import 'dart:convert';
import 'package:html/parser.dart' show parse;
import 'package:flutter_downloader/flutter_downloader.dart';

class WelcomScreen extends StatefulWidget {
  const WelcomScreen({Key? key}) : super(key: key);

  @override
  State<WelcomScreen> createState() => _WelcomScreenState();
}

class _WelcomScreenState extends State<WelcomScreen> {
  //عندما تكون الشاشة فارغة
  static const platform = MethodChannel('app.channel.shared.data');
  String? dataShared

  /* ='https://vm.tiktok.com/ZMNpKfgRb/?k=1'*/;

  bool profile = false;
  bool video = false;

  Future<void> getSharedText() async {
    //بيتم استدعائها لمن افتح الشاشة بدون مشاركة شي عليها
    print("getSharedText *******");
    var sharedData = await platform.invokeMethod('getSharedText');
    if (sharedData != null) {
      dataShared = sharedData;
      print("getSharedText$dataShared");
      if (dataShared!.contains('https://vm.')) {
        setState(() {
          video = true;
        });
      } else {
        setState(() {
          profile = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //الشاشة عندما ما اكون مشارك عليها شي
    return Stack(
      children: [
        profile
            ? MyHomePage(
          title: dataShared!,
        )
            : video
            ? SingleVideoPage(
          sharedUrl: dataShared!,
        )
            : Container(
          color: Colors.white,
        ),
      ],
    );
  }

  @override
  void initState() {
    //الخاصة ب الشاشة وهي فارغة
    getSharedText();
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({
    Key? key,
    required this.title,
  }) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  List<TaskInfo>? _tasks;
  late List<ItemHolder> _items;
  late bool _loading; //جلبنا بيانات اعطي صح
  late bool _permissionReady;
  late String _localPath = '/storage/emulated/0/Download/New App/';
  final ReceivePort _port = ReceivePort();

  HeadlessInAppWebView? headlessWebView;
  static const platform = MethodChannel('app.channel.shared.data');
  String? dataShared

  /*='https://vm.tiktok.com/ZMNpKfgRb/?k=1'*/;

  InAppWebViewController? webViewController;
  InAppWebViewController? headlessWebViewController;
  String? avatar;
  String? name = '';
  String? atname = '';
  List<VideoModel> trimmedVideos = []; //قائمة الفيديوهات الي جبناها عنا عتطبيق
  List<VideoModel> videos = []; //قائمة الفيديوهات ليست الي من التيك توك
  int? allVideosCount; // عدد الفيديوهات الي جاية من التيك توك
  dynamic data;
  dynamic images;
  dynamic urls;
  dynamic watches;
  bool isLoading = false;
  int triesCount = 0;
  bool selectAll = false;
  var initialVideosListData;
  List<VideoModel> selectedVideos = []; //الفيديوهات الي حددناها
  bool isDownloading = false;
  double downloadProgress = 0;
  int downloadFile = 0;
  CancelToken _cancelToken = CancelToken();
  String? isPermission = CacheHelper.getData(key: 'isPermission') ?? "perm1";
  bool isCanceled = false; // هاد عملتو عشان امنع ظهور الرسالة اكثر من مرة تعت الكانسل
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool isBotmoConectivity = true;
  bool isTopConectivity = true;
  double? diskFree = 0;
  Future<void> initDiskSpace() async {
    diskFree = await DiskSpace.getFreeDiskSpace;
  }

  void _showErrorDialog(String message, BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      useRootNavigator: false,
      builder: (ctx) =>
          AlertDialog(
            // child: Column(
            //   mainAxisSize:MainAxisSize.min,
            //   children: [
            //     Text ("Cancel!",style: TextStyle(
            //       fontWeight: FontWeight.bold,
            //       fontSize: 20
            //     )),
            //     Text ("message",style: TextStyle(
            //        // fontWeight: FontWeight.bold,
            //         fontSize: 18
            //     )),
            //   ],
            // )
            title: Text("Cancel!"),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: Text("No",
                  style: TextStyle(
                    color: Color.fromRGBO(254, 44, 85, 1.0),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),),

                onPressed: () async {
                  _tasks?.sublist(downloadFile).forEach((element) async {
                    await _retryDownload(element);
                  });
                  isDownloading = true;
                  Navigator.of(ctx).pop();
                  setState(() {
                    isDownloading = true;
                  });
                },
              ),
              TextButton(
                child: Text("Yes",
                  style: TextStyle(
                    color: Color.fromRGBO(254, 44, 85, 1.0),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),),
                onPressed: () async {
                  await FlutterDownloader.cancelAll();

                  _tasks?.sublist(downloadFile).forEach((element) async {
                    await _delete(element);
                  });
                  Navigator.of(ctx).pop();
                  setState(() {
                    isDownloading = false;
                  });
                  setState(() {
                    _modalBottomSheetMenu("cancel", "eee");
                  });
                },
              ),
            ],

          ),

    );
  }


  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    _connectivitySubscription.cancel();

    super.dispose();
  }


  void _bindBackgroundIsolate() {
    //بيتم استدعائها اول منفتح وحنا مشاركين البيانات
    final isSuccess = IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'downloader_send_port',
    );
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }

    _port.listen((dynamic data) {
    //  initDiskSpace();
      //  print(data);
      final taskId = (data as List<dynamic>)[0] as String;
      DownloadTaskStatus status = data[1] as DownloadTaskStatus;
      final progress = data[2] as int;

      // print(
      //   'Callback on UI isolateeeeeeeeeeee: '
      //   'task ($taskId) is in status ($status) and process ($progress)',
      // );

      setState(() {
        if (status == DownloadTaskStatus.paused) {
          // print("compketeeeedpaused");
          // print("compketeeeed1paused $downloadFile");
          //
          // print("compketeeeed2paused $downloadFile");
          print("compketeeeed3************paused ${selectedVideos.length.toString()}");
        } else if (status == DownloadTaskStatus.canceled) {
          // print("compketeeeedcanceled");
          // print("compketeeeed1canceled $downloadFile");
          //
          // print("compketeeeed2canceled $downloadFile");
          print("compketeeeed3**************canceled ${selectedVideos.length.toString()}");
          if (isCanceled) {
            _tasks?.sublist(downloadFile).forEach((element) async {
              await _pauseDownload(element);
            });
            setState(() async {
              isDownloading = false;
              isCanceled = false;
              print("fffffffffffffffff");
              bool checInternet = await checkConectivity();
              if (checInternet == false) {
                isDownloading = false;
                _modalBottomSheetMenu("err", "");
              } else if (diskFree! <= 750) {
                _modalBottomSheetMenu("space", "");
              }
            });
          } else if (isDownloading) {
            _tasks?.sublist(downloadFile).forEach((element) async {
              await _pauseDownload(element);
            });
            setState(() {
              isDownloading = false;
            });
            _modalBottomSheetMenu("err", "");
          }
        } else if (status == DownloadTaskStatus.failed) {
          // print("compketeeeedfailed");
          // print("compketeeeed1failed $downloadFile");
          //
          // print("compketeeeed2failed $downloadFile");
          print("compketeeeed3****************failed ${selectedVideos.length.toString()}");
          if (isCanceled) {
            _tasks?.sublist(downloadFile).forEach((element) async {
              await _pauseDownload(element);
            });

            setState(() async {
              isDownloading = false;
              isCanceled = false;
              print("compketeeeed333");
              //isDownloading = false;
              bool checInternet = await checkConectivity();
              if (checInternet == false) {
                _modalBottomSheetMenu("err", "");
              } else if (diskFree! <= 750) {
                _modalBottomSheetMenu("space", "");
              }
            });
          } else if (isDownloading) {
            _tasks?.sublist(downloadFile).forEach((element) async {
              await _pauseDownload(element);
            });
            setState(() {
              isDownloading = false;
            });
            _modalBottomSheetMenu("err", "");
          }
        } else if (status == DownloadTaskStatus.complete) {
          FlutterDownloaderException;
          // print("${FlutterDownloaderException(message: "message")}");
          // print("compketeeeedcomplete");
          // print("compketeeeed1complete $downloadFile");
          initDiskSpace();
          downloadFile++;
         // print("compketeeeed2complete $downloadFile");
          print("compketeeeed3complete ${selectedVideos.length.toString()}");

          if (downloadFile == selectedVideos.length) {
            setState(() {
              print("compketeeeed333complete");
              isDownloading = false;
              _modalBottomSheetMenu("ok", "");
            });
            ;
          }
        }else{

          setState(() async {

           // print("compketeeeed333");
            //isDownloading = false;
            bool checInternet = await checkConectivity();
            if (checInternet == false) {
              isDownloading = false;
              isCanceled = false;
              _modalBottomSheetMenu("err", "");
            } else if (diskFree! <= 750) {
              isDownloading = false;
              isCanceled = false;
              _modalBottomSheetMenu("space", "");
            }
          });
        }
        downloadProgress = progress.toDouble();
        // print("downloadFile");
        //
        // print("downloadFile1$downloadFile");
        print("downloadFile*******************1${selectedVideos.length}");
      });

      if (downloadFile == selectedVideos.length) {
        // _modalBottomSheetMenu("ok", "");
        //isDownloading = false;
        //print("isDownloadinggg$isDownloading");
      }

      if (_tasks != null && _tasks!.isNotEmpty) {
        //isDownloading = true;

        final task = _tasks!.firstWhere((task) => task.taskId == taskId);
        setState(() {
          //isDownloading = true;

          task
            ..status = status
            ..progress = progress;
        });
      }
      //
      // else {
      //   setState(() {
      //     isDownloading = false;
      //   });
      // }
    });
    // setState(() {
    //   isDownloading = false;
    // });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id,
      DownloadTaskStatus status,
      int progress,) {
    print(
      'Callback on background isolate: '
          'task ($id) is in status ($status) and process ($progress)',
    );

    IsolateNameServer.lookupPortByName('downloader_send_port')
        ?.send([id, status, progress]);
  }

  @override
  void initState() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    // getSharedText();
    dataShared = widget.title;
    _bindBackgroundIsolate();

    FlutterDownloader.registerCallback(downloadCallback, step: 1);

    _loading = true;
    _permissionReady = false;
    print("isDownloading$isDownloading");
    initDiskSpace();
    super.initState();
    // _prepare();


  }

  void htmlParser(String value) {
    //استدعيت في المور فقط
    avatar = value
        .split('<meta data-rh="true" property="og:image" content="')[1]
        .split('">')[0];
    data = parse(value);
    images = data
        .querySelectorAll(
        'div > div > a > div > div.tiktok-1jxhpnd-DivContainer.e1yey0rl0 > img')
        .map((element) => element.attributes['src'].trim())
        .toList();
    print("images$images");
    urls = data
        .querySelectorAll(
        'div.tiktok-yvmafn-DivVideoFeedV2.e5w7ny40 >div > div > div > div > a')
        .map((element) => element.attributes['href'].trim())
        .toList();
    watches = data
        .querySelectorAll(
        'div > div > a > div > div.tiktok-11u47i-DivCardFooter.e148ts220 > strong')
        .map((element) => element.text)
        .toList();
    // allVideosCount = int.parse(value.split(',"videoCount":')[1].split(',"diggCount"')[0]);
    videos.addAll(List.generate(
        images.length,
            (index) =>
            VideoModel(
                id: urls[index].toString().split('video/')[1],
                url: urls[index],
                thumbUrl: images[index],
                watchesCount: watches[index],
                downloadAddr: initialVideosListData[
                urls[index].toString().split('video/')[1]] ==
                    null
                    ? null
                    : initialVideosListData[
                urls[index].toString().split('video/')[1]]['video']
                ['downloadAddr'])).sublist(videos.length));
    if (selectAll && !isDownloading) {
      selectedVideos = List.from(videos);
    }
    trimmedVideos = List.from(videos.sublist(0, videos.length - getTrimSize()));
    setState(() {});
    print("images.length");

    print(images.length);
    print(videos.length);
    print(urls);
  }

  int getTrimSize() {
    if (allVideosCount == null || videos.length >= allVideosCount! - 3) {
      return 0;
    } else {
      return videos.length % 3;
    }
  }

  Future<void> getSharedText() async {
    var sharedData = await platform.invokeMethod('getSharedText');
    if (sharedData != null) {
      dataShared = sharedData;
    }
    /* headlessWebView =  HeadlessInAppWebView(
      initialOptions: InAppWebViewGroupOptions(crossPlatform:
      InAppWebViewOptions(
        preferredContentMode: UserPreferredContentMode.DESKTOP,
        useShouldInterceptFetchRequest: true,

      ),
      ),
      shouldInterceptFetchRequest: (controller,request){
        //print('request: ${request.url}');
        return Future(() => request);
      },
      onPageCommitVisible: (controller,url){
        controller.getHtml().then((value) => {
          print('length: ${value!.length}'),
        });
      },
      onLoadStart: (controller,uri){
     //   print('loaaaaaad started');
      },

      onWebViewCreated: (InAppWebViewController controller) {
        print('creaaaaaaaated');
        headlessWebViewController = controller;
      },
    );*/
  }

  Future<bool> checkConectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return false;
      // I am connected to a mobile network.
    }
    return true;
  }

  Widget topWidget() {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            name != null
                ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '$name',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600),
              ),
            )
                : Container(
              padding: const EdgeInsets.all(16.0),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors .grey,
                        borderRadius: BorderRadius.circular(50),
                      //  shape: BoxShape.circle
                  ),
                  // backgroundColor: Colors.grey.shade300,
                  // radius: 50,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                      height: 100,
                      //  color: Colors.black,
                        alignment: Alignment.center,
                      //  child: Image.asset('images/loading-avatar.gif'),
                        decoration: BoxDecoration(
                          // color: Colors .grey,
                          borderRadius: BorderRadius.circular(50),
                          image:    DecorationImage(
                            image: const AssetImage('images/loading-avatar.gif'),
                            fit: BoxFit.fill
                          ),
                          //  shape: BoxShape.circle
                        ),
                      ),
                      avatar != null
                     ? ClipOval(
                       child: Image.network(

                          avatar!,

                        //  fit: BoxFit.fill,
                          errorBuilder: (_, obj, trace) {
                            return Container(
                         //     color: Colors.grey,
                             // width: double.infinity,
                         //     height: double.infinity,
                           //   alignment: Alignment.center,
                              child: Container(
                                decoration: BoxDecoration(
                                 // color: Colors .grey,
                                  borderRadius: BorderRadius.circular(50),
                               image:    DecorationImage(
                                    image: const AssetImage('images/generic_author.png'),
                                  ),
                                  //  shape: BoxShape.circle
                                ),
                         //       child: Image.asset('images/generic_author.png'),
                              ),
                            );
                          },
                          /*  loadingBuilder: (context,child,loadingProgress){
                        if (loadingProgress == null) {
                          return child;
                        }else {
                          return Container(
                            alignment: Alignment.center,
                            child: Image.asset('images/loading.gif'),
                          );
                        }
                    }*/
                        ),
                     )
                          :Container(),
                    ],
                  )

                //  child: avatar != null
                //      ? ClipRRect(
                //          child: Image.network(
                //            avatar!,
                //
                //            errorBuilder: (_, obj, trace) {
                //              return ClipRRect(
                //                  child: Image.asset("images/generic_author.png"),
                //                  borderRadius: BorderRadius.circular(50.0),
                //
                //              );
                //            },
                //
                //          ),
                //          borderRadius: BorderRadius.circular(50.0),
                //        )
                //      :
                //  ClipRRect(
                //   child: Image.asset("images/loading.gif"),
                //   borderRadius: BorderRadius.circular(50.0),
                // ),
                //  // Container(
                //  //         width: 50,
                //  //         height: 50,
                //  //         decoration: BoxDecoration(
                //  //             color: Colors.grey.shade300,
                //  //             borderRadius:
                //  //                 const BorderRadius.all(Radius.circular(50))),
                //  //
                //  //       ),

              ),
            ),
            atname != null
                ? Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    //النص تاع تاق التيك توك محذوف
                    //     '$atname',
                    "",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
                : Container(
              padding: const EdgeInsets.only(top: 8.0, bottom: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget thumbnailsGrid() {
    //ليست
    return ListView(
      // controller: _controller,
      children: [
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 0.5,
            childAspectRatio: 0.7,
            mainAxisSpacing: 0.5,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, index) =>
              GestureDetector(
                onTap: isDownloading
                    ? () async {}
                    : () {
                  if (selectedVideos.contains(
                      trimmedVideos[index])) { //trimmedVideos[index]  الفييديو  الي ضغطنا عليه
                    setState(() {
                      selectedVideos.remove(trimmedVideos[index]);
                    });
                  } else {
                    setState(() {
                      selectedVideos.add(trimmedVideos[index]);
                    });
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      child: Image.asset('images/loading.gif'),
                    ),
                    Image.network(
                      trimmedVideos[index].thumbUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, obj, trace) {
                        return Container(
                          color: Colors.black,
                          width: double.infinity,
                          height: double.infinity,
                          alignment: Alignment.center,
                          child: Container(
                            width: MediaQuery
                                .of(context)
                                .size
                                .height * .07,
                            height: MediaQuery
                                .of(context)
                                .size
                                .height * .07,
                            child: Image.asset('images/generic_thumbnail.png'),
                          ),
                        );
                      },
                      /*  loadingBuilder: (context,child,loadingProgress){
                      if (loadingProgress == null) {
                        return child;
                      }else {
                        return Container(
                          alignment: Alignment.center,
                          child: Image.asset('images/loading.gif'),
                        );
                      }
                    }*/
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  //     Colors.black.withAlpha(180),
                                  //     Colors.white,
                                  Colors.transparent,
                                  Colors.transparent,

                                ],
                              )),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                '',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                    fontFamily: 'tiktok'),
                              ),

                            ],
                          ),
                        ),
                      ),
                    ),
                    // Transform.scale(
                    //   scale:MediaQuery.of(context).size.height * .005,
                    //   child: Checkbox( //شيكبوكس
                    //       checkColor: Color.fromRGBO(147, 242, 237, 1.0),
                    //       activeColor:Colors.transparent,
                    //       value: selectedVideos.contains(
                    //         trimmedVideos[index],
                    //       ),
                    //       side:  BorderSide(
                    //         color: Colors.transparent,
                    //         width: 0,
                    //
                    //       ),
                    //       onChanged: (value) {}),
                    // ),
                    Container( //الظل  الي فوق  الفيديوهات
                      color: selectedVideos.contains(trimmedVideos[index])
                          ? Color.fromRGBO(147, 242, 237, 1.0).withAlpha(120)
                      // : Colors.white.withAlpha(120),
                          : Colors.transparent, //معناها فش لون
                    ),
                    Icon(Icons.check, color: selectedVideos.contains(
                      trimmedVideos[index],
                    ) ? Color.fromRGBO(147, 242, 237, 1.0)
                        : Colors.white,
                      size: MediaQuery
                          .of(context)
                          .size
                          .height * .07,
                    ),
                  ],
                ),
              ),
          itemCount: videos.length >= 17
              ? trimmedVideos.length : trimmedVideos.length == 16
              ? trimmedVideos.length - 4 : trimmedVideos.length == 15
              ? trimmedVideos.length - 3 : trimmedVideos.length == 14
              ? trimmedVideos.length - 2 : trimmedVideos.length == 13
              ? trimmedVideos.length - 1 :
          trimmedVideos.length,
        ),
        allVideosCount == null ||
            videos.length >=
                allVideosCount! -
                    3 //allVideosCount عدد الفيديوها الي جاية من التيك توك
            ? Container() //
            : isLoading //كل الفيديوهات الي جيات من التيك توك محملات
            ? Container(
          //الكونتينر الأزرق الي بيظهر فوق كلمة مور بقا لمن اضغط عليها
          //  height: 54,
          color: Colors.blue,
          alignment: Alignment.center,
        )
            : InkWell(
          onTap: isDownloading
              ? () async {}
              : () async {
            setState(() {
              isLoading = true;
            });
            String? html;
            int prevLength = videos.length;
            html = await webViewController!.getHtml();
            htmlParser(html!);
            print(
                "********************allVideosCount********$allVideosCount videos.length${videos
                    .length}");
            while (videos.length == prevLength &&
                allVideosCount != null &&
                videos.length < allVideosCount! - 3 &&
                triesCount < 5) {
              triesCount++;
              webViewController!.android.pageDown(bottom: true);
              html = await webViewController!.getHtml();
              htmlParser(html!);
              await Future.delayed(
                  const Duration(seconds: 1), () {});
            }
            if (triesCount == 5) {
              allVideosCount = videos.length;
              htmlParser(html!);
            }

            triesCount = 0;
            setState(() {
              isLoading = false;
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 12),
            child: const Text(
              'MORE',
              style: TextStyle(
                color: Color.fromRGBO(254, 44, 85, 1.0),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    //البداية لمن  يكون في بيانات جاية
    Color getColor(Set<MaterialState> states) {
      //هاي  شيك بوكس
      const Set<MaterialState> interactiveStates = <MaterialState>{
        MaterialState.pressed,
        MaterialState.hovered,
        MaterialState.focused,
      };

      return Colors.transparent;
    }
    return Scaffold(



      bottomSheet: (!isDownloading)
          ? null
          : BottomSheet(
          enableDrag :false,
          builder: (context) {
            return Container(
         decoration: new BoxDecoration(
           color: const Color.fromARGB(255, 228, 225, 225),
           /*  borderRadius: new BorderRadius.only(
                              topLeft: const Radius.circular(40.0),
                              topRight: const Radius.circular(40.0)) */
         ),
         height: MediaQuery
             .of(context)
             .size
             .height * .4,
         child: Column(
           mainAxisAlignment: MainAxisAlignment.spaceAround,
           children: [
             Padding(
                 padding: const EdgeInsets.only(top: 15),
                 child: Image.asset(
                   'images/Download.png',
                   height: 70,
                   width: 70,
                 )),
             Padding(
               padding: const EdgeInsets.only(top: 8.0),
               child: Text(
                 'Video ${downloadFile} of ${selectedVideos
                     .length}' /*  ' ${selectedVideos[downloadFile].id} .mp4'*/,
                 style: const TextStyle(fontSize: 16),
               ),
             ),
             /*      Padding(
                            padding: const EdgeInsets.only(bottom: 20, top: 20),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10,
                              children: [
                                Text('Current'),
                                LinearProgressIndicator(value: (downloadProgress)),
                              ],
                            )), */
             Padding(
               padding: const EdgeInsets.only(top: 10),
               child: LinearProgressIndicator(
                 semanticsValue: downloadProgress.toString(),
                 value: (downloadFile +
                     (downloadProgress < 100
                         ? downloadProgress / 100
                         : 0)) /
                     selectedVideos.length,
               ),
             ),
             Padding(
               padding: const EdgeInsets.all(8.0),
               child: InkWell(
                 onTap: () async {
                   _tasks?.sublist(downloadFile).forEach((element) async {
                     await _pauseDownload(element);
                   });
                   setState(() {
                     isDownloading = false;
                   });
                   _showErrorDialog(
                       "Are you sure to cancel the download", context);
                 },
                 child: Container(
                     height: 38,
                     alignment: Alignment.center,
                     decoration: const BoxDecoration(
                         color: Colors.blue,
                         borderRadius:
                         BorderRadius.all(Radius.circular(8))),
                     child: const Text(
                       'Cancel',
                       style: TextStyle(color: Colors.white, fontSize: 15),
                     )),
               ),
             ),
           ],
         ),
       );
     }, onClosing: () {  },
          ),
      // Countdown(
      //   seconds: 1,
      //   build: (BuildContext context, double time) =>
      //       Text(time.toString(), style: TextStyle(
      //           color: Colors.transparent),),
      //   interval: Duration(milliseconds: 100),
      //   onFinished: () async {
      //     setState(() {
      //       showModalBottomSheet(
      //           elevation:
      //           10,
      //           backgroundColor:
      //           Colors
      //               .transparent,
      //           isDismissible:false,
      //
      //           context:
      //           context,
      //           builder:
      //               (builder) {
      //             return StatefulBuilder(
      //                 builder: (BuildContext
      //                 context,
      //                     StateSetter
      //                     setState
      //                     /*You can rename this!*/) {
      //                   return  Container(
      //                     decoration: new BoxDecoration(
      //                       color: const Color.fromARGB(255, 228, 225, 225),
      //                       /*  borderRadius: new BorderRadius.only(
      //                   topLeft: const Radius.circular(40.0),
      //                   topRight: const Radius.circular(40.0)) */
      //                     ),
      //                     height: MediaQuery
      //                         .of(context)
      //                         .size
      //                         .height * .4,
      //                     child: Column(
      //                       mainAxisAlignment: MainAxisAlignment.spaceAround,
      //                       children: [
      //                         Padding(
      //                             padding: const EdgeInsets.only(top: 15),
      //                             child: Image.asset(
      //                               'images/Download.png',
      //                               height: 70,
      //                               width: 70,
      //                             )),
      //                         Padding(
      //                           padding: const EdgeInsets.only(top: 8.0),
      //                           child: Text(
      //                             'Video ${downloadFile} of ${selectedVideos
      //                                 .length}' /*  ' ${selectedVideos[downloadFile].id} .mp4'*/,
      //                             style: const TextStyle(fontSize: 16),
      //                           ),
      //                         ),
      //                         /*      Padding(
      //                 padding: const EdgeInsets.only(bottom: 20, top: 20),
      //                 child: Wrap(
      //                   alignment: WrapAlignment.center,
      //                   crossAxisAlignment: WrapCrossAlignment.center,
      //                   spacing: 10,
      //                   children: [
      //                     Text('Current'),
      //                     LinearProgressIndicator(value: (downloadProgress)),
      //                   ],
      //                 )), */
      //                         Padding(
      //                           padding: const EdgeInsets.only(top: 10),
      //                           child: LinearProgressIndicator(
      //                             semanticsValue: downloadProgress.toString(),
      //                             value: (downloadFile +
      //                                 (downloadProgress < 100
      //                                     ? downloadProgress / 100
      //                                     : 0)) /
      //                                 selectedVideos.length,
      //                           ),
      //                         ),
      //                         Padding(
      //                           padding: const EdgeInsets.all(8.0),
      //                           child: InkWell(
      //                             onTap: () async {
      //                               _tasks?.sublist(downloadFile).forEach((element) async {
      //                                 await _pauseDownload(element);
      //                               });
      //                               setState(() {
      //                                 isDownloading = false;
      //                               });
      //                               _showErrorDialog(
      //                                   "Are you sure to cancel the download", context);
      //                             },
      //                             child: Container(
      //                                 height: 38,
      //                                 alignment: Alignment.center,
      //                                 decoration: const BoxDecoration(
      //                                     color: Colors.blue,
      //                                     borderRadius:
      //                                     BorderRadius.all(Radius.circular(8))),
      //                                 child: const Text(
      //                                   'Cancel',
      //                                   style: TextStyle(color: Colors.white, fontSize: 15),
      //                                 )),
      //                           ),
      //                         ),
      //                       ],
      //                     ),
      //                   );
      //                 });
      //           });
      //     });
      //
      //   },
      //
      // ),



      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          name != null ? name! : '',
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 0,
      ),
      body: Stack(
        children: [
          dataShared == null
              ? Container()
              : InAppWebView(
            initialUrlRequest: URLRequest(url: Uri.parse(dataShared!)),
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                preferredContentMode: UserPreferredContentMode.DESKTOP,
                useShouldInterceptFetchRequest: true,
              ),
            ),
            onTitleChanged: (controller, title) async {
              controller.getHtml().then((value) =>
              {
                setState(() {
                  avatar = value!
                      .split('property="og:image" content="')[1]
                      .split('"><meta')[0];
                })
              });
              if (avatar != null) {
                webViewController!.clearCache().then((value) =>
                {
                  setState(() {
                    name = title!.split(' (@')[0];
                    atname =
                    '@${title.split(' (@')[1].split(')')[0]}';
                  })
                });
              } else {
                setState(() {
                  name = title!.split(' (@')[0];
                  atname = '@${title.split(' (@')[1].split(')')[0]}';
                });
              }
            },
            onPageCommitVisible: (controller, url) {
              print("onPageCommitVisible");
              controller.getHtml().then((value) =>
              {
                avatar = value!
                    .split(
                    '<meta data-rh="true" property="og:image" content="')[1]
                    .split('">')[0],
                //   allVideosCount = int.parse(value.split(',"videoCount":')[1].split(',"diggCount"')[0]),
                data = parse(value),
                images = data
                    .querySelectorAll(
                    'div > div > a > div > div.tiktok-1jxhpnd-DivContainer.e1yey0rl0 > img')
                    .map(
                        (element) => element.attributes['src'].trim())
                    .toList(),

                urls = data
                    .querySelectorAll(
                    'div.tiktok-yvmafn-DivVideoFeedV2.e5w7ny40 >div > div > div > div > a')
                    .map((element) =>
                    element.attributes['href'].trim())
                    .toList(),
                watches = data
                    .querySelectorAll(
                    'div > div > a > div > div.tiktok-11u47i-DivCardFooter.e148ts220 > strong')
                    .map((element) => element.text)
                    .toList(),
                videos.addAll(List.generate(
                    images.length,
                        (index) =>
                        VideoModel(
                            id: urls[index].toString().split('video/')[1],
                            url: urls[index],
                            thumbUrl: images[index],
                            watchesCount: watches[index],
                            downloadAddr: null)).sublist(videos.length)),
                /* trimmedVideos = List.from(videos.sublist(

                              0, videos.length - videos.length % 3) */
                trimmedVideos = List.from(videos),
                setState(() {}),
              });
              print("images2$images");
            },
            onLoadStop: (controller, uri) async {
              String? html;
              html = await controller.getHtml();
              initialVideosListData = jsonDecode(html!
                  .split('"ItemModule":')[1]
                  .split(',"UserModule"')[0]);
              avatar = html
                  .split(
                  '<meta data-rh="true" property="og:image" content="')[1]
                  .split('">')[0];
              data = parse(html);
              images = data
                  .querySelectorAll(
                  'div > div > a > div > div.tiktok-1jxhpnd-DivContainer.e1yey0rl0 > img')
                  .map((element) => element.attributes['src'].trim())
                  .toList();

              print("images$images");
              urls = data
                  .querySelectorAll(
                  'div.tiktok-yvmafn-DivVideoFeedV2.e5w7ny40 >div > div > div > div > a')
                  .map((element) => element.attributes['href'].trim())
                  .toList();
              watches = data
                  .querySelectorAll(
                  'div > div > a > div > div.tiktok-11u47i-DivCardFooter.e148ts220 > strong')
                  .map((element) => element.text)
                  .toList();
              allVideosCount = int.parse(html
                  .split(',"videoCount":')[1]
                  .split(',"diggCount"')[0]);
              videos = List.generate(
                  images.length,
                      (index) =>
                      VideoModel(
                          id: urls[index].toString().split('video/')[1],
                          url: urls[index],
                          thumbUrl: images[index],
                          watchesCount: watches[index],
                          downloadAddr: initialVideosListData[urls[index]
                              .toString()
                              .split('video/')[1]] ==
                              null
                              ? null
                              : initialVideosListData[urls[index]
                              .toString()
                              .split('video/')[1]]['video']
                          ['downloadAddr']));
              if (selectAll && !isDownloading) {
                selectedVideos = List.from(videos);
              }
              trimmedVideos = List.from(
                //  videos.sublist(0, videos.length - videos.length % 3));
                  videos);
              print("trimmedVideos$trimmedVideos");
              print("videos$videos");

              if (!isDownloading) {
                selectedVideos = [];
              }
              setState(() {});
            },
            onWebViewCreated: (InAppWebViewController controller) {
              webViewController = controller;
            },
          ),
          topWidget(),
          NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                const SliverAppBar(
                  expandedHeight: 220.0,
                  backgroundColor: Colors.transparent,
                  toolbarHeight: 0,
                  floating: false,
                  pinned: true,
                  leading: Text(''),
                ),
              ];
            },
            body: Container(
              color: Colors.white,
              width: MediaQuery
                  .of(context)
                  .size
                  .width,
              height: MediaQuery
                  .of(context)
                  .size
                  .height,
              child: dataShared == null
                  ? Container()
                  : name == null ||
                  avatar == null ||
                  atname ==
                      null /* ||  allVideosCount == null */ ? Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16.0),
                child: const CircularProgressIndicator(
                  color: Color.fromRGBO(
                    //بروجرس اساسي
                      254,
                      44,
                      85,
                      1.0),
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                    ),
                    child: videos.isEmpty
                        ? Container()
                        : allVideosCount == null
                        ? Container(
                      alignment: Alignment.centerLeft,
                      child: const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            //بروجرس select

                            strokeWidth: 1,
                          )),
                    )
                        : Row(
                      mainAxisAlignment:
                      MainAxisAlignment.start,
                      crossAxisAlignment:
                      CrossAxisAlignment.center,
                      children: [
                        /* Expanded(
                          flex:1,
                          child: currentPage == 1 ? Container() :
                        IconButton(onPressed: (){
                          pagesController.jumpToPage(currentPage-2);
                        }, icon: Icon(Icons.skip_previous_sharp)),),
                        SizedBox(width: 16,),*/
                        Expanded(
                          flex: 3,
                          child: Row(children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [

                                // Container(
                                //   color: Colors.white,
                                //   width: MediaQuery.of(context).size.height * .07,
                                //   height: MediaQuery.of(context).size.height * .07,
                                // ),
                                Icon(
                                  Icons.check,
                                  color: selectAll
                                      ? Color.fromRGBO(
                                      25, 207, 198, 1.0)
                                      : Colors.black,
                                  size: MediaQuery
                                      .of(context)
                                      .size
                                      .height * .07,
                                ),


                                Transform.scale(
                                  scale: MediaQuery
                                      .of(context)
                                      .size
                                      .height * .003,
                                  child: Checkbox(
                                    checkColor: selectAll
                                        ? Colors.transparent
                                        : Colors.transparent,
                                    activeColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    fillColor: MaterialStateProperty
                                        .resolveWith(getColor),
                                    focusNode: FocusNode(
                                    ),
                                    //   overlayColor: Colors.transparent,
                                    value: selectedVideos.isNotEmpty,
                                    side: BorderSide(
                                      color: Colors.transparent,
                                      width: 0,


                                    ),
                                    onChanged: (value) {
                                      selectAll = value!;
                                      if (value) {
                                        setState(() {
                                          videos.length >= 17
                                              ?
                                          selectedVideos = List.from(videos)
                                              : trimmedVideos.length == 16
                                              ? selectedVideos =
                                              List.from(videos.sublist(0, 12))
                                              : trimmedVideos.length == 15
                                              ? selectedVideos =
                                              List.from(videos.sublist(0, 12))
                                              : trimmedVideos.length == 14
                                              ? selectedVideos =
                                              List.from(videos.sublist(0, 12))
                                              : trimmedVideos.length == 13
                                              ? selectedVideos =
                                              List.from(videos.sublist(0, 12)) :
                                          selectedVideos = List.from(videos);
                                        });
                                      } else {
                                        setState(() {
                                          selectedVideos = [];
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              selectedVideos.isEmpty
                                  ? ''
                                  : selectAll
                                  ? '${selectedVideos
                                  .length} / ${allVideosCount!}'
                                  : '${selectedVideos
                                  .length} / ${allVideosCount!}',
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16),
                            ),
                          ]),
                        ),
                        selectedVideos.isEmpty
                            ? Container()
                            : Expanded(
                          flex: 1,
                          child: Padding(
                            padding:
                            const EdgeInsets.only(
                                right: 8.0),
                            child: InkWell(
                              onTap: isDownloading
                                  ? () async {}
                                  : () async {
                                initDiskSpace();
                             //   print("**DiskSpace****$x***");

                                final permission = Permission.storage;
                                final status = await permission.status;
                                debugPrint('>>>Status $status');

                                /// here it is coming as PermissionStatus.granted
                                if (status != PermissionStatus.granted) {
                                  await permission.request();
                                }
                                // if (status == permission.status.isPermanentlyDenied){
                                //   _modalBottomSheetMenu("perm", '');
                                // }
                                // }
                                //لا حل حتى الاان
                                // print("*********************************************${ await permission.status.isPermanentlyDenied}");
                                // print("*********************************************${ await permission.status.isDenied}");
                                // print("*********************************************${status}******");
                                // print("*********************************************${await permission.request()}***R***");
                                // print("*********************************************${ await permission.status.isGranted}*****");
                                // print("*********************************************${ await permission.status.isRestricted}******");
                                // print("*********************************************${ await permission.status.isLimited}******");
                                // print("${ await  PermissionStatus.permanentlyDenied}");
                                if (await permission.status.isDenied) {
                                  print(
                                      "*************مرفوووض**************************");
                                  if (isPermission == "perm1") {
                                    CacheHelper.saveData(
                                      key: 'isPermission',
                                      value: "perm",);
                                    isPermission =
                                    "perm";
                                    _modalBottomSheetMenu(
                                        "perm1",
                                        '');
                                  } else if (isPermission == "perm") {
                                    _modalBottomSheetMenu("perm", '');
                                  }
                                }
                                if (await permission.status
                                    .isGranted) //اذ تم السماح
                                    {
                                  showModalBottomSheet(
                                      elevation:
                                      10,
                                      backgroundColor:
                                      Colors
                                          .transparent,
                                      isDismissible:false,

                                      context:
                                      context,
                                      builder:
                                          (builder) {
                                        return StatefulBuilder(
                                            builder: (BuildContext
                                            context,
                                                StateSetter
                                                setState
                                                /*You can rename this!*/) {
                                              return Container(
                                                decoration:
                                                new BoxDecoration(
                                                  color: Colors.white,
                                                ),
                                                child:
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .only(left: 13.0,
                                                      right: 15,
                                                      top: 25,
                                                      bottom: 15),

                                                  child: Column(
                                                    mainAxisSize: MainAxisSize
                                                        .min,
                                                    crossAxisAlignment: CrossAxisAlignment
                                                        .start,
                                                    mainAxisAlignment: MainAxisAlignment
                                                        .center,
                                                    children: [
                                                      Column(
                                                        mainAxisSize: MainAxisSize
                                                            .min,
                                                        crossAxisAlignment: CrossAxisAlignment
                                                            .start,
                                                        mainAxisAlignment: MainAxisAlignment
                                                            .end,

                                                        children: [
                                                          Text(
                                                            'Download',
                                                            style: TextStyle(
                                                                fontWeight: FontWeight
                                                                    .bold,
                                                                fontSize: 18),
                                                          ),
                                                          SizedBox(
                                                            height: 10,
                                                          ),
                                                          Text(
                                                            true
                                                                ? 'Are you sure you want to continue and save the selected TikToks? You will find them in your Files app, Downloads folder.'
                                                                : 'Are you want to download this video?',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .black,
                                                              fontSize: 14,
                                                            ),
                                                            //    textAlign: TextAlign.center,
                                                          ),
                                                        ],
                                                      ),
                                                      // Expanded(child: Container()),
                                                      SizedBox(height: 20,),
                                                      Row(
                                                        mainAxisSize: MainAxisSize
                                                            .min,
                                                        mainAxisAlignment: MainAxisAlignment
                                                            .start,
                                                        children: [
                                                          InkWell(
                                                            onTap: () {

                                                              Navigator.of(
                                                                  context)
                                                                  .pop();
                                                            },
                                                            child: Container(
                                                              child: Text(
                                                                'NO',
                                                                style: TextStyle(
                                                                  color: Color
                                                                      .fromRGBO(
                                                                      38, 38,
                                                                      38, 1.0),
                                                                  fontSize: 15,
                                                                  fontWeight: FontWeight
                                                                      .w600,
                                                                ),
                                                                textAlign: TextAlign
                                                                    .center,
                                                              ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                              child: SizedBox()),
                                                          InkWell(
                                                            onTap: () async {
                                                              bool checInternet = await checkConectivity();
                                                              if(diskFree! <= 1050){
                                                                _modalBottomSheetMenu("space", "");

                                                              }
                                                              else if (checInternet == true) {
                                                                isCanceled =
                                                                true;
                                                                Navigator
                                                                    .of(
                                                                    context)
                                                                    .pop();
                                                                downloadFiles2();
                                                              } else {
                                                                // showModalBottomSheet(
                                                                //     elevation:
                                                                //     10,
                                                                //     backgroundColor:
                                                                //     Colors
                                                                //         .white,
                                                               // isDismissible:false,

                                                              //     context:
                                                                //     context,
                                                                //     builder:
                                                                //         (
                                                                //         builder) {
                                                                //       return StatefulBuilder(
                                                                //           builder: (
                                                                //               BuildContext
                                                                //               context,
                                                                //               StateSetter
                                                                //               setState
                                                                //               /*You can rename this!*/) {
                                                                //             return Padding(
                                                                //               padding: const EdgeInsets
                                                                //                   .symmetric(
                                                                //                   horizontal: 20.0,
                                                                //                   vertical: 25),
                                                                //               child: Column(
                                                                //                 mainAxisSize: MainAxisSize
                                                                //                     .min,
                                                                //                 mainAxisAlignment: MainAxisAlignment
                                                                //                     .start,
                                                                //                 crossAxisAlignment: CrossAxisAlignment
                                                                //                     .start,
                                                                //                 children: [
                                                                //                   Row(
                                                                //                     mainAxisAlignment: MainAxisAlignment
                                                                //                         .start,
                                                                //                     crossAxisAlignment: CrossAxisAlignment
                                                                //                         .start,
                                                                //                     mainAxisSize: MainAxisSize
                                                                //                         .min,
                                                                //                     children: [
                                                                //                       Image
                                                                //                           .asset(
                                                                //                         'images/error-connection.png',
                                                                //                         height: 60,
                                                                //                         width: 60,
                                                                //                       ),
                                                                //                       SizedBox(
                                                                //                         width: 12,),
                                                                //
                                                                //                       Expanded(
                                                                //                         child: Column(
                                                                //                           mainAxisAlignment: MainAxisAlignment
                                                                //                               .start,
                                                                //                           crossAxisAlignment: CrossAxisAlignment
                                                                //                               .start,
                                                                //                           mainAxisSize: MainAxisSize
                                                                //                               .min,
                                                                //                           children: [
                                                                //                             Text(
                                                                //                               "Internet connection failed",
                                                                //                               style: TextStyle(
                                                                //                                 fontSize: 18,
                                                                //                                 color: Colors
                                                                //                                     .black,
                                                                //
                                                                //                               ),),
                                                                //                             Text(
                                                                //                               "Make sure the internet is connected And try again",
                                                                //                               style: TextStyle(
                                                                //                                 fontSize: 17,
                                                                //                                 color: Colors
                                                                //                                     .black,
                                                                //
                                                                //                               ),),
                                                                //                           ],
                                                                //                         ),
                                                                //                       ),
                                                                //
                                                                //
                                                                //                     ],
                                                                //                   ),
                                                                //                   SizedBox(
                                                                //                     height: 10,),
                                                                //                   InkWell(
                                                                //                     onTap: () {
                                                                //                       Navigator
                                                                //                           .of(
                                                                //                           context)
                                                                //                           .pop();
                                                                //                     },
                                                                //
                                                                //                     child: Align(
                                                                //                       alignment: Alignment
                                                                //                           .bottomRight,
                                                                //                       child: Text(
                                                                //                         "Undo",
                                                                //                         style: TextStyle(
                                                                //                             fontSize: 20,
                                                                //                             color: Colors
                                                                //                                 .black,
                                                                //                             fontWeight: FontWeight
                                                                //                                 .bold
                                                                //
                                                                //                         ),),
                                                                //                     ),
                                                                //                   ),
                                                                //                 ],
                                                                //               ),
                                                                //             );
                                                                //           });
                                                                //     });
                                                              }

                                                            },
                                                            child: Text(
                                                              //كونتنتيو
                                                              'CONTINUE',
                                                              style: TextStyle(
                                                                color: Color
                                                                    .fromRGBO(
                                                                    254, 44, 85,
                                                                    1.0),
                                                                fontSize: 15,
                                                                fontWeight: FontWeight
                                                                    .w600,
                                                              ),
                                                              textAlign: TextAlign
                                                                  .center,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            });
                                      });
                                }


                                else {
                                  // // await permission
                                  // //     .request();
                                  // print("nexttt");
                                  // if(isPermission=="perm1"){
                                  //   CacheHelper.saveData(key: 'isPermission', value: "perm",);
                                  //   isPermission = "perm";
                                  //   _modalBottomSheetMenu("perm1", '');
                                  // // }else if(isPermission=="perm2"){
                                  // //   CacheHelper.saveData(key: 'isPermission', value: "perm",);
                                  // //   isPermission = "perm";
                                  // //   _modalBottomSheetMenu("perm2", '');
                                  // }
                                  //
                                  //
                                  // print(
                                  //     "Permission denied");
                                }
                              },
                              child: Container(
                                height: 38,
                                alignment:
                                Alignment.center,
                                decoration:
                                const BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius:
                                  BorderRadius
                                      .all(
                                    Radius.circular(
                                        24),
                                  ),
                                ),
                                child: Text(
                                  'Save',
                                  style: TextStyle(
                                      color: Colors
                                          .white,
                                      fontSize: 15),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: videos.isEmpty
                          ? Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(24.0),
                        child: const CircularProgressIndicator(
                          color: Color.fromRGBO(
                            //بروجرس1
                              254,
                              44,
                              85,
                              1.0),
                        ),
                      )
                          : thumbnailsGrid(), //ليست
                    ),
                  )
                ],
              ),
            ),
          ),
          isLoading
              ? Container(
            color: Colors.white.withAlpha(50),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              color: Color.fromRGBO(254, 44, 85, 1.0),
            ), //بروجرس2
          )
              : Container(),
          // BottomSheet(
          //
          //   builder: (BuildContext context) =>
          //       StreamBuilder<ConnectivityResult>(
          //         stream: Connectivity().onConnectivityChanged,
          //
          //         builder: (context, snapshot) {
          //           // bool  isVisibality =false;
          //           if (snapshot.data == ConnectivityResult.none &&
          //               isTopConectivity) {
          //             return Container(
          //               width: double.infinity,
          //
          //               height: 50,
          //               color: Colors.black,
          //               child: Padding(
          //                 padding: const EdgeInsets.symmetric(horizontal: 20.0),
          //                 child: Row(
          //                   mainAxisSize: MainAxisSize.min,
          //                   children: [
          //                     Text(
          //                       "No network connection", style: TextStyle(
          //                       fontSize: 17,
          //                       color: Colors.white,
          //
          //                     ),),
          //                     Expanded(child: Container()),
          //                     // InkWell(
          //                     //   onTap: () async {
          //                     //     setState(() {
          //                     //       isTopConectivity = false;
          //                     //     });
          //                     //     //
          //                     //     // Future.delayed(
          //                     //     //     const Duration(milliseconds: 5), () {
          //                     //     //   isTopConectivity = true;
          //                     //     // });
          //                     //     //
          //                     //     // Timer(Duration(seconds: 3), () {
          //                     //     //   setState(() {
          //                     //     //     isTopConectivity = true;
          //                     //     //
          //                     //     //     // Here you can write your code for open new view
          //                     //     //     print("print after every 3 seconds");
          //                     //     //   });
          //                     //     // });
          //                     //   },
          //                     //   child: Text("Undo", style: TextStyle(
          //                     //       fontSize: 17,
          //                     //       color: Colors.white,
          //                     //       fontWeight: FontWeight.bold
          //                     //
          //                     //   ),),
          //                     // ),
          //                     Countdown(
          //                       seconds: 10,
          //                       build: (BuildContext context, double time) =>
          //                           Text(time.toString(), style: TextStyle(
          //                               color: Colors.transparent),),
          //                       interval: Duration(milliseconds: 100),
          //                       onFinished: () async {
          //                         setState(() {
          //                           isTopConectivity = false;
          //                         });
          //                         // print(
          //                         //     "*****************************************");
          //                         //
          //                         // Future.delayed(
          //                         //     const Duration(milliseconds: 5), () {
          //                         //   isTopConectivity = true;
          //                         // });
          //                         //
          //                         // Timer(Duration(seconds: 3), () {
          //                         //   setState(() {
          //                         //     isTopConectivity = true;
          //                         //
          //                         //     // Here you can write your code for open new view
          //                         //     print("print after every 3 seconds");
          //                         //   });
          //                         // });
          //                       },
          //
          //                     ),
          //                   ],
          //                 ),
          //               ),
          //             );
          //           } else {
          //             return Countdown(
          //               seconds: 8,
          //               build: (BuildContext context, double time) =>
          //                   Text(time.toString(), style: TextStyle(color: Colors
          //                       .transparent),),
          //               interval: Duration(milliseconds: 100),
          //               onFinished: () async {
          //                 setState(() {
          //                   isTopConectivity = true;
          //                 });
          //                 // isTopConectivity = true;
          //                 // print("*****************************************");
          //                 //
          //                 // Future.delayed(const Duration(milliseconds: 5), () {
          //                 //   isTopConectivity = true;
          //                 // });
          //                 //
          //                 // Timer(Duration(seconds: 3), () {
          //                 //   setState(() {
          //                 //     isTopConectivity = true;
          //                 //
          //                 //     // Here you can write your code for open new view
          //                 //     print("print after every 3 seconds");
          //                 //   });
          //                 // });
          //               },
          //
          //             );
          //           }
          //         },), onClosing: () {},
          // ),
          // isBotmoConectivity
          //     ? Align(
          //   alignment: Alignment.bottomCenter,
          //   child: BottomSheet(
          //
          //     builder: (BuildContext context) =>
          //         StreamBuilder<ConnectivityResult>(
          //           stream: Connectivity().onConnectivityChanged,
          //
          //           builder: (context, snapshot) {
          //             // bool  isVisibality =false;
          //             if (snapshot.data == ConnectivityResult.none) {
          //               return Container(
          //                 width: double.infinity,
          //
          //                 //   height: 400,
          //                 color: Colors.white,
          //                 child: Padding(
          //                   padding: const EdgeInsets.symmetric(
          //                       horizontal: 20.0, vertical: 25),
          //                   child: Column(
          //                     mainAxisSize: MainAxisSize.min,
          //                     mainAxisAlignment: MainAxisAlignment.start,
          //                     crossAxisAlignment: CrossAxisAlignment.start,
          //                     children: [
          //                       Row(
          //                         mainAxisAlignment: MainAxisAlignment.start,
          //                         crossAxisAlignment: CrossAxisAlignment.start,
          //                         mainAxisSize: MainAxisSize.min,
          //                         children: [
          //                           Image.asset(
          //                             'images/error-connection.png',
          //                             height: 60,
          //                             width: 60,
          //                           ),
          //                           SizedBox(width: 12,),
          //                           Text("Internet connection failed",
          //                             style: TextStyle(
          //                               fontSize: 17,
          //                               color: Colors.black,
          //
          //                             ),),
          //
          //
          //                         ],
          //                       ),
          //                       SizedBox(height: 10,),
          //                       InkWell(
          //                         onTap: () async {
          //                           setState(() {
          //                             isBotmoConectivity = false;
          //                           });
          //
          //                           Future.delayed(
          //                               const Duration(milliseconds: 5), () {
          //                             isBotmoConectivity = true;
          //                           });
          //
          //                           Timer(Duration(seconds: 3), () {
          //                             setState(() {
          //                               isBotmoConectivity = true;
          //
          //
          //                               // Here you can write your code for open new view
          //                               print("print after every 3 seconds");
          //                             });
          //                           });
          //                         },
          //
          //                         child: Align(
          //                           alignment: Alignment.bottomRight,
          //                           child: Text("Undo", style: TextStyle(
          //                               fontSize: 20,
          //                               color: Colors.black,
          //                               fontWeight: FontWeight.bold
          //
          //                           ),),
          //                         ),
          //                       ),
          //                     ],
          //                   ),
          //                 ),
          //               );
          //             } else {
          //               return Container(height: 0,);
          //             }
          //
          //             //  }
          //
          //             // return
          //             //   snapshot.data == ConnectivityResult.none
          //             //     ?Container(
          //             //           height: 20,
          //             //           width: 100,
          //             //         color: Colors.red,
          //             //     child: Row(
          //             //       children: [
          //             //         Text("sad"),
          //             //       ],
          //             //     ),
          //             //       )
          //             //      :Container();
          //
          //
          //             //       child: SnackBar(
          //             //   backgroundColor: Colors.black,
          //             //   content: Container(
          //             //       height: 20,
          //             //       child: Row(
          //             //    //   mainAxisSize:MainAxisSize.min,
          //             //         children: [
          //             //           Expanded(
          //             //             child: Text("Internet connection failed",style: TextStyle(
          //             //               fontSize: 20,
          //             //               color: Colors.white,
          //             //
          //             //             ), ),
          //             //           ),
          //             //           // Expanded(child: Container()),
          //             //           // InkWell(
          //             //           //   onTap: () {
          //             //           //     Navigator.of(context).pop();
          //             //           //
          //             //           //   },
          //             //           //   child: Text("Undo",style: TextStyle(
          //             //           //     fontSize: 20,
          //             //           //     color: Colors.white,
          //             //           //
          //             //           //   ), ),
          //             //           // ),
          //             //
          //             //         ],
          //             //       ),
          //             //   ),
          //             //
          //             // ),
          //             //   )
          //             //    : Container();
          //           },), onClosing: () {},
          //
          //   ),
          // )
          //     : Container(),


        ],
      ),
    );
  }

  void _modalBottomSheetMenu(String s, String e) {
    setState(() {
      isDownloading = false;
    });
    showModalBottomSheet(
        elevation: 10,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        context: context,
        builder: (builder) {
          return StatefulBuilder(builder: (BuildContext context,
              StateSetter setState /*You can rename this!*/) {
            return Container(
              //  height: MediaQuery.of(context).size.height * .3,
              decoration: new BoxDecoration(
                //  color: const Color.fromARGB(255, 228, 225, 225),
                color: Colors.white,
                /*  borderRadius: new BorderRadius.only(
                        topLeft: const Radius.circular(40.0),
                        topRight: const Radius.circular(40.0)) */
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 13.0, right: 15, top: 25, bottom: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          child: s == "perm" || s == "perm1" || s == "perm2"
                              ? Image.asset(
                            'images/permissi.png',
                            height: 60,
                            width: 60,
                          )
                              : s == "ok"
                              ? Image.asset(
                            'images/success.png',
                            height: 60,
                            width: 60,
                          )
                              : s == "cancel"
                              ? Image.asset(
                            'images/cancelled.png',
                            height: 60,
                            width: 60,
                          )
                              : s == "space"
                              ? Image.asset(
                            'images/error-storage.png',
                            height: 60,
                            width: 60,
                          )
                              : e == "DioErrorType.connectTimeout" ||
                              e == "DioErrorType.sendTimeout" ||
                              e == "DioErrorType.receiveTimeout"
                              ? Image.asset(
                            'images/timeout.png',
                            height: 60,
                            width: 60,
                          )
                              : e == "DioErrorType.response"
                              ? Image.asset(
                            'images/serverErr.png',
                            height: 60,
                            width: 60,
                          )
                              : e == "DioErrorType.other"
                              ? Padding(
                            padding:
                            const EdgeInsets.only(
                                top: 6.0),
                            child: Image.asset(
                              'images/checkcnx.png',
                              height: 60,
                              width: 60,
                            ),
                          )
                              : Padding(
                            padding:
                            const EdgeInsets.only(
                                top: 6.0),
                            child: Image.asset(
                              'images/checkcnx.png',
                              height: 60,
                              width: 60,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 13,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: s == "ok"
                                      ? Text(
                                      '${downloadFile} of ${selectedVideos
                                          .length} File/s have been downloaded successfully.',
                                      style: const TextStyle(
                                        //  fontWeight: FontWeight.bold,
                                          fontSize: 13))
                                      : s == "cancel"
                                      ? Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${downloadFile} of ${selectedVideos
                                              .length} File/s have been downloaded successfully.',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            //    fontWeight: FontWeight.bold
                                          ),
                                        ),
                                        Text(
                                          'Failed to download ${selectedVideos
                                              .length - downloadFile} file/s',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            //    fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ])
                                      : s == "space"
                                      ? Text(
                                    "Storage full \n ${downloadFile} of ${selectedVideos
                                        .length} File/s have been downloaded successfully.\n  Failed to download ${selectedVideos
                                        .length - downloadFile} file/s ",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      //    fontWeight: FontWeight.bold
                                    ),)
                                      : s == "err"
                                      ? Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          '',
                                          style: TextStyle(
                                            fontSize: 0,
                                            //    fontWeight: FontWeight.bold
                                          ),
                                        ),
                                        Text(
                                          e == "DioErrorType.cancel"
                                              ? "oop something went wrong Cancelled"
                                              : e ==
                                              "DioErrorType.connectTimeout" ||
                                              e ==
                                                  "DioErrorType.sendTimeout" ||
                                              e ==
                                                  "DioErrorType.receiveTimeout"
                                              ? "oop something went wrong connectTimeout"
                                              : e == "DioErrorType.response"
                                              ? "oop something went wrong Server Erreur"
                                              : e == "DioErrorType.other"
                                              ? "oop something went wrong Check Your Internet Connection"
                                              : "oop something went wrong Check Your Internet Connection2",
                                          style: const TextStyle(
                                              fontSize: 13
                                            //    fontWeight: FontWeight.bold
                                          ),
                                        ),
                                        Text(
                                          '${downloadFile} of ${selectedVideos
                                              .length}  File/s have been downloaded successfully.Failed to download ${selectedVideos
                                              .length - downloadFile} file/s',
                                          style: const TextStyle(
                                            fontSize: 13,

                                            //   fontWeight: FontWeight.bold
                                          ),
                                        ),
                                        //  Text(''),
                                      ])
                                      : s == "perm"
                                      ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Check Permission 2',
                                          style: TextStyle(
                                              fontSize: 13
                                            //  fontWeight: FontWeight.bold
                                          ),
                                        ),
                                        const Text(
                                          "You Can't use the app without Allow Permission",
                                          style: TextStyle(
                                              fontSize: 13
                                            //   fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ])
                                      : s == "perm1"
                                      ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Check Permission 1',
                                          style: TextStyle(
                                              fontSize: 13
                                            //  fontWeight: FontWeight.bold
                                          ),
                                        ),
                                        const Text(
                                          "You Can't use the app without Allow Permission",
                                          style: TextStyle(
                                              fontSize: 13
                                            //   fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ])
                                      : s == "perm2"
                                      ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Check Permission2',
                                          style: TextStyle(
                                              fontSize: 13
                                            //  fontWeight: FontWeight.bold
                                          ),
                                        ),
                                        const Text(
                                          "You Can't use the app without Allow Permission",
                                          style: TextStyle(
                                              fontSize: 13
                                            //   fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ])
                                      : Text(e)),
                              s == "perm" || s == "perm1" || s == "perm2"
                                  ? Container()
                              // Padding(
                              //   padding: const EdgeInsets.all(8.0),
                              //   child: InkWell(
                              //     onTap: () async {
                              //       openAppSettings();
                              //     },
                              //     child: Container(
                              //         height: 38,
                              //         alignment: Alignment.center,
                              //         decoration: const BoxDecoration(
                              //             color: Colors.blue,
                              //             borderRadius: BorderRadius.all(
                              //                 Radius.circular(8))),
                              //         child: const Text(
                              //           'Open Setting',
                              //           style: TextStyle(
                              //               color: Colors.white,
                              //               fontSize: 15),
                              //         )),
                              //   ),
                              // )
                                  : Container(),

                            ],
                          ),
                        ),


                      ],
                    ),

                    SizedBox(height: 20,),

                    s == "ok"
                        ? Align(
                      alignment: Alignment.bottomRight,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'OK',
                          style: TextStyle(
                            color: Color.fromRGBO(254, 44, 85, 1.0),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                        : s == "cancel"
                        ? Align(
                      alignment: Alignment.bottomRight,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'CLOSE',
                          style: TextStyle(
                            color: Color.fromRGBO(254, 44, 85, 1.0),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                        : s == "perm" || s == "perm2"
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            child: Text(
                              'NO',
                              style: TextStyle(
                                color: Color.fromRGBO(38, 38, 38, 1.0),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(child: SizedBox()),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            openAppSettings();
                          },
                          child: Text(
                            //كونتنتيو
                            'OPEN SETTINGS',
                            style: TextStyle(
                              color: Color.fromRGBO(254, 44, 85, 1.0),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                        : s == "perm1"
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            child: Text(
                              'NO',
                              style: TextStyle(
                                color: Color.fromRGBO(38, 38, 38, 1.0),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(child: SizedBox()),
                        // InkWell(
                        //   onTap: () {
                        //     Navigator.of(context).pop();
                        //     openAppSettings();
                        //   },
                        //   child: Text(
                        //     //كونتنتيو
                        //     'OPEN SETTINGS',
                        //     style: TextStyle(
                        //       color: Color.fromRGBO(254, 44, 85, 1.0),
                        //       fontSize: 15,
                        //       fontWeight: FontWeight.w600,
                        //     ),
                        //     textAlign: TextAlign.center,
                        //   ),
                        // ),
                      ],
                    )
                        : Align(
                      alignment: Alignment.bottomRight,
                      child: InkWell(
                        onTap: isDownloading
                            ? () async {}
                            : () async {
                          bool checInternet = await checkConectivity();
                          if (diskFree! <= 1050) {
                            _modalBottomSheetMenu("space", "");
                          } else if(checInternet == true) {
                            isCanceled = true;
                            Navigator.of(context).pop();
                            //       downloadFiles2();
                            //        await FlutterDownloader.cancelAll();

                            isDownloading = true;
                            setState(() {
                              isDownloading = true;
                            });

                            _tasks?.sublist(downloadFile).forEach((
                                element) async {
                              await _retryDownload(element);
                            });
                          } else {
                            // showModalBottomSheet(
                            //     elevation:
                            //     10,
                            //     backgroundColor:
                            //     Colors
                            //         .white,
                             //   isDismissible:false,
                            //     context:
                            //     context,
                            //     builder:
                            //         (builder) {
                            //       return StatefulBuilder(builder: (BuildContext
                            //       context,
                            //           StateSetter
                            //           setState /*You can rename this!*/) {
                            //         return Padding(
                            //           padding: const EdgeInsets.symmetric(
                            //               horizontal: 20.0, vertical: 25),
                            //           child: Column(
                            //             mainAxisSize: MainAxisSize.min,
                            //             mainAxisAlignment: MainAxisAlignment
                            //                 .start,
                            //             crossAxisAlignment: CrossAxisAlignment
                            //                 .start,
                            //             children: [
                            //               Row(
                            //                 mainAxisAlignment: MainAxisAlignment
                            //                     .start,
                            //                 crossAxisAlignment: CrossAxisAlignment
                            //                     .start,
                            //                 mainAxisSize: MainAxisSize.min,
                            //                 children: [
                            //                   Image.asset(
                            //                     'images/error-connection.png',
                            //                     height: 60,
                            //                     width: 60,
                            //                   ),
                            //                   SizedBox(width: 12,),
                            //
                            //                   Expanded(
                            //                     child: Column(
                            //                       mainAxisAlignment: MainAxisAlignment
                            //                           .start,
                            //                       crossAxisAlignment: CrossAxisAlignment
                            //                           .start,
                            //                       mainAxisSize: MainAxisSize
                            //                           .min, children: [
                            //                       Text(
                            //                         "Internet connection failed",
                            //                         style: TextStyle(
                            //                           fontSize: 18,
                            //                           color: Colors.black,
                            //
                            //                         ),),
                            //                       Text(
                            //                         "Make sure the internet is connected And try again",
                            //                         style: TextStyle(
                            //                           fontSize: 17,
                            //                           color: Colors.black,
                            //
                            //                         ),),
                            //                     ],
                            //                     ),
                            //                   ),
                            //
                            //
                            //                 ],
                            //               ),
                            //               SizedBox(height: 10,),
                            //               InkWell(
                            //                 onTap: () {
                            //                   Navigator.of(context).pop();
                            //                 },
                            //
                            //                 child: Align(
                            //                   alignment: Alignment.bottomRight,
                            //                   child: Text(
                            //                     "Undo", style: TextStyle(
                            //                       fontSize: 20,
                            //                       color: Colors.black,
                            //                       fontWeight: FontWeight.bold
                            //
                            //                   ),),
                            //                 ),
                            //               ),
                            //             ],
                            //           ),
                            //         );
                            //       });
                            //     });
                          }
                        },
                        child: Text(
                          'RETRY',
                          style: TextStyle(
                            color: Color.fromRGBO(254, 44, 85, 1.0),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    //  const SizedBox(height: 10,),
                  ],
                ),
              ),
            );
          });
        });
  }

  downloadFiles2() async {
    setState(() {
      // isDownloading = true;
      downloadProgress = 0;
    });
    Dio dio = Dio();
    downloadFile = 0;
    _cancelToken = CancelToken();

    await getRemainingDownloadAddress();
    setState(() {
      isDownloading = true;
    });
    await _prepare();

    print("isDownloading$isDownloading");

    print("selectedVideos$selectedVideos");

    print("gggggf");

    // downloadFile++;

    //  isDownloading = false;
  }

  on(e) {
    //غير مستخدمة
    print("e${e.error}");
    //print("eeeee${ex.stackTrace}");
    print("ee${e.type}");
    setState(() {
      isDownloading = false;
    });

    /*   if (!_cancelToken.isCancelled) {
        _modalBottomSheetMenu("err", ex.type.toString());
      } */
    //_modalBottomSheetMenu("err", e.type.toString());

    print("e${e.error}");
    //print("eeeee${ex.stackTrace}");
    print("ee${e.type}");
    print("eee${e.toString()}");

    print("eeee${e.message}");

    setState(() {
      // isDownloading = false;
    });
  }

  downloadFiles() async {
    //عير مستخدمة
    isDownloading = true;
    Dio dio = Dio();
    downloadFile = 0;
    _cancelToken = CancelToken();
    setState(() {
      downloadProgress = 0;
    });
    getRemainingDownloadAddress();
    try {
      for (var video in selectedVideos) {
        print("selectedVideos$selectedVideos");
        if (!isDownloading || _cancelToken.isCancelled) {
          break;
        }
        while (video.downloadAddr == null) {
          if (!isDownloading || _cancelToken.isCancelled) {
            break;
          }
          await Future.delayed(const Duration(seconds: 2), () {});
        }
        if (!isDownloading || _cancelToken.isCancelled) {
          break;
        }
        if (video.downloadAddr != null) {
          await dio.download(video.downloadAddr!,
              '/storage/emulated/0/Download/New App/${atname}__${video.id}.mp4',
              cancelToken: _cancelToken, onReceiveProgress: (received, total) {
                setState(() {
                  downloadProgress = received == total ? 0 : received / total;
                  print("downloadProgress$downloadProgress");
                });
              }).then((value) =>
              setState(() {
                print("ggggg${value.statusCode}");

                downloadFile++;
              }));
        }
        print("gggggf");

        // downloadFile++;
      }
      isDownloading = false;

      _modalBottomSheetMenu("ok", "");

      if (_cancelToken.isCancelled) {
        _modalBottomSheetMenu("cancel", "");

        /*   showDialog(
            context: context,
            builder: (builder) {
              return AlertDialog(
                title: Text('Download Cancelled'),
                content: SizedBox(
                    width: double.infinity,
                    height: 100,
                    child: Container(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${downloadFile} File/s have been downloaded successfully.'),
                            Text(
                                'Failed to download${selectedVideos.length - downloadFile} file/s'),
                          ],
                        ))),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8))),
                          child: Text(
                            'Ok',
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          )),
                    ),
                  ),
                ],
              );
            }); */
      }
      setState(() {});
    } on DioError catch (ex) {
      setState(() {
        isDownloading = false;
      });

      /*   if (!_cancelToken.isCancelled) {
        _modalBottomSheetMenu("err", ex.type.toString());
      } */
      _modalBottomSheetMenu("err", ex.type.toString());

      print("e${ex.error}");
      //print("eeeee${ex.stackTrace}");
      print("ee${ex.type}");
      print("eee${ex.toString()}");

      print("eeee${ex.message}");
    } catch (e) {
      print(e);
      if (!_cancelToken.isCancelled) {
        setState(() {
          isDownloading = false;
        });
        _modalBottomSheetMenu("err", e.toString());
      }

      /*   showDialog(
          context: context,
          builder: (builder) {
            return AlertDialog(
              title: Text('Download Failed: Error'),
              content: SizedBox(
                  width: double.infinity,
                  height: 100,
                  child: Container(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${downloadFile} File/s have been downloaded successfully.'),
                          Text(
                              'Failed to download${selectedVideos.length - downloadFile} file/s'),
                        ],
                      ))),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                        child: Text(
                          'Ok',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        )),
                  ),
                ),
              ],
            );
          }); */
    }
  }

  Future<void> getRemainingDownloadAddress() async {
    for (VideoModel video in selectedVideos) {
      if (video.downloadAddr == null) {
        headlessWebView = HeadlessInAppWebView(
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
              preferredContentMode: UserPreferredContentMode.DESKTOP,
              useShouldInterceptFetchRequest: true,
            ),
          ),
          shouldInterceptFetchRequest: (controller, request) {
            return Future(() => request);
          },
          onPageCommitVisible: (controller, url) {},
          onLoadStart: (controller, uri) {},
          onLoadStop: (controller, url) {
            controller.getHtml().then((value) =>
            {
              video.downloadAddr =
              value!.split('"video" src="')[1].split('"></video>')[0]
            });
          },
          onWebViewCreated: (InAppWebViewController controller) {
            headlessWebViewController = controller;
          },
        );
        await headlessWebView!.dispose();
        await headlessWebView!.run();
        headlessWebViewController!
            .loadUrl(urlRequest: URLRequest(url: Uri.parse(video.url)));
        while (video.downloadAddr == null) {
          if (!isDownloading) break;
          await Future.delayed(const Duration(seconds: 2), () {});
        }
      }
      if (!isDownloading) break;
    }
  }

  Future<void> _retryRequestPermission() async {
    final hasGranted = await _checkPermission();

    if (hasGranted) {
      await _prepareSaveDir();
    }

    setState(() {
      _permissionReady = hasGranted;
    });
  }

  Future<void> _requestDownload(TaskInfo task) async {
    // print("tasktaskId${task.toString()}");

    // print("tasktaskId${task.taskId}");

    // print("tasktaskId${task.link}");

    // // String? a = task.taskId == null ? DateTime.now().toString() : task.taskId;
    try {
      task.taskId = await FlutterDownloader.enqueue(
        fileName:
        "${atname}__${DateTime.now().toString().replaceAll(
            RegExp('[^A-Za-z0-9]'), '')}.mp4",

        url: task.link!,
        // "https://www.learningcontainer.com/download/sample-mp4-video-file-download-for-testing/?wpdmdl=2727&refresh=62dcf803d15e91658648579",
        savedDir: _localPath,
        // saveInPublicStorage: true,
      );
    } on FlutterDownloaderException catch (err) {
      log('Failed to enqueue. Reason: ${err.message}');
    } on PlatformException catch (err) {
      log('Failed to enqueue. Reason: ${err.message}');
    }
  }

  Future<void> _pauseDownload(TaskInfo task) async {
    await FlutterDownloader.pause(taskId: task.taskId!);
  }

  Future<void> _resumeDownload(TaskInfo task) async {
    final newTaskId = await FlutterDownloader.resume(taskId: task.taskId!);
    task.taskId = newTaskId;
  }

  Future<void> _retryDownload(TaskInfo task) async {
    final newTaskId = await FlutterDownloader.retry(taskId: task.taskId!);
    task.taskId = newTaskId;
  }

  Future<bool> _openDownloadedFile(TaskInfo? task) {
    if (task != null) {
      return FlutterDownloader.open(taskId: task.taskId!);
    } else {
      return Future.value(false);
    }
  }

  Future<void> _delete(TaskInfo task) async {
    await FlutterDownloader.remove(
      taskId: task.taskId!, shouldDeleteContent: false,);
    // await _prepare();
    setState(() {});
  }

  Future<bool> _checkPermission() async {
    if (Platform.isIOS) {
      return true;
    }

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt! <= 28) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  Future<void> _prepare() async {
    final tasks = await FlutterDownloader.loadTasks();
    tasks?.forEach((element) async {
      await FlutterDownloader.remove(taskId: element.taskId);
    });

    if (tasks == null) {
      print('No tasks were retrieved from the database.');
      return;
    }
    final tasks2 = await FlutterDownloader.loadTasks();

    print("task llll${tasks2!.length}");

    var count = 0;
    _tasks = [];
    _items = [];

    print("isDownloadinggg$isDownloading");

    _tasks!.addAll(
      selectedVideos.map(
            (document) =>
            TaskInfo(name: document.id, link: document.downloadAddr),
      ),
    );

    _items.add(ItemHolder(name: 'Videos'));
    for (var i = count; i < selectedVideos!.length; i++) {
      _items.add(ItemHolder(name: _tasks![i].name, task: _tasks![i]));
      count++;
    }
    for (final task in tasks2) {
      for (final info in _tasks!) {
        if (info.link == task.url) {
          info
            ..taskId = task.taskId
            ..status = task.status
            ..progress = task.progress;
        }
      }
    }

    _permissionReady = await _checkPermission();

    if (_permissionReady) {
      await _prepareSaveDir();
    }
    print("_tasks${_tasks?.length}");
    _tasks?.forEach((element) async {
      try {
        await _requestDownload(element);
      } catch (er) {
        print("errr*******************************محمووووووود*******$er");
      }
    });

    //isDownloading = false;
    print("isDownloadinggg$isDownloading");

    print(downloadFile);

    print(selectedVideos.length);
    if (downloadFile == selectedVideos.length) {
      //  _modalBottomSheetMenu("ok", "");
      //isDownloading = false;
      print("isDownloadinggg$isDownloading");

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _prepareSaveDir() async {
    _localPath = "/storage/emulated/0/Download/New App/";
    final savedDir = Directory(_localPath);
    final hasExisted = savedDir.existsSync();
    if (!hasExisted) {
      await savedDir.create();
    }
  }
}


class ItemHolder {
  ItemHolder({this.name, this.task});

  final String? name;
  final TaskInfo? task;
}

class TaskInfo {
  TaskInfo({this.name, this.link});

  final String? name;
  final String? link;

  String? taskId;
  int? progress = 0;
  DownloadTaskStatus? status = DownloadTaskStatus.undefined;
}
