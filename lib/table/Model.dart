import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:w_alps/constants.dart';
import 'package:w_alps/main.dart';

class Model {
  Model._();

  static Future<List<DocumentSnapshot>> fetchSampleData(
      {List<MyTaggable> depositFilter,
      // List<MyTaggable> methodFilter,
      String depositFieldName,
      String orderBy,
      bool orderAsc}) async {
    var lists = List<List<DocumentSnapshot>>();

    if (depositFilter != null && depositFilter.length > 0)
      lists.add(await fetchSampleDataWithFilter(
          filterName: depositFieldName, filterValues: depositFilter, orderBy: orderBy, orderAsc: orderAsc));

    // if (methodFilter != null && methodFilter.length > 0)
    //   lists.add(await fetchSampleDataWithFilter(filterName: kSampleFieldMethod, filterValues: methodFilter));

    if ((depositFilter == null || depositFilter.length == 0)) // && (methodFilter == null || methodFilter.length == 0))
      lists.add(await fetchSampleDataWithFilter(orderBy: orderBy, orderAsc: orderAsc));

    // count how much each result occurs in the various lists
    Map map = Map();
    for (List l in lists) {
      l.forEach((item) => map[item.reference.documentID] =
          map.containsKey(item.reference.documentID) ? (map[item.reference.documentID] + 1) : 1);
    }

    // if count == lists.count -> the result was returned by each query -> add to result
    var refs = map.keys.where((key) => map[key] == lists.length);

    // return all elements of the first list which is contained by the refs list
    return lists[0].where((element) => refs.contains(element.reference.documentID)).toList();
  }

  static Future<List<DocumentSnapshot>> fetchSampleDataWithFilter(
      {String filterName, List<MyTaggable> filterValues, String orderBy, bool orderAsc}) async {
    Query query = Firestore.instance.collection(kSampleCollectionName);

    if (filterValues != null && filterValues.length > 0) {
      query = query.where(filterName, whereIn: filterValues.map((e) => e.name).toList());
    }else{
      query = query.orderBy(orderBy, descending: !orderAsc);
    }

    var snapshot = await query.getDocuments();

    return snapshot.documents;
    // .map(
    //   (e) => DataEntry(
    //       name: e[kSampleFieldName],
    //       deposit: e[kSampleFieldDeposit],
    //       method: e[kSampleFieldMethod],
    //       ref: e,
    //       test: e[kSampleFieldTest]),
    // )
    //.toList();
  }

  static String getValue(data) {
    if (data is DocumentReference) {
      return data.documentID.toString();
    } else if (data is GeoPoint) {
      GeoPoint geoPoint = data;
      return "Lng: " + geoPoint.longitude.toString() + ", Lat: " + geoPoint.latitude.toString();
    } else {
      return data.toString();
    }
  }

  static String formatColumnName(String columnName) {
    return columnName.substring(columnName.indexOf('#') + 1);
  }

  static importCSVData(String csvString, String collectionName) async {
    List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter(
      fieldDelimiter: ';',
    ).convert(csvString);

    if (rowsAsListOfValues.length < 2) {
      return;
    }

    var headerList = rowsAsListOfValues[0];

    for (var i = 1; i < rowsAsListOfValues.length; i++) {
      var list = rowsAsListOfValues[i];
      Map<String, dynamic> data = new Map<String, dynamic>();
      list.asMap().forEach((key, value) {
        data[key.toString() + "#" + headerList[key]] = value;
      });

      await Firestore.instance.collection(collectionName).document(list[0]).setData(data);
    }
  }
}
