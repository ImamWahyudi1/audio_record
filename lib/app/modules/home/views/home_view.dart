import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart' as p;

import '../controllers/home_controller.dart';

class HomeView extends StatefulWidget {
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final record = Record();

  bool isRecord = false;

  int waktu = 0;

  bool isStop = true;

  // ---------------------
  AudioPlayer audioPlayer = AudioPlayer();

  Duration durasi = Duration();

  List<FileSystemEntity> listFile = [];

  Directory? dirApp;

  @override
  void initState() {
    audioPlayer.onDurationChanged.listen((duration) async {
      final dur = await audioPlayer.getCurrentPosition();

      durasi = dur ?? Duration();
      setState(() {});
    });
    audioPlayer.setReleaseMode(ReleaseMode.loop);
    fetchAllFile();

    super.initState();
  }

  void playSound(String path) async {
    await audioPlayer.play(DeviceFileSource(path));
  }

  void fetchAllFile() {
    getExternalStorageDirectory().then((value) async {
      dirApp = value;
      listFile = dirApp!.listSync();
      setState(() {});
    });
  }

  void pauseSound() async {
    await audioPlayer.pause();
  }

  void stopSound() async {
    await audioPlayer.stop();
    durasi = Duration();
  }

  void resumeSound() async {
    await audioPlayer.resume();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HomeView'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 80, left: 20, right: 20),
          child: Column(
            children: [
              Container(
                height: 250,
                child: Lottie.asset("assets/lottie/record.json"),
              ),
              Center(
                child: Column(
                  children: [
                    Text(
                      waktu.toString(),
                      style:
                          TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final path = await getExternalStorageDirectory();
                            print(path);
                            final permission = await record.hasPermission();

                            if (await record.isRecording()) {
                              await record.stop();
                              isRecord = false;
                              setState(() {});
                              return;
                            }

                            if (permission) {
                              await record.start(
                                path: path!.path + "/audio.mp3",
                                encoder: AudioEncoder.aacLc, // by default
                                bitRate: 128000, // by default
                              );

                              isRecord = true;
                              setState(() {});
                              fetchAllFile();
                            } else {
                              print("Izin Ditolak");
                            }

                            waktu = 0;
                            isStop = false;
                            Timer.periodic(Duration(seconds: 1), (timer) {
                              if (isStop) timer.cancel();
                              waktu++;
                              setState(() {});
                            });
                          },
                          child: Text("Start Record"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            isStop = true;
                            record.stop();
                          },
                          child: Text("Stop Record"),
                        ),
                      ],
                    ),
                    Divider(color: Colors.black, height: 50),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final file = await FilePicker.platform.pickFiles();
                            playSound(file!.paths.first!);
                          },
                          child: Text("Play"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            pauseSound();
                          },
                          child: Text("Pause"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            resumeSound();
                          },
                          child: Text("resume"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            stopSound();
                          },
                          child: Text("Stop"),
                        ),
                      ],
                    ),
                    SizedBox(height: 40),
                    Text(
                      durasi.toString(),
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Divider(color: Colors.black),
                    SizedBox(height: 20),
                    ...listFile
                        .map(
                          (e) => Container(
                            margin: EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text(p.basename(e.path)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      final renameC = TextEditingController(
                                          text: p.basenameWithoutExtension(
                                              e.path));

                                      showDialog(
                                        context: context,
                                        builder: (context) => Dialog(
                                          child: Column(
                                            children: [
                                              TextFormField(
                                                controller: renameC,
                                              ),
                                              SizedBox(height: 8),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  await e.rename(
                                                    e.parent.path +
                                                        "/" +
                                                        "${renameC.text}.mp3",
                                                  );

                                                  Navigator.pop(context);
                                                  fetchAllFile();
                                                },
                                                child: Text("Rename"),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.edit),
                                  ),
                                  SizedBox(width: 10),
                                  IconButton(
                                    onPressed: () {
                                      e.deleteSync();
                                      fetchAllFile();
                                    },
                                    icon: Icon(Icons.delete),
                                  ),
                                  SizedBox(width: 10),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
