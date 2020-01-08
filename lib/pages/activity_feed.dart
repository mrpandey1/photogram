import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/post_screen.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;
class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  getActivityFeed() async{
   QuerySnapshot snapshot=
    await feedRef.document(currentUser.id)
    .collection('feedItem')
    .orderBy("timeStamp",descending:true)
    .getDocuments();
    List<ActivityFeedItem> feedItem=[];
    snapshot.documents.forEach((val){
      feedItem.add(ActivityFeedItem.fromDocument(val));
    });
    return feedItem;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
      appBar: header(context,titleText:"Activity Feed"),
      body: Container(
        child: FutureBuilder(
          future: getActivityFeed(),
          builder: (context,snapshot){
            if(!snapshot.hasData){
              return circularProgress();
            }
            return  ListView(
              children: snapshot.data,
            );
          },
        ),
      ),
    );
  }
}
Widget mediaPreview;
String activtyItemText;
class ActivityFeedItem extends StatelessWidget {
  final String commentData;
  final String mediaUrl;
  final String postId;
  final String type;
  final String userId;
  final String username;
  final String userProfileImg;
  final Timestamp timestamp;

ActivityFeedItem({this.commentData, this.mediaUrl, this.postId, this.type, this.userId, this.username, this.userProfileImg, this.timestamp});
  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc){
    return ActivityFeedItem(
      userId: doc['userId'],
      username: doc['username'],
      type: doc['type'],
      postId: doc['postId'],
      userProfileImg: doc['userProfileImg'],
      commentData: doc['commentData'],
      timestamp: doc['timeStamp'],
      mediaUrl: doc['mediaUrl'],
    );
  }
  configureMediaaPreview(context){
    print('type $type');
    if(type=="like" || type=="comment"){
      mediaPreview=GestureDetector(
        onTap: ()=>showPost(context),
        child: Container(
          height: 50,
          width: 50,
          child: AspectRatio(
            aspectRatio: 16/9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.fill,
                  image: NetworkImage(mediaUrl)
                )
              ),
            ),
          ),
        ),
      );
    }
    if(type=="like"){
      activtyItemText=" liked your post";
    }else if(type=="follow"){
      activtyItemText=" started following you";
    }else if(type=="comment"){
      activtyItemText=" commented on your post ' $commentData '";
    }
  }
  showPost(context){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>PostScreen(postId: postId,userId: userId,)));
  }

  @override
  Widget build(BuildContext context) {
    configureMediaaPreview(context);
    return Padding(
      padding: EdgeInsets.only(bottom:2.0),
      child: Container(
        color: Colors.white,
        child: ListTile(
          title: GestureDetector(
            onTap: ()=>showProfile(context,profileId:userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black
                ),
                children: [
                  TextSpan(
                    text: username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold
                    )
                  ),
                  TextSpan(
                    text: '$activtyItemText',
                  )
                ]
              ),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: NetworkImage(userProfileImg),
          ),
          subtitle: Text(
            timeago.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }
}
showProfile(BuildContext context,{String profileId}){
  Navigator.push(context, MaterialPageRoute(builder: (context)=>Profile(profileId: profileId,)));
}