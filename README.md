# sabzi_wala_app

An app to enable discoery of cart vendors to increase their reachability whether they're stationary or mobile.

- A Flutter app, currently targeted for android only.
- Deeplinks and Firebase authentication enabling sign in by email link 
- Firebase FireStore to store static locations
- Firebase realtime db to store live locations
- Foreground service to get location updates for live location
- Only sensitive data stored is email for authentication, enabling loose security rules on location stores, i.e. firestore and realtime db, inherently mitigating privacy and security risks

- Discover live location of vendors broadcasting their location
- Discover static location of vendors broadcasting their static position
- time limited positions to allow for clean up of stale information
