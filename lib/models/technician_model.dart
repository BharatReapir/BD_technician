// technician_model.dart

DateTime _parseDate(dynamic value) {
  if (value == null) {
    return DateTime.now();
  }

  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  return DateTime.now();
}

class TechnicianModel {
  final String uid;
  final String name;
  final String mobile;
  final String email;
  final String city;
  final String primaryPincode; // 🔑 NEW: Primary pincode for mapping
  final String? fcmToken; // 🔑 NEW: FCM token for notifications
  final List<String> specializations;
  final bool isOnline;
  final int totalJobs;
  final double rating;
  final double walletBalance;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TechnicianModel({
    required this.uid,
    required this.name,
    required this.mobile,
    required this.email,
    required this.city,
    required this.primaryPincode, // 🔑 NEW: Required pincode
    this.fcmToken, // 🔑 NEW: FCM token
    required this.specializations,
    this.isOnline = false,
    this.totalJobs = 0,
    this.rating = 0.0,
    this.walletBalance = 0.0,
    this.profileImage,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'mobile': mobile,
      'email': email,
      'city': city,
      'primaryPincode': primaryPincode, // 🔑 NEW
      'fcmToken': fcmToken, // 🔑 NEW
      'specializations': specializations,
      'isOnline': isOnline,
      'totalJobs': totalJobs,
      'rating': rating,
      'walletBalance': walletBalance,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory TechnicianModel.fromJson(Map<String, dynamic> json) {
    return TechnicianModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      city: json['city'] ?? '',
      primaryPincode: json['primaryPincode'] ?? '', // 🔑 NEW
      fcmToken: json['fcmToken'], // 🔑 NEW
      specializations: List<String>.from(json['specializations'] ?? []),
      isOnline: json['isOnline'] ?? false,
      totalJobs: json['totalJobs'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      walletBalance: (json['walletBalance'] ?? 0).toDouble(),
      profileImage: json['profileImage'],
      createdAt: _parseDate(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? _parseDate(json['updatedAt'])
          : null,
    );
  }

  TechnicianModel copyWith({
    String? uid,
    String? name,
    String? mobile,
    String? email,
    String? city,
    String? primaryPincode, // 🔑 NEW
    String? fcmToken, // 🔑 NEW
    List<String>? specializations,
    bool? isOnline,
    int? totalJobs,
    double? rating,
    double? walletBalance,
    String? profileImage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TechnicianModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      city: city ?? this.city,
      primaryPincode: primaryPincode ?? this.primaryPincode, // 🔑 NEW
      fcmToken: fcmToken ?? this.fcmToken, // 🔑 NEW
      specializations: specializations ?? this.specializations,
      isOnline: isOnline ?? this.isOnline,
      totalJobs: totalJobs ?? this.totalJobs,
      rating: rating ?? this.rating,
      walletBalance: walletBalance ?? this.walletBalance,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
