import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:new_app/playvedeo%20copy.dart';
import 'package:new_app/responsive/responsive.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class Download2 extends StatefulWidget {
  const Download2({Key? key}) : super(key: key);

  @override
  State<Download2> createState() => _DownloadState2();
}

class _DownloadState2 extends State<Download2>
    with SingleTickerProviderStateMixin {
  bool isSwitched = false;
  static const _pageSize = 2;

  var showProgress2 = false;

  bool selectall = false;

  bool test = true;

  void alertDialog(BuildContext context) {
    var alert = AlertDialog(
      title: Text('Delete Video'),
      content: SizedBox(
          width: double.infinity,
          height: 100,
          child: Container(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Are you sure you want to delete?'),
                ],
              ))),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () async {
              Navigator.of(context).pop();

              List<Uint8List> listselectedtmp = [];
              if (await Permission.manageExternalStorage.request().isGranted) {
                setState(() {
                  showProgress = true;
                });

                print("listselectedtmp${_selectedfolders.length}");

                //images.clear();
                for (var element in _selectedfolders) {
                  log(element.path);

                  print("startdele${element.path}");

                  //listselected.removeAt(0);

                  await deleteFileall(File(element.path)).then((value) async {
                    setState(() {
                      //  images.removeAt(listselected[0]);
                      // listselected.removeAt(0);
                    });
                    print(listselected);
                    print("value");
                  });
                }
                for (var element1 in listselected) {
                  setState(() {
                    // showProgress = true;

                    images.removeAt(element1);
                  });
                }
                ;

                //_folders.remove(e);
                listselected.clear();
                _selectedfolders.clear();
                //_foldersinit.remove(e);

                /*    for (var element in _foldersinit) {
                  print(element.path);
                  Uint8List? image = await getBackgroundImage(element.path);
                  
                  images.add(image!);
                  log(element.path);
                } */

                //   Navigator.of(context).pop();

                setState(() {
                  isselcted = false;

                  showProgress = false;
                  //  getDir();
                });

                const snackBar = SnackBar(
                  content: Text('Videos Deleted'),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              } else {
                showProgress = false;

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('NeeD Permission'),
                ));
                //    Navigator.of(context).pop();
                //  Navigator.of(context).pop();
              }
            },
            child: Container(
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 218, 34, 10),
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                child: Text(
                  'Ok',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                )),
          ),
        ),
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
                  'Cancel',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                )),
          ),
        ),
      ],
    );
    showDialog(context: context, builder: (BuildContext context) => alert);
  }

  late AnimationController _controller;
  late List<FileSystemEntity> _folders = [];
  late List<FileSystemEntity> _foldersinit = [];

  late List<FileSystemEntity> _today = [];
  late List<FileSystemEntity> _yesterday = [];
  late List<FileSystemEntity> _twoday = [];

  late List<FileSystemEntity> _selectedfolders = [];

  bool isselcted = false;
  bool showProgress = true;

  late List<Uint8List> images = [];
  Future<void> deleteFile(File file, int index) async {
    const snackBar = SnackBar(
      content: Text('Video Deleted'),
    );
    // await Permission.manageExternalStorage.request().isGranted;
    if (await Permission.manageExternalStorage.request().isGranted) {
      try {
        if (await file.exists()) {
          print("exist");
          await file.delete().then((value) {
            _foldersinit.removeAt(index);
            images.removeAt(index);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            Navigator.of(context).pop();
          });
        }
      } catch (e) {
        log(e.toString());
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('NeeD Permission'),
      ));
      Navigator.of(context).pop();
      //
    }
  }

  Future<void> deleteFileall(File file) async {
    /*  const snackBar = SnackBar(
      content: Text('Video Deleted'),
    ); */
    // await Permission.manageExternalStorage.request().isGranted;

    try {
      if (await file.exists()) {
        print("exist");
        // _folders.removeWhere((ee) => ee.path == file.path);

        await file.delete().then((value) {
          //  _folders.removeWhere((ee) => ee.path == file.path);
          setState(() {
            _folders.removeWhere((e) => e.path == file.path);

            _foldersinit.removeWhere((ee) => ee.path == file.path);
          });

          //  ScaffoldMessenger.of(context).showSnackBar(snackBar);
          // Navigator.of(context).pop();
        });
      } else {
        print("not exist");
      }
    } catch (e) {
      log(e.toString());
      setState(() {
        showProgress = false;
      });
    }

    //  Navigator.of(context).pop();
    //
  }

  Future getDir() async {
    setState(() {
      images.clear();
      _folders.clear();
      _foldersinit.clear();
      listselected.clear();
      _selectedfolders.clear();
      // selectall = false;
      showProgress = false;
    });
    //_folders.clear();
    final Directory _photoDir =
        Directory('/storage/emulated/0/Download/New App');
    _folders = _photoDir
        .listSync()
        .where((e) => e.path.endsWith('.mp4'))
        .toList()
      ..sort((l, r) => r.statSync().modified.compareTo(l.statSync().modified));
    // images.clear();

    _folders.length <= 12
        ? _foldersinit.addAll(_folders)
        : _foldersinit.addAll(_folders.sublist(0, 12));

    _foldersinit
        .sort((l, r) => r.statSync().modified.compareTo(l.statSync().modified));
    log(_folders.length.toString());
    for (var element in _foldersinit) {
      print(element.path);
      Uint8List? image = await getBackgroundImage(element.path);
      setState(() {
        images.add(image!);
      });
      log(element.path);
    }
    showProgress = false;
    print(_foldersinit.length);
    setState(() {
      showProgress = false;
    });
  }

  Future<Uint8List?> getBackgroundImage(path) async {
    return await VideoThumbnail.thumbnailData(
      video: path,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 480,
      maxWidth:
          360, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
      quality: 100,
    );
  }

  Future<bool> getDir2() async {
    print("ddddd");
    setState(() {
      showProgress = true;
    });
    //_folders.clear();

    if (_foldersinit.length < _folders.length) {
      if (_folders.length >= _foldersinit.length + 12) {
        List<FileSystemEntity> temp =
            _folders.sublist(_foldersinit.length, _foldersinit.length + 12);
        _foldersinit.addAll(
            _folders.sublist(_foldersinit.length, _foldersinit.length + 12));

        for (var element in temp
            // _folders.sublist(_foldersinit.length, _foldersinit.length + 12)
            ) {
          Uint8List? image = await getBackgroundImage(element.path);
          setState(() {
            images.add(image!);
          });
          log(element.path);
        }
      } else {
        List<FileSystemEntity> temp =
            _folders.sublist(_foldersinit.length, _folders.length);

        _foldersinit
            .addAll(_folders.sublist(_foldersinit.length, _folders.length));
        for (var element in temp
            // _folders.sublist(_foldersinit.length, _foldersinit.length + 12)
            ) {
          print(element.path);
          Uint8List? image = await getBackgroundImage(element.path);
          setState(() {
            images.add(image!);
          });
          log(element.path);
        }
      }
    }
    showProgress = false;
    print(_foldersinit.length);
    setState(() {
      showProgress = false;
    });
    return true;
  }

  Future<void> shareFile(path) async {
    await FlutterShare.shareFile(
      title: ' ',
      filePath: path,
    );
  }

  Future<void> sharemultiFiles(List<String> files) async {
    Share.shareFiles(files, text: ' ');
  }

  List<int> listselected = [];
  Widget fileManager(FileManagerController controller) {
    //controller.se(SortBy.date);
    return FileManager(
      controller: controller,
      builder: (context, snapshot) {
        final List<FileSystemEntity> entities = snapshot;
        return ListView.builder(
          itemCount: entities.length,
          itemBuilder: (context, index) {
            return Card(
              child: ListTile(
                leading: FileManager.isFile(entities[index])
                    ? Icon(Icons.feed_outlined)
                    : Icon(Icons.folder),
                title: Text(FileManager.basename(entities[index])),
                onTap: () {
                  if (FileManager.isDirectory(entities[index])) {
                    controller.openDirectory(entities[index]); // open directory
                  } else {
                    // Perform file-related tasks.
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  late FileManagerController controller;
  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    controller = FileManagerController();
    //controller.sortBy(SortBy.date);
    // print(" pageKey --  pageKey");
    getDir();
    //_fetchPage(0);

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: IconButton(icon: Icon(Icons.abc), onPressed: GG),
      body: test
          ? fileManager(controller)
          :

          /* showProgress
          ? Center(
              child: Image.asset('images/loading.gif'),
            )
          : */
          mywidget(MediaQuery.of(context).size.width),
      floatingActionButton: selectall
          //isselcted
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: FloatingActionButton(
                          backgroundColor: Colors.red,
                          onPressed: () async {
                            if (_selectedfolders.isNotEmpty) {
                              alertDialog(context);
                            }

                            /*  _folders.map((e) async {
                                await deleteFile(File(e.path));
                                log('deleted ${e.path}');
                              }).toList();
                              _folders.clear();
                              images.clear();
                              isselcted = false;
                              setState(() {}); */
                          },
                          child: const Icon(Icons.delete)),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: FloatingActionButton(
                          backgroundColor: Color.fromARGB(255, 125, 114, 221),
                          onPressed: () {},
                          child: Text(_selectedfolders.length.toString())),
                    ),
                  ),
                ),
                Expanded(
                    child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FloatingActionButton(
                                backgroundColor: !_selectedfolders.isEmpty
                                    ? Colors.blue
                                    : Colors.blueGrey,
                                onPressed: () {
                                  setState(() {
                                    isSwitched = !isSwitched;
                                    if (isSwitched == true) {
                                      _selectedfolders.clear();
                                      listselected.clear();
                                      _selectedfolders.addAll(_foldersinit);
                                      selectall = true;

                                      print(true);
                                      /*  for (int i = 0; i < _folders.length; i++) {
                                      listselected.add(i);
                                    } */
                                    } else {
                                      selectall = true;

                                      _selectedfolders.clear();
                                      listselected.clear();
                                    }
                                  });
                                },
                                child: const Icon(Icons.checklist_rounded)),

                            // Text("Select All"),
                            /*      InkWell(
                                child: CircleAvatar(
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    isSwitched = !isSwitched;
                                    if (isSwitched == true) {
                                      _selectedfolders.clear;
                                      _selectedfolders.addAll(_folders);

                                      print(true);
                                      /*  for (int i = 0; i < _folders.length; i++) {
                                      listselected.add(i);
                                    } */
                                    } else {
                                      _selectedfolders.clear();
                                    }
                                  });
                                })
                      */ /*        }),
                            Switch(
                              value: isSwitched,
                              onChanged: (value) {
                                setState(() {
                                  isSwitched = value;
                                  if (isSwitched == true) {
                                    _selectedfolders.clear;
                                    _selectedfolders.addAll(_folders);

                                    print(true);
                                    /*  for (int i = 0; i < _folders.length; i++) {
                                      listselected.add(i);
                                    } */
                                  } else {
                                    _selectedfolders.clear();
                                  }
                                });
                              },
                            ) */
                          ],
                        ))),
                Expanded(
                    child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FloatingActionButton(
                                backgroundColor: Colors.red,
                                onPressed: () {
                                  setState(() {
                                    //  isSwitched = !isSwitched;
                                    //  selectall = false;
                                    // if (isSwitched == true) {
                                    // } else {
                                    _selectedfolders.clear();
                                    listselected.clear();

                                    selectall = false;
                                    //}
                                  });
                                },
                                child: const Icon(Icons.clear)),
                          ],
                        ))),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: FloatingActionButton(
                        backgroundColor: Colors.green,
                        onPressed: () async {
                          if (_selectedfolders.isNotEmpty) {
                            List<String> paths =
                                _selectedfolders.map((e) => e.path).toList();
                            sharemultiFiles(paths);
                          }
                        },
                        child: const Icon(Icons.share)),
                  ),
                ),
              ],
            )
          : /* _folders.isNotEmpty && !showProgress
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                          backgroundColor:
                              isSwitched ? Colors.blue : Colors.blue,
                          onPressed: () {
                            setState(() {
                              isSwitched = !isSwitched;
                              if (isSwitched == true) {
                                _selectedfolders.clear;
                                _selectedfolders.addAll(_folders);

                                print(true);
                                /*  for (int i = 0; i < _folders.length; i++) {
                                      listselected.add(i);
                                    } */
                              } else {
                                _selectedfolders.clear();
                              }
                            });
                          },
                          child: const Icon(Icons.checklist_rounded)),
                      /*  Text("Select All"),
                      Switch(
                        value: isSwitched,
                        onChanged: (value) {
                          setState(() {
                            isSwitched = value;
                            if (isSwitched == true) {
                              _selectedfolders.clear;
                              _selectedfolders.addAll(_folders);
                              print(true);
                              /*  for (int i = 0; i < _folders.length; i++) {
                                      listselected.add(i);
                                    } */
                            } else {
                              _selectedfolders.clear();
                            }
                          });
                        },
                      ) */
                    ],
                  ))
            */
          null,
    );
  }

  Widget mywidget(currentWidth) {
    int i = getSliver(currentWidth);
    final data = MediaQueryData.fromWindow(WidgetsBinding.instance.window);

    return (_folders.isNotEmpty)
        ? NotificationListener<ScrollNotification>(
            onNotification: (scrollNotification) {
              if (scrollNotification.metrics.pixels ==
                  scrollNotification.metrics.maxScrollExtent) {
                setState(() {
                  // showProgress = true;
                  getDir2();
                });
              }

              return true;
            },
            child: RefreshIndicator(
              triggerMode: RefreshIndicatorTriggerMode.anywhere,
              onRefresh: _refresh,
              child: GridView.builder(
                  itemCount: _foldersinit.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      childAspectRatio: 0.75,
                      //  mainAxisExtent: 300,
                      // mainAxisExtent: 150,
                      mainAxisSpacing: 1,
                      crossAxisSpacing: 1,
                      crossAxisCount: i),
                  itemBuilder: (context, index) {
                    print("${_foldersinit.length} ---- ${_foldersinit.length}");

                    var video = _foldersinit[index];
                    /*   final stat = FileStat.statSync(video.path);
                    print('Accessed: ${stat.accessed}');
                    print('Modified: ${stat.modified}');
                    print('Changed:  ${stat.changed}');
                    */
                    return Stack(children: [
                      _foldersinit[index].existsSync()
                          ? Positioned.fill(
                              child: InkWell(
                                child: Padding(
                                    padding: const EdgeInsets.all(1),
                                    child: (index > images.length - 1)
                                        ? Shimmer.fromColors(
                                            baseColor: Colors.black,
                                            highlightColor:
                                                Color.fromARGB(239, 0, 0, 0),
                                            child: Container(
                                              //height: height,
                                              //width: width,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Image.memory(
                                            images[index],
                                            filterQuality: FilterQuality.high,
                                            fit: BoxFit.cover,
                                          )),
                                onLongPress: () {
                                  print("$selectall");
                                  if (_selectedfolders.isNotEmpty) {
                                    if (_selectedfolders
                                        .contains(_foldersinit[index])) {
                                      print("existtt");
                                      _selectedfolders.removeWhere((element) =>
                                          element == _foldersinit[index]);
                                      listselected.removeWhere(
                                          (element1) => element1 == index);
                                    } else {
                                      setState(() {
                                        print("notexisttt");
                                        selectall = true;

                                        _selectedfolders
                                            .add(_foldersinit[index]);
                                        listselected.add(index);
                                      });
                                    }
                                    print(_selectedfolders.length);
                                    print(listselected);

                                    isselcted = false;
                                    setState(() {});
                                  } else {
                                    _selectedfolders.add(_foldersinit[index]);
                                    listselected.add(index);
                                    print(_selectedfolders.length);
                                    print(listselected);

                                    isselcted = false;
                                    setState(() {
                                      selectall = true;
                                    });
                                  }
                                  isselcted = !isselcted;
                                  setState(() {});
                                },
                                onTap: () async {
                                  if ((_selectedfolders.isNotEmpty) ||
                                      selectall) {
                                    if (_selectedfolders
                                        .contains(_foldersinit[index])) {
                                      print("existtt");
                                      _selectedfolders.removeWhere((element) =>
                                          element == _foldersinit[index]);
                                      listselected.removeWhere(
                                          (element1) => element1 == index);
                                    } else {
                                      print("notexisttt");

                                      _selectedfolders.add(_foldersinit[index]);
                                      listselected.add(index);
                                    }
                                    print(_selectedfolders.length);
                                    print(listselected);

                                    isselcted = false;
                                    setState(() {});
                                  } else {
                                    await OpenFile.open(
                                      video.path,
                                    );
                                    /*  ExternalVideoPlayerLauncher
                                        .launchOtherPlayer(
                                            video.path, MIME.applicationMp4, {
                                      "title": "",
                                    }); */
                                    /*   Navigator.push(context,
                                        MaterialPageRoute(builder: (context) {
                                      return showVideo2(
                                          file: File(video.path),
                                          listFiles: _foldersinit
                                              .map((e) => File(e.path))
                                              .toList());
                                    })); */
                                  }
                                },
                              ),
                            )
                          : SizedBox(),
                      _selectedfolders.isEmpty && !selectall
                          ? Center(
                              child: IconButton(
                              onPressed: () async {
                                // await OpenFile.open(video.path);

                                /*   ExternalVideoPlayerLauncher.launchOtherPlayer(
                                    video.path, MIME.applicationMp4, {
                                  "title": "",
                                }); */
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return showVideo2(
                                      file: File(video.path),
                                      listFiles: _foldersinit
                                          .map((e) => File(e.path))
                                          .toList());
                                }));
                              },
                              icon: _selectedfolders.isNotEmpty ||
                                      (index > images.length - 1)
                                  ? SizedBox()
                                  : const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                            ))
                          : SizedBox(),
                      /*   Positioned(
                    height: 40,
                    bottom: 0,
                    left: 4,
                    right: 4,
                    child: _selectedfolders.isNotEmpty
                        ?

                        //  isselcted
                        SizedBox()
                        : Container(
                            color: Colors.black.withOpacity(0.6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                IconButton(
                                    onPressed: () async {
                                      var alert = AlertDialog(
                                        title: Text('Delete Video'),
                                        content: SizedBox(
                                            width: double.infinity,
                                            height: 100,
                                            child: Container(
                                                alignment: Alignment.centerLeft,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        'Are you sure you want to delete?'),
                                                  ],
                                                ))),
                                        actions: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: InkWell(
                                              onTap: () async {
                                                String path =
                                                    _folders[index].path;
                                                log(path);
                                                await deleteFile(
                                                    File(path), index);

                                                //  _folders.removeAt(index);
                                                // images.removeAt(index);
                                                setState(() {
                                                  //  ScaffoldMessenger.of(context)
                                                  //    .showSnackBar(snackBar);
                                                  //Navigator.of(context).pop();
                                                });
                                              },
                                              child: Container(
                                                  height: 38,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                      color: Color.fromARGB(
                                                          255, 218, 34, 10),
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  8))),
                                                  child: Text(
                                                    'Ok',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15),
                                                  )),
                                            ),
                                          ),
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
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  8))),
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15),
                                                  )),
                                            ),
                                          ),
                                        ],
                                      );
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              alert);
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    )),
                                IconButton(
                                    onPressed: () async {
                                      await shareFile(_folders[index].path);
                                    },
                                    icon: const Icon(
                                      Icons.share,
                                      color: Colors.green,
                                    ))
                              ],
                            ),
                          )), */
                      Positioned(
                          top: 4,
                          right: 10,
                          height: 21,
                          width: 21,
                          child: _selectedfolders.contains(_foldersinit[index])
                              ?
                              //isselcted
                              const CircleAvatar(
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                )
                              : (_selectedfolders.isNotEmpty) || selectall
                                  ? Container(
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              width: 3,
                                              color: Color.fromARGB(
                                                      255, 148, 148, 150)
                                                  .withOpacity(0.6))),
                                    )
                                  : const SizedBox())
                    ]);
                  }),
              /*  whenEmptyLoad: false,
              delegate: DefaultLoadMoreDelegate(),
              textBuilder: DefaultLoadMoreTextBuilder.chinese,
          */
            ))
        : Center(
            child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "No Vidéos Exists",
                      style: TextStyle(fontSize: 33),
                    ),
                    SizedBox(
                      height: 40,
                    ),
                    Image.asset('images/novideo.png')
                  ],
                )));
  }

  Future<void> _refresh() async {
    // _folders.clear();
    return getDir();
  }

  Future<void> GG() async {
    final String dir = (await getTemporaryDirectory()).path;
    print("dd");
    final Directory _photoDir =
        Directory('/storage/emulated/0/Download/New App/');

    await OpenFile.open('$dir\\');
  }
}
