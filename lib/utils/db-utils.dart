import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class DbUtils{

  static FirebaseFirestore getFirestoreDb(){
    return FirebaseFirestore.instance;
  }

  static addOrUpdateToFirestore(data, collectionName) async {

    var timestamp = DateTime.now();
    timestamp = timestamp.toUtc();

    await getFirestoreDb().collection(collectionName).doc(data["uid"]).set({...data, "timestamp": timestamp.toIso8601String()})
    .then(
      (value) => print('Successfully added data to $collectionName'),
      onError: (error) => print('Error encountered trying to add data to firestore collection $collectionName: $error'));
  }

  static FirebaseDatabase getRealtimeDb(){
    return FirebaseDatabase.instance;
  }

  static addorUpdataToRealtime(data, key) async{

    var timestamp = DateTime.now();
    timestamp = timestamp.toUtc();
    try{
      await getRealtimeDb().ref(key).set({...data, "timestamp": timestamp.toIso8601String()});
    }
    catch(error){
      print('Error encountererd trying to save to realtime db: $error');
    }
    print('Successfully saved data to $key');
  }

  static removeFromRealtime(uid){
    getRealtimeDb().ref(uid).remove();
  }

  static updateRealtimePosition(uid, position){
    var updates = {'position': position};
    getRealtimeDb().ref(uid).update(updates);
  }

  static getFirestoreRow(uid, collectionName) async {
    final row = await getFirestoreDb().collection(collectionName).doc(uid).get();
    return row.data();
  }

  static getRealtimeValue(uid) async {
    final val = await getRealtimeDb().ref(uid).get();
    return val.value;
  }

  static Future<List<QueryDocumentSnapshot<Object?>>> getActiveStaticVendors() async {
    final QuerySnapshot querySnapshot = await getFirestoreDb().collection('vendors').where('time_in_hours', isGreaterThan: 0).get();
    final docs = querySnapshot.docs;
    return docs;
  }

  static Future<DatabaseReference> getActiveLiveVendors() async {
    return getRealtimeDb().ref();
  }
}