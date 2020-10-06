import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../constants.dart';
import '../../main.dart';

class AccountDetailsScreen extends StatefulWidget {
  final User user;

  AccountDetailsScreen({Key key, @required this.user}) : super(key: key);

  @override
  _AccountDetailsScreenState createState() {
    return _AccountDetailsScreenState(user);
  }
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  User user;
  GlobalKey<FormState> _key = new GlobalKey();
  bool _validate = false;
  String firstName,
      lastName,
      age,
      bio,
      school,
      email,
      mobile,
      relationshipStatus,
      denominationView,
      churchInvolvement,
      seeking,
      willingToRelocate;

  _AccountDetailsScreenState(this.user);
  @override
  void initState() {
    relationshipStatus = user.relationshipStatus;
    denominationView = user.denominationalViews;
    churchInvolvement = user.churchInvolvement;
    seeking = user.seeking;
    willingToRelocate = user.willingToRelocate;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: isDarkMode(context) ? Colors.black : Colors.white,
          brightness: isDarkMode(context) ? Brightness.dark : Brightness.light,
          centerTitle: true,
          iconTheme: IconThemeData(
              color: isDarkMode(context) ? Colors.white : Colors.black),
          title: Text(
            'Account Details',
            style: TextStyle(
                color: isDarkMode(context) ? Colors.white : Colors.black),
          ),
        ),
        body: Builder(
            builder: (buildContext) => SingleChildScrollView(
                  child: Form(
                    key: _key,
                    autovalidate: _validate,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 16.0, right: 16, bottom: 8, top: 24),
                            child: Text(
                              'PUBLIC INFO',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                          Material(
                              elevation: 2,
                              color: isDarkMode(context)
                                  ? Colors.black12
                                  : Colors.white,
                              child: ListView(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  children: ListTile.divideTiles(
                                      context: buildContext,
                                      tiles: [
                                        ListTile(
                                          title: Text(
                                            'First Name',
                                            style: TextStyle(
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          trailing: ConstrainedBox(
                                            constraints:
                                                BoxConstraints(maxWidth: 100),
                                            child: TextFormField(
                                              onSaved: (String val) {
                                                firstName = val;
                                              },
                                              validator: validateName,
                                              textInputAction:
                                                  TextInputAction.next,
                                              textAlign: TextAlign.end,
                                              initialValue: user.firstName,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: isDarkMode(context)
                                                      ? Colors.white
                                                      : Colors.black),
                                              cursorColor: Color(COLOR_ACCENT),
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              keyboardType: TextInputType.text,
                                              decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText: 'First name',
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          vertical: 5)),
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Last Name',
                                            style: TextStyle(
                                                color: isDarkMode(context)
                                                    ? Colors.white
                                                    : Colors.black),
                                          ),
                                          trailing: ConstrainedBox(
                                            constraints:
                                                BoxConstraints(maxWidth: 100),
                                            child: TextFormField(
                                              onSaved: (String val) {
                                                lastName = val;
                                              },
                                              validator: validateName,
                                              textInputAction:
                                                  TextInputAction.next,
                                              textAlign: TextAlign.end,
                                              initialValue: user.lastName,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: isDarkMode(context)
                                                      ? Colors.white
                                                      : Colors.black),
                                              cursorColor: Color(COLOR_ACCENT),
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              keyboardType: TextInputType.text,
                                              decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText: 'Last name',
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          vertical: 5)),
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Age',
                                            style: TextStyle(
                                                color: isDarkMode(context)
                                                    ? Colors.white
                                                    : Colors.black),
                                          ),
                                          trailing: ConstrainedBox(
                                            constraints:
                                                BoxConstraints(maxWidth: 100),
                                            child: TextFormField(
                                              onSaved: (String val) {
                                                age = val;
                                              },
                                              textInputAction:
                                                  TextInputAction.next,
                                              textAlign: TextAlign.end,
                                              initialValue: user.age,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: isDarkMode(context)
                                                      ? Colors.white
                                                      : Colors.black),
                                              cursorColor: Color(COLOR_ACCENT),
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText: 'Age',
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          vertical: 5)),
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Bio',
                                            style: TextStyle(
                                                color: isDarkMode(context)
                                                    ? Colors.white
                                                    : Colors.black),
                                          ),
                                          trailing: ConstrainedBox(
                                            constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    .5),
                                            child: TextFormField(
                                              onSaved: (String val) {
                                                bio = val;
                                              },
                                              initialValue: user.bio,
                                              minLines: 1,
                                              maxLines: 3,
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: isDarkMode(context)
                                                      ? Colors.white
                                                      : Colors.black),
                                              cursorColor: Color(COLOR_ACCENT),
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              keyboardType:
                                                  TextInputType.multiline,
                                              decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText: 'Bio',
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          vertical: 5)),
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'School',
                                            style: TextStyle(
                                                color: isDarkMode(context)
                                                    ? Colors.white
                                                    : Colors.black),
                                          ),
                                          trailing: ConstrainedBox(
                                            constraints:
                                                BoxConstraints(maxWidth: 100),
                                            child: TextFormField(
                                              onSaved: (String val) {
                                                school = val;
                                              },
                                              textAlign: TextAlign.end,
                                              textInputAction:
                                                  TextInputAction.next,
                                              initialValue: user.school,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: isDarkMode(context)
                                                      ? Colors.white
                                                      : Colors.black),
                                              cursorColor: Color(COLOR_ACCENT),
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              keyboardType: TextInputType.text,
                                              decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText: 'School',
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          vertical: 5)),
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Relationship Status',
                                            style: TextStyle(
                                              fontSize: 17,
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          trailing: GestureDetector(
                                            onTap: _onGenderClick,
                                            child: Text('$relationshipStatus',
                                                style: TextStyle(
                                                    fontSize: 17,
                                                    color: isDarkMode(context)
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Denominationl Views',
                                            style: TextStyle(
                                              fontSize: 17,
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          trailing: GestureDetector(
                                            onTap: _onDenominationViewClick,
                                            child: Text('$denominationView',
                                                style: TextStyle(
                                                    fontSize: 17,
                                                    color: isDarkMode(context)
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Church Involvement',
                                            style: TextStyle(
                                              fontSize: 17,
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          trailing: GestureDetector(
                                            onTap: _onchurchInvolvmentClick,
                                            child: Container(
                                              width: 180,
                                              child: Text('$churchInvolvement',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      color: isDarkMode(context)
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Seeking',
                                            style: TextStyle(
                                              fontSize: 17,
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          trailing: GestureDetector(
                                            onTap: _onSeekingClick,
                                            child: Text('$seeking',
                                                style: TextStyle(
                                                    fontSize: 17,
                                                    color: isDarkMode(context)
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Willing to Relocate',
                                            style: TextStyle(
                                              fontSize: 17,
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          trailing: GestureDetector(
                                            onTap: _onWillingClick,
                                            child: Text('$willingToRelocate',
                                                style: TextStyle(
                                                    fontSize: 17,
                                                    color: isDarkMode(context)
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ),
                                      ]).toList())),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 16.0, right: 16, bottom: 8, top: 24),
                            child: Text(
                              'PRIVATE DETAILS',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                          Material(
                            elevation: 2,
                            color: isDarkMode(context)
                                ? Colors.black12
                                : Colors.white,
                            child: ListView(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                children: ListTile.divideTiles(
                                  context: buildContext,
                                  tiles: [
                                    ListTile(
                                      title: Text(
                                        'Email Address',
                                        style: TextStyle(
                                            color: isDarkMode(context)
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                      trailing: ConstrainedBox(
                                        constraints:
                                            BoxConstraints(maxWidth: 200),
                                        child: TextFormField(
                                          onSaved: (String val) {
                                            email = val;
                                          },
                                          validator: validateEmail,
                                          textInputAction: TextInputAction.next,
                                          initialValue: user.email,
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black),
                                          cursorColor: Color(COLOR_ACCENT),
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'Email Address',
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      vertical: 5)),
                                        ),
                                      ),
                                    ),
                                    ListTile(
                                      title: Text(
                                        'Phone Number',
                                        style: TextStyle(
                                            color: isDarkMode(context)
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                      trailing: ConstrainedBox(
                                        constraints:
                                            BoxConstraints(maxWidth: 150),
                                        child: TextFormField(
                                          onSaved: (String val) {
                                            mobile = val;
                                          },
                                          validator: validateMobile,
                                          textInputAction: TextInputAction.done,
                                          initialValue: user.phoneNumber,
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black),
                                          cursorColor: Color(COLOR_ACCENT),
                                          keyboardType: TextInputType.phone,
                                          decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'Phone Number',
                                              contentPadding:
                                                  EdgeInsets.only(bottom: 2)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ).toList()),
                          ),
                          Padding(
                              padding:
                                  const EdgeInsets.only(top: 32.0, bottom: 16),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                    minWidth: double.infinity),
                                child: Material(
                                  elevation: 2,
                                  color: isDarkMode(context)
                                      ? Colors.black12
                                      : Colors.white,
                                  child: CupertinoButton(
                                    padding: const EdgeInsets.all(12.0),
                                    onPressed: () async {
                                      _validateAndSave(buildContext);
                                    },
                                    child: Text(
                                      'Save',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Color(COLOR_PRIMARY)),
                                    ),
                                  ),
                                ),
                              )),
                        ]),
                  ),
                )));
  }

  _validateAndSave(BuildContext buildContext) async {
    if (_key.currentState.validate()) {
      _key.currentState.save();
      if (user.email != email) {
        TextEditingController _passwordController = new TextEditingController();
        showDialog(
            context: context,
            child: Dialog(
              elevation: 16,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40)),
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Inorder to change your email, you must type your password first',
                        style: TextStyle(color: Colors.red, fontSize: 17),
                        textAlign: TextAlign.start,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(hintText: 'Password'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: RaisedButton(
                          color: Color(COLOR_ACCENT),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12))),
                          onPressed: () async {
                            if (_passwordController.text.isEmpty) {
                              showAlertDialog(context, "Empty Password",
                                  "Password is required to update email");
                            } else {
                              Navigator.pop(context);
                              showProgress(context, 'Verifying...', false);
                              AuthResult result = await FirebaseAuth.instance
                                  .signInWithEmailAndPassword(
                                      email: 'test@user2.com',
                                      password: _passwordController.text)
                                  .catchError((onError) {
                                hideProgress();
                                showAlertDialog(context, 'Couldn\'t verify',
                                    'Please double check the password and try again.');
                              });
                              _passwordController.dispose();
                              if (result.user != null) {
                                await result.user.updateEmail(email);
                                updateProgress('Saving details...');
                                await _updateUser(buildContext);
                                hideProgress();
                              } else {
                                hideProgress();
                                Scaffold.of(buildContext).showSnackBar(SnackBar(
                                    content: Text(
                                  'Couldn\'t verify, Please try again.',
                                  style: TextStyle(fontSize: 17),
                                )));
                              }
                            }
                          },
                          child: Text(
                            'Verify',
                            style: TextStyle(
                                color: isDarkMode(context)
                                    ? Colors.black
                                    : Colors.white),
                          ),
                        ),
                      )
                    ],
                  )),
            ));
      } else {
        showProgress(context, "Saving details...", false);
        await _updateUser(buildContext);
        hideProgress();
      }
    } else {
      setState(() {
        _validate = true;
      });
    }
  }

  _onGenderClick() {
    final action = CupertinoActionSheet(
      message: Text(
        "Relationship Status",
        style: TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Single"),
          isDefaultAction: false,
          onPressed: () {
            Navigator.pop(context);
            relationshipStatus = 'Single';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Divorced"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            relationshipStatus = 'Divorced';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Divorce Filed/Pending"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            relationshipStatus = 'Divorce Filed/Pending';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Widowed"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            relationshipStatus = 'Widowed';
            setState(() {});
          },
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  _onDenominationViewClick() {
    final action = CupertinoActionSheet(
      message: Text(
        "Denominational Views",
        style: TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Christian"),
          isDefaultAction: false,
          onPressed: () {
            Navigator.pop(context);
            denominationView = 'Christian';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Pentecostal"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            denominationView = 'Pentecostal';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Trinitarian"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            denominationView = 'Trinitarian';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Apostolic"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            denominationView = 'Apostolic';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Full Gospel"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            denominationView = 'Full Gospel';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Baptist"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            denominationView = 'Baptist';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Non Denominational"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            denominationView = 'Non Denominational';
            setState(() {});
          },
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  _onchurchInvolvmentClick() {
    final action = CupertinoActionSheet(
      message: Text(
        "Church Involvement",
        style: TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("believe in God but don’t attend church"),
          isDefaultAction: false,
          onPressed: () {
            Navigator.pop(context);
            churchInvolvement = 'believe in God but don’t attend church';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Attend Church on Holidays/Special a events"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            churchInvolvement = 'Attend Church on Holidays/Special a events';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Attend Church regularly"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            churchInvolvement = 'Attend Church regularly';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("In Church Leadership"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            churchInvolvement = 'In Church Leadership';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Church Musician"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            churchInvolvement = 'Church Musician';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Church Singer"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            churchInvolvement = 'Church Singer';
            setState(() {});
          },
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  _onSeekingClick() {
    final action = CupertinoActionSheet(
      message: Text(
        "Seeking",
        style: TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Casual Dating"),
          isDefaultAction: false,
          onPressed: () {
            Navigator.pop(context);
            seeking = 'Casual Dating';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Courtship"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            seeking = 'Courtship';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Marriage"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            seeking = 'Marriage';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Marriage and Kids"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            seeking = 'Marriage and Kids';
            setState(() {});
          },
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  _onWillingClick() {
    final action = CupertinoActionSheet(
      message: Text(
        "Willing to Relocate",
        style: TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Yes"),
          isDefaultAction: false,
          onPressed: () {
            Navigator.pop(context);
            willingToRelocate = 'Yes';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("No"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            willingToRelocate = 'No';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("For the right person"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            willingToRelocate = 'For the right person';
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Open for Discussion"),
          isDestructiveAction: false,
          onPressed: () {
            Navigator.pop(context);
            willingToRelocate = 'Open for Discussion';
            setState(() {});
          },
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  _updateUser(BuildContext buildContext) async {
    user.firstName = firstName;
    user.lastName = lastName;
    user.age = age;
    user.bio = bio;
    user.school = school;
    user.email = email;
    user.relationshipStatus = relationshipStatus;
    user.denominationalViews = denominationView;
    user.seeking = seeking;
    user.willingToRelocate = willingToRelocate;
    user.churchInvolvement = churchInvolvement;
    user.phoneNumber = mobile;
    var updatedUser = await FireStoreUtils().updateCurrentUser(user, context);
    if (updatedUser != null) {
      MyAppState.currentUser = user;
      Scaffold.of(buildContext).showSnackBar(SnackBar(
          content: Text(
        'Details saved successfuly',
        style: TextStyle(fontSize: 17),
      )));
    } else {
      Scaffold.of(buildContext).showSnackBar(SnackBar(
          content: Text(
        'Couldn\'t save details, Please try again.',
        style: TextStyle(fontSize: 17),
      )));
    }
  }
}
