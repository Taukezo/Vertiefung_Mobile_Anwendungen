import 'package:flutter/material.dart';
import 'dart:io';
import 'package:vertiefung_3/MyClasses.dart';
import 'package:vertiefung_3/MyUtils.dart';
import 'package:vertiefung_3/StationScreen.dart';
import 'package:vertiefung_3/StopScreen.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Gespeicherte Fahrpläne'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  List<TrainScheduleFile> trainScheduleFiles = [];

  Future<void> _onNavBarTapped(int index) async {
    _selectedIndex = index;
    if (_selectedIndex == 0) {
      _showStations();
    }
    if (_selectedIndex == 1) {
      Position position = await determinePosition();
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MyStationPage(
                  title: 'Bahnhöfe',
                  position: position,
                )),
      );
      getTrainScheduleFiles().then((newTrainScheduleFiles) {
        setState(() {
          trainScheduleFiles = newTrainScheduleFiles;
        });
      });
    }
    if (_selectedIndex == 2) {
      Position position = await determinePosition();
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MyStationPage(
                  title: 'Yo man',
                  position: position,
                )),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    debugPrint("Start initState");
    getTrainScheduleFiles().then((newTrainScheduleFiles) {
      setState(() {
        trainScheduleFiles = newTrainScheduleFiles;
      });
    });
  }

  void _showTrainSchedule(String filePath, String fileName) async {
    String xmlString = await readFile(filePath);
    List<TimeTableStop> stops = getStops(xmlString);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              MyStopPage(title: fileName.substring(11), stops: stops)),
    );
  }

  void _deleteTrainSchedule(String filePath) {
    File fileToDelete = File(filePath);
    try {
      fileToDelete.deleteSync(recursive: false);
    } catch (e) {
      debugPrint("Could not delete file $filePath because: $e");
    }
    getTrainScheduleFiles().then((newTrainScheduleFiles) {
      setState(() {
        trainScheduleFiles = newTrainScheduleFiles;
      });
    });
  }

  void _deleteAllSchedules() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sind Sie sicher?'),
          content:
              Text('Wollen Sie wirklich alle gespeicherten Fahrpläne löschen?'),
          actions: <Widget>[
            TextButton(
              child: Text('Ja'),
              onPressed: () {
                for (TrainScheduleFile trainSchedulefile
                    in trainScheduleFiles) {
                  File fileToDelete = File(trainSchedulefile.filePath);
                  fileToDelete.deleteSync(recursive: false);
                }
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showStations() async {
    Position position = await determinePosition();
    debugPrint("${position.latitude.toStringAsFixed(8)}"
        ", ${position.longitude.toStringAsFixed(8)}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Scrollbar(
        child: ListView(
          restorationId: 'list_demo_list_view',
          children: [
            for (TrainScheduleFile trainScheduleFile in trainScheduleFiles)
              ListTile(
                leading: const Icon(Icons.list),
                title: Text(
                  "${trainScheduleFile.fileName}",
                ),
                subtitle: Text("${trainScheduleFile.fileInfoString}"),
                onTap: () {
                  _showTrainSchedule(
                      trainScheduleFile.filePath, trainScheduleFile.fileName);
                },
                onLongPress: () {
                  _deleteTrainSchedule(trainScheduleFile.filePath);
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'About',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions),
            label: 'Bahnhöfe',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onNavBarTapped,
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
