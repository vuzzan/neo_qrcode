import 'dart:convert';

HttpParam qrcodeFromJson(String str) {
  final jsonData = json.decode(str);
  return HttpParam.fromMap(jsonData);
}

String qrcodetoJson(HttpParam data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}

class HttpParam {
  String type;
  String key;
  String value;

  HttpParam({required this.type, required this.key, required this.value});

  factory HttpParam.fromMap(Map<String, dynamic> json) {
    return new HttpParam(
        type: json["type"], key: json["key"], value: json["value"]);
  }

  Map<String, dynamic> toMap() => {"type": type, "key": key, "value": value};

  @override
  String toString() {
    return 'HttpParam{type: $type, key: $key, value: $value}';
  }
}
