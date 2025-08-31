import 'dart:convert';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:fl_location/fl_location.dart';
import 'package:sabzi_wala_app/location-service/foregroundLocationTaskHandler.dart';
import 'package:sabzi_wala_app/location-services-page/location-services-page.dart';

class LocationService {

  static LocationService instance = LocationService();

  Future<void> _requestPermissions() async {
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    }

    if (!await FlLocation.isLocationServicesEnabled) {
      throw Exception('Location services is disabled.');
    }

    if (await FlLocation.checkLocationPermission() ==
        LocationPermission.denied) {
      await FlLocation.requestLocationPermission();
    }

    return;
  }

  void initService({int timeToStopInMillis = 5000}) {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(timeToStopInMillis),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<ServiceRequestResult> _startService(serviceMode) async {
    print("starting foreground location services");
    await FlutterForegroundTask.stopService();
    return FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: '${serviceMode == LocationServicesPageState.LIVE_MODE ? 'Live' : serviceMode == LocationServicesPageState.STATIC_MODE ? 'Static' : ''} Location is active for Sabzi Wala App',
      notificationText: 'Tap to return to the app',
      notificationIcon: null,
      notificationButtons: [
        const NotificationButton(id: 'btn_stop', text: 'Stop'),
      ],
      notificationInitialRoute: '/',
      callback: serviceMode == LocationServicesPageState.LIVE_MODE ? startLiveLocationForeground : startStaticLocationForeground
        ,
    );
  }

  void startService(serviceMode) async {
    await _requestPermissions();
    _startService(serviceMode);
  }

  Future<ServiceRequestResult> stopService() {
    return FlutterForegroundTask.stopService();
  }


}