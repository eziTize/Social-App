import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:social_app/models/user.dart';
import 'package:social_app/pages/activity_feed.dart';
import 'package:social_app/pages/create_account.dart';
import 'package:social_app/pages/profile.dart';
import 'package:social_app/pages/search.dart';
import 'package:social_app/pages/timeline.dart';
import 'package:social_app/pages/upload.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final usersRef = Firestore.instance.collection('users');  // creating the collection user
final postsRef = Firestore.instance.collection('posts');  // creating the collection posts
final commentsRef = Firestore.instance.collection('comment'); //creating the collection for comment
final activityFeedRef = Firestore.instance.collection('feed'); //creating the collection for feed
final followersRef = Firestore.instance.collection('followers'); //creating the collection for followers
final followingRef = Firestore.instance.collection('following'); //creating the collection for following
final reportRef = Firestore.instance.collection('reports'); //creating the collection for reports made
final timelineRef = Firestore.instance.collection('timeline'); //creating the collection for timeline
final StorageReference storageRef = FirebaseStorage.instance.ref();
final timeStamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _scaffoldKey = GlobalKey<ScaffoldState>(); // for push notification
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    // Detects when user signed in
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {
      print('Error signing in: $err');
    });
    // Re-authenticate user when app is opened
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }).catchError((err) {
      print('Error signing in: $err');
    });
  }

//--- Create User in FireStore

  handleSignIn(GoogleSignInAccount account) async { // we are making this async so that null value is not called
    if (account != null) {
      await createUserInFireStore();  // making sure current user is always created first and provided to the timeline screen
      setState(() {
        isAuth = true;
      });

      configurePushNotifications(); // for push notification

    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if (Platform.isIOS) getiOSPermission(); // for platform detection

    _firebaseMessaging.getToken().then((token) {
      print("Firebase Messaging Token: $token\n");
      usersRef
          .document(user.id)
          .updateData({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
      // onLaunch: (Map<String, dynamic> message) async {},
      // onResume: (Map<String, dynamic> message) async {},
      onMessage: (Map<String, dynamic> message) async {
        print("on message: $message\n");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        if (recipientId == user.id) {
          print("Notification shown!");
          SnackBar snackbar = SnackBar(
              content: Text(
                body,
                overflow: TextOverflow.ellipsis,
              ));
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
        print("Notification NOT shown");
      },
    );
  }

  getiOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(alert: true, badge: true, sound: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("Settings registered: $settings");
    });
  }


  createUserInFireStore() async{
    //check if users exists in users collection in database

   final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(user.id).get();

   if(!doc.exists){
    // if user doesn't exist redirect to create account
     final username = await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateAccount() ));

     // get username and create a new user collection in database
     usersRef.document(user.id).setData({
       "id": user.id,
       "username": username,
       "photoUrl": user.photoUrl,
       "email": user.email,
       "displayName": user.displayName,
       "bio": "",
       "timeStamp": timeStamp,
    });
     //------- make a user their own follower so they can see their post in news feed
     await followersRef
      .document(user.id)
      .collection('userFollowers')
      .document(user.id)
      .setData({});

     doc = await usersRef.document(user.id).get();

    }

   currentUser = User.fromDocument(doc);
   print(currentUser);
   print(currentUser.username);

  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }
// animation on tap on the bottom navigation bar
  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey, // for push notification
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser,),
          ActivityFeed(),
          Upload(currentUser: currentUser,),
          Search(),
          Profile(profileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
          currentIndex: pageIndex,
          onTap: onTap,
          activeColor: Theme.of(context).primaryColor,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.whatshot),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_active),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.photo_camera,
                size: 35.0,
              ),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
            ),
          ]),
    );

  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).accentColor,
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Social App',
              style: TextStyle(
                fontFamily: "Signatra",
                fontSize: 90.0,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260.0,
                height: 60.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/google_signin_button.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
