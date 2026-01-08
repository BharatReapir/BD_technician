class TechnicianModel {
  final String uid;
  final String name;
  final String mobile;
  final String email;
  final String city;
  final List<String> specializations;
  final bool isOnline;
  final int totalJobs;
  final double monthlyEarnings;
  final double rating;
  final double walletBalance; // NEW FIELD
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TechnicianModel({
    required this.uid,
    required this.name,
    required this.mobile,
    required this.email,
    required this.city,
    required this.specializations,
    this.isOnline = false,
    this.totalJobs = 0,
    this.monthlyEarnings = 0.0,
    this.rating = 0.0,
    this.walletBalance = 0.0, // NEW FIELD
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
      'specializations': specializations,
      'isOnline': isOnline,
      'totalJobs': totalJobs,
      'monthlyEarnings': monthlyEarnings,
      'rating': rating,
      'walletBalance': walletBalance, // NEW FIELD
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
      specializations: List<String>.from(json['specializations'] ?? []),
      isOnline: json['isOnline'] ?? false,
      totalJobs: json['totalJobs'] ?? 0,
      monthlyEarnings: (json['monthlyEarnings'] ?? 0.0).toDouble(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      walletBalance: (json['walletBalance'] ?? 0.0).toDouble(), // NEW FIELD
      profileImage: json['profileImage'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  TechnicianModel copyWith({
    String? uid,
    String? name,
    String? mobile,
    String? email,
    String? city,
    List<String>? specializations,
    bool? isOnline,
    int? totalJobs,
    double? monthlyEarnings,
    double? rating,
    double? walletBalance, // NEW FIELD
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
      specializations: specializations ?? this.specializations,
      isOnline: isOnline ?? this.isOnline,
      totalJobs: totalJobs ?? this.totalJobs,
      monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
      rating: rating ?? this.rating,
      walletBalance: walletBalance ?? this.walletBalance, // NEW FIELD
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}