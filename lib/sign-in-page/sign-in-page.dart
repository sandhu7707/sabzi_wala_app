import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sabzi_wala_app/main.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => SignInPageState(); //TODO: fix this somehow
}

class SignInPageState extends State<SignInPage> {
  final emailController = TextEditingController();
  bool linkSent = false;
  String linkAddress = '';

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();

  Future<void> sendSignInLinkToEmail(email) {
    final acs = ActionCodeSettings(
      url: 'https://sandhu7707.github.io/',
      handleCodeInApp: true,
      androidPackageName: 'com.example.sabzi_wala_app',
      androidInstallApp: true,
    );

    return FirebaseAuth.instance.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: acs,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        color: Theme.of(context).colorScheme.secondaryFixedDim,
        child: Builder(
          builder: (context) {
            return Center(
              // height: Wid,
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Sabzi Wala App",
                            textScaler: TextScaler.linear(3),
                            style: TextStyle(
                              decorationColor: Colors.white,
                              shadows: [
                                Shadow(
                                  color: const Color.fromARGB(
                                    255,
                                    150,
                                    170,
                                    157,
                                  ),
                                  offset: Offset(4, 4),
                                  blurRadius: 10,
                                ),
                              ],
                              fontWeight: FontWeight.w900,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          Text(
                            "Live map of local vendors near you",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ],
                      ),
                    ),
                    linkSent
                        ? Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                Text('Verification link sent to $linkAddress. Please check your inbox and spam folders.', textAlign: TextAlign.center,),
                                Container(
                                  margin: EdgeInsets.only(top: 40),
                                  child: SizedBox.fromSize(
                                    size: Size(double.infinity, 40),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            0,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                         sendSignInLinkToEmail(linkAddress)
                                              .then(
                                                (value){
                                                  if(context.mounted){
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Resent verification link to $linkAddress')));
                                                  }
                                            },                              //TODO: this then gets invoked even on error, on proper successsful then, add a message on the lines of.. 'mail sent, please check..'
                                          onError: (onError) =>
                                              print('Error sending email verification $onError'
                                          ));
                                      },
                                      child: Text('Resend'),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(top: 20),
                                  child: SizedBox.fromSize(
                                    size: Size(double.infinity, 40),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            0,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          linkAddress = '';
                                          linkSent = false;
                                        });
                                      },
                                      child: Text('Back To Sign In Page'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Expanded(
                            flex: 1,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                spacing: 0,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    margin: EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      'Enter your email to continue',
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  TextFormField(
                                    controller: emailController,
                                    decoration: InputDecoration(
                                      border: UnderlineInputBorder(),
                                      labelText: 'Email',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please Enter a valid email';
                                      }
                                      print('matching value $value');
                                      return RegExp(
                                            r'^[\w]*[@][a-z]*[.]\w{2,6}$',
                                          ).hasMatch(value)
                                          ? null
                                          : 'Please Enter a valid email';
                                    },
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(top: 50),
                                    child: SizedBox.fromSize(
                                      size: Size(double.infinity, 40),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              0,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          if (!_formKey.currentState!
                                              .validate()) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please Enter a valid email!',
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          final email = emailController.text;
                                          print(email);

                                          sendSignInLinkToEmail(email)
                                              .then(
                                                (value){
                                                  print('Successfully sent verification mail.');
                                          setState(() {
                                            linkSent = true;
                                            linkAddress = email;
                                          });
                                            },                              //TODO: this then gets invoked even on error, on proper successsful then, add a message on the lines of.. 'mail sent, please check..'
                                          onError: (onError) =>
                                              print('Error sending email verification $onError'
                                          ));
                                          print(email);
                                        },
                                        child: Text('Sign In'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    Expanded(
                      flex: 2,
                      child: Image.asset('assets/images/groceries.png'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
