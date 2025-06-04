import 'line.dart';

class WorkCenter {
  final int id;
  final String number;
  final String name;
  final String? ip;
  final Line? line;

  WorkCenter({
    required this.id,
    required this.number,
    required this.name,
    this.ip,
    this.line,
  });

  factory WorkCenter.fromJson(Map<String, dynamic> json) {
    return WorkCenter(
      id: json['id'],
      number: json['number'],
      name: json['name'],
      ip: json['ip'],
      line: json['line'] != null ? Line.fromJson(json['line']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'name': name,
      'ip': ip,
      'line': line?.toJson(),
    };
  }
}
