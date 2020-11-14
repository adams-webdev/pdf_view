import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String pathPDF = "cards.pdf";
  // String landscapePathPdf = "";
  String remotePDFpath = "";
  // String corruptedPathPDF = "";

  @override
  void initState() {
    super.initState();
    // fromAsset('assets/corrupted.pdf', 'corrupted.pdf').then((f) {
    //   setState(() {
    //     corruptedPathPDF = f.path;
    //   });
    // });
    fromAsset('assets/cards.pdf', 'cards.pdf').then((f) {
      setState(() {
        pathPDF = f.path;
      });
    });
    // fromAsset('assets/demo-landscape.pdf', 'landscape.pdf').then((f) {
    //   setState(() {
    //     landscapePathPdf = f.path;
    //   });
    // });
    createFileOfPdfUrl().then((f) {
      setState(() {
        remotePDFpath = f.path;
      });
    });
  }

  Future<File> createFileOfPdfUrl() async {
    Completer<File> completer = Completer();
    print("Start download file from internet!");
    try {
      final url = "https://stephenadamsdesign.com/IASLC_f86dhrkwivyvbnwksiHDYensiYwjfh/img/staging.pdf";
      final filename = url.substring(url.lastIndexOf("/") + 1);
      var request = await HttpClient().getUrl(Uri.parse(url));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      var dir = await getApplicationDocumentsDirectory();
      print("Download files");
      print("${dir.path}/$filename");
      File file = File("${dir.path}/$filename");

      await file.writeAsBytes(bytes, flush: true);
      completer.complete(file);
    } catch (e) {
      throw Exception('Error parsing asset file!');
    }

    return completer.future;
  }

  Future<File> fromAsset(String asset, String filename) async {
    // To open from assets, you can copy them to the app storage folder, and the access them "locally"
    Completer<File> completer = Completer();

    try {
      var dir = await getApplicationDocumentsDirectory();
      File file = File("${dir.path}/$filename");
      var data = await rootBundle.load(asset);
      var bytes = data.buffer.asUint8List();
      await file.writeAsBytes(bytes, flush: true);
      completer.complete(file);
    } catch (e) {
      throw Exception('Error parsing asset file!');
    }

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IASLC Staging Cards',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.blue[900],
        appBar: AppBar(title: const Text('Staging Cards Contents'),
          backgroundColor: Colors.blue[900],
        ),
        body: Center(child: Builder(
          builder: (BuildContext context) {
            return ListView(
              children: <Widget>[
                RaisedButton(
                  child: Text("Open Staging Cards"),
                  onPressed: () {
                    if (pathPDF != null || pathPDF.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PDFScreen(path: pathPDF),
                        ),
                      );
                    }
                  },
                ),
                // ListTile(
                //   title: Text("Open Landscape PDF"),
                //   onTap: () {
                //     if (landscapePathPdf != null || landscapePathPdf.isNotEmpty) {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) => PDFScreen(path: landscapePathPdf),
                //         ),
                //       );
                //     }
                //   },
                // ),
                // ListTile(
                //   title: Text("Download PDF"),
                //   onTap: () {
                //     if (remotePDFpath != null || remotePDFpath.isNotEmpty) {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) => PDFScreen(path: remotePDFpath),
                //         ),
                //       );
                //     }
                //   },
                // ),
                // RaisedButton(
                //   child: Text("Open Corrupted PDF"),
                //   onPressed: () {
                //     if (pathPDF != null) {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) =>
                //               PDFScreen(path: corruptedPathPDF),
                //         ),
                //       );
                //     }
                //   },
                // )
              ],
            );
          },
        )),
      ),
    );
  }
}

class PDFScreen extends StatefulWidget {
  final String path;

  PDFScreen({ Key key, this.path }) : super(key: key);

  _PDFScreenState createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFScreen> with WidgetsBindingObserver {
  final Completer<PDFViewController> _controller =
  Completer<PDFViewController>();
  int pages = 0;
  int currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Staging Cards"),
        backgroundColor: Colors.blue[900],
        actions: <Widget>[
        ],
      ),
      endDrawer: FutureBuilder<PDFViewController>(
        future: _controller.future,
        builder: (context, AsyncSnapshot<PDFViewController> snapshot) {
          if (snapshot.hasData) {
            return Drawer(
              child: ListView(
                // TODO: Create ListTiles with loop from contents.json
                children: [
                  ListTile(
                    title: Text("CT Atlas"),
                    onTap: () async {
                      // TODO: Go to page 1 (index 0)
                      await snapshot.data.setPage(1);

                      Navigator.pop(context); // Close drawer
                    },
                  ),
                  ListTile(
                    title: Text("Nodal Chart"),
                    onTap: () async {
                      // TODO: Go to page 3 (index 2)

                      await snapshot.data.setPage(3);

                      Navigator.pop(context); // Close drawer
                    },
                  ),
                ],
              ),
            );
          }

          return Container();
        },
      ),
      body: Stack(
        children: <Widget>[
          PDFView(
            filePath: widget.path,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            defaultPage: currentPage,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation:
            false, // if set to true the link is handled in flutter
            onRender: (_pages) {
              setState(() {
                pages = _pages;
                isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
              print(error.toString());
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = '$page: ${error.toString()}';
              });
              print('$page: ${error.toString()}');
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _controller.complete(pdfViewController);
            },
            onLinkHandler: (String uri) {
              print('goto uri: $uri');
            },
            onPageChanged: (int page, int total) {
              print('page change: $page/$total');
              setState(() {
                currentPage = page;
              });
            },
          ),
          errorMessage.isEmpty
              ? !isReady
              ? Center(
            child: CircularProgressIndicator(),
          )
              : Container()
              : Center(
            child: Text(errorMessage),
          )
        ],
      ),

      floatingActionButton: FutureBuilder<PDFViewController>(
        future: _controller.future,
        builder: (context, AsyncSnapshot<PDFViewController> snapshot) {
          if (snapshot.hasData) {
            return FloatingActionButton.extended(
              label: Text("Go to p. 3"),
              onPressed: () async {
                await snapshot.data.setPage(2);
              },
            );
          }

          return Container();
        },
      ),
    );
  }
}
