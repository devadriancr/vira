import 'work_center.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String? nickname;
  final DateTime? createdAt;
  final List<WorkCenter>? workCenters;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.nickname,
    this.createdAt,
    this.workCenters,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;

    if (json['created_at'] != null) {
      if (json['created_at'] is String) {
        createdAt = DateTime.parse(json['created_at']);
      } else if (json['created_at'] is DateTime) {
        createdAt = json['created_at'];
      }
    }

    List<WorkCenter>? workCentersList;
    if (json['work_centers'] != null) {
      workCentersList =
          (json['work_centers'] as List)
              .map((center) => WorkCenter.fromJson(center))
              .toList();
    }

    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      nickname: json['nickname'],
      createdAt: createdAt,
      workCenters: workCentersList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'nickname': nickname,
      'created_at': createdAt?.toIso8601String(),
      'work_centers': workCenters?.map((center) => center.toJson()).toList(),
    };
  }
}
