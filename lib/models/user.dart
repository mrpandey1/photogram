import 'package:cloud_firestore/cloud_firestore.dart';

class User {
final String id;
final String username;
final String email;
final String photourl;
final String displayname;
final String bio;

  User({this.id, this.username, this.email, this.photourl, this.displayname, this.bio});
  factory User.fromDocument(DocumentSnapshot doc)
  {
    return User(
      id:doc['id'],
      username:doc['username'],
      email:doc['email'],
      photourl:doc['photourl'],
      displayname:doc['displayname'],
      bio:doc['bio']
    );
  }
}
