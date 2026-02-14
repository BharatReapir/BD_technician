import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/pricing_service.dart';
import 'service_list_page.dart';

class ServiceTypePage extends StatefulWidget {
  final String acType;

  const ServiceTypePage({
    Key? key,
    required this.acType,
  }) : super(key: key);

  @override
  State<ServiceTypePage> createState() => _ServiceTypePageState();
}

class _ServiceTypePageState extends State<ServiceTypePage> {
  Map<String, dynamic> _allPricing = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  Future<void> _loadPricing() async {
    try {
      final pricing = await PricingService.getAllPricing();
      if (mounted) {
        setState(() {
          _allPricing = pricing;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading pricing: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _getPrice(String serviceId, int fallbackPrice) {
    if (_allPricing.containsKey(serviceId)) {
      return _allPricing[serviceId]['price'] ?? fallbackPrice;
    }
    return fallbackPrice;
  }

  String? _getPriceType(String serviceId) {
    if (_allPricing.containsKey(serviceId)) {
      return _allPricing[serviceId]['priceType'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.acType,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select Service Type',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _getServiceTypes(context),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  List<Widget> _getServiceTypes(BuildContext context) {
    final List<Map<String, dynamic>> serviceTypes = [
      {
        'name': 'Service',
        'icon': Icons.home_repair_service,
        'color': Color(0xFF4CAF50),
      },
      {
        'name': 'Installation',
        'icon': Icons.build_circle,
        'color': Color(0xFF2196F3),
      },
      {
        'name': 'Uninstall',
        'icon': Icons.remove_circle_outline,
        'color': Color(0xFFFF9800),
      },
      {
        'name': 'Repair',
        'icon': Icons.handyman,
        'color': Color(0xFFF44336),
      },
    ];

    return serviceTypes.map((serviceType) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.bgMedium, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceListPage(
                    serviceType: 'AC Repair',
                    subCategory: widget.acType,
                    serviceAction: serviceType['name'],
                    services: _getServicesForType(serviceType['name']),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: serviceType['color'].withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      serviceType['icon'],
                      color: serviceType['color'],
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      serviceType['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: AppColors.textGray,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Map<String, dynamic>> _getServicesForType(String serviceTypeName) {
    // SPLIT AC
    if (widget.acType == 'Split AC') {
      if (serviceTypeName == 'Service') {
        return [
          {
            'name': 'General Service',
            'price': _getPrice('split-ac-general-service', 499),
            'priceType': _getPriceType('split-ac-general-service'),
          },
          {
            'name': 'Jet Machine Service',
            'price': _getPrice('split-ac-jet-machine-service', 550),
            'priceType': _getPriceType('split-ac-jet-machine-service'),
          },
          {
            'name': 'Foam Service',
            'price': _getPrice('split-ac-foam-service', 600),
            'priceType': _getPriceType('split-ac-foam-service'),
          },
          {
            'name': 'Spray Service',
            'price': _getPrice('split-ac-spray-service', 750),
            'priceType': _getPriceType('split-ac-spray-service'),
          },
        ];
      } else if (serviceTypeName == 'Installation') {
        return [
          {
            'name': 'AC Installation',
            'price': _getPrice('split-ac-installation', 1150),
            'priceType': _getPriceType('split-ac-installation'),
            'note': '⚠️ Copper pipe + Stand cost extra'
          },
        ];
      } else if (serviceTypeName == 'Uninstall') {
        return [
          {
            'name': 'AC Uninstallation',
            'price': _getPrice('split-ac-uninstallation', 550),
            'priceType': _getPriceType('split-ac-uninstallation'),
          },
        ];
      } else if (serviceTypeName == 'Repair') {
        return [
          {
            'name': 'Gas Refilling',
            'price': _getPrice('split-ac-gas-refilling', 0),
            'priceType': _getPriceType('split-ac-gas-refilling') ?? 'inspection',
          },
          {
            'name': 'Noise Problem',
            'price': _getPrice('split-ac-noise-problem', 0),
            'priceType': _getPriceType('split-ac-noise-problem') ?? 'inspection',
          },
          {
            'name': 'Not Responding',
            'price': _getPrice('split-ac-not-responding', 0),
            'priceType': _getPriceType('split-ac-not-responding') ?? 'inspection',
          },
          {
            'name': 'Any Other Problem',
            'price': _getPrice('split-ac-any-other-problem', 0),
            'priceType': _getPriceType('split-ac-any-other-problem') ?? 'inspection',
          },
        ];
      }
    }

    // WINDOW AC
    if (widget.acType == 'Window AC') {
      if (serviceTypeName == 'Service') {
        return [
          {
            'name': 'General Service',
            'price': _getPrice('window-ac-general-service', 449),
            'priceType': _getPriceType('window-ac-general-service'),
          },
          {
            'name': 'Jet Machine Service',
            'price': _getPrice('window-ac-jet-machine-service', 499),
            'priceType': _getPriceType('window-ac-jet-machine-service'),
          },
          {
            'name': 'Foam + Jet Service',
            'price': _getPrice('window-ac-foam-jet-service', 549),
            'priceType': _getPriceType('window-ac-foam-jet-service'),
          },
          {
            'name': 'Spray + Jet Service',
            'price': _getPrice('window-ac-spray-jet-service', 649),
            'priceType': _getPriceType('window-ac-spray-jet-service'),
          },
        ];
      } else if (serviceTypeName == 'Installation') {
        return [
          {
            'name': 'AC Installation',
            'price': _getPrice('window-ac-installation', 649),
            'priceType': _getPriceType('window-ac-installation'),
          },
        ];
      } else if (serviceTypeName == 'Uninstall') {
        return [
          {
            'name': 'AC Uninstallation',
            'price': _getPrice('window-ac-uninstallation', 549),
            'priceType': _getPriceType('window-ac-uninstallation'),
          },
        ];
      } else if (serviceTypeName == 'Repair') {
        return [
          {
            'name': 'Gas Refilling',
            'price': _getPrice('window-ac-gas-refilling', 0),
            'priceType': _getPriceType('window-ac-gas-refilling') ?? 'inspection',
          },
          {
            'name': 'Noise Problem',
            'price': _getPrice('window-ac-noise-problem', 0),
            'priceType': _getPriceType('window-ac-noise-problem') ?? 'inspection',
          },
          {
            'name': 'Not Responding',
            'price': _getPrice('window-ac-not-responding', 0),
            'priceType': _getPriceType('window-ac-not-responding') ?? 'inspection',
          },
          {
            'name': 'Any Other Problem',
            'price': _getPrice('window-ac-any-other-problem', 0),
            'priceType': _getPriceType('window-ac-any-other-problem') ?? 'inspection',
          },
        ];
      }
    }

    // CASSETTE & CENTRAL AC
    if (widget.acType == 'Cassette AC' || widget.acType == 'Central AC') {
      return [
        {
          'name': '${serviceTypeName} - Inspection Required',
          'price': 0,
          'priceType': 'inspection',
          'note': '💬 Final bill will be decided by Technician after visit'
        },
      ];
    }

    return [];
  }
}