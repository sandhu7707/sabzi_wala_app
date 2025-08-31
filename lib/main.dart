

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sabzi_wala_app/discover-page/discover-page.dart';
import 'package:sabzi_wala_app/firebase_options.dart';
import 'package:go_router/go_router.dart';
import 'package:sabzi_wala_app/location-services-page/location-services-page.dart';
import 'package:sabzi_wala_app/profile-page/profile-page.dart';
import 'package:sabzi_wala_app/sign-in-page/mail-link-auth-page.dart';
import 'package:sabzi_wala_app/sign-in-page/sign-in-page.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void main() async {
  FlutterForegroundTask.initCommunicationPort();
  WidgetsFlutterBinding.ensureInitialized();  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(MaterialApp.router(
    routerConfig: router,
    theme: ThemeData.from(colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent)),  
  ));
}

String? emailLink;

final router = GoRouter(
  routes: [
    GoRoute(
      name: 'locationServices',
      path: '/',
      builder: (_, _) => LocationServicesPage()
    ),
    GoRoute(path: '/signInPage',
      builder: (_, _) => SignInPage()
    ),
    GoRoute(path: '/profile',
      builder: (_, _) => ProfilePage()
    ),
    GoRoute(path: '/verifyEmailLink',
      builder: (_, state) => MailLinkAuth(emailLink!)
    ),
    GoRoute(path: '/discover',
      builder: (_, _) => DiscoverPage()
    )
  ],
  redirect: (context, state) {
    if(FirebaseAuth.instance.isSignInWithEmailLink(state.uri.toString())) {
      print("it is an email link, can proceed");
      emailLink = state.uri.toString();
      return '/verifyEmailLink';
    }
  }
);

void onItemTapped(index){
  if(index == 1){
    router.pushReplacement('/');
  }
  else{
    router.pushReplacement('/discover');
  }
}

Widget scaffoldWrapper(BuildContext context, Widget body){
  final user = FirebaseAuth.instance.currentUser;
  final List<Widget> actions = [];
  if(user != null){
    actions.add(IconButton(onPressed: () => context.go('/profile'), icon: Icon(Icons.person_rounded)));
  }
  return 
  
  Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.secondaryFixedDim,
      title: const Text('Sabzi Wala'),
      actions: actions,
    ),
    body: body,
    bottomNavigationBar: BottomNavigationBar(items: [
      BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Discover'),
      BottomNavigationBarItem(icon: Icon(Icons.location_on_rounded), label: 'Location Services'),
      ],
      currentIndex: router.state.path == '/' ? 1 : 0 ,
      onTap: onItemTapped,
    ),
  );
}





