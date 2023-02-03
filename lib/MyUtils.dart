import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:vertiefung_3/GlobalConstants.dart';
import 'package:vertiefung_3/MyClasses.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

Future<Directory> getSchedulesDirectory() async {
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String appDocPath = appDocDir.path;
  String schedulesPath = "$appDocPath/$TRAINSCHEDULE_DIRECTORY";
  Directory workDir = Directory(schedulesPath);
  if (!workDir.existsSync()) {
    workDir.createSync(recursive: false);
  }
  if (workDir.existsSync()) {
    return workDir;
  } else {
    throw Exception("Directory $schedulesPath not available.");
  }
}

Future<List<TrainScheduleFile>> getTrainScheduleFiles() async {
  List<TrainScheduleFile> _trainScheduleFiles = [];
  Directory schedulesDir = await getSchedulesDirectory();
  for (FileSystemEntity entity in schedulesDir.listSync(recursive: false)) {
    if (entity is File) {
      File f = entity;
      _trainScheduleFiles.add(TrainScheduleFile(
          filePath: f.path,
          fileDate: f.lastModifiedSync(),
          fileLength: f.lengthSync()));
    }
  }
  return _trainScheduleFiles;
}

Future<List<Station>> fetchStations() async {
  const URL_PARAMS = '?locales=DE&offset=0&limit=10000';
  List<Station> stations = [];
  http.Response response = await http.get(
    Uri.parse("$API_MARKETPLACE_URL$STATION_SERVICE_ENDPOINT$URL_PARAMS"),
    headers: {
      'Accept': 'application/vnd.de.db.ris+json',
      'DB-Client-Id': '8101d0a841a7c8633e9a227835713a76',
      'DB-Api-Key': '1b0e8c9c8c61577866c644c20a10a9b8',
    },
  );
  if (response.statusCode == 200) {
    var data = jsonDecode(utf8.decode(response.bodyBytes));
    var liste = data["stations"] as List;
    stations = liste.map<Station>((json) => Station.fromJson(json)).toList();
  }
  return stations;
}

Future<int> getStationEva(String stationID) async {
  http.Response response = await http.get(
    Uri.parse("$API_MARKETPLACE_URL$STADA_SERVICE_ENDPOINT/$stationID"),
    headers: {
      'Accept': 'application/json',
      'DB-Client-Id': APPLICATION_ID,
      'DB-Api-Key': API_KEY,
    },
  );
  if (response.statusCode == 200) {
    List<StadaStation> stations = [];
    var data = jsonDecode(utf8.decode(response.bodyBytes));
    var liste = data["result"] as List;
    stations =
        liste.map<StadaStation>((json) => StadaStation.fromJson(json)).toList();
    StadaStation stadaStation = stations[0];
    return stadaStation.evaNumber.number;
  } else {
    return EVA_NOT_FOUND;
  }
}

Future<String> getTimeTableHttp(int evaNumber, DateTime date, int hour) async {
  NumberFormat formatter = new NumberFormat("00");
  String url = "$API_MARKETPLACE_URL$TIMETABLE_SERVICE_ENDPOINT"
      "/$evaNumber/${DateFormat('yyMMdd').format(date)}"
      "/${formatter.format(hour)}";
  http.Response response = await http.get(
    Uri.parse(url),
    headers: {
      'Accept': 'application/xml',
      'DB-Client-Id': APPLICATION_ID,
      'DB-Api-Key': API_KEY,
    },
  );
  if (response.statusCode == 200) {
    return response.body;
  } else {
    return "";
  }
}

void saveFile(String pName, String pContent) async {
  Directory schedulesDir = await getSchedulesDirectory();
  DateTime now = DateTime.now();
  String fileName = "${schedulesDir.path}/$pName";
  File newFile = File(fileName);
  newFile.writeAsString(pContent);
}

Future<String> readFile(String fileName) async {
  Directory schedulesDir = await getSchedulesDirectory();
  File file = File(fileName);
  return file.readAsStringSync();
}

/*
Parsing TimeTable-XML to a List of TimeTableStop-Objects (serialize).
 */
List<TimeTableStop> getStops(String xmlString) {
  List<TimeTableStop> stops = [];
  final document = xml.XmlDocument.parse(xmlString);
  final timeTableNode = document.findElements('timetable').first;
  final stopNodes = timeTableNode.findElements('s');
  for (final stopNode in stopNodes) {
    final dpNode = stopNode.findElements('dp').isNotEmpty
        ? stopNode.findElements('dp').first
        : null;
    final arNode = stopNode.findElements('ar').isNotEmpty
        ? stopNode.findElements('ar').first
        : null;
    final tlNode = stopNode.findElements('tl').isNotEmpty
        ? stopNode.findElements('tl').first
        : null;

    String? number = tlNode != null ? tlNode.getAttribute('n') : "";
    String? category = tlNode != null ? tlNode.getAttribute('c') : "";
    String? lane = arNode != null ? arNode.getAttribute('pp') : "";
    String? line = arNode != null ? arNode.getAttribute('l') : "";
    String? dpPath = dpNode != null ? dpNode.getAttribute('ppth') : "";
    String? arString = arNode != null ? arNode.getAttribute('pt') : "";
    DateTime? arDate = arString != null && arString != ""
        ? DateTime(
            2000 + int.parse(arString.substring(0, 2)),
            int.parse(arString.substring(2, 4)),
            int.parse(arString.substring(4, 6)),
            int.parse(arString.substring(6, 8)),
            int.parse(arString.substring(8)))
        : DateTime.now();
    String? dpString = dpNode != null ? dpNode.getAttribute('pt') : "";
    DateTime? dpDate = dpString != null && dpString != ""
        ? DateTime(
            2000 + int.parse(dpString.substring(0, 2)),
            int.parse(dpString.substring(2, 4)),
            int.parse(dpString.substring(4, 6)),
            int.parse(dpString.substring(6, 8)),
            int.parse(dpString.substring(8)))
        : DateTime.now();

    TimeTableStop newStop = TimeTableStop(
        number: number,
        category: category,
        ar: arDate,
        dp: dpDate,
        lane: lane,
        line: line,
        dpPath: dpPath);
    newStop.hasAr = arNode == null ? false : true;
    newStop.hasDp = dpNode == null ? false : true;

    stops.add(newStop);
  }
  debugPrint(xmlString);
  return stops;
}

Future<Position> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  return await Geolocator.getCurrentPosition();
}
