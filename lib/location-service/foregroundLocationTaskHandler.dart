// The callback function should always be a top-level or static function.
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sabzi_wala_app/firebase_options.dart';
import 'package:sabzi_wala_app/utils/db-utils.dart';

final ForegroundTaskOptions defaultTaskOptions = ForegroundTaskOptions(
  eventAction: ForegroundTaskEventAction.repeat(5000),
  autoRunOnBoot: true,
  autoRunOnMyPackageReplaced: true,
  allowWakeLock: true,
  allowWifiLock: true,
);


  @pragma('vm:entry-point')
  void startLiveLocationForeground() {
    print("startCallback");
    FlutterForegroundTask.setTaskHandler(LiveLocationTaskHandler());
  }

  @pragma('vm:entry-point')
  void startStaticLocationForeground() {
    print("startCallback");
    FlutterForegroundTask.setTaskHandler(StaticLocationTaskHandler());
  }

class StaticLocationTaskHandler extends TaskHandler {
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // TODO: implement onDestroy
    return;
    // throw UnimplementedError();
  }

  @override
  void onNotificationButtonPressed(String id) {
    print("$id button is pressed");
    if (id == "btn_stop") {
      print("stopping foreground service");
      stopLocationService();
    }
    super.onNotificationButtonPressed(id);
  }


  @override
  void onRepeatEvent(DateTime timestamp) {
    print('stopping static location service at $timestamp');
    stopLocationService();
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('static location service started at $timestamp');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
    );
    return;
  }

  void stopLocationService() async{
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ("User not found!");
    }

    final data = await DbUtils.getFirestoreRow(user.uid, "vendors");
    data["time_in_hours"] = 0;
    await DbUtils.addOrUpdateToFirestore(data, "vendors");
    

    FlutterForegroundTask.sendDataToMain(jsonEncode({"message_code": "foreground_stop"}));
    FlutterForegroundTask.stopService();
  }
  
}

class LiveLocationTaskHandler extends TaskHandler {
  int _count = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print("in onStart");
    print("registering listener for realtime updates");

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
    );
    final user = FirebaseAuth.instance.currentUser;
    if(user == null){
      throw("user not found!");
    }
    final data = await DbUtils.getRealtimeValue(user.uid);
    final timestampStr = data["start_timestamp"];
    final hours = data["time_in_hours"];
    final dateTimeTimestamp = DateTime.parse(timestampStr);

    FlLocation.getLocationStream().listen((position){

        if(DateTimeRange(start: dateTimeTimestamp, end: DateTime.now()).duration.inHours > hours){
          stopLocationService();
          return;
        }

        print("sending realtime position update");
        FlutterForegroundTask.sendDataToMain(jsonEncode({"latitude": position.latitude, "longitude": position.longitude}));
        
        print("timestamp in onStart: $timestamp");
        DbUtils.updateRealtimePosition(user.uid, {
          "latitude": position.latitude,
          "longitude": position.longitude,
        });

        FlutterForegroundTask.updateService(
          notificationTitle: 'Live Location is active for Sabzi Wala App',
          notificationText: 'lat:${position.latitude} lng:${position.longitude} \n Tap to return to the app',
          notificationIcon: null,
          notificationButtons: [
            const NotificationButton(id: 'btn_stop', text: 'Stop'),
          ],);
      });
    // }
          
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
  }

  @override
  void onNotificationButtonPressed(String id) {
    print("$id button is pressed");
    if (id == "btn_stop") {
      print("stopping foreground service");
      stopLocationService();
    }
    super.onNotificationButtonPressed(id);
  }

  void stopLocationService() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ("User not found!");
    }      
    
    DbUtils.removeFromRealtime(user.uid);
      
    FlutterForegroundTask.stopService();
    FlutterForegroundTask.sendDataToMain(jsonEncode({"message_code": "foreground_stop"}));

  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // some code
  }
}
