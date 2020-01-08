import 'dart:async';
import 'package:animator/animator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/comments.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

class Post extends StatefulWidget {
final String postId;
final String ownerId;
final String username;
final String location; 
final String description;
final String mediaUrl;
int likeCounts=0;
Map likes;
Post({this.postId, this.ownerId, this.username, this.location, this.description, this.mediaUrl, this.likes,this.likeCounts});
factory Post.fromDocument(DocumentSnapshot doc){
  return Post(
    postId: doc['postId'],
    ownerId: doc['ownerid'],
    username: doc['username'],
    location: doc['location'],
    description: doc['description'],
    mediaUrl: doc['mediaUrl'],
    likes: doc['likes'],
  );
}
int getLikeCounts(likes){
  if(likes==null){
    return 0;
  }
  int count=0;
  likes.values.forEach((val){
    if(val==true){
      count+=1;
    }
  });
  return count;
}
@override
  _PostState createState() => _PostState(
    
    postId: this.postId,
    ownerId: this.ownerId,
    username: this.username,
    location: this.location,
    description: this.description,
    mediaUrl: this.mediaUrl,
    likes:this.likes,
    likeCounts: getLikeCounts(likes)
  );
}

class _PostState extends State<Post> {
  final String currentUserId=currentUser?.id;
  final String postId;
final String ownerId;
final String username;
final String location; 
final String description;
final String mediaUrl;
int likeCounts=0;
Map likes;
bool isLiked;
bool showHeart=false;
_PostState({this.postId, this.ownerId, this.username, this.location, this.description, this.mediaUrl, this.likes,this.likeCounts});
factory _PostState.fromDocument(DocumentSnapshot doc){
  return _PostState(
    postId: doc['postId'],
    ownerId: doc['ownerid'],
    username: doc['username'],
    location: doc['location'],
    description: doc['description'],
    mediaUrl: doc['mediaUrl'],
    likes: doc['likes'],
  );
}
buildPostHeader(){
  return FutureBuilder(
    future: usersRef.document(ownerId).get(),
    builder: (context,snapshot){
      if(!snapshot.hasData){
        return circularProgress();
      }
      User user=User.fromDocument(snapshot.data);
      bool isOwner=currentUserId==ownerId;
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey,
          backgroundImage: NetworkImage(user.photourl),
        ),
        title: GestureDetector(
          onTap: ()=>showProfile(context,profileId:user.id),
          child: Text(
            username,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        subtitle: Text(
          location,
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        trailing: isOwner?IconButton(
          icon: Icon(Icons.more_vert),
          onPressed: ()=>handleDeletePost(context),
        ):Text(''),
      );
    },
  );
}
buildPostBody(){
  return GestureDetector(
    onDoubleTap: handleLikePost,
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Image(image: NetworkImage(mediaUrl),),
        showHeart?Animator(
          duration: Duration(milliseconds: 400),
          tween: Tween(begin: 0.8,end: 1.2),
          curve: Curves.elasticOut,
          cycles: 0,
          builder: (anim)=>Transform.scale(
            scale: anim.value,
            child:Icon(Icons.favorite,size: 80,color: Colors.pink,),
          ),
        ) :Text(''),
      ],
    ),
  );
}
handleDeletePost(BuildContext parentContext){
  return showDialog(
    context: parentContext,
    builder: (context){
      return SimpleDialog(
        title: Text("Remove this post"),
        children: <Widget>[
          SimpleDialogOption(
            onPressed: deletePost,
            child: Text('Delete',
            style: TextStyle(color: Colors.red),
            ),
          ),
          SimpleDialogOption(
            child: Text('Cancel'),
            onPressed: ()=>Navigator.pop(context),
          )
        ]
      );
    }
  );
}
deletePost()async{
  postsRef
  .document(ownerId)
  .collection('usersPosts')
  .document(postId)
  .get().then((doc){
    if(doc.exists){
      doc.reference.delete();
    }
  });
  storeRef.child("post_$postId.jpg").delete();
  QuerySnapshot activityfeed=await feedRef.document(ownerId)
  .collection('feedItem')
  .where('postId',isEqualTo: postId)
  .getDocuments();
  activityfeed.documents.forEach((doc){
    if(doc.exists){
      doc.reference.delete();
    }
  });
  //delete all comments
 QuerySnapshot commentsSnapshot=await commentRef.document(postId)
  .collection('comments')
  .getDocuments();
  commentsSnapshot.documents.forEach((doc){
    if(doc.exists){
      doc.reference.delete();
    }
  });
  Navigator.pop(context);
}
 handleLikePost(){
bool _isLiked  = likes[currentUserId]==true;
if(_isLiked){
  postsRef
  .document(ownerId)
  .collection('usersPosts')
  .document(postId).updateData({'likes.$currentUserId':false});
  removeFeedActivity();
setState(() {
  likeCounts-=1;
  isLiked=false;
  likes[currentUserId]=false;
});
}
else if(!_isLiked){
 postsRef
  .document(ownerId)
  .collection('usersPosts')
  .document(postId).updateData({'likes.$currentUserId':true});
  addLikeToActivityFeed();
setState(() {
  likeCounts+=1;
  isLiked=true;
  likes[currentUserId]=true;
  showHeart=true;
});
Timer(Duration(milliseconds: 500),(){
  setState(() {
    showHeart=false;
  });
});
}
 }
buildPostFooter(){
  return Column(
    children: <Widget>[
      Row(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 20,left: 10)
          ),
          GestureDetector(
            onTap: handleLikePost,
            child: Icon(
              isLiked?Icons.favorite:Icons.favorite_border,
              size: 28,
              color: Colors.pink,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 20,right: 10)
          ),
          GestureDetector(
            onTap: ()=>showComments(
              context,
              postId: postId,
              mediaUrl: mediaUrl,
              ownerId: ownerId
            ),
            child: Icon(
              Icons.chat,
              size: 28,
              color: Colors.blue,
            ),
          ),
        ],
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
               Padding(
            padding: EdgeInsets.only(top: 20,right: 20)
               ),
              Text('$likeCounts likes'),
            ],
          ),
          Row(
            children: <Widget>[
              Padding(
            padding: EdgeInsets.only(top: 20,right: 20)
               ),
              Text(
                '$username   -',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold
                ),
              ),
              Text(
                '$description',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
addLikeToActivityFeed(){
  // add a notification for others
  bool notme=currentUserId!=ownerId;
  if(notme){
feedRef.document(ownerId)
  .collection('feedItem')
  .document(postId).setData({
    "type":"like",
    "username":currentUser.username,
    "userId":currentUser.id,
    "userProfileImg":currentUser.photourl,
    "postId":postId,
    "mediaUrl":mediaUrl,
  "timeStamp":timestamp
  });
  } 
}
removeFeedActivity(){ 
   bool notme=currentUserId!=ownerId;
  if(notme){
  feedRef.document(ownerId)
  .collection('feedItem')
  .document(postId)
  .get().then((doc){
    if(doc.exists){
      doc.reference.delete();
    }
  });
  }

}
  @override
  Widget build(BuildContext context) {
    isLiked=(likes[currentUserId]==true);
    return Container(
      decoration: BoxDecoration(
      boxShadow: [new BoxShadow(
            color: Colors.white,
          ),]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          buildPostHeader(),
          Divider(height: 0.0,),
          buildPostBody(),
          Divider(height: 0.0,),
          buildPostFooter(),
          SizedBox(height: 30,)
        ],
      ),
    );
  }
}
showComments(BuildContext context,{String postId,String ownerId,String mediaUrl}){
  Navigator.push(context, MaterialPageRoute(builder: (context){
    return Comments( 
   postsId: postId,
   ownersId: ownerId,
   mediasUrl: mediaUrl,  
    );
  }));
}