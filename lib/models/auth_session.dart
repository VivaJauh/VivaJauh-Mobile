class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.deviceId,
  });

  final String token;
  final String userId;
  final String name;
  final String email;
  final String role;
  final String deviceId;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        token: json['token'] as String? ?? '',
        userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? 'field_officer',
        deviceId:
            json['deviceId'] as String? ?? json['device_id'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'userId': userId,
        'name': name,
        'email': email,
        'role': role,
        'deviceId': deviceId,
      };
}
