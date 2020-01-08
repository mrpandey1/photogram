import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'home.dart';
import 'package:timeago/timeago.dart' as timeago;
class Comments extends StatefulWidget {
  final String postsId;
  final String ownersId;
  final String mediasUrl;
  Comments({ this.postsId, this.ownersId, this.mediasUrl});
  @override
  CommentsState createState() => CommentsState( 
    postsId: this.postsId,
    ownersId: this.ownersId,
    mediasUrl: this.mediasUrl
  );
}

class CommentsState extends State<Comments> {

TextEditingController commentController=TextEditingController();
    final String postsId;
  final String ownersId;
  final String mediasUrl;
  CommentsState({ this.postsId, this.ownersId, this.mediasUrl});

   buildComments(){
    return StreamBuilder(
      stream: commentRef.document(postsId).collection('comments').orderBy('timeStamp',descending:false).snapshots(),
      builder: (context,snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        List<Comment> comments=[];
        snapshot.data.documents.forEach((doc){
          comments.add(Comment.fromDocument(doc));
        });
        return ListView(
          children: comments
        );
      },
    );
   }
   addComment(){
       commentRef.document(postsId)
     .collection('comments')
     .add({
       "username":currentUser.username,
       "comment":commentController.text,
       "timeStamp":timestamp,
       "avatarUrl":currentUser.photourl,
       "userId":currentUser.id
     });
     bool notMe=currentUser.id!=ownersId;
     //if(notMe){
     feedRef.document(ownersId).
     collection('feedItem')
     .add({
    "type":"comment",
    "commentData":commentController.text,
    "username":currentUser.username,
    "userId":currentUser.id,
    "userProfileImg":currentUser.photourl,
    "postId":postsId,
    "mediaUrl":mediasUrl,
    "timeStamp":timestamp      
     });

    // }
    commentController.clear();
   }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context,titleText: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(
            child: buildComments(),
          ),
          Divider(height: 0,),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: "Write a comment .."
              ),
            ),
            trailing: OutlineButton(
              onPressed: addComment,
              borderSide: BorderSide.none,
              child: Text('Post'),
            ),
          )
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  Comment({this.username, this.userId, this.avatarUrl, this.comment, this.timestamp});
  factory Comment.fromDocument(DocumentSnapshot doc){
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      avatarUrl: doc['avatarUrl'],
      comment: doc['comment'],
      timestamp: doc['timeStamp'],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(comment),
          leading: CircleAvatar(
            backgroundImage: NetworkImage(avatarUrl),
          ),
          subtitle: Text(
            timeago.format(timestamp.toDate())
            ),
        )
      ],
    );
  }
}
