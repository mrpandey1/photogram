import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'home.dart';
class EditProfile extends StatefulWidget {
  final String currentUserId;
  EditProfile({this.currentUserId});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  TextEditingController displayNameController=TextEditingController();
  TextEditingController bioController=TextEditingController();
  bool isLoading=false;
  User user;
  bool _displayNameValid=true;
  bool _bioValid=true;
  final _scaffoldKey=GlobalKey<ScaffoldState>();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  } 
  updateProfileData(){
    setState(() {
      displayNameController.text.trim().length<3  || displayNameController.text.isEmpty? _displayNameValid=false:
      _displayNameValid=true;
      bioController.text.trim().length>100 ?_bioValid=false:_bioValid=true;
    });
    if(_displayNameValid && _bioValid){
      usersRef.document(widget.currentUserId).updateData({
        "displayname":displayNameController.text,
        'bio':bioController.text
      }
      );
      SnackBar snackBar=SnackBar(content: Text('Profile Updates'),);
      _scaffoldKey.currentState.showSnackBar(snackBar);
      Timer(Duration(milliseconds: 1500),(){
      Navigator.pop(context);
      });
    }
  }
  getUser()async{
      setState(() {
        isLoading=true;
      });
  DocumentSnapshot doc=await usersRef.document(widget.currentUserId).get();
  user=User.fromDocument(doc);
  displayNameController.text=user.displayname;
  bioController.text=user.bio;
  print(user.photourl);
  setState(() {
    isLoading=false;
  });
    }
 Column buildDisplayNameField(){
   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: <Widget>[
       Padding(
         padding: EdgeInsets.only(top: 13),
         child: Text('Display Name',
         style: TextStyle(color: Colors.grey),),
       ),
       TextField(
         controller: displayNameController,
         decoration: InputDecoration(
           hintText: "Update displayname",
           errorText: _displayNameValid?null:"Display Name too short"
         ),
       )
     ],
   );
  }
  Column buildBioField(){
   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: <Widget>[
       Padding(
         padding: EdgeInsets.only(top: 13),
         child: Text('Bio',
         style: TextStyle(color: Colors.grey),),
       ),
       TextField(
         controller: bioController,
         decoration: InputDecoration(
           hintText: "Update  Bio",
           errorText: _bioValid?null:"Bio too Long"
         ),
       )
     ],
   );
  }
  logout()async{
   await googleSignin.signOut();
   Navigator.push(context, MaterialPageRoute(builder: (context)=>
   Home()
   ));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.done,size: 30,color: Colors.green,),
            onPressed: (){
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: isLoading?circularProgress():ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 16,bottom: 8),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey,
                    backgroundImage: NetworkImage(user.photourl),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      buildDisplayNameField(),
                      buildBioField(),
                    ],
                  ),
                ),
                RaisedButton(
                  onPressed:updateProfileData,
                  child: Text('Update Profile',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold
                  ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: FlatButton.icon(
                    onPressed: logout,
                    icon: Icon(Icons.cancel,color: Colors.red,),
                    label: Text('Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 20
                    ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
}
}
