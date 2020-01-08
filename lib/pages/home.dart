import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/timeline.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import 'activity_feed.dart';
import 'create_account.dart';
import 'create_account.dart';
import 'profile.dart';
import 'search.dart';
import 'upload.dart';
import 'package:firebase_storage/firebase_storage.dart';

final CollectionReference usersRef=Firestore.instance.collection('users');
final CollectionReference postsRef=Firestore.instance.collection('posts');
final CollectionReference commentRef=Firestore.instance.collection('comments');
final CollectionReference feedRef=Firestore.instance.collection('feed');
final CollectionReference followersRef=Firestore.instance.collection('followers');
final CollectionReference followingRef=Firestore.instance.collection('following');
final CollectionReference timelineRef=Firestore.instance.collection('timeline');
final DateTime timestamp=DateTime.now();
User currentUser;
final googleSignin =GoogleSignIn();
final StorageReference storeRef=FirebaseStorage.instance.ref();
class Home extends StatefulWidget {
@override
_HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
bool isAuth=false;
PageController pageController;
int pageIndex=0;
@override
void initState(){
super.initState();
pageController=PageController(
initialPage: 0
);
//detects the auth state of user ie logged in or not
googleSignin.onCurrentUserChanged.listen((account){
handleSignin(account);    
},onError: (err){
        print('error signing in $err');
      });
      googleSignin.signInSilently(suppressErrors: false).then((account){
          handleSignin(account);    
      }).catchError((err){
        print('error signing in $err');
      });
}
handleSignin(GoogleSignInAccount account){
  if(account!=null){
    createUserInFirebase();
    setState(() {
      isAuth=true;
    });
  }
  else{
    setState(() {
      isAuth=false;
    });
  }

}


createUserInFirebase()async{
//check if user already exists by their google id
final GoogleSignInAccount user=googleSignin.currentUser;
DocumentSnapshot doc= await usersRef.document(user.id).get();
//getting username form createaccount page
if(!doc.exists){
final username=await Navigator.push(context, MaterialPageRoute(builder: (context)=>CreateAccount()));
usersRef.document(user.id).setData({
'id':user.id,
'username':username,
'photourl':user.photoUrl,
'email':user.email,
'displayname':user.displayName,
'bio':'',
'timestamp':timestamp
});
doc= await usersRef.document(user.id).get();
}
currentUser=User.fromDocument(doc);
}


login(){
googleSignin.signIn();
}
signOut(){
googleSignin.signOut();
}   
@override
void dispose(){
pageController.dispose();
super.dispose();
}
onPageChanged(int pageIndex){
setState(() {
this.pageIndex=pageIndex;
});
}
onTap(int pageIndex){
pageController.animateToPage(pageIndex,
duration: Duration(milliseconds: 200),
curve: Curves.bounceInOut
);
}
Scaffold buildAuthScreen() {
  return Scaffold(
    body: PageView(
      children: <Widget>[
        Timeline(currentUser: currentUser,),
        //RaisedButton(child: Text('Signout'),onPressed: signOut,),
        ActivityFeed(),
        Upload(currentUser:currentUser),
        Search(),
        Profile(profileId:currentUser?.id),
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
        BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
        BottomNavigationBarItem(icon: Icon(Icons.photo_camera,size: 35.0,)),
        BottomNavigationBarItem(icon: Icon(Icons.search)),
        BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
      ],
    ),
  );
}

Scaffold buildUnAuthScreen() {
  return Scaffold(
    body: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
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
          Text('Kya Haal?',
            style: TextStyle(
              fontFamily: "Signatra",
              fontSize: 90,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: login,
            child: Container(
              width: 260,
              height: 60,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/google_signin_button.png'),
                  fit: BoxFit.cover,
                )
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
return isAuth?buildAuthScreen():buildUnAuthScreen();
}

}
