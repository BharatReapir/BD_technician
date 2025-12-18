class UserModel {
  final String name;
  final String phone;
  final String email;
  final String city;
  final String? referralCode;

  UserModel({
    required this.name,
    required this.phone,
    required this.email,
    required this.city,
    this.referralCode,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'city': city,
    'referralCode': referralCode,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    email: json['email'] ?? '',
    city: json['city'] ?? '',
    referralCode: json['referralCode'],
  );
}