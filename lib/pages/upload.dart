import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';
import 'home.dart';
class Upload extends StatefulWidget {
  final User currentUser;
  Upload({this.currentUser});
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  TextEditingController locationController=TextEditingController();
  TextEditingController captionController=TextEditingController();
  File file;
  bool isUploading=false;
  String postId=Uuid().v4();
  handleTakePhoto()async
  {
    Navigator.pop(context);
    File file=await ImagePicker.pickImage(source: ImageSource.camera,maxHeight: 675,maxWidth: 960);
    setState(() {
      this.file=file;
    });
  }
  handleChooseFromGallery() async
  {
    Navigator.pop(context);
    File file= await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      this.file=file;
    });
  }
  cancelImage(){
    setState(() {
      this.file=null;
    });
  }
  compressImage() async{
    final tempDir=await getTemporaryDirectory();
    final path=tempDir.path;
    Im.Image imagefile=Im.decodeImage(file.readAsBytesSync());
    final compressedImage=File('$path/img_$postId.jpg')..writeAsBytesSync(Im.encodeJpg(imagefile,quality:85));
    setState(() {
      file=compressedImage;
    });
  }
 Future<String> uploadImage() async{
  StorageUploadTask  uploadTask= storeRef.child("post_$postId.jpg").putFile(file);
  StorageTaskSnapshot storageSnap=await uploadTask.onComplete;
  String downloadUrl=await storageSnap.ref.getDownloadURL();
  return downloadUrl;
  }
createPostFireStore({String mediaUrl,String location,String description}){
  postsRef.document(widget.currentUser.id)
  .collection("usersPosts").
  document(postId).
  setData({
    'likes':{},
    'postId':postId,
    'ownerid':widget.currentUser.id,
    "username":widget.currentUser.username,
    "mediaUrl":mediaUrl,
    "description":description,
    "location":location,
    "timeStamp":timestamp,
  });
  locationController.clear();
  captionController.clear();
  setState(() {
    file=null;
    isUploading=false;
  });
}
  handleUploading()async{
    setState(() {
      isUploading=true;
    });
    await compressImage();
    String mediaUrl=await uploadImage();
    //create post in fireStore
    createPostFireStore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text
    );
  }
  selectImage(parentcontext){
    return showDialog(
      context: parentcontext,
      builder: (context){
        return SimpleDialog(
          title: Text("Create Post"),
          children: <Widget>[
            SimpleDialogOption(
              child: Text('Photo with camera'),
              onPressed: handleTakePhoto,
            ),
            SimpleDialogOption(
              child: Text('Photo with gallery'),
              onPressed: handleChooseFromGallery,
            ),
            SimpleDialogOption(
              child: Text('Cancel'),
              onPressed: (){Navigator.pop(context);},
            ),
          ],
        );
      }
    );
  }
  Container buildSplashScreen(){
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset('assets/images/upload.svg',height: 260,),
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text('Upload Image',style: TextStyle(
                color: Colors.white,
                fontSize: 22
              ),
              ),
              color: Colors.deepOrange,
              onPressed: ()=>selectImage(context),
            ),
          )
        ],
      ),
    );
  }
  getUserLocation() async{
  Position position=await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  List<Placemark> placemarks= await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
  Placemark placemark=placemarks[0];
  String formattedaddress="${placemark.locality},${placemark.country},";
  locationController.text=formattedaddress;
  }
  buildUploadForm(){
    return Scaffold(
        appBar: AppBar(
    backgroundColor: Colors.grey[300],
    leading: IconButton(
      icon:Icon(Icons.arrow_back,color: Colors.black,),
      onPressed: cancelImage,
    ),
    title: Text('Caption Post',style: TextStyle(color: Colors.black),),
    actions: <Widget>[
      FlatButton(
        onPressed: isUploading?null:()=>handleUploading(),
        child: Text("Post",
        style: TextStyle(
          color: Colors.blueAccent,
          fontWeight: FontWeight.bold,
          fontSize: 20.0
        ),),
      )
    ],
        ),
        body: ListView(
    children: <Widget>[
      isUploading?linearProgress():Text(''),
      Container(
        height: 225.0,
        width: MediaQuery.of(context).size.width,
        child: Center(
          child: AspectRatio(
            aspectRatio: 16/9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: FileImage(file),
                )
              ),
            ),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(top: 10),
      ),
      ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(widget.currentUser.photourl),
        ),
        title: Container(
          width: 250,
          child: TextField(
            controller: captionController,
            decoration: InputDecoration(
              hintText: "Write a caption",
              border: InputBorder.none
            ),
          ),
        ),
      ),
      Divider(),
      ListTile(
        leading: Icon(Icons.pin_drop,color: Colors.orange,size: 35,),
        title: Container(
          width: 250,
          child: TextField(
            controller: locationController,
            decoration: InputDecoration(
              hintText: "Location",
              border: InputBorder.none
            ),
          ),
        ),
      ),
      Container(
        width: 200,
        height: 100,
        alignment: Alignment.center,
        child: RaisedButton.icon(
          label: Text('Use Current Location',
          style: TextStyle(color: Colors.white),),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          onPressed:getUserLocation,
          icon: Icon(
            Icons.my_location,
            color: Colors.white,
          ),
          color: Colors.blue,
        ),
      )
    ],
        ),
      );
  }
  @override
  Widget build(BuildContext context) {
    return file==null? buildSplashScreen():buildUploadForm();
  }
}
