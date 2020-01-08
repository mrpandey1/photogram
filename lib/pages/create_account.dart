import 'dart:async';

import 'package:flutter/material.dart';
import '../widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _formkey=GlobalKey<FormState>();
  final _scaffoldkey=GlobalKey<ScaffoldState>();
  String username;
  submit(){
    final form=_formkey.currentState;
    if(_formkey.currentState.validate()){
    form.save();
    SnackBar snackbar=SnackBar(content: Text('Welcome $username'),);
    _scaffoldkey.currentState.showSnackBar(snackbar);
    Timer(Duration(seconds: 2),(){
    Navigator.pop(context,username);
    });
    }
  }
  Future<bool> _onbackpressed() async {
    if(username==null)
    {

    }
}
  @override
  Widget build(BuildContext parentContext) {
    return WillPopScope (
      onWillPop: _onbackpressed,
          child: Scaffold(
        key: _scaffoldkey,
        appBar: header(context,titleText:"Set up your profile",removeback: true),
        body: ListView(
          children: <Widget>[
            Container(
              child: Column(children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 25),
                  child: Center(
                    child: Text('Create UserName',style: TextStyle(
                      fontSize: 25,
                    ),),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Container(
                    child: Form(
                      key: _formkey,
                      child: TextFormField(
                        autovalidate: true,
                        validator:(val)=>val.trim().length<6||val.isEmpty?"username must be of 6 digits":null,
                       onSaved: (val)=>username=val,
                       onChanged: (val)=>username=val,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "UserName",
                          labelStyle: TextStyle(
                            fontSize: 15,
                          ),
                          hintText: "UserName must be more than 6 digits"
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: submit,
                  child: Container(
                    height: 50,
                    width: 350,
                    child: Center(
                      child: Text('Submit',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                )
              ],),
            )
          ],
        ),
      ),
    );
  }
}
