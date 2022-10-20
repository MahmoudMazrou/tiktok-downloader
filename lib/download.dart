import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:new_app/playvedeo%20copy.dart';
import 'package:new_app/responsive/responsive.dart';
import 'package:new_app/thumbnails_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class Download extends StatefulWidget {
  const Download({Key? key}) : super(key: key);

  @override
  State<Download> createState() => _DownloadState();
}

class _DownloadState extends State<Download>
    with SingleTickerProviderStateMixin {
  bool isSwitched = false;
  static const _pageSize = 2;

  bool selectall = false;

  void alertDialog(BuildContext context) {
    var alert = AlertDialog(
      title: const Text('Delete Video'),
      content: SizedBox(
        width: double.infinity,
        height: 100,
        child: Container(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Are you sure you want to delete?'),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () async {
              Navigator.of(context).pop();

              List<Uint8List> listselectedtmp = [];
              if (await Permission.storage.request().isGranted) {
                print("listselectedtmp${_selectedfolders.length}");

                //images.clear();
                for (var element in _selectedfolders) {
                  await deleteFileall(File(element.path));
                }
                await getDir();
                listselected.clear();
                _selectedfolders.clear();

                const snackBar = SnackBar(
                  content: Text('Videos Deleted'),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('NeeD Permission'),
                  ),
                );
                //    Navigator.of(context).pop();
                //  Navigator.of(context).pop();
              }
            },
            child: Container(
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 218, 34, 10),
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              child: const Text(
                'Ok',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
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
              decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    );
    showDialog(context: context, builder: (BuildContext context) => alert);
  }

  late AnimationController _controller;
  late List<FileSystemEntity> _foldersinit = [];

  late List<FileSystemEntity> _selectedfolders = [];

  Future<void> deleteFile(File file, int index) async {
    const snackBar = SnackBar(
      content: Text('Video Deleted'),
    );
    // await Permission.manageExternalStorage.request().isGranted;
    if (await Permission.storage.request().isGranted) {
      try {
        if (await file.exists()) {
          await file.delete().then((value) {
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            Navigator.of(context).pop();
          });
        }
      } catch (e) {
        log(e.toString());
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
        // _folders.removeWhere((ee) => ee.path == file.path);

        await file.delete();
      } else {}
    } catch (e) {
      log(e.toString());
    }

    //  Navigator.of(context).pop();
    //
  }

  Future getDir() async {
    _foldersinit.clear();
    listselected.clear();
    _selectedfolders.clear();
    selectall = false;
    final Directory _photoDir =
        Directory('/storage/emulated/0/Download/New App');
    _foldersinit = _photoDir
        .listSync()
        .where((e) => e.path.endsWith('.mp4'))
        .toList()
      ..sort((l, r) => r.statSync().modified.compareTo(l.statSync().modified));
    // images.clear();

    // _folders.length <= 12
    //     ? _foldersinit.addAll(_folders)
    //     : _foldersinit.addAll(_folders.sublist(0, 12));

    _foldersinit
        .sort((l, r) => r.statSync().modified.compareTo(l.statSync().modified));
    // for (var element in _foldersinit) {
    //   log("----------------here");
    //   Uint8List? image = await getBackgroundImage(element.path);
    //   images.add(image!);
    // }
    setState(() {
      log("----> set State 7");
    });
  }

  // Future<bool> getDir2() async {
  //   images.clear();
  //   if (_foldersinit.length < _folders.length) {
  //     if (_folders.length >= _foldersinit.length + 12) {
  //       List<FileSystemEntity> temp =
  //           _folders.sublist(_foldersinit.length, _foldersinit.length + 12);
  //       _foldersinit.addAll(
  //           _folders.sublist(_foldersinit.length, _foldersinit.length + 12));
  //
  //       for (var element in temp
  //           // _folders.sublist(_foldersinit.length, _foldersinit.length + 12)
  //           ) {
  //         Uint8List? image = await getBackgroundImage(element.path);
  //         images.add(image!);
  //       }
  //     } else {
  //       List<FileSystemEntity> temp =
  //           _folders.sublist(_foldersinit.length, _folders.length);
  //
  //       _foldersinit
  //           .addAll(_folders.sublist(_foldersinit.length, _folders.length));
  //       for (var element in temp
  //           // _folders.sublist(_foldersinit.length, _foldersinit.length + 12)
  //           ) {
  //         Uint8List? image = await getBackgroundImage(element.path);
  //         images.add(image!);
  //       }
  //     }
  //   }
  //   showProgress = false;
  //   return true;
  // }

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

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
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
      body:

          /* showProgress
          ? Center(
              child: Image.asset('images/loading.gif'),
            )
          : */
          myWidget(MediaQuery.of(context).size.width),
      floatingActionButton: selectall
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
                          backgroundColor:
                              const Color.fromARGB(255, 125, 114, 221),
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
                                    log("----> set State 3");
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
                                    log("----> set State 4");
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

  Widget myWidget(currentWidth) {
    int i = getSliver(currentWidth);
    // //final data = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
    // final computedTime = <String, DateTime>{};
    // for (final item in _foldersinit) {
    //   DateTime time = (await item.stat()).modified;
    //   computedTime[item.path] = time;
    // }
    // //computedTime.keys.toList().s
    // _foldersinit.sort((a, b) {
    //   return a.statSync().modified.compareTo(b.statSync().modified);
    // });

    return (_foldersinit.isNotEmpty)
        ? RefreshIndicator(
            triggerMode: RefreshIndicatorTriggerMode.anywhere,
            onRefresh: () async {
              await getDir();
            },
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
                // print("${_foldersinit.length} ---- ${_foldersinit.length}");

                var video = _foldersinit[index];
                /*   final stat = FileStat.statSync(video.path);
                print('Accessed: ${stat.accessed}');
                print('Modified: ${stat.modified}');
                print('Changed:  ${stat.changed}');
                */
                return Stack(
                  children: [
                    Positioned.fill(
                      child: InkWell(
                        child: Padding(
                          padding: const EdgeInsets.all(1),
                          child: ThumbnailWidget(
                            path: _foldersinit[index].path,
                          ),
                        ),
                        onLongPress: () {
                          if (_selectedfolders.isNotEmpty) {
                            if (_selectedfolders
                                .contains(_foldersinit[index])) {
                              print("existtt");
                              _selectedfolders.removeWhere(
                                  (element) => element == _foldersinit[index]);
                              listselected
                                  .removeWhere((element1) => element1 == index);
                            } else {
                              selectall = true;

                              _selectedfolders.add(_foldersinit[index]);
                              listselected.add(index);
                            }
                          } else {
                            _selectedfolders.add(_foldersinit[index]);
                            listselected.add(index);

                            selectall = true;
                          }
                          setState(() {
                            log("----> set State 5");
                          });
                        },
                        onTap: () async {
                          if ((_selectedfolders.isNotEmpty) || selectall) {
                            if (_selectedfolders
                                .contains(_foldersinit[index])) {
                              _selectedfolders.removeWhere(
                                  (element) => element == _foldersinit[index]);
                              listselected
                                  .removeWhere((element1) => element1 == index);
                            } else {
                              _selectedfolders.add(_foldersinit[index]);
                              listselected.add(index);
                            }

                            setState(() {
                              log("----> set State 6");
                            });
                          } else {
                            /*   await OpenFile.open(
                                  video.path,
                                ); */
                            /*  ExternalVideoPlayerLauncher
                                    .launchOtherPlayer(
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
                          }
                        },
                      ),
                    ),
                    _selectedfolders.isEmpty && !selectall
                        ? Center(
                            child: IconButton(
                              onPressed: () async {
                                //  await OpenFile.open(
                                //    '/storage/emulated/0/Download/New App/');
                                /*    final Directory _photoDir =
                                Directory('/storage/emulated/0/NewApp/');
                            print(_photoDir.path);

                            ExternalVideoPlayerLauncher.launchOtherPlayer(
                                _photoDir.path,
                                "vnd.android.document/directory", {
                              "title": "",
                              "folder": "New App",
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
                              icon: _selectedfolders.isNotEmpty
                                  ? const SizedBox()
                                  : const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                            ),
                          )
                        : const SizedBox(),
                    /*   Positioned(
                height: 40,
                bottom: 0,
                left: 4,
                right: 4,
                child: _selectedfolders.isNotEmpty
                    ?

                    //
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
                            ? const CircleAvatar(
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
                                        color: const Color.fromARGB(
                                          255,
                                          148,
                                          148,
                                          150,
                                        ).withOpacity(0.6),
                                      ),
                                    ),
                                  )
                                : const SizedBox()),
                  ],
                );
              },
            ),
            /*  whenEmptyLoad: false,
          delegate: DefaultLoadMoreDelegate(),
          textBuilder: DefaultLoadMoreTextBuilder.chinese,
          */
          )
        : Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "No Vidéos Exists",
                    style: TextStyle(fontSize: 33),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  Image.asset('images/novideo.png')
                ],
              ),
            ),
          );
  }
}
