import 'package:flutter/material.dart';

class ServiceModel {
  final String id;
  final String name;
  final String icon;
  final String bgColor;
  final String type;
  final String status;
  final int order;

  ServiceModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.bgColor,
    required this.type,
    required this.status,
    required this.order,
  });

  factory ServiceModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return ServiceModel(
      id: id,
      name: map['name'] ?? '',
      icon: map['icon'] ?? 'build',
      bgColor: map['bgColor'] ?? '#E0F7F4',
      type: map['type'] ?? 'coming_soon',
      status: map['status'] ?? 'active',
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'bgColor': bgColor,
      'type': type,
      'status': status,
      'order': order,
    };
  }

  // Convert icon string to IconData
  IconData getIconData() {
    switch (icon) {
      case 'ac_unit':
        return Icons.ac_unit;
      case 'kitchen':
        return Icons.kitchen;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      case 'water_drop':
        return Icons.water_drop;
      case 'microwave':
        return Icons.microwave;
      case 'kitchen_outlined':
        return Icons.kitchen_outlined;
      case 'tv':
        return Icons.tv;
      case 'bolt':
        return Icons.bolt;
      case 'build':
        return Icons.build;
      default:
        return Icons.build;
    }
  }

  // Convert hex color to Color
  Color getBgColor() {
    String hexColor = bgColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
