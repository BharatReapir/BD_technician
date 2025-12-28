class BookingModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String? technicianId;
  final String? technicianName;
  final String service;
  final String status; // 'pending', 'accepted', 'in_progress', 'completed', 'cancelled'
  final double earnings;
  final String scheduledTime;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.technicianId,
    this.technicianName,
    required this.service,
    this.status = 'pending',
    required this.earnings,
    required this.scheduledTime,
    this.address,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'technicianId': technicianId,
        'technicianName': technicianName,
        'service': service,
        'status': status,
        'earnings': earnings,
        'scheduledTime': scheduledTime,
        'address': address,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['id'] ?? '',
        userId: json['userId'] ?? '',
        userName: json['userName'] ?? '',
        userPhone: json['userPhone'] ?? '',
        technicianId: json['technicianId'],
        technicianName: json['technicianName'],
        service: json['service'] ?? '',
        status: json['status'] ?? 'pending',
        earnings: (json['earnings'] ?? 0.0).toDouble(),
        scheduledTime: json['scheduledTime'] ?? '',
        address: json['address'],
        notes: json['notes'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
      );

  BookingModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? technicianId,
    String? technicianName,
    String? service,
    String? status,
    double? earnings,
    String? scheduledTime,
    String? address,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      technicianId: technicianId ?? this.technicianId,
      technicianName: technicianName ?? this.technicianName,
      service: service ?? this.service,
      status: status ?? this.status,
      earnings: earnings ?? this.earnings,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}