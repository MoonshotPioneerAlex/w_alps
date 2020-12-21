import 'package:w_alps/main.dart';
import 'package:flutter/foundation.dart';

import 'DataEntry.dart';

class TableDataNotifier with ChangeNotifier {
  TableDataNotifier() {
    fetchData();
  }

  List<DataEntry> get userModel => _userModel;

  // SORT COLUMN INDEX...

  int get sortColumnIndex => _sortColumnIndex;

  set sortColumnIndex(int sortColumnIndex) {
    _sortColumnIndex = sortColumnIndex;
    notifyListeners();
  }

  // SORT ASCENDING....

  bool get sortAscending => _sortAscending;

  set sortAscending(bool sortAscending) {
    _sortAscending = sortAscending;
    notifyListeners();
  }

  int get rowsPerPage => _rowsPerPage;

  set rowsPerPage(int rowsPerPage) {
    _rowsPerPage = rowsPerPage;
    notifyListeners();
  }

  // -------------------------------------- INTERNALS --------------------------------------------

  var _userModel = <DataEntry>[];

  int _sortColumnIndex;
  bool _sortAscending = true;

  // int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int _rowsPerPage = 10;

  Future<void> fetchData({List<MyTaggable> depositFilter, List<MyTaggable> methodFilter, String depositFieldName}) async {
    //_userModel = await Model.fetchSampleData(depositFilter: depositFilter, depositFieldName: depositFieldName);
    notifyListeners();
  }
}
