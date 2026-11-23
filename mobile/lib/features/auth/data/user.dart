class User {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.businessName,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    email: json['email'] as String,
    fullName: json['fullName'] as String,
    phone: json['phone'] as String?,
    businessName: json['businessName'] as String?,
  );

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? businessName;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;
}
