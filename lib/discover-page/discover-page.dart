import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:sabzi_wala_app/main.dart';
import 'package:sabzi_wala_app/utils/db-utils.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => DiscoverPageState();
}

class DiscoverPageState extends State<DiscoverPage> {
  final MapController controller;
  final OSMFlutter map;
  bool trackingEnabled = false;

  factory DiscoverPageState() {
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

    return DiscoverPageState.state(controller, map);
  }

  DiscoverPageState.state(this.controller, this.map);

  Map<String, GeoPoint> markerLocations = {};

  @override
  void initState() {

    print("fetching current state of vendors");

    // DbUtils.getActiveStaticVendors().then((staticVendors){
    //   print(staticVendors);
    //   for(var staticVendor in staticVendors){
    //     final data = staticVendor.data();
    //       if(data is Map){
    //         final startTime = DateTime.fromMicrosecondsSinceEpoch(data["start_timestamp"].microsecondsSinceEpoch);
    //         if(DateTimeRange(start: startTime, end: DateTime.now()).duration.inHours < data["time_in_hours"]){
    //           final position = GeoPoint(latitude: data["position"]?["latitude"], longitude: data["position"]?["longitude"]);
    //           controller.addMarker(position); 
    //           markerLocations[data["uid"]] = position;
    //         }
    //       }
    //     print('here fetched data: $data');
    //     // controller.addMarker();
    //   }
    // });

    DbUtils.getFirestoreDb().collection('vendors').snapshots().listen((event) {                                                     //TODO: need to test this logic
      for (var docChange in event.docChanges) {
        final data = docChange.doc.data();
        if (data is Map && data != null) {
          if(markerLocations[data["uid"]]!= null){
            controller.removeMarker(markerLocations[data["uid"]]!);
          }

          final startTime = DateTime.fromMicrosecondsSinceEpoch(data["start_timestamp"].microsecondsSinceEpoch,);
          if (DateTimeRange(start: startTime, end: DateTime.now()).duration.inHours < data["time_in_hours"]
           && data["position"] != null && data["position"]["latitude"] != null && data["position"]["longitude"] != null) {                  //TODO: shouldn't be needed
            final position = GeoPoint(
              latitude: data["position"]["latitude"],
              longitude: data["position"]["longitude"],
            );
            controller.addMarker(position);
            markerLocations[data["uid"]] = position;
          }
          // if(markerLocations[])
        }
      }
      final updatedData = event.docChanges[0].doc.data();
      print(event);
    });


    final Map<String, GeoPoint> liveMarkerLocations = Map();
    final liveVendors = DbUtils.getActiveLiveVendors().then((dbRef){
      dbRef.onValue.listen((event){
        final vendors = event.snapshot.value;
        if(vendors is Map){
          final Map<String, GeoPoint> newLiveMarkers = Map();
          for(var vendor in vendors.keys){
            if(liveMarkerLocations[vendor] != null){
              controller.removeMarker(liveMarkerLocations[vendor]!);
              liveMarkerLocations.remove(vendor);
            }
            if(vendors[vendor]["position"] != null && vendors[vendor]["position"]["latitude"] != null && vendors[vendor]["position"]["longitude"] != null) {   
              final position = GeoPoint(
                latitude: vendors[vendor]["position"]?["latitude"],
                longitude: vendors[vendor]["position"]?["longitude"],
              );
              controller.addMarker(position);
              newLiveMarkers[vendors[vendor]["uid"]] = position;
            }
          }

          for(var vendor in liveMarkerLocations.keys){
            controller.removeMarker(liveMarkerLocations[vendor]!);
          }
          liveMarkerLocations.addAll(newLiveMarkers);
        }
        // event.snapshot.
        print(event);
      });
    });
    print(liveVendors);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return scaffoldWrapper(
      context,
      Container(
        padding: EdgeInsets.only(top: 20),
        alignment: Alignment(0, 0),
        color: Theme.of(context).colorScheme.secondaryFixed,
        child: Column(
          children: [
            Text(
              'Discover Vendors near you',
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
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: BoxBorder.all(
                  color: Colors.white,
                  width: 2,
                )),
                margin: EdgeInsets.only(top: 30, bottom: 50),
                child: SizedBox(
                  height: double.infinity,
                  width: MediaQuery.sizeOf(context).width * 0.9,
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
                                controller.currentLocation();
                              },
                              label: Icon(Icons.my_location_outlined),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
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
            ),
          ],
        ),
      ),
    );
  }
}
