import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sabzi_wala_app/main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error Signing in. Please retry')),
        );
        context.go('/signInPage');
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final formKey = GlobalKey<FormState>();
    final displayNameController = TextEditingController(
      text: user!.displayName,
    );

    return (scaffoldWrapper(
      context,
      Container(
        padding: EdgeInsets.all(20),
        color: Theme.of(context).colorScheme.secondaryFixed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.only(top: 50),
              child: Form(
                child: Form(
                  key: formKey,
                  child: Column(
                    spacing: 0,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextFormField(
                        controller: displayNameController,
                        decoration: InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Your Display Name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please Enter between 3 and 50 alpha numerical characters';
                          }
                          print('matching value $value');
                          return value.length >= 3 && value.length < 50
                              ? null
                              : 'Please Enter between 3 and 50 alpha numerical characters';
                        },
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 50),
                        child: SizedBox.fromSize(
                          size: Size(double.infinity, 40),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0),
                              ),
                            ),
                            onPressed: () {
                              if (!formKey.currentState!.validate()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please Enter between 3 and 50 alpha numerical characters',
                                    ),
                                  ),
                                );
                                return;
                              }

                              user
                                  .updateDisplayName(displayNameController.text)
                                  .then((value) {
                                    if (context.mounted) {
                                      context.go('/');
                                    }
                                  });
                            },
                            child: Text('Save'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 50),
              child: SizedBox.fromSize(
                size: Size(double.infinity, 40),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  onPressed: () async {
                    FirebaseAuth.instance.signOut().then((value) {
                      if (context.mounted) {
                        context.go('/');
                      }
                    });
                  },
                  child: Text('Sign Out'),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
