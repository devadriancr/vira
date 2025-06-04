class Line {
  final int id;
  final String name;

  Line({required this.id, required this.name});

  factory Line.fromJson(Map<String, dynamic> json) {
    return Line(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
