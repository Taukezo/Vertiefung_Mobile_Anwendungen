import 'package:flutter/material.dart';
import 'package:vertiefung_3/MyClasses.dart';

class MyStopPage extends StatefulWidget {
  const MyStopPage({super.key, required this.title, required this.stops});

  final String title;
  final List<TimeTableStop> stops;

  @override
  State<MyStopPage> createState() => _MyStopPageState(stops: stops);
}

class _MyStopPageState extends State<MyStopPage> {
  List<TimeTableStop> stops = [];

  _MyStopPageState({required this.stops});

  @override
  void initState() {
    super.initState();
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
              for (TimeTableStop stop in stops)
                Card(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      color: Colors.blue,
                    ),
                    borderRadius: BorderRadius.circular(20.0), //<-- SEE HERE
                  ),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 5),
                      Row(
                        children: <Widget>[
                          const Expanded(
                            flex: 1,
                            child: Icon(Icons.train, size: 30.0),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              stop.getCategory(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              stop.getNumber(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Gleis ${stop.getLane()}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              stop.getDateString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                              ),
                            ),
                          ),
                          Expanded(
                              child: Column(
                            children: <Widget>[
                              const Text(
                                "Ankunft",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                stop.getArString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          )),
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                const Text(
                                  "Abfahrt",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  stop.getDpString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(children: <Widget>[
                        Expanded(
                          child: Text(
                            stop.getDpPath(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              /*ListTile(
                  leading: const Icon(Icons.house),
                  title: Text(stop.getNumber()),
                  onTap: () {
                  },
                ),*/
            ]),
          ),
        ],
      ),
    );
  }
}
