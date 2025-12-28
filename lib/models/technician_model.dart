class TechnicianModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String city;
  final List<String> specializations; // ['AC Repair', 'TV Repair', etc.]
  final bool isOnline;
  final double rating;
  final int totalJobs;
  final double monthlyEarnings;
  final String? profileImage;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  TechnicianModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.city,
    required this.specializations,
    this.isOnline = false,
    this.rating = 0.0,
    this.totalJobs = 0,
    this.monthlyEarnings = 0.0,
    this.profileImage,
    this.address,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'phone': phone,
        'email': email,
        'city': city,
        'specializations': specializations,
        'isOnline': isOnline,
        'rating': rating,
        'totalJobs': totalJobs,
        'monthlyEarnings': monthlyEarnings,
        'profileImage': profileImage,
        'address': address,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TechnicianModel.fromJson(Map<String, dynamic> json) =>
      TechnicianModel(
        uid: json['uid'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'] ?? '',
        city: json['city'] ?? '',
        specializations: List<String>.from(json['specializations'] ?? []),
        isOnline: json['isOnline'] ?? false,
        rating: (json['rating'] ?? 0.0).toDouble(),
        totalJobs: json['totalJobs'] ?? 0,
        monthlyEarnings: (json['monthlyEarnings'] ?? 0.0).toDouble(),
        profileImage: json['profileImage'],
        address: json['address'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
      );

  TechnicianModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? email,
    String? city,
    List<String>? specializations,
    bool? isOnline,
    double? rating,
    int? totalJobs,
    double? monthlyEarnings,
    String? profileImage,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TechnicianModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      specializations: specializations ?? this.specializations,
      isOnline: isOnline ?? this.isOnline,
      rating: rating ?? this.rating,
      totalJobs: totalJobs ?? this.totalJobs,
      monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
      profileImage: profileImage ?? this.profileImage,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}