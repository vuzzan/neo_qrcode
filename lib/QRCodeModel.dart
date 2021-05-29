import 'dart:convert';

Qrcode qrcodeFromJson(String str) {
  final jsonData = json.decode(str);
  return Qrcode.fromMap(jsonData);
}

String qrcodetoJson(Qrcode data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}

class Qrcode {
  int id;
  String qrcode;
  String create_time;
  String result;

  Qrcode(
      {required this.id,
      required this.qrcode,
      required this.create_time,
      required this.result});

  factory Qrcode.fromMap(Map<String, dynamic> json) {
    return new Qrcode(
        id: json["id"],
        qrcode: json["qrcode"],
        create_time: json["create_time"],
        result: ((json["result"]?.isEmpty ?? true) ? "" : json["result"]));
  }

  Map<String, dynamic> toMap() => {
        "id": id,
        "qrcode": qrcode,
        "create_time": create_time,
        "result": result
      };

  @override
  String toString() {
    return 'Qrcode{id: $id, qrcode: $qrcode, create_time: $create_time, result: $result}';
  }
}
