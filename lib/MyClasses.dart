import 'dart:io';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class TrainScheduleFile {
  String _fileName = '';
  String _filePath = '';
  DateTime _fileDate = DateTime(1965, 02, 12);
  int _fileLength = 0;

  TrainScheduleFile(
      {required String filePath,
      required DateTime fileDate,
      required int fileLength}) {
    _filePath = filePath;
    _fileName = File(filePath).uri.pathSegments.last;
    _fileDate = fileDate;
    _fileLength = fileLength;
  }

  String get fileName {
    return _fileName;
  }

  String get filePath {
    return _filePath;
  }

  String get fileInfoString {
    String dateString = DateFormat("dd.MM.yyyy").format(_fileDate);
    String timeString = DateFormat.Hms().format(_fileDate);
    return "$dateString - $timeString - $_fileLength";
  }
}

class Station {
  String stationID = '';
  Names? names;
  TauPosition? position;
  Address? address;
  double distance = 1000000.0;

  Station(
      {required this.stationID,
      Names? this.names,
      Address? this.address,
      TauPosition? this.position});

  factory Station.fromJson(Map<String, dynamic> json) {
    final stationID = json["stationID"] as String;
    TauPosition position = TauPosition(longitude: 0.0, latitude: 0.0);
    try {
      position = TauPosition.fromJson(json["position"]);
    } catch (e) {
      debugPrint("$stationID has no position specified.");
    }
    Address address =
        Address(street: "", houseNumber: "", postalCode: "", city: "");
    try {
      address = Address.fromJson(json["address"]);
    } catch (e) {
      debugPrint("$stationID has no address specified.");
    }
    Names names = Names(deLocale: DeLocale(name: "unbekannt"));
    try {
      names = Names.fromJson(json["names"]);
    } catch (e) {
      debugPrint("$stationID has no names specified.");
    }
    return Station(
      stationID: stationID,
      names: names,
      address: address,
      position: position,
    );
  }

  String getDescription() {
    return "${names?.deLocale?.name}"
        ", ${address?.postalCode} ${address?.city}"
        ", ${address?.street} ${address?.houseNumber}"
        ", (${distance.toStringAsFixed(1)} km)";
  }

  double _getDistanceByHaversine(
      {required double latitude1,
      required double longitude1,
      required double latitude2,
      required double longitude2}) {
    double earthRadius = 6265.0;
    double latrad1 = latitude1 * pi / 180;
    double latrad2 = latitude2 * pi / 180;
    double longrad1 = longitude1 * pi / 180;
    double longrad2 = longitude2 * pi / 180;
    return 2 *
        earthRadius *
        asin(sqrt(pow((sin((latrad2 - latrad1) / 2)), 2) +
            (cos(latrad1) *
                cos(latrad2) *
                pow((sin((longrad2 - longrad1) / 2)), 2))));
  }

  void setDistance(double latitude, double longitude) {
    if (position != null) {
      distance = _getDistanceByHaversine(
          latitude1: position!.latitude,
          longitude1: position!.longitude,
          latitude2: latitude,
          longitude2: longitude);
    } else {
      distance = 40000.0;
    }
  }
}

class TauPosition {
  double longitude = 0.0;
  double latitude = 0.0;

  TauPosition({required this.longitude, required this.latitude});

  factory TauPosition.fromJson(Map<String, dynamic> json) {
    return TauPosition(
        longitude: json["longitude"], latitude: json["latitude"]);
  }
}

class Address {
  String street = '';
  String houseNumber = '';
  String postalCode = '';
  String city = '';

  Address(
      {required this.street,
      required this.houseNumber,
      required this.postalCode,
      required this.city});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
        street: json["street"],
        houseNumber: json["houseNumber"],
        postalCode: json["postalCode"],
        city: json["city"]);
  }
}

class Names {
  DeLocale? deLocale;

  Names({DeLocale? this.deLocale});

  factory Names.fromJson(Map<String, dynamic> json) {
    DeLocale deLocale = DeLocale(name: "unbekannt");
    try {
      deLocale = DeLocale.fromJson(json["DE"]);
    } catch (e) {
      debugPrint("No german name specified");
    }
    return Names(deLocale: deLocale);
  }
}

class DeLocale {
  String name = '';

  DeLocale({required this.name});

  factory DeLocale.fromJson(Map<String, dynamic> json) {
    return DeLocale(name: json["name"]);
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class EvaNumber {
  int number;

  EvaNumber({required this.number});

  factory EvaNumber.fromJson(Map<String, dynamic> json) {
    return EvaNumber(number: json["number"]);
  }
}

class StadaStation {
  EvaNumber evaNumber;

  StadaStation({required this.evaNumber});

  factory StadaStation.fromJson(Map<String, dynamic> json) {
    var liste = json["evaNumbers"] as List;
    EvaNumber evaNumber = EvaNumber.fromJson(liste[0]);
    return StadaStation(evaNumber: EvaNumber(number: evaNumber.number));
  }
}

class TimeTableStop {
  String? number = "";
  String? category = "";
  DateTime? ar = DateTime.now();
  DateTime? dp = DateTime.now();
  String? lane = "";
  String? line = "";
  String? dpPath = "";
  bool hasAr = false;
  bool hasDp = false;

  TimeTableStop(
      {this.number,
      this.category,
      this.ar,
      this.dp,
      this.lane,
      this.line,
      this.dpPath});

  String getNumber() => (number == null) ? "" : number.toString();

  String getCategory() => category == null ? "" : category.toString();

  String getLane() => lane == null ? "" : lane.toString();

  String getLine() => line == null ? "" : line.toString();

  String getDpPath() =>
      dpPath == null || !hasDp ? "- Keine Weiterfahrt -" : dpPath.toString();

  String getDateString() =>
      hasDp ? DateFormat('dd.MM.yyyy').format(dp!) : " - ";

  String getArString() => hasAr ? DateFormat('kk:mm').format(ar!) : " - ";

  String getDpString() => hasDp ? DateFormat('kk:mm').format(dp!) : " - ";
}
