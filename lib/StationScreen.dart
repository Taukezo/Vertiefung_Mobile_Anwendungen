import 'package:flutter/material.dart';
import 'package:vertiefung_3/GlobalConstants.dart';
import 'package:vertiefung_3/MyClasses.dart';
import 'package:vertiefung_3/MyUtils.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class MyStationPage extends StatefulWidget {
  const MyStationPage({super.key, required this.title, required this.position});

  final String title;
  final Position position;

  @override
  State<MyStationPage> createState() => _MyStationPageState(position: position);
}

class _MyStationPageState extends State<MyStationPage> {
  List<Station> stations = [];
  DateTime date = DateTime.now();
  int hour = DateTime.now().hour;
  Position position;

  _MyStationPageState({required this.position});

  @override
  void initState() {
    super.initState();

    fetchStations().then((newStations) {
      for (Station station in newStations) {
        station.setDistance(position.latitude, position.longitude);
      }
      newStations.sort((a, b) => a.distance.compareTo(b.distance));
      setState(() {
        stations = newStations;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(children: [
              for (Station station in stations)
                ListTile(
                  leading: const Icon(Icons.house),
                  title: Text(station.getDescription()),
                  onTap: () {
                    _loadPlan(station);
                  },
                ),
            ]),
          ),
          Card(
            color: Colors.amberAccent,
            child: Row(children: <Widget>[
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "${DateFormat('dd.MM.yyyy').format(date)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                    onPressed: () async {
                      DateTime? newDate = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime(date.year + 1, date.month, date.day));
                      if (newDate == null) return;
                      setState(() => date = newDate);
                    },
                    child: Icon(Icons.date_range)),
              ),
              Expanded(flex: 1, child: Center(child: Text("$hour Uhr"))),
              Expanded(
                flex: 3,
                child: Slider(
                  value: hour.toDouble(),
                  min: 0.0,
                  max: 23.0,
                  onChanged: (newHour) => {
                    debugPrint(newHour.toString()),
                    setState(() => hour = newHour.toInt()),
                  },
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  void _loadPlan(Station station) async {
    // At first get EVA from stationID
    int evaNbr = await getStationEva(station.stationID);
    // If not available: Send message and stop here ...
    if (evaNbr == EVA_NOT_FOUND) {
      _showAlertDialog(
          context,
          'Fehlende Daten DB-API',
          "Für die DB-Station ${station.names?.deLocale?.name} fehlen"
              " im Datenmodell der Bahn notwendige Informationen.");
      return;
    }
    String xml = await getTimeTableHttp(evaNbr, date, hour);
    String fileName = "${DateFormat('yyyy-MM-dd').format(date)}"
        " $hour Uhr ${station.names?.deLocale?.name} (EVA: $evaNbr)";
    if (xml == "") {
      _showAlertDialog(
          context,
          "Station ${station.names?.deLocale?.name}",
          "Kein Fahrplan für ${station.names?.deLocale?.name}"
              " am ${DateFormat('dd.MM.yyyy').format(date)} um $hour"
              " abrufbar oder vorhanden.");
    } else {
      saveFile(fileName, xml);
    }
    debugPrint("XML: $xml");
  }

  _showAlertDialog(BuildContext context, String title, String text) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(text),
      icon: Icon(Icons.railway_alert),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
