//=======    multiDexEnabled true =======\\
//=======    place the above code in android>app>build.gradle>defaultConfig =======\\

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_app/pages/home.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async{

  //---------- we need to initialize the firebase app first in order to use its elements
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Firestore.instance.settings(timestampsInSnapshotsEnabled: true).then((_) {
  //   print("Timestamps enabled in snapshots\n");
  // }, onError: (_) {
  //   print("Error enabling timestamps in snapshots\n");
  // });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        accentColor: Colors.teal,
      ),
      home: Home(),
    );
  }
}
