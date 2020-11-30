import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:w_alps/table/DataEntry.dart';
import 'package:flutter/material.dart';

import 'Model.dart';

typedef OnRowSelect = void Function(DocumentSnapshot document);

class SampleDataTableSource extends DataTableSource {
  SampleDataTableSource({
    @required List<DataEntry> sampleData,
    @required this.onRowSelect,
    @required this.context,
  })  : _sampleData = sampleData,
        assert(sampleData != null);

  final List<DataEntry> _sampleData;
  final OnRowSelect onRowSelect;
  BuildContext context;

  @override
  DataRow getRow(int index) {
    assert(index >= 0);

    if (index >= _sampleData.length) {
      return null;
    }

    final _sample = _sampleData[index];
    var fieldSequence = _sampleData[0].ref.data.keys.toList();
    fieldSequence.sort((a,b) => a.compareTo(b));

    return DataRow.byIndex(
      index: index,
      onSelectChanged: (value) => onRowSelect(_sample.ref),
      cells: fieldSequence
          .map<DataCell>(
            (e) => DataCell(
              Text(
                Model.getValue(_sample.ref[e.toString()]),
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _sampleData.length;

  @override
  int get selectedRowCount => 0;

  /*
   *
   * Sorts this list according to the order specified by the [compare] function.
    The [compare] function must act as a [Comparator].
    List<String> numbers = ['two', 'three', 'four'];
// Sort from shortest to longest.
    numbers.sort((a, b) => a.length.compareTo(b.length));
    print(numbers);  // [two, four, three]
    The default List implementations use [Comparable.compare] if [compare] is omitted.
    List<int> nums = [13, 2, -11];
    nums.sort();
    print(nums);  // [-11, 2, 13]
   */
  void sort<T>(Comparable<T> Function(DataEntry d) getField, bool ascending) {
    _sampleData.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
    });

    notifyListeners();
  }
}
