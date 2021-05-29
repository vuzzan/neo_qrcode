import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:upgrader/upgrader.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

import 'Database.dart';
import 'QRCodeModel.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Qrcode obj = new Qrcode(id:1,qrcode:"TEST ME", create_time:"TIME");
  // print(obj.toMap());
  //await DBProvider.db.newQrCode(obj);
  //await DBProvider.db.deleteAll();
  print("MAIN MAIN MAIN ");
  // var list = await DBProvider.db.getAllQrcode();
  // print(list);
  // list.forEach((element) => print(element));
  await DBProvider.db.upgradeDb();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // reference to our single class that manages the database

  bool _postSending = false;
  String _scanBarcode = '';
  String _postResult = '';
  List<Qrcode> _listQrcode = [];
  dynamic _httpConfig = {};
  final myControllerUrl = TextEditingController();

  @override
  void initState() {
    loadListQrcode();
    loadConfigHttp();
    super.initState();
  }

  Future<void> startBarcodeScanStream() async {
    FlutterBarcodeScanner.getBarcodeStreamReceiver(
            '#ff6666', 'Cancel', true, ScanMode.BARCODE)!
        .listen((barcode) => print(barcode));
  }

  Future<void> scanQR() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.QR);
      //print(barcodeScanRes);
      // Qrcode obj =
      //     new Qrcode(id: 1, qrcode: barcodeScanRes, create_time: "TIME");
      // print(obj.toMap());
      // await DBProvider.db.newQrCode(obj);
    } on PlatformException {
      barcodeScanRes = 'ERROR!!';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _scanBarcode = barcodeScanRes;
    });

    // Post http
    try {
      setState(() {
        _postResult = "";
        _postSending = true;
      });
      String postResult = await postData(barcodeScanRes);
      setState(() {
        _postResult = postResult;
        _postSending = false;
      });
    } on Exception catch (e) {
      print(e);
      setState(() {
        _postResult = e.toString();
        _postSending = false;
      });
    }
    print("INSERT QRCODE RESULT...===============================.");
    Qrcode obj = new Qrcode(
        id: 0, qrcode: barcodeScanRes, create_time: "", result: _postResult);
    print(obj.toMap());
    await DBProvider.db.newQrCode(obj);
  }

  Future<void> saveConfig() async {
    print("SAVE CONFIG");
    setState(() {
      _httpConfig["url"] = myControllerUrl.text;
    });
    await DBProvider.db.saveConfig(_httpConfig);
    print("LOAD CONFIG");
    loadConfigHttp();
  }

  loadListQrcode() async {
    var list = await DBProvider.db.getAllQrcode();
    setState(() {
      _listQrcode = list;
    });
  }

  loadConfigHttp() async {
    var config = await DBProvider.db.getConfig();
    var obj = json.decode(config["value"].toString());
    setState(() {
      _httpConfig = obj;
      myControllerUrl.text = obj["url"].toString();
    });

    print(obj);
  }

  Future<String> postData(barcodeScanRes) async {
    try {
      if (_httpConfig["method"].toString().toLowerCase() == "get") {
        final response = await http.get(
            Uri.parse(_httpConfig["url"] + "?barcode=" + barcodeScanRes),
            headers: {
              HttpHeaders.authorizationHeader: 'Basic your_api_token_here',
            });
        if (response.statusCode == 200) {
          // If the server did return a 200 OK response,
          // then parse the JSON.
          return response.body;
        } else {
          // If the server did not return a 200 OK response,
          // then throw an exception.
          throw Exception('Send data lỗi');
        }
      } else {
        var requestBody = {
          'grant_type': 'password',
          'client_id':
              '3MVG9dZJodJWITSviqdj3EnW.LrZ81MbuGBqgIxxxdD6u7Mru2NOEs8bHFoFyNw_nVKPhlF2EzDbNYI0rphQL',
          'client_secret':
              '42E131F37E4E05313646E1ED1D3788D76192EBECA7486D15BDDB8408B9726B42',
          'username': 'example@mail.com.us',
          'password': 'ABC1234563Af88jesKxPLVirJRW8wXvj3D',
          'barcode': barcodeScanRes
        };
        final response = await http.post(
          Uri.parse(_httpConfig["url"]),
          headers: <String, String>{
            //'Content-Type': 'application/json; charset=UTF-8',
          },
          body: requestBody,
        );

        if (response.statusCode == 200) {
          // If the server did return a 200 OK response,
          // then parse the JSON.
          return response.body;
        } else {
          // If the server did not return a 200 OK response,
          // then throw an exception.
          throw Exception('Post data lỗi');
        }
      }
    } on Exception catch (ex) {
      throw ex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            bottom: TabBar(
              onTap: (index) {
                // Should not used it as it only called when tab options are clicked,
                // not when user swapped
                //print("On tab " + index.toString());
                if (index == 1) {
                  loadListQrcode();
                }
              },
              tabs: [
                Tab(icon: Icon(Icons.add_a_photo_outlined)),
                Tab(icon: Icon(Icons.checklist_sharp)),
                Tab(icon: Icon(Icons.content_copy)),
              ],
            ),
            title: Text('Neo QRcode - Đọc QRcode'),
          ),
          body: TabBarView(
            children: [
              buildTabBarcodeReader(context),
              buildTabListViewBarcode(context),
              buildTabConfiguration(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTabListViewBarcode(BuildContext context) {
    return ListView.builder(
        // padding: const EdgeInsets.all(8),
        itemCount: _listQrcode.length,
        itemBuilder: (context, index) {
          Qrcode item = _listQrcode.elementAt(index);
          // print("buildTabListViewBarcode index= " + item.toString());
          // return ListTile(
          //   title: Text(item.toString()),
          // );
          return ListTile(
              title: Container(
            //height: 100,
            margin: EdgeInsets.all(2),
            color: const Color(0xFF00FF00),
            child: Center(
                child: Text(
              '${item.create_time} - ${item.qrcode} (${item.result})',
              style: TextStyle(fontSize: 16),
            )),
          ));
        });
  }

  Widget buildTabBarcodeReader(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // set it to false
      body: SingleChildScrollView(
          child: Container(
              alignment: Alignment.center,
              child: Flex(
                  direction: Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                        onPressed: () => scanQR(), child: Text('Bắt đầu')),
                    Center(
                        child: Container(
                            padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                            child: Text('$_scanBarcode\n',
                                style: TextStyle(fontSize: 16)))),
                    (_postSending == true)
                        ? Text('Đang gửi...')
                        : Text(_postResult),
                  ]))),
    );
  }

  void _handleRadioValueChange(value) {
    setState(() {
      _httpConfig["method"] = value;
    });
  }

  Widget buildTabConfiguration(BuildContext context) {
    return Container(
        alignment: Alignment.topLeft,
        child: Flex(
            direction: Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              new Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  new Radio(
                    value: "get",
                    groupValue: _httpConfig["method"],
                    onChanged: _handleRadioValueChange,
                  ),
                  new Text(
                    'GET',
                    style: new TextStyle(fontSize: 16.0),
                  ),
                  new Radio(
                    value: 'post',
                    groupValue: _httpConfig["method"],
                    onChanged: _handleRadioValueChange,
                  ),
                  new Text(
                    'POST',
                    style: new TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: TextField(
                  controller: myControllerUrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Nhập đường dẫn web',
                  ),
                ),
              ),
              ElevatedButton(
                  onPressed: () {
                    print("PRESS SAVE");
                    saveConfig();
                  },
                  child: Text('Save Me')),
            ]));
  }
}
