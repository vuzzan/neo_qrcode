import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'QRCodeModel.dart';
import 'package:sqflite/sqflite.dart';

class DBProvider {
  DBProvider._();

  static final DBProvider db = DBProvider._();

  dynamic _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    // if _database is null we instantiate it
    _database = await initDB();
    return _database;
  }

  initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "NeoQRCode.db");
    return await openDatabase(path, version: 1, onOpen: (db) {},
        onCreate: (Database db, int version) async {
      await db.execute("CREATE TABLE QRCODE ("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "qrcode TEXT,"
          "result TEXT,"
          "create_time DATETIME DEFAULT (datetime('now','localtime'))"
          ")");
      await db.execute("CREATE TABLE Config ("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "key TEXT,"
          "active INTEGER,"
          "value TEXT"
          ")");
      await db.rawInsert(
              "INSERT Into Config (key, value)"
              " VALUES (?,?)",
              [
                "HTTP",
                '{"method": "post", "url": "http://localhost"}'
              ]);
      print("CREATE DB");
    });
  }

  upgradeDb() async {
    final db = await database;

    print("UPGRADE DB START");
    //insert to the table using the new id
    // try{
    //   var resConfig = await db.rawQuery("SELECT * FROM Config");
    
    // } on Exception catch (exception) {} catch (error) {}
    
    try {
      await db.execute("DROP TABLE IF EXISTS Config");
      await db.execute("CREATE TABLE Config ("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "key TEXT,"
          "active INTEGER,"
          "value TEXT"
          ")");
      // await db.rawInsert(
      //         "INSERT Into Config (key, value)"
      //         " VALUES (?,?)",
      //         [
      //           "HTTP",
      //           '{"method": "post", "url": "http://localhost"}'
      //         ]);
      // if (resConfig.isNotEmpty) {
      //   resConfig.forEach((element) {
      //     db.rawInsert(
      //         "INSERT Into Config (id, key, value,active )"
      //         " VALUES (?,?,?,?)",
      //         [
      //           element["id"],
      //           element["key"],
      //           element["value"],
      //           element["active"],
      //         ]);
      //   });
      // }
      //
      print("UPGRADE CONFIG OK ");
      // var httppost = '{"method": "post", "url": "http://localhost"}';

      // print(json.encode(httppost.toString()));
      // print(json.decode(json.encode(httppost.toString())));
      // print("INSERT CONFIG BEGIN");
      // int rc = await db.rawInsert(
      //     "INSERT Into Config (id, key, active, value )"
      //     " VALUES (?,?,?, ?)",
      //     [0, "HTTP", 1, httppost]);

      // print("INSERT CONFIG " + rc.toString());
    } on Exception catch (exception) {
      print(exception);
    } catch (error) {
      print(error);
    }
print("UPGRADE QRCODE");
    try {
      var res = await db.rawQuery("SELECT * FROM Qrcode");
      await db.execute("DROP TABLE IF EXISTS QRCODE");
      await db.execute("CREATE TABLE QRCODE ("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "qrcode TEXT,"
          "result TEXT,"
          "create_time DATETIME DEFAULT (datetime('now','localtime'))"
          ")");
      print("UPGRADE QRCODE OK ");
      if (res.isNotEmpty) {
        res.forEach((element) {
          print(" upgradeDb = " + element.toString());
          db.rawInsert(
              "INSERT Into QRCODE (id, qrcode, create_time, result )"
              " VALUES (?,?,?,?)",
              [
                element["id"],
                element["qrcode"].toString(),
                element["create_time"],
                element.keys.contains("result") ? element["result"] : ''
              ]);
        });
      }
    } on Exception catch (exception) {
      print(exception);
    } catch (error) {
      print(error);
    }

    return;
  }

  Future<void> saveConfig(obj) async {
    final db = await database;
    print(json.encode(obj));
    try{
      await getConfig();
      await db.rawUpdate("Update Config set value=?", [json.encode(obj)]);
    }
    on Exception catch (exception) {
      await db.rawInsert(
              "INSERT Into Config (key, value)"
              " VALUES (?,?)",
              [
                obj["method"],
                obj["value"]
              ]);
      print(exception);
    } catch (error) {
      print(error);
    }
  }

  Future<Map<String, Object?>> getConfig() async {
    final db = await database;
    try{
      var res = await db.rawQuery("SELECT * FROM Config limit 1");
      return res.first;
    }
    catch (error) {
      await db.rawInsert(
              "INSERT Into Config (key, value)"
              " VALUES (?,?)",
              [
                "HTTP",
                "http://localhost"
              ]);
      var res = await db.rawQuery("SELECT * FROM Config limit 1");
      return res.first;
    }
    
  }

  newQrCode(Qrcode newClient) async {
    final db = await database;
    //insert to the table using the new id
    var raw = await db.rawInsert(
        "INSERT Into QRCODE (qrcode, result)"
        " VALUES (?, ?)",
        [newClient.qrcode, newClient.result]);
    return raw;
  }

  Future<List<Qrcode>> getAllQrcode() async {
    final db = await database;
    var res =
        await db.rawQuery("SELECT * FROM Qrcode order by create_time desc");
    List<Qrcode> list =
        res.isNotEmpty ? res.map((c) => Qrcode.fromMap(c)).toList() : [];
    return list;
  }

  deleteAll() async {
    final db = await database;
    db.rawDelete("Delete from Qrcode");
  }
}
