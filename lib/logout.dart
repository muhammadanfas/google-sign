import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class HomePage extends StatefulWidget {
  const HomePage();

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _signOutGoogle(BuildContext context) async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    Navigator.pop(context);
  }

  final StreamController<Duration> _streamController =
      StreamController<Duration>.broadcast();

  Timer? _timer;
  Duration _elapsedTime = const Duration(seconds: 0); // Initialize with zero

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedTime += const Duration(seconds: 1);
      _streamController.add(_elapsedTime);
    });
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  Future<void> _storeScreenTime(Duration screenTime) async {
    final CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('screen');

    final String userId = 'SCREEN TIME';
    int hours = screenTime.inHours;
    int minutes = screenTime.inMinutes.remainder(60);
    int seconds = screenTime.inSeconds.remainder(60);
    await usersCollection.doc(userId).set({
      'screenTime': {'hours': hours, 'minutes': minutes, 'seconds': seconds}
    }, SetOptions(merge: true));
  }

  List<charts.Series<TimeData, DateTime>> _createSeriesData(
      Duration screenTime) {
    final now = DateTime.now();
    final data = [
      TimeData(now.subtract(Duration(hours: 4)), 0.0),
      TimeData(now.subtract(Duration(hours: 3)), 0.0),
      TimeData(now.subtract(Duration(hours: 2)), 0.0),
      TimeData(now.subtract(Duration(hours: 1)), 0.0),
      TimeData(now, screenTime.inSeconds.toDouble()),
    ];

    return [
      charts.Series<TimeData, DateTime>(
        id: 'TimeData',
        colorFn: (_, __) => charts.MaterialPalette.deepOrange.shadeDefault,
        domainFn: (TimeData data, _) => data.time,
        measureFn: (TimeData data, _) => data.value,
        data: data,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text("Home Page"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<Duration>(
              stream: _streamController.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  final String formattedTime =
                      '${_elapsedTime.inHours.toString().padLeft(2, '0')}:${_elapsedTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_elapsedTime.inSeconds.remainder(60).toString().padLeft(2, '0')}';

                  _storeScreenTime(_elapsedTime);

                  return Column(
                    children: [
                      Text(
                        formattedTime,
                        style: const TextStyle(fontSize: 40),
                      ),
                      Container(
                        height: 300,
                        child: charts.TimeSeriesChart(
                          _createSeriesData(_elapsedTime),
                          animate: false,
                          dateTimeFactory: const charts.LocalDateTimeFactory(),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Container();
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _signOutGoogle(context);
              },
              child: const Text('Logout'),
            ),
            SizedBox(
              height: 50,
            )
          ],
        ),
      ),
    );
  }
}

class TimeData {
  final DateTime time;
  final double value;

  TimeData(this.time, this.value);
}
