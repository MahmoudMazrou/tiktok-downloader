import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:new_app/download%20copy.dart';
import 'package:new_app/download.dart';
import 'package:new_app/local/cache_helper.dart';
import 'package:new_app/single_video.dart';
import 'package:new_app/welcomescren.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'models/video.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheHelper.init();
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'New App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyStatefulWidget(),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key? key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> _widgetOptions = <Widget>[
    WelcomScreen(),
    Download(),
    Download2(),

    /*     Center(
      child: Text(
        'Index 2: School',
        style: optionStyle,
      ),
    ), */
    Center(
      child: Text(
        'Index 3: Settings',
        style: optionStyle,
      ),
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final doublee = MediaQuery.of(context).size.width;
    bool isTopConectivity = true;

    return SafeArea(
      child: Stack(
        children: [
          Scaffold(
            body: _widgetOptions[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              elevation: 0,
              unselectedItemColor: Colors.grey,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.download),
                  label: 'Downloads',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.school),
                  label: 'School',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.amber[800],
              onTap: _onItemTapped,
            ),
          ),
          BottomSheet(

            builder: (BuildContext context) =>
                StreamBuilder<ConnectivityResult>(
                  stream: Connectivity().onConnectivityChanged,

                  builder: (context, snapshot) {
                    // bool  isVisibality =false;
                    if (snapshot.data == ConnectivityResult.none &&
                        isTopConectivity) {
                      return Container(
                        width: double.infinity,

                        height: 50,
                        color: Colors.black,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "No network connection", style: TextStyle(
                                fontSize: 17,
                                color: Colors.white,

                              ),),
                              Expanded(child: Container()),
                              // InkWell(
                              //   onTap: () async {
                              //     setState(() {
                              //       isTopConectivity = false;
                              //     });
                              //     //
                              //     // Future.delayed(
                              //     //     const Duration(milliseconds: 5), () {
                              //     //   isTopConectivity = true;
                              //     // });
                              //     //
                              //     // Timer(Duration(seconds: 3), () {
                              //     //   setState(() {
                              //     //     isTopConectivity = true;
                              //     //
                              //     //     // Here you can write your code for open new view
                              //     //     print("print after every 3 seconds");
                              //     //   });
                              //     // });
                              //   },
                              //   child: Text("Undo", style: TextStyle(
                              //       fontSize: 17,
                              //       color: Colors.white,
                              //       fontWeight: FontWeight.bold
                              //
                              //   ),),
                              // ),
                              Countdown(
                                seconds: 10,
                                build: (BuildContext context, double time) =>
                                    Text(time.toString(), style: TextStyle(
                                        color: Colors.transparent),),
                                interval: Duration(milliseconds: 100),
                                onFinished: () async {
                                  isTopConectivity = false;
                                  setState(() {
                                    isTopConectivity = false;
                                  });
                                  // print(
                                  //     "*****************************************");
                                  //
                                  // Future.delayed(
                                  //     const Duration(milliseconds: 5), () {
                                  //   isTopConectivity = true;
                                  // });
                                  //
                                  // Timer(Duration(seconds: 3), () {
                                  //   setState(() {
                                  //     isTopConectivity = true;
                                  //
                                  //     // Here you can write your code for open new view
                                  //     print("print after every 3 seconds");
                                  //   });
                                  // });
                                },

                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Countdown(

                        seconds: 8,
                        build: (BuildContext context, double time) =>
                            Text(time.toString(), style: TextStyle(color: Colors
                                .transparent),),
                        interval: Duration(milliseconds: 100),
                        onFinished: () async {
                          isTopConectivity = true;
                          setState(() {
                            isTopConectivity = true;
                          });
                          // isTopConectivity = true;
                          // print("*****************************************");
                          //
                          // Future.delayed(const Duration(milliseconds: 5), () {
                          //   isTopConectivity = true;
                          // });
                          //
                          // Timer(Duration(seconds: 3), () {
                          //   setState(() {
                          //     isTopConectivity = true;
                          //
                          //     // Here you can write your code for open new view
                          //     print("print after every 3 seconds");
                          //   });
                          // });
                        },

                      );
                    }
                  },), onClosing: () {},
          ),

        ],
      ),
    );
  }
}
