
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'home.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  TextEditingController searchController=TextEditingController();
  Future<QuerySnapshot> searchResultFuture;

  handleSearch(String query){
    Future<QuerySnapshot> users=usersRef.where('username',isLessThanOrEqualTo:query).getDocuments();
    setState(() {
      searchResultFuture=users;
    });
  }
  clearSearch(){
    searchController.clear();
  }
   buildSearchResults()
  {
    return FutureBuilder(
      future: searchResultFuture,
      builder: (context,snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        List<UserResult> searchResults=[];
        snapshot.data.documents.forEach((doc){
          User user=User.fromDocument(doc);
          UserResult searchResult=UserResult(user);
          searchResults.add(searchResult);
        });
        return ListView(
          children: searchResults,
        );
      }
    );
  }
  String username;
  AppBar buildSearchField(){
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: searchController,
        decoration:InputDecoration(
          hintText: "Search for user",
          filled: true,
          prefixIcon: Icon(
            Icons.account_box,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: clearSearch,
          )
        ),
        onFieldSubmitted: handleSearch,
      ),
    );
  }
  Container buildNoContent(){
  final Orientation orientation=MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset('assets/images/search.svg',height:orientation==Orientation.portrait?300:200),
            Text('Find Users',textAlign: TextAlign.center,style:TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
      appBar: buildSearchField(),
      body:searchResultFuture==null?buildNoContent():buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;
  UserResult(this.user);
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.9),
      child: Column(
        children: <Widget>[
          GestureDetector(
             onTap:()=>showProfile(context,profileId:user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red,
                backgroundImage: NetworkImage(user.photourl),
              ),
              title: Text(user.displayname,style: TextStyle(color: Colors.white,fontSize: 20),),
              subtitle: Text(user.username,style: TextStyle(color: Colors.white),),
            ),
          ),
          Divider(height: 2,color: Colors.white54,)
        ],
      ),
    );
  }
}
