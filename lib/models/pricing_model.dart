class PricingModel {
  final String serviceId;
  final String serviceName;
  final int basic;
  final int standard;
  final int premium;
  final String currency;
  final PricingDescription? description;

  PricingModel({
    required this.serviceId,
    required this.serviceName,
    required this.basic,
    required this.standard,
    required this.premium,
    required this.currency,
    this.description,
  });

  factory PricingModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return PricingModel(
      serviceId: id,
      serviceName: map['serviceName'] ?? '',
      basic: map['basic'] ?? 0,
      standard: map['standard'] ?? 0,
      premium: map['premium'] ?? 0,
      currency: map['currency'] ?? 'INR',
      description: map['description'] != null
          ? PricingDescription.fromMap(map['description'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceName': serviceName,
      'basic': basic,
      'standard': standard,
      'premium': premium,
      'currency': currency,
      'description': description?.toMap(),
    };
  }

  String getFormattedPrice(String tier) {
    int price;
    switch (tier) {
      case 'basic':
        price = basic;
        break;
      case 'standard':
        price = standard;
        break;
      case 'premium':
        price = premium;
        break;
      default:
        price = basic;
    }
    return '₹$price';
  }
}

class PricingDescription {
  final String basic;
  final String standard;
  final String premium;

  PricingDescription({
    required this.basic,
    required this.standard,
    required this.premium,
  });

  factory PricingDescription.fromMap(Map<dynamic, dynamic> map) {
    return PricingDescription(
      basic: map['basic'] ?? '',
      standard: map['standard'] ?? '',
      premium: map['premium'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'basic': basic,
      'standard': standard,
      'premium': premium,
    };
  }
}
