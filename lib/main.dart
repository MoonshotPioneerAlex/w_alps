import 'dart:async';
import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase/firebase.dart' as fb;
import 'package:w_alps/constants.dart';
import 'package:w_alps/table/LoginHelper.dart';
import 'package:w_alps/table/Model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:flutter_tagging/flutter_tagging.dart';
import 'package:photo_view/photo_view.dart';
import 'package:sortedmap/sortedmap.dart';
import 'package:path/path.dart' as Path;
import 'package:universal_html/prefer_universal/html.dart' as html;

import 'navigation_drawer/collapsing_nav_drawer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'W Alps',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the con/Users/alex/development/flutter/bin/fluttersole where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blueGrey,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder<AuthResult>(
        future: FirebaseAuth.instance.signInAnonymously(),
        builder: (BuildContext context, AsyncSnapshot<AuthResult> snapshot) {
          if (snapshot.hasData) {
            return MyHomePage(title: 'W Alps');
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Widget _myAnimatedWidget;

  bool tableDropZoneHighlighted = false;

  DropzoneViewController _depositFileDropController;

  bool _detailDropZoneHighlighted = false;
  List<String> _currentlyUploadingFiles = new List();

  bool _showDetailPane = false;
  DocumentSnapshot _detailDocument;

  @override
  Widget build(BuildContext context) {
    if (_myAnimatedWidget == null) changeContentWidget(0);
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CollapsingNavigationDrawer(
            onListItemPress: changeContentWidget,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(4.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _myAnimatedWidget,
              ),
            ),
          ),
          Visibility(
            visible: _showDetailPane,
            child: SizedBox(
              width: 800,
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 4.0, right: 4.0),
                child: IntrinsicWidth(
                  child: Card(
                    elevation: _detailDropZoneHighlighted ? 5.0 : 1.0,
                    color: _detailDropZoneHighlighted ? Colors.blueGrey[50] : null,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16.0),
                          color: Colors.blueGrey[50],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Details " + (_detailDocument != null ? _detailDocument.documentID : "")),
                              InkWell(
                                child: Icon(
                                  Icons.close,
                                  size: 20.0,
                                ),
                                onTap: closeDetailPane,
                              )
                            ],
                          ),
                        ),
                        Expanded(
                          child: FutureBuilder<List<Widget>>(
                            future: getDetailPaneSlivers(_detailDocument),
                            builder: (context, snapshot) {
                              if (snapshot.hasData)
                                return CustomScrollView(shrinkWrap: false, slivers: snapshot.data);
                              else
                                return SizedBox();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  List<Widget> buildImageCollectionViewer(String title, {String collectionName}) {
    return [
      SliverToBoxAdapter(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.0),
          color: Colors.blueGrey[100],
          child: Text(title),
        ),
      ),
      LoginHelper.adminModeActive
          ? SliverPadding(
              padding: const EdgeInsets.all(8.0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  height: 50,
                  decoration: new BoxDecoration(
                    borderRadius: new BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Colors.blueGrey[100], Colors.blueGrey[200]],
                    ),
                  ),
                  child: Stack(
                    children: [
                      DropzoneView(
                        operation: DragOperation.all,
                        cursor: CursorType.grab,
                        onHover: () {
                          setState(() => _detailDropZoneHighlighted = true);
                        },
                        onLeave: () {
                          setState(() => _detailDropZoneHighlighted = false);
                        },
                        onDrop: (ev) async {
                          var fileName = ev.name;

                          if (_currentlyUploadingFiles != null && _currentlyUploadingFiles.contains(fileName)) return;

                          _currentlyUploadingFiles.add(fileName);
                          print(title + ' drop: ' + fileName);

                          await uploadHTMLFile(ev, collectionName, _detailDocument.reference.path);

                          setState(() {
                            _detailDropZoneHighlighted = false;
                            _currentlyUploadingFiles.remove(fileName);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(fileName + ' successfully uploaded'),
                            ),
                          );
                        },
                      ),
                      Center(child: Text(title + "-Upload Zone")),
                    ],
                  ),
                ),
              ),
            )
          : SliverToBoxAdapter(),
      getImageSliverGrid(_detailDocument, collectionName, true)
    ];
  }

  getImageSliverGrid(DocumentSnapshot documentSnapshot, String collectionName, bool returnEmptyScreen) {
    return documentSnapshot != null
        ? StreamBuilder(
            stream: Firestore.instance.document(documentSnapshot.reference.path).collection(collectionName).snapshots(),
            builder: (context, snapshots) {
              if (snapshots.hasData) {
                if (snapshots.data.documents.length > 0) {
                  return SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: kImageViewGridColumnsCount,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      delegate: SliverChildListDelegate(
                        snapshots.data.documents
                            .map<Widget>(
                              (document) => InkWell(
                                child: Image.network(
                                  document[kDocumentFieldUrl],
                                  fit: BoxFit.cover,
                                ),
                                onTap: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      child: PhotoView(
                                        backgroundDecoration: BoxDecoration(color: Colors.white),
                                        imageProvider: NetworkImage(document[kDocumentFieldUrl]),
                                      ),
                                    ),
                                  );
                                },
                                onLongPress: LoginHelper.adminModeActive
                                    ? () {
                                        showDeleteConfirmationDialog(context, () {
                                          Firestore.instance.document(document.reference.path).delete();
                                          deleteFile(collectionName, document[kDocumentFieldFileName]);
                                          Navigator.pop(context);
                                        });
                                      }
                                    : null,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  );
                } else if (returnEmptyScreen) {
                  return SliverToBoxAdapter(
                    child: ListTile(
                      title: Text(
                        "No Images",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                } else {
                  return SliverToBoxAdapter(child: SizedBox());
                }
              } else {
                return SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
          )
        : SliverToBoxAdapter(child: SizedBox());
  }

  List<Widget> buildDocumentCollectionViewer() {
    return [
      SliverToBoxAdapter(
        child: Container(
          padding: EdgeInsets.all(16.0),
          color: Colors.blueGrey[100],
          child: Text("Documents"),
        ),
      ),
    LoginHelper.adminModeActive
    ? SliverPadding(
        padding: const EdgeInsets.all(8.0),
        sliver: SliverToBoxAdapter(
          child: Container(
                  height: 50,
                  decoration: new BoxDecoration(
                    borderRadius: new BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Colors.blueGrey[100], Colors.blueGrey[200]],
                    ),
                  ),
                  child: Stack(
                    children: [
                      DropzoneView(
                          operation: DragOperation.all,
                          cursor: CursorType.grab,
                          onHover: () {
                            setState(() => _detailDropZoneHighlighted = true);
                          },
                          onLeave: () {
                            setState(() => _detailDropZoneHighlighted = false);
                          },
                          onDrop: (ev) async {
                            var fileName = ev.name;

                            if (_currentlyUploadingFiles != null && _currentlyUploadingFiles.contains(fileName)) return;
                            _currentlyUploadingFiles.add(fileName);

                            print('Dokumenten drop: ' + fileName);

                            await uploadHTMLFile(ev, kDocumentsCollectionName, _detailDocument.reference.path);

                            setState(() {
                              _detailDropZoneHighlighted = false;
                              _currentlyUploadingFiles.remove(fileName);
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(fileName + ' successfully uploaded'),
                              ),
                            );
                          }),
                      Center(child: Text("Document-Upload Zone")),
                    ],
                  ),
                ),
        ),
      ) : SliverToBoxAdapter(),
      _detailDocument != null
          ? StreamBuilder(
              stream: Firestore.instance
                  .document(_detailDocument.reference.path)
                  .collection(kDocumentsCollectionName)
                  .snapshots(),
              builder: (context, snapshots) {
                if (snapshots.hasData) {
                  if (snapshots.data.documents.length > 0) {
                    return SliverPadding(
                      padding: const EdgeInsets.all(8.0),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: kDocumentViewGridColumnsCount,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        delegate: SliverChildListDelegate(
                          snapshots.data.documents
                              .map<Widget>(
                                (document) => InkWell(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Icon(
                                        Icons.insert_drive_file,
                                        size: 40,
                                        color: Colors.black54,
                                      ),
                                      Text(
                                        document[kDocumentFieldName],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 8),
                                      ),
                                    ],
                                  ),
                                  onTap: () => downloadFile(document[kDocumentFieldUrl], document[kDocumentFieldName]),
                                  onLongPress: LoginHelper.adminModeActive
                                      ? () {
                                          showDeleteConfirmationDialog(context, () {
                                            Firestore.instance.document(document.reference.path).delete();
                                            deleteFile(kDocumentsCollectionName, document[kDocumentFieldFileName]);
                                            Navigator.pop(context);
                                          });
                                        }
                                      : null,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    );
                  } else {
                    return SliverToBoxAdapter(
                      child: ListTile(
                        title: Text(
                          "No Documents",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                } else {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              },
            )
          : SliverToBoxAdapter(
              child: SizedBox(),
            )
    ];
  }

  static showDeleteConfirmationDialog(BuildContext context, Function confirmAction) {
    // set up the buttons
    Widget cancelButton = FlatButton(
      child: Text("Cancel"),
      onPressed: () => Navigator.pop(context),
    );
    Widget continueButton = FlatButton(
      child: Text(
        "Delete",
        style: TextStyle(color: Colors.redAccent),
      ),
      onPressed: confirmAction,
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Are you sure?"),
      content: Text("Do you really want to delete this file?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  _startFilePicker() async {
    InputElement uploadInput = FileUploadInputElement();
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      // read file content as dataURL
      final files = uploadInput.files;
      if (files.length == 1) {
        final file = files[0];
        FileReader reader = FileReader();

        reader.onLoadEnd.listen((e) {
          setState(() {
            var uploadedImage = reader.result;
            var test = "";
          });
        });

        reader.onError.listen((fileEvent) {
          setState(() {
            print("Some Error occured while reading the file");
          });
        });

        reader.readAsArrayBuffer(file);
      }
    });
  }

  uploadHTMLFile(file, String storageName, String originalDocumentPath) async {
    var fileName = Path.basename(DateTime.now().millisecondsSinceEpoch.toString() + "_" + file.name);

    fb.StorageReference storageRef = fb.storage().ref(storageName + "/" + fileName);

    await storageRef.put(file).future.then(
          (uploadTaskSnapshot) => uploadTaskSnapshot.ref.getDownloadURL().then(
            (url) {
              if (originalDocumentPath != "")
                Firestore.instance.document(originalDocumentPath).collection(storageName).add(
                  {
                    kDocumentFieldUrl: url.toString(),
                    kDocumentFieldName: file.name.toString(),
                    kDocumentFieldFileName: fileName
                  },
                );
            },
          ),
        );

    // Uri url = await uploadTaskSnapshot.ref.getDownloadURL();
    //
    // if (originalDocumentPath != "") {
    //   Firestore.instance.document(originalDocumentPath).collection(storageName).add(
    //     {
    //       'url': url.toString(),
    //       'name': file.name.toString(),
    //     },
    //   );
    // }
    //
    // return url;
  }

  deleteFile(String storageName, String fileName) async {
    fb.storage().ref(storageName).child(fileName).delete();
  }

  void downloadFile(String url, String fileName) {
    html.AnchorElement anchorElement = new html.AnchorElement()..href = url;
    anchorElement.download = url;
    anchorElement.target = "_blank";
    anchorElement.click();
  }

  void changeContentWidget(int widgetIndex) {
    closeDetailPane();

    switch (widgetIndex) {
      case 0:
        setState(() {
          _myAnimatedWidget = Container(
            child: DepositContentWidget(
              parentState: this,
            ),
          );
        });
        break;

      case 1:
        setState(() {
          _myAnimatedWidget = Container(
            child: SampleContentWidget(
              parentState: this,
            ),
          );
        });
        break;
    }
  }

  void setDetail(DocumentSnapshot document) {
    setState(() {
      _showDetailPane = true;
      _detailDocument = document;
    });
  }

  void closeDetailPane() {
    setState(() {
      _showDetailPane = false;
    });
  }

  List<Widget> buildWidgetForDocument(DocumentSnapshot document) {
    if (document != null) {
      return SortedMap.from(document.data).entries.map<Widget>((entry) {
        if (entry.key.toString().contains("Deposit")) {
          return FutureBuilder(
            future: Firestore.instance.collection(kDepositCollectionName).document(entry.value.toString()).get(),
            builder: (context, snapshot) {
              if (snapshot.hasData)
                return ExpansionTile(
                  title: Text(Model.formatColumnName(entry.key.toString()) + " " + entry.value.toString()),
                  childrenPadding: const EdgeInsets.only(left: 16.0),
                  children: buildWidgetForDocument(snapshot.data),
                );
              else
                return SizedBox();
            },
          );
        } else {
          return TextFormField(
            controller: TextEditingController(text: Model.getValue(entry.value)),
            readOnly: true,
            decoration: new InputDecoration(
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              labelText: Model.formatColumnName(entry.key.toString()),
            ),
          );
        }
      }).toList();
    } else {
      return [
        ListTile(
          title: Text("No Data"),
        )
      ];
    }
  }

  Future<List<Widget>> getDetailPaneSlivers(DocumentSnapshot document) async {
    List<Widget> slivers = [
      SliverPadding(
        padding: EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildListDelegate(
            buildWidgetForDocument(_detailDocument),
          ),
        ),
      ),
    ];

    List<DocumentSnapshot> sampleDocs;
    if (document != null && document.reference.path.contains("deposit")) {
      sampleDocs = (await Firestore.instance
              .collection(kSampleCollectionName)
              .where(kDepositColumnName, isEqualTo: document.reference.documentID)
              .getDocuments())
          .documents;
    }

    slivers.addAll(buildImageCollectionViewer("Images", collectionName: kImageCollectionName));
    if (sampleDocs != null && sampleDocs.length > 0) {
      sampleDocs.forEach((sampleDoc) {
        slivers.addAll(getSubImageCollectionViewer(sampleDoc.reference.documentID, sampleDoc, kImageCollectionName));
      });
    }

    slivers.addAll(buildImageCollectionViewer("EMPA Analysis", collectionName: kEMPAImagesCollectionName));
    if (sampleDocs != null && sampleDocs.length > 0) {
      sampleDocs.forEach((sampleDoc) {
        slivers
            .addAll(getSubImageCollectionViewer(sampleDoc.reference.documentID, sampleDoc, kEMPAImagesCollectionName));
      });
    }

    slivers.addAll(buildImageCollectionViewer("LA-ICP-MS Analysis", collectionName: kLAICPMSImagesCollectionName));
    if (sampleDocs != null && sampleDocs.length > 0) {
      sampleDocs.forEach((sampleDoc) {
        slivers.addAll(
            getSubImageCollectionViewer(sampleDoc.reference.documentID, sampleDoc, kLAICPMSImagesCollectionName));
      });
    }

    slivers.addAll(buildDocumentCollectionViewer());

    return slivers;
  }

  List<Widget> getSubImageCollectionViewer(String title, DocumentSnapshot document, String collectionName) {
    List<Widget> list = new List();

    list.add(
      StreamBuilder(
        stream: Firestore.instance.document(document.reference.path).collection(collectionName).snapshots(),
        builder: (context, snapshots) {
          if (snapshots.hasData) {
            if (snapshots.data.documents.length > 0) {
              return SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.0),
                  child: Text(title),
                ),
              );
            }
          }
          return SliverToBoxAdapter(
            child: SizedBox(),
          );
        },
      ),
    );

    var grid = getImageSliverGrid(document, collectionName, false);

    if (grid == null) {
      return null;
    }

    list.add(grid);

    return list;
  }
}

class SampleContentWidget extends StatefulWidget {
  SampleContentWidget({Key key, this.parentState}) : super(key: key);

  final _MyHomePageState parentState;

  @override
  SampleContentWidgetState createState() => SampleContentWidgetState();
}

class SampleContentWidgetState extends State<SampleContentWidget> {
  List<MyTaggable> _depositFilter = [];

  bool _tableDropZoneHighlighted = false;
  String _currentlyUploadingFile = "";

  bool _sortAsc = true;
  int _sortColumnIndex = 0;
  List<String> fieldSequence;

  static Future<List<MyTaggable>> getSuggestions(String collectionName, String query) async {
    var snapshot = await Firestore.instance.collection(collectionName).getDocuments();

    return snapshot.documents
        .map(
          (e) => MyTaggable(
            id: e.reference,
            name: e.documentID,
          ),
        )
        .where((tag) => tag.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: _tableDropZoneHighlighted ? 5.0 : 1.0,
      color: _tableDropZoneHighlighted ? Colors.blueGrey[50] : null,
      child: FutureBuilder(
        future: Model.fetchSampleData(
          depositFilter: _depositFilter,
          depositFieldName: kDepositColumnName,
          orderBy: fieldSequence == null ? "0#ID" : fieldSequence[_sortColumnIndex].toString(),
          orderAsc: _sortAsc,
        ),
        builder: (BuildContext context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) return Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: SelectableText(snapshot.error.toString()));

          if (fieldSequence == null && snapshot.hasData && snapshot.data.length > 0) {
            fieldSequence = snapshot.data[0].data.keys.toList();
            fieldSequence.sort((a, b) => a.toString().compareTo(b.toString()));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  "Samples " + (snapshot.data != null ? "(" + snapshot.data.length.toString() + ")" : ""),
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  getMultiComboBoxFilter("Deposit", _depositFilter,
                      (query) => getSuggestions(kDepositCollectionName, query), () => setState(() {})),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Tooltip(
                      message: "Reset Filter",
                      child: MaterialButton(
                        height: 58,
                        child: Icon(Icons.settings_backup_restore),
                        onPressed: () => setState(() {
                          _depositFilter.clear();
                        }),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Stack(
                  children: [
                    LoginHelper.adminModeActive
                        ? DropzoneView(
                            onCreated: (ctrl) => widget.parentState._depositFileDropController = ctrl,
                            operation: DragOperation.all,
                            cursor: CursorType.grab,
                            onHover: () => setState(() => _tableDropZoneHighlighted = true),
                            onLeave: () => setState(() => _tableDropZoneHighlighted = false),
                            onDrop: (ev) async {
                              var fileName = ev.name;

                              if (fileName == _currentlyUploadingFile) return;

                              print('CSV drop: ${ev.name}');
                              _currentlyUploadingFile = fileName;

                              var fileData = await widget.parentState._depositFileDropController.getFileData(ev);
                              String string = String.fromCharCodes(fileData);

                              await Model.importCSVData(string, kSampleCollectionName);

                              setState(() {
                                _tableDropZoneHighlighted = false;
                                _currentlyUploadingFile = "";
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(fileName + ' successfully uploaded'),
                                ),
                              );
                            },
                          )
                        : SizedBox(),
                    snapshot.data == null || snapshot.data.length == 0
                        ? Center(
                            child: Text('No Data'),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: DataTable(
                                  showCheckboxColumn: false,
                                  sortColumnIndex: _sortColumnIndex,
                                  sortAscending: _sortAsc,
                                  columns: getDataColumns4Document(fieldSequence),
                                  rows: snapshot.data.map((DocumentSnapshot documentSnapshot) {
                                    return getDataRowForDocument(documentSnapshot, fieldSequence);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // return Card(
    //   elevation: _tableDropZoneHighlighted ? 5.0 : 1.0,
    //   color: _tableDropZoneHighlighted ? Colors.blueGrey[50] : null,
    //   child: Column(
    //     children: [
    //       Row(
    //         mainAxisAlignment: MainAxisAlignment.start,
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         children: [
    //           getMultiComboBoxFilter(
    //             "Deposit",
    //             _depositFilter,
    //             (query) => getSuggestions(kDepositCollectionName, query),
    //             () {
    //               widget.parentState.setState(() {
    //                 _provider.fetchData(depositFilter: _depositFilter, depositFieldName: '1#Deposit');
    //               });
    //             },
    //           ),
    //           Padding(
    //             padding: const EdgeInsets.all(8.0),
    //             child: Tooltip(
    //               message: "Reset Filter",
    //               child: MaterialButton(
    //                 height: 58,
    //                 child: Icon(Icons.settings_backup_restore),
    //                 onPressed: () => widget.parentState.setState(() {
    //                   _depositFilter.clear();
    //                   _methodFilter.clear();
    //                   _provider.fetchData(depositFilter: _depositFilter, methodFilter: _methodFilter);
    //                 }),
    //               ),
    //             ),
    //           ),
    //         ],
    //       ),
    //       Expanded(
    //         child: Stack(
    //           children: <Widget>[
    //             DropzoneView(
    //               onCreated: (ctrl) => widget.parentState._depositFileDropController = ctrl,
    //               operation: DragOperation.all,
    //               cursor: CursorType.grab,
    //               onHover: () => setState(() => _tableDropZoneHighlighted = true),
    //               onLeave: () => setState(() => _tableDropZoneHighlighted = false),
    //               onDrop: (ev) async {
    //                 var fileName = ev.name;
    //
    //                 if (fileName == _currentlyUploadingFile) return;
    //
    //                 print('CSV drop: ${ev.name}');
    //
    //                 var fileData = await widget.parentState._depositFileDropController.getFileData(ev);
    //                 String string = String.fromCharCodes(fileData);
    //
    //                 await Model.importCSVData(string, kSampleCollectionName);
    //
    //                 setState(() {
    //                   _tableDropZoneHighlighted = false;
    //                   _currentlyUploadingFile = "";
    //                 });
    //
    //                 ScaffoldMessenger.of(context).showSnackBar(
    //                   SnackBar(
    //                     content: Text('File successfully uploaded'),
    //                   ),
    //                 );
    //               },
    //             ),
    //             _model.isNotEmpty
    //                 ? PaginatedDataTable(
    //                     header: Text("Samples (" + _model.length.toString() + ")"),
    //                     sortColumnIndex: _provider.sortColumnIndex,
    //                     sortAscending: _provider.sortAscending,
    //                     rowsPerPage: _provider.rowsPerPage,
    //                     availableRowsPerPage: [5, 10],
    //                     onRowsPerPageChanged: (index) => _provider.rowsPerPage = index,
    //                     showCheckboxColumn: false,
    //                     columns: getSampleColumns4Document(_model[0], _dtSource, _provider),
    //                     source: _dtSource,
    //                   )
    //                 : Card(
    //                     child: Center(
    //                       child: Text(
    //                         "No Data. Please adjust Filter.",
    //                       ),
    //                     ),
    //                   ),
    //           ],
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }

  void onRowSelect(DocumentSnapshot document) {
    widget.parentState.setDetail(document);
  }

  getMultiComboBoxFilter(
      String label, List<MyTaggable> list, Function(String) findSuggestionsCallback, Function onChangedCallback) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FlutterTagging<MyTaggable>(
          initialItems: list,
          hideOnEmpty: true,
          suggestionsBoxConfiguration: SuggestionsBoxConfiguration(
            suggestionsBoxVerticalOffset: 0,
          ),
          textFieldConfiguration: TextFieldConfiguration(
            decoration: InputDecoration(
              filled: true,
              hintText: 'Tippen um Vorschlagswerte einzuschränken',
              labelText: label + ' Filter',
            ),
          ),
          findSuggestions: findSuggestionsCallback,
          configureSuggestion: (tag) {
            return SuggestionConfiguration(
              title: Text(tag.name.toString()),
              // subtitle: Text(tag.position.toString()),
            );
          },
          configureChip: (tag) {
            return ChipConfiguration(
              label: Text(tag.name),
              deleteIconColor: Colors.blueGrey,
              materialTapTargetSize: MaterialTapTargetSize.padded,
            );
          },
          onChanged: onChangedCallback,
          enableImmediateSuggestion: true,
        ),
      ),
    );
  }

  DataRow getDataRowForDocument(DocumentSnapshot document, Iterable<String> fieldSequence) {
    return DataRow(
      onSelectChanged: (bool) => onRowSelect(document),
      cells: fieldSequence
          .map<DataCell>(
            (e) => DataCell(Text(Model.getValue(document.data[e]))),
          )
          .toList()
            ..add(
              DataCell(
                LoginHelper.adminModeActive
                    ? FlatButton(
                        child: Icon(
                          Icons.clear,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _MyHomePageState.showDeleteConfirmationDialog(context, () {
                          Firestore.instance.document(document.reference.path).delete();
                          Navigator.pop(context);
                        }),
                      )
                    : SizedBox(),
              ),
            ),
    );
  }

  List<DataColumn> getDataColumns4Document(Iterable<String> fieldSequence) {
    return fieldSequence
        .map<DataColumn>(
          (e) => DataColumn(
            label: Text(Model.formatColumnName(e)),
            onSort: (colIndex, asc) {
              setState(() {
                _sortColumnIndex = colIndex;
                _sortAsc = asc;
              });
            },
          ),
        )
        .toList()
          ..add(
            DataColumn(
              label: Text(''),
            ),
          );
  }
}

class DepositContentWidget extends StatefulWidget {
  DepositContentWidget({Key key, this.parentState}) : super(key: key);

  final _MyHomePageState parentState;

  @override
  DepositContentWidgetState createState() => DepositContentWidgetState();
}

class DepositContentWidgetState extends State<DepositContentWidget> {
  DropzoneViewController _depositFileDropController;
  bool _tableDropZoneHighlighted = false;
  String _currentlyUploadingFile = "";
  bool _sortAsc = true;
  int _sortColumnIndex = 0;
  List<String> fieldSequence;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: _tableDropZoneHighlighted ? 5.0 : 1.0,
      color: _tableDropZoneHighlighted ? Colors.blueGrey[50] : null,
      child: StreamBuilder(
        stream: Firestore.instance
            .collection(kDepositCollectionName)
            .orderBy(fieldSequence == null ? "0#ID" : fieldSequence[_sortColumnIndex].toString(), descending: !_sortAsc)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) return Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: SelectableText(snapshot.error.toString()));

          if (fieldSequence == null && snapshot.hasData && snapshot.data.documents.length > 0) {
            fieldSequence = snapshot.data.documents[0].data.keys.toList();
            fieldSequence.sort((a, b) => a.toString().compareTo(b.toString()));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  "Deposits (" + snapshot.data.documents.length.toString() + ")",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LoginHelper.adminModeActive
                        ? DropzoneView(
                            onCreated: (ctrl) => _depositFileDropController = ctrl,
                            operation: DragOperation.all,
                            cursor: CursorType.grab,
                            onHover: () => setState(() => _tableDropZoneHighlighted = true),
                            onLeave: () => setState(() => _tableDropZoneHighlighted = false),
                            onDrop: (ev) async {
                              var fileName = ev.name;

                              if (fileName == _currentlyUploadingFile) return;
                              _currentlyUploadingFile = fileName;

                              print('CSV drop: ${ev.name}');

                              var fileData = await _depositFileDropController.getFileData(ev);
                              String string = String.fromCharCodes(fileData);

                              await Model.importCSVData(string, kDepositCollectionName);

                              setState(() {
                                _tableDropZoneHighlighted = false;
                                _currentlyUploadingFile = "";
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(fileName + ' successfully uploaded'),
                                ),
                              );
                            },
                          )
                        : SizedBox(),
                    snapshot.data.documents.length == 0
                        ? Center(child: Text('No Data'))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: DataTable(
                                  showCheckboxColumn: false,
                                  sortColumnIndex: _sortColumnIndex,
                                  sortAscending: _sortAsc,
                                  columns: getDataColumns4Document(fieldSequence),
                                  rows: snapshot.data.documents.map((DocumentSnapshot documentSnapshot) {
                                    return getDataRowForDocument(documentSnapshot, fieldSequence);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  DataRow getDataRowForDocument(DocumentSnapshot document, Iterable<String> fieldSequence) {
    return DataRow(
      onSelectChanged: (bool) => onRowSelect(document),
      cells: fieldSequence
          .map<DataCell>(
            (e) => DataCell(Text(Model.getValue(document.data[e]))),
          )
          .toList()
            ..add(
              DataCell(
                LoginHelper.adminModeActive
                    ? FlatButton(
                        child: Icon(
                          Icons.clear,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _MyHomePageState.showDeleteConfirmationDialog(
                          context,
                          () {
                            Firestore.instance.document(document.reference.path).delete();
                            Navigator.pop(context);
                          },
                        ),
                      )
                    : SizedBox(),
              ),
            ),
    );
  }

  void onRowSelect(DocumentSnapshot document) {
    widget.parentState.setDetail(document);
  }

  List<DataColumn> getDataColumns4Document(Iterable<String> fieldSequence) {
    return fieldSequence
        .map<DataColumn>(
          (e) => DataColumn(
            label: Text(Model.formatColumnName(e)),
            onSort: (colIndex, asc) {
              setState(() {
                _sortColumnIndex = colIndex;
                _sortAsc = asc;
              });
            },
          ),
        )
        .toList()
          ..add(
            DataColumn(
              label: Text(''),
            ),
          );
  }
}

// Filter List Object
class MyTaggable extends Taggable {
  final String name;
  DocumentReference id;

  // Creates Tag
  MyTaggable({
    this.id,
    this.name,
  });

  @override
  List<Object> get props => [name];
}
