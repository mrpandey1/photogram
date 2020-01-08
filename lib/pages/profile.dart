import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/edit_profile.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/post_tile.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'home.dart';

import '../widgets/header.dart';

class Profile extends StatefulWidget {
  final String profileId;
  Profile({this.profileId});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId=currentUser?.id;
  bool isLoading=false;
  int postCount=0;
  List<Post> posts=[];
  String postOrientation="grid";
  bool isFollowing=false;
  int followerCount=0;
  int followingCount=0;
  @override
  void initState(){
    super.initState();
    getProfilePost();
    checkIfFollowing();
    getFollowers();
    getFollowings();
  }
  checkIfFollowing()async{
    DocumentSnapshot doc=await 
    followersRef.document(widget.profileId)
    .collection('userFollowers')
    .document(currentUserId)
    .get();
    setState(() {
      isFollowing=doc.exists;
    });
  }
  getFollowings()async{
QuerySnapshot snapshot=  await followingRef.
    document(widget.profileId)
    .collection('userFollowing').
    getDocuments();
    setState(() {
      followingCount=snapshot.documents.length;
    });
  }
  getFollowers() async{
  QuerySnapshot snapshot=  await followersRef.
    document(widget.profileId)
    .collection('userFollowers').
    getDocuments();
    setState(() {
      followerCount=snapshot.documents.length;
    });
  }
  getProfilePost() async{
    setState(() {
      isLoading=true;
    });
    QuerySnapshot snapshot=await postsRef.document(widget.profileId).collection('usersPosts').orderBy('timeStamp',descending:true)
    .getDocuments();
    setState(() {
      isLoading=false;
      postCount=snapshot.documents.length;
      posts=snapshot.documents.map((doc)=>Post.fromDocument(doc)).toList();
    });
  }
  Column  buildCountColumn(String label,int count){
    return Column(
      mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Text(count.toString(),
      style: TextStyle(
        fontSize: 22,fontWeight: FontWeight.bold,
      ),),
      Container(
        margin: EdgeInsets.only(top: 4),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      )
    ],
    );
  }
  editProfile(){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>EditProfile(currentUserId:currentUserId)));
  }
 Container buildButton({String text,Function function}){
    return Container(
      child: Padding(
        padding: EdgeInsets.only(top: 2),
        child: FlatButton(
          onPressed: function,
          child: Container(
            alignment: Alignment.center,
            width: 220,
            height: 27,
            child: Text(
            text,
            style: TextStyle(
              color: isFollowing?Colors.black:Colors.white,
              fontWeight: FontWeight.bold,
            ),),
            decoration: BoxDecoration(
              color: isFollowing?Colors.white:Colors.blue,
              border:Border.all(
                color: isFollowing?Colors.grey:Colors.blue,
              )
            ),
          ),
        ),
      ),
    );
  }
  buildProfileButton(){
    // when we are seeing out own profile
    bool isProfileOwner=currentUserId==widget.profileId;
    if(isProfileOwner){
    return buildButton(
      text: 'Edit Profile',
      function: editProfile
    );
    }else if(isFollowing){
      return buildButton(text: "unfollow",function: handleUnfollowUser);
    }
    else if(!isFollowing){
      return buildButton(text: "follow",function: handleFollowUser);
    }
  }
  handleUnfollowUser(){
setState(() {
      isFollowing=false;
    });
    followersRef.document(widget.profileId)
    .collection('userFollowers')
    .document(currentUserId)
    .get().then((doc){
      if(doc.exists){
        doc.reference.delete();
      }
    });
    followingRef.document(currentUserId)
    .collection('userFollowing')
    .document(widget.profileId)
    .get().then((doc){
      if(doc.exists){
        doc.reference.delete();
      }
    });
    //for activity feed
    feedRef.document(widget.profileId)
    .collection('feedItem')
    .document(currentUserId)
    .get().then((doc){
      if(doc.exists){
        doc.reference.delete();
      }
    });
  }
  handleFollowUser(){
    setState(() {
      isFollowing=true;
    });
    followersRef.document(widget.profileId)
    .collection('userFollowers')
    .document(currentUserId)
    .setData({});
    followingRef.document(currentUserId)
    .collection('userFollowing')
    .document(widget.profileId)
    .setData({});
    //for activity feed
    feedRef.document(widget.profileId)
    .collection('feedItem')
    .document(currentUserId)
    .setData({
      "type":"follow",
      "ownerId":widget.profileId,
      "username":currentUser.username,
      "userId":currentUserId,
      "userProfileImg":currentUser.photourl,
      "timeStamp":timestamp,
    });
  }
  buildProfilePost(){
    if(isLoading){
      return circularProgress();
    }else if(posts.isEmpty){
       return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset('assets/images/no_content.svg',height: 260,),
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text('No Image',style: TextStyle(
              color: Colors.redAccent,
              fontSize:40,
              fontWeight: FontWeight.bold
            ),
            ),
          )
        ],
      ),
    );
    }
    else if(postOrientation=="grid"){
      List<GridTile> gridTile=[];
    posts.forEach((post){
      gridTile.add(GridTile(child:PostTile(post: post,)));
    });
          return GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          mainAxisSpacing: 1.5,
          crossAxisSpacing: 1.5,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: gridTile,
    );
    }else if(postOrientation=='list'){      
          return Column(
                children: posts,
                  );
    }
  }
  setPostsOrient(String orientation){
setState(() {
  this.postOrientation=orientation;
});
  }
  buildTogglePostsOrient(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: ()=>setPostsOrient('grid'),
          icon: Icon(Icons.grid_on),
          color:postOrientation=='grid'?Theme.of(context).primaryColor:Colors.grey,
        ),
        IconButton(
          onPressed:()=> setPostsOrient('list'),
          icon: Icon(Icons.list),
          color:postOrientation=='list'?Theme.of(context).primaryColor:Colors.grey,
        )
      ],
    );
  }
buildProfileHeader(){
return FutureBuilder(
  future: usersRef.document(widget.profileId).get(),
  builder: (context,snapshot){
    if(!snapshot.hasData){
      return circularProgress();
    }
    User user=User.fromDocument(snapshot.data);
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey,
                backgroundImage: NetworkImage(user.photourl),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        buildCountColumn('posts',postCount),
                        buildCountColumn('followers',followerCount),
                        buildCountColumn('following',followingCount),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        buildProfileButton(),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        user.displayname,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                        ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        user.username,
                        style: TextStyle(
                          fontSize: 14
                        ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        user.bio,
                        style: TextStyle(
                          fontSize: 14
                        ),
                      ),
                    ),
        ],
      ),
    );
  },
);
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context,isAppTitle: false,titleText: 'Profile',removeback: false),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(height: 0.0,),
          buildTogglePostsOrient(),
          Divider(height: 0.0,),
          buildProfilePost()
        ],
      )
    );
  }
}
