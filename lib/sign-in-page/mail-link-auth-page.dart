import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class MailLinkAuth extends StatelessWidget {
  final String emailLink;

  MailLinkAuth(this.emailLink, {super.key});

  Future<UserCredential?> emailLinkAuthentication(String emailAuth) async {
    print("emailAuth: $emailAuth && emailLink: $emailLink");
    // The client SDK will parse the code from the link for you.
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailLink(
        email: emailAuth,
        emailLink: emailLink,
      );
      // You can access the new user via userCredential.user.
      final emailAddress = userCredential.user?.email;

      print('Successfully signed in $emailAddress with email link!');

      return userCredential;
    } catch (error) {
      print(
        "error signing in!!!!!!: ",
      ); //TODO: handle gracefully, invalid, expired tokens and etc,
      print(error);
      return null;
    }
  }

  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(20),
        color: Theme.of(context).colorScheme.secondaryFixedDim,
        child: Center(
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    border: UnderlineInputBorder(),
                    label: Text("Please verify your email"),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 40),
                  child: SizedBox.fromSize(
                    size: Size(double.infinity, 40),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
                      onPressed: () {
                        final emailAuth = emailController.text;
                        emailLinkAuthentication(emailAuth).then((value) {
                          if (context.mounted) {
                            context.go('/profile');
                          }
                        });
                      },
                      child: Text("Verify"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
