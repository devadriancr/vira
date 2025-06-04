import 'user.dart';
import 'work_center.dart';

class AuthResponse {
  final User user;
  final String token;
  final List<WorkCenter> workCenters;

  AuthResponse({
    required this.user,
    required this.token,
    required this.workCenters,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user']),
      token: json['token'],
      workCenters:
          (json['work_centers'] as List)
              .map((item) => WorkCenter.fromJson(item))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      'work_centers': workCenters.map((wc) => wc.toJson()).toList(),
    };
  }
}
