import 'line.dart';

class WorkCenter {
  final int id;
  final String name;
  final Line? line;

  WorkCenter({required this.id, required this.name, this.line});

  factory WorkCenter.fromJson(Map<String, dynamic> json) {
    return WorkCenter(
      id: json['id'],
      name: json['name'],
      line: json['line'] != null ? Line.fromJson(json['line']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'line': line?.toJson()};
  }
}
