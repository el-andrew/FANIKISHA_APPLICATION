class User {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.businessName,
    this.phoneVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    email: json['email'] as String,
    fullName: json['fullName'] as String,
    phone: json['phone'] as String?,
    businessName: json['businessName'] as String?,
    phoneVerified: json['phoneVerified'] as bool? ?? false,
  );

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? businessName;

  /// True once the phone number was confirmed with an SMS code.
  final bool phoneVerified;

  bool get needsPhoneVerification => phone != null && !phoneVerified;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;
}
