import 'dart:developer';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

import 'models/video.dart';

class SingleVideoPage extends StatefulWidget {
  SingleVideoPage({
    Key? key,
    required this.sharedUrl,
  }) : super(key: key);
  final String sharedUrl;

  @override
  State<SingleVideoPage> createState() => _SingleVideoPageState();
}

class _SingleVideoPageState extends State<SingleVideoPage> {
  HeadlessInAppWebView? headlessWebView;
  static const platform = MethodChannel('app.channel.shared.data');
  String? dataShared /* ='https://www.tiktok.com/@modeldee4'*/;

  InAppWebViewController? webViewController;
  InAppWebViewController? headlessWebViewController;
  String? avatar;
  String? name = '';
  String? atname = '';
  VideoModel? video;
  bool isLoading = false;
  int triesCount = 0;
  bool selectAll = false;
  double downloadProgress = 0;
  int downloadFile = 0;
  bool isDownloading = false;

  CancelToken _cancelToken = CancelToken();

  Widget thumbnailsGrid() {
    return Image.network(video!.thumbUrl, errorBuilder: (_, obj, trace) {
      return Container(
        alignment: Alignment.center,
        child: Icon(Icons.error_outline_sharp),
      );
    }, loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) {
        return child;
      } else {
        return Container(
          alignment: Alignment.center,
          child: Image.asset('images/loading.gif'),
        );
      }
    });
  }

  Widget topWidget() {
    return Container(
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(16.0),
                ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              child: avatar != null
                  ? ClipRRect(
                      child: Image.network(
                        avatar!,
                      ),
                      borderRadius: BorderRadius.circular(50.0),
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.all(Radius.circular(50))),
                    ),
              radius: 50,
            ),
          ),
          atname != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$atname',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 24),
                ),
        ],
      ),
    );
  }

  @override
  void initState() {
    getDownloadAddress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          name != null ? name! : '',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 0,
      ),
      body: Stack(
        children: [
          topWidget(),
          NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
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
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: name == null ||
                      avatar == null ||
                      atname == null /* ||  allVideosCount == null */ ? Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 70,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                          child: video == null
                              ? Container(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1,
                                      )),
                                )
                              : Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                  child: InkWell(
                                    onTap: () async {
                                      if (await Permission.storage.request().isGranted) {
                                        downloadFiles();
                                      } else {
                                        print("Permission denied");
                                      }
                                    },
                                    child: Container(
                                      height: 38,
                                      width: 150,
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.all(Radius.circular(24))),
                                        child: Text(
                                          'Save',
                                          style: TextStyle(color: Colors.white, fontSize: 15),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: video == null
                              ? Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(24.0),
                                  child: CircularProgressIndicator(),
                                )
                              : Image.network(video!.thumbUrl,
                                  width: MediaQuery.of(context).size.width / 2,
                                  errorBuilder: (_, obj, trace) {
                                  return Container(
                                    alignment: Alignment.center,
                                    child: Icon(Icons.error_outline_sharp),
                                  );
                                }, loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  } else {
                                    return Container(
                                      width: 100,
                                      alignment: Alignment.center,
                                      child: Image.asset('images/loading.gif'),
                                    );
                                  }
                                }),
                        )
                      ],
                    ),
            ),
          ),
          isLoading
              ? Container(
                  color: Colors.white.withAlpha(50),
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(),
                )
              : Container(),
          isDownloading
              ? Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: AlertDialog(
                    title: Text('Downloading'),
                    content: SizedBox(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height / 4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Video ${1} of ${1}' /*  ' ${selectedVideos[downloadFile].id} .mp4'*/,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          /* Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: LinearProgressIndicator(
                          value: downloadProgress,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text('Overall progress',
                          style: TextStyle(fontSize: 16),),
                      ),*/
                          Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: LinearProgressIndicator(
                              value: downloadProgress,
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: InkWell(
                          onTap: () async {
                            setState(() {
                              isDownloading = false;
                            });
                            _cancelToken.cancel();
                          },
                          child: Container(
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.all(Radius.circular(8))),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white, fontSize: 15),
                              )),
                        ),
                      ),
                    ],
                  ),
                )
              : Container()
        ],
      ),
    );
  }

  downloadFiles() async {
    isDownloading = true;
    Dio dio = Dio();
    _cancelToken = CancelToken();
    setState(() {});
    try {
      while (video!.downloadAddr == null) {
        print('null adress');
        if (!isDownloading || _cancelToken.isCancelled) {
          break;
        }
        await Future.delayed(const Duration(seconds: 2), () {});
      }
      if (video!.downloadAddr != null) {
        await dio.download(video!.downloadAddr!,
            '/storage/emulated/0/Download/New App/${atname}__${video!.id}.mp4',
            cancelToken: _cancelToken, onReceiveProgress: (received, total) {
          setState(() {
            downloadProgress = received / total;
          });
          print('progress: $downloadProgress');
        });
        if (_cancelToken.isCancelled) {
          await showDialog(
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
                              Text('Downloading the video is canelled.'),
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
              });
        }
      }
    } catch (e) {
      await showDialog(
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
                          Text('Failed to download the video.'),
                          //  Text('${downloadFile} File/s have been downloaded successfully.'),
                          //  Text('Failed to download${selectedVideos.length - downloadFile} file/s'),
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
                            color: Colors.blue, borderRadius: BorderRadius.all(Radius.circular(8))),
                        child: Text(
                          'Ok',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        )),
                  ),
                ),
              ],
            );
          });
    }
  }

  Future<void> getDownloadAddress() async {
    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: Uri.parse(widget.sharedUrl)),
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          preferredContentMode: UserPreferredContentMode.DESKTOP,
        ),
      ),
      onTitleChanged: (controller, title) async {
        controller.getHtml().then((value) => {
              // log('titleHtml: ${value}'),
              setState(() {
                name = value!.split('"og:title" content="')[1].split('on TikTok">')[0];
                atname = '@${value.split('/video/')[0].split('https://www.tiktok.com/@')[1]}';
              }),
            });
      },
      onLoadStop: (controller, url) {
        controller.getHtml().then((value) => {
              avatar = value!.split('><img loading="lazy" src="')[1].split('" class=')[0],
              video = VideoModel(
                  id: value.split('/video/')[1].split('">')[0],
                  url: '',
                  thumbUrl: value.split('<img mode="4" src="')[1].split('" alt=')[0],
                  watchesCount: '',
                  downloadAddr: value.split('mediatype="video" src="')[1].split('"></video>')[0]),
              setState(() {}),
            });
      },
      onWebViewCreated: (InAppWebViewController controller) {
        headlessWebViewController = controller;
      },
    );
    await headlessWebView!.dispose();
    await headlessWebView!.run();
  }
}
