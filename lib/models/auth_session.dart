String roleTitleOf(String role) => switch (role) {
      'member' => 'Anggota',
      'primary_admin' => 'Pengurus Primer',
      'secondary_admin' => 'Pengurus Sekunder',
      _ => role,
    };

class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.deviceId,
    this.tenantId,
    this.koperasiName,
    this.koperasiType,
  });

  final String token;
  final String userId;
  final String name;
  final String email;
  final String role;
  final String deviceId;
  final String? tenantId;
  final String? koperasiName;
  final String? koperasiType;

  String get roleTitle => roleTitleOf(role);

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        token: json['token'] as String? ?? '',
        userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? 'member',
        deviceId:
            json['deviceId'] as String? ?? json['device_id'] as String? ?? '',
        tenantId:
            json['tenantId'] as String? ?? json['tenant_id'] as String?,
        koperasiName: json['koperasiName'] as String? ??
            json['koperasi_name'] as String?,
        koperasiType: json['koperasiType'] as String? ??
            json['koperasi_type'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'userId': userId,
        'name': name,
        'email': email,
        'role': role,
        'deviceId': deviceId,
        'tenantId': tenantId,
        'koperasiName': koperasiName,
        'koperasiType': koperasiType,
      };
}
