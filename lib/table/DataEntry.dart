import 'package:cloud_firestore/cloud_firestore.dart';

class DataEntry {
  DataEntry({this.name, this.deposit, this.method, this.ref, this.test});

  String name, depositName, methodName, test;
  DocumentReference deposit;
  DocumentReference method;
  DocumentSnapshot ref;
}
