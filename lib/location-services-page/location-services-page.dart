import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sabzi_wala_app/location-service/location-service.dart';
import 'package:sabzi_wala_app/main.dart';
import 'package:sabzi_wala_app/sign-in-page/sign-in-page.dart';
import 'package:sabzi_wala_app/utils/db-utils.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:skeletonizer/skeletonizer.dart';

class LocationServicesPage extends StatefulWidget {
  const LocationServicesPage({super.key});

  @override
  State<LocationServicesPage> createState() => LocationServicesPageState();
}


class LocationServicesPageState extends State<LocationServicesPage>
    with OSMMixinObserver {
  static final String STATIC_MODE = 'static';
  static final String LIVE_MODE = 'live';

  bool staticLocationStateRestored = true;
  bool liveLocationStateRestored = true;
  GeoPoint? location;
  bool isMapReady = false;
  GeoPoint? liveLocation;
  bool trackingEnabled = false;
  bool disableNextAutoLocationUpdate =
      false; // to prevent mapisReady to override if location is restored from db

  final MapController controller;
  OSMFlutter map;

  void _onReceiveTaskData(Object data) {
    if (data is! String) {
      return;
    }

    final Map<String, dynamic> dataMap = jsonDecode(data);

    if (dataMap["message_code"] == "foreground_stop") {
      print("stopping location services");

      setState(() {
        locationServiceActive = false;
      });
      return;
    }

    final newLiveLocation = GeoPoint(
      latitude: dataMap["latitude"]!,
      longitude: dataMap["longitude"]!,
    );

    if (liveLocation == null) {
      controller.addMarker(newLiveLocation!);
    } else {
      controller.changeLocationMarker(
        oldLocation: liveLocation!,
        newLocation: newLiveLocation,
      );
    }

    setState(() {
      liveLocation = newLiveLocation;
    });

    // final user = FirebaseAuth.instance.currentUser;
    // if (user != null) {
    //   DbUtils.updateRealtimePosition(user.uid, {
    //     "latitude": dataMap["latitude"]!,
    //     "longitude": dataMap["longitude"]!,
    //   });
    // }

    print("timestamp: ${dataMap["start_time"]}");
    print("hours is $hours");
  }

  @override
  void initState() {
    super.initState();

        controller.addObserver(this);


    print("getting values in dbs");
    WidgetsBinding.instance.addPostFrameCallback((_) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DbUtils.getFirestoreRow(user.uid, "vendors").then((data) {
        if (data == null) {
          setState(() {
            staticLocationStateRestored = true;
          });
          return;
        }
        final timestamp = data["start_timestamp"];
        final timeInHours = data["time_in_hours"];
        if (timestamp == null || timeInHours == null) {
          setState(() {
            staticLocationStateRestored = true;
          });
          return;
        }
        final durationSinceStart = DateTimeRange(
          start: DateTime.fromMicrosecondsSinceEpoch(
            timestamp.microsecondsSinceEpoch,
          ),
          end: DateTime.now(),
        ).duration;
        print('static position durationSinceStart is $durationSinceStart');
        final hoursSinceStart = durationSinceStart.inHours;
        if (hoursSinceStart < timeInHours) {
          final storedLocation = GeoPoint(
            latitude: data["position"]["latitude"],
            longitude: data["position"]["longitude"],
          );
          if (location != null) {
            controller.removeMarker(location!);
          }
          if (liveLocation != null) {
            controller.removeMarker(liveLocation!);
          }
          setState(() {
            mode = STATIC_MODE;
            locationServiceActive = true;
            staticLocationStateRestored = true;
            location = storedLocation;
            disableNextAutoLocationUpdate = true;
          });
        } else {
          setState(() {
            staticLocationStateRestored = true;
          });
        }
      });
      DbUtils.getRealtimeValue(user.uid).then((data) {
        if (data == null) {
          setState(() {
            liveLocationStateRestored = true;
          });
          return;
        }
        final timestampStr = data["start_timestamp"];
        final timeInHours = data["time_in_hours"];
        if (timestampStr == null || timeInHours == null) {
          setState(() {
            liveLocationStateRestored = true;
          });
          return;
        }

        final timestamp = DateTime.parse(timestampStr);
        final durationSinceStart = DateTimeRange(
          start: timestamp,
          end: DateTime.now(),
        ).duration;
        print('live position durationSinceStart is $durationSinceStart');
        final hoursSinceStart = durationSinceStart.inHours;
        if (hoursSinceStart < timeInHours) {
          if (data["position"] == null) {
            setState(() {
              mode = LIVE_MODE;
              locationServiceActive = true;
              liveLocationStateRestored = true;
            });
            return;
          }
          final storedLocation = GeoPoint(
            latitude: data["position"]["latitude"],
            longitude: data["position"]["longitude"],
          );
          if (liveLocation != null) {
            controller.removeMarker(liveLocation!);
          }
          if (location != null) {
            controller.removeMarker(location!);
          }
          setState(() {
            mode = LIVE_MODE;
            locationServiceActive = true;
            liveLocationStateRestored = true;
            liveLocation = storedLocation;
            disableNextAutoLocationUpdate = true;
          });
        } else {
          setState(() {
            liveLocationStateRestored = true;
          });
        }
      });
    }
      if (user == null) {
        context.go('/signInPage');
      } else if (user.displayName == null || user.displayName == '') {
        context.go('/profile');
      }
    });
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }

  factory LocationServicesPageState() {
    MapController controller = MapController.withUserPosition(
      trackUserLocation: UserTrackingOption(
        enableTracking: true,
        unFollowUser: false,
      ),
    );

    OSMFlutter map = OSMFlutter(
      controller: controller,
      onLocationChanged: (p0) {
        print("location tracking, location changed ");
        print(p0);
      },
      osmOption: OSMOption(
        zoomOption: const ZoomOption(
          initZoom: 16,
          minZoomLevel: 3,
          maxZoomLevel: 19,
          stepZoom: 1.0,
        ),
      ),
    );

    return LocationServicesPageState.state(controller, map);
  }

  LocationServicesPageState.state(this.controller, this.map);

  String mode = LIVE_MODE;
  int hours = 1;
  bool locationServiceActive =
      false; //TODO: not covered when starting the app after closing

  void startStaticLocationService() {
    final user = FirebaseAuth.instance.currentUser;
    if (location == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please Set the location first!")));
      return;
    }

    print('start static location service for $hours hours');

    final vendor = <String, dynamic>{
      "name": user!.displayName,
      "uid": user.uid,
      "position": <String, double?>{
        "latitude": location?.latitude,
        "longitude": location?.longitude,
      },
      "start_timestamp": DateTime.now(),
      "time_in_hours": hours,
    };

    DbUtils.addOrUpdateToFirestore(vendor, "vendors");

    LocationService.instance.initService(timeToStopInMillis: hours *60 * 60* 1000);
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
    LocationService.instance.startService(STATIC_MODE);

    setState(() {
      locationServiceActive = true;
    });
  }

  void startLiveLocationService() async {
    final user = FirebaseAuth.instance.currentUser;

    final vendor = <String, dynamic>{
      "name": user!.displayName,
      "uid": user.uid,
      "position": <String, double?>{
        "latitude": liveLocation?.latitude,
        "longitude": liveLocation?.longitude,
      },
      "start_timestamp": DateTime.now().toString(),
      "time_in_hours": hours,
    };

    await DbUtils.addorUpdataToRealtime(vendor, user.uid);
    print('start live location service for $hours hours');

    LocationService.instance.initService();
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
    LocationService.instance.startService(LIVE_MODE);

    setState(() {
      locationServiceActive = true;
    });
  }

  void stopStaticLocationService() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ("User not found!");
    }

    DbUtils.getFirestoreRow(user.uid, "vendors").then((data) {
      data["time_in_hours"] = 0;
      DbUtils.addOrUpdateToFirestore(data, "vendors");
    });

    LocationService.instance.stopService();
  }

  void stopLiveLocationService() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ("User not found!");
    }

    DbUtils.removeFromRealtime(user.uid);

    LocationService.instance.stopService();
  }

  Widget setLocationPage() {
    print(mode);

    // controller.removeObserver(this);
    // // if (mode == STATIC_MODE) {
    // controller.addObserver(this);
    // }

    final actions = locationServiceActive
        ? [
            ElevatedButton(
              onPressed: () {
                if (mode == STATIC_MODE) {
                  stopStaticLocationService();
                } else if (mode == LIVE_MODE) {
                  stopLiveLocationService();
                }
                setState(() {
                  locationServiceActive = false;
                });
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
              ),
              child: Text('Stop Location Service'),
            ),
          ]
        : [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
              ),
              onPressed: () {
                if (mode == STATIC_MODE) {
                  startStaticLocationService();
                } else if (mode == LIVE_MODE) {
                  startLiveLocationService();
                }
              },
              child: Text(
                "Start ${mode == STATIC_MODE
                    ? 'Static'
                    : mode == LIVE_MODE
                    ? 'Live'
                    : ''} Location Broadcast",
              ),
            ),
            Text('for'),
            NumberPicker(
              value: hours,
              minValue: 1,
              maxValue: 12,
              onChanged: (value) => setState(() => hours = value),
            ),
            Text('hours'),
          ];

    return (scaffoldWrapper(
      context,
      Skeletonizer(
        enabled: !staticLocationStateRestored || !liveLocationStateRestored,
        child: Container(
          padding: EdgeInsets.only(top: 10, bottom: 50),
          alignment: Alignment(0, 0),
          color: Theme.of(context).colorScheme.secondaryFixed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
              'Broadcast your location',
              textScaler: TextScaler.linear(1.5),
              style: TextStyle(
                decorationColor: Colors.white,
                shadows: [
                  Shadow(
                    color: const Color.fromARGB(255, 150, 170, 157),
                    offset: Offset(2, 2),
                    blurRadius: 10,
                  ),
                ],
                fontWeight: FontWeight.w900,
                color: Color.fromARGB(255, 58, 54, 54),
              ),
            ),
              Container(
                margin: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: FilledButton(
                          onPressed: mode == STATIC_MODE
                              ? null
                              : () {
                                  if (locationServiceActive) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Please stop location service before switching modes',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    mode = STATIC_MODE;
                                  });
                                  setMarkerToCurrentLocation();
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondary,
                            disabledBackgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.black,
                            disabledForegroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusGeometry.circular(0),
                            ),
                          ),
                          child: Text('Static Mode'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: FilledButton(
                          onPressed: mode == LIVE_MODE
                              ? null
                              : () {
                                  if (locationServiceActive) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Please stop location service before switching modes',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    mode = LIVE_MODE;
                                  });
                                  setMarkerToCurrentLocation();
                                },
                          onLongPress: null,
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondary,
                            disabledBackgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.black,
                            disabledForegroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusGeometry.circular(0),
                            ),
                          ),
                          child: Text('Live Mode'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: double.infinity,
                  width: MediaQuery.sizeOf(context).width * 0.8,
                  child: Stack(
                    children: [
                      map,
                      Container(
                        margin: EdgeInsets.all(20),
                        alignment: Alignment(1, 1),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                setMarkerToCurrentLocation();
                              },
                              label: Icon(Icons.my_location_outlined),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                if (!isMapReady) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Loading the map.. please wait a few seconds',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (!trackingEnabled) {
                                  await controller.enableTracking(
                                    enableStopFollow: false,
                                  );
                                } else {
                                  await controller.disabledTracking();
                                }
                                setState(() {
                                  trackingEnabled = !trackingEnabled;
                                });
                              },
                              label: Icon(
                                Icons.track_changes,
                                color: trackingEnabled
                                    ? Colors.blueAccent
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.white),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: actions,
                ),
              ),
              DataTable(
                columns: [
                  DataColumn(label: Text('Latitude')),
                  DataColumn(label: Text('Longitude')),
                ],
                rows: [
                  DataRow(
                    cells: [
                      DataCell(
                        Text(
                          '${mode == STATIC_MODE ? location?.latitude : liveLocation?.latitude}',
                        ),
                      ),
                      DataCell(
                        Text(
                          '${mode == STATIC_MODE ? location?.longitude : liveLocation?.longitude}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    
    // controller.addObserver(this);
    final user = FirebaseAuth.instance.currentUser;

    final vendor = <String, dynamic>{
      "name": "Demo Vendor",
      "uid": user?.uid,
      "position": <String, double?>{
        "latitude": location?.latitude,
        "longitude": location?.longitude,
      },
    };
    print(user);
    return user == null ? SignInPage() : setLocationPage();
  }

  void setMarkerToCurrentLocation() {
    controller.myLocation().then((value) {
      print(' startup, detecting mylocation, $value');

      if (location != null) {
        controller.removeMarker(location!);
      }

      if (liveLocation != null) {
        controller.removeMarker(liveLocation!);
      }

      controller.addMarker(value);
      setState(() {
        if (mode == STATIC_MODE) {
          location = value;
        } else if (mode == LIVE_MODE) {
          liveLocation = value;
        }
      });
    });
  }

  @override
  Future<void> mapIsReady(Object isReady) async {
    isMapReady = true;
    if (!disableNextAutoLocationUpdate) {
      setMarkerToCurrentLocation();
    } else {
      setState(() {
        disableNextAutoLocationUpdate = false;
      });
    }
    return Future(() => print('map is ready!'));
  }

  @override
  void onSingleTap(GeoPoint position) {
    super.onSingleTap(position);
    if (location != null) {
      controller.removeMarker(location!);
    }
    if (liveLocation != null) {
      controller.removeMarker(liveLocation!);
    }
    controller.addMarker(position);
    setState(() {
      if (mode == STATIC_MODE) {
        location = position;
      } else if (mode == LIVE_MODE) {
        liveLocation = position;
      }
    });
  }
}
