import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tracker_app/login.dart';
import 'package:tracker_app/mymap.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: LoginPage()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    location.changeSettings(interval: 300, accuracy: loc.LocationAccuracy.high);
    location.enableBackgroundMode(enable: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('live location tracker'),
      // ),
      body:
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/appimage.png'), fit: BoxFit.cover),
            ),
    child: Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 240.0),
          // padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          // color: Color.fromARGB(255, 255, 192, 46),
          borderRadius: BorderRadius.circular(12),
        ),
          child: TextButton(
              onPressed: () {
                _getLocation();
              },
              style: TextButton.styleFrom(
                primary: Colors.black,
                backgroundColor: Colors.white,
                // shape: const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))), // Background Color
              ),
            child: Center(
              child: Text('Add My Location',
                  style: GoogleFonts.alata(
                    fontSize: 18,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ))),),),),
            Padding(
              padding: EdgeInsets.only(top: 1.0),
              // padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                   // color: Color.fromARGB(255, 255, 192, 46),
                  borderRadius: BorderRadius.circular(12),
                ),
          child: TextButton(
              onPressed: () {
                _listenLocation();
              },
              style: TextButton.styleFrom(
                primary: Colors.black,
                backgroundColor: Colors.white,
                // shape: const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))), // Background Color
              ),
            child: Center(
              child: Text('Enable Live Location',
                  style: GoogleFonts.alata(
                    fontSize: 18,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ))),),),),
            Padding(
              // padding: const EdgeInsets.symmetric(horizontal: 25.0),
              padding: EdgeInsets.only(top: 1.0),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  // color: Color.fromARGB(255, 255, 192, 46),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: TextButton(
              onPressed: () {
                _stopListening();
              },
              style: TextButton.styleFrom(
                primary: Colors.black,
                backgroundColor: Colors.white,
                // shape: const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))), // Background Color
              ),
                  child: Center(
              child: Text('Stop Live Location',
                  style: GoogleFonts.alata(
                    fontSize: 18,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ))),),),),
          Expanded(
              child: StreamBuilder(
            stream:
                FirebaseFirestore.instance.collection('location').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                  itemCount: snapshot.data?.docs.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title:
                          Text(snapshot.data!.docs[index]['name'].toString(),style: GoogleFonts.alata(
                              fontSize: 16,
                              color: Color.fromARGB(255, 255, 255, 255)),),
                      subtitle: Row(
                        children: [
                          Text(snapshot.data!.docs[index]['latitude']
                              .toString(),style: GoogleFonts.alata(
                        fontSize: 16,
                        color: Color.fromARGB(255, 255, 255, 255)),),
                          SizedBox(
                            width: 20,
                          ),
                          Text(snapshot.data!.docs[index]['longitude']
                              .toString(),style: GoogleFonts.alata(
                    fontSize: 16,
                    color: Color.fromARGB(255, 255, 255, 255)),),
                        ],
                      ),
                      trailing: IconButton(

                        icon: Icon(Icons.directions),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  MyMap(snapshot.data!.docs[index].id)));
                        },

                      ),

                    );
                  });
            },
          )),
        ],
      ),
          ),
          ),
    );
  }

  _getLocation() async {
    try {
      final loc.LocationData _locationResult = await location.getLocation();
      await FirebaseFirestore.instance.collection('location').doc('user1').set({
        'latitude': _locationResult.latitude,
        'longitude': _locationResult.longitude,
        'name': 'abcd'
      }, SetOptions(merge: true));
    } catch (e) {
      print(e);
    }
  }

  Future<void> _listenLocation() async {
    _locationSubscription = location.onLocationChanged.handleError((onError) {
      print(onError);
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((loc.LocationData currentlocation) async {
      await FirebaseFirestore.instance.collection('location').doc('user1').set({
        'latitude': currentlocation.latitude,
        'longitude': currentlocation.longitude,
        'name': 'abcd'
      }, SetOptions(merge: true));
    });
  }

  _stopListening() {
    _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
  }

  _requestPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      print('done');
    } else if (status.isDenied) {
      _requestPermission();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }
}