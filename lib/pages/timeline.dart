import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/progress.dart';
import '../widgets/header.dart';
import 'home.dart';

class Timeline extends StatefulWidget {
  final User currentUser;
  Timeline({this.currentUser});
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  @override
  void initState() {
    super.initState();
    getTimeline();
  }
  getTimeline() async{
   QuerySnapshot snapshot= await timelineRef.document(widget.currentUser.id)
  .collection('timelinePosts')
  .orderBy('timeStamp',descending: true)
  .getDocuments();
  snapshot.documents.forEach((data){
    print(data.data['timeStamp']);
  });
  List<Post> posts=snapshot.documents.map((doc)=>Post.fromDocument(doc)).toList();
  setState(() {
    this.posts=posts;
  });
  }
  buildTimeline(){
    if(posts==null){
      return circularProgress();
    }if(posts.isEmpty){
      return Center(child: Text('No posts'));
    }
    return ListView(
      children: posts,
    );
  }
  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context,isAppTitle: true,titleText: ''),
      body: RefreshIndicator(
        onRefresh: ()=>getTimeline(),
        child: buildTimeline(),
      ),
    );
  }
}
