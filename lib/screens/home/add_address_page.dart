import 'package:flutter/material.dart';
import '../../services/address_service.dart';
import '../../services/location_service.dart';
import '../../constants/colors.dart';

class AddAddressPage extends StatefulWidget {
  final Map<String, String>? existingAddress;
  final int? addressIndex;
  final bool useCurrentLocation;

  const AddAddressPage({
    Key? key,
    this.existingAddress,
    this.addressIndex,
    this.useCurrentLocation = false,
  }) : super(key: key);

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();

  String _selectedType = 'Home';
  final List<String> _addressTypes = ['Home', 'Office', 'Other'];

  bool _isLoading = false;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    
    // If editing existing address, populate fields
    if (widget.existingAddress != null) {
      _selectedType = widget.existingAddress!['type'] ?? 'Home';
      _typeController.text = _selectedType;
      _addressController.text = widget.existingAddress!['address'] ?? '';
      _cityController.text = widget.existingAddress!['city'] ?? '';
      _pincodeController.text = widget.existingAddress!['pincode'] ?? '';
      _landmarkController.text = widget.existingAddress!['landmark'] ?? '';
    }
    
    // If useCurrentLocation is true, automatically fetch GPS location
    if (widget.useCurrentLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getCurrentLocation();
      });
    }
  }

  @override
  void dispose() {
    _typeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final address = await LocationService.getCurrentLocationAddress();
      
      if (address != null && mounted) {
        setState(() {
          _addressController.text = address['address'] ?? '';
          _cityController.text = address['city'] ?? '';
          _pincodeController.text = address['pincode'] ?? '';
          _landmarkController.text = address['landmark'] ?? '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location fetched successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Unable to get current location';
        
        if (e.toString().contains('Location services are disabled')) {
          errorMessage = 'Please enable location services';
        } else if (e.toString().contains('permissions are denied')) {
          errorMessage = 'Please grant location permission';
        } else if (e.toString().contains('permanently denied')) {
          errorMessage = 'Please enable location access in settings';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
            action: e.toString().contains('settings') 
                ? SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: () => LocationService.openLocationSettings(),
                  )
                : null,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final address = {
      'type': _selectedType,
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'landmark': _landmarkController.text.trim(),
    };

    bool success = false;

    if (widget.addressIndex != null) {
      // Update existing address
      success = await AddressService.updateAddress(widget.addressIndex!, address);
    } else {
      // Save new address
      success = await AddressService.saveAddress(address);
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.addressIndex != null 
                ? 'Address updated successfully!' 
                : 'Address saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save address. Please try again.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingAddress != null ? 'Edit Address' : 'Add New Address',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address Type Selection
                    const Text(
                      'Address Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _addressTypes.map((type) {
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = type;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedType == type
                                    ? AppColors.primary
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedType == type
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                type,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _selectedType == type
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // GPS Location Button
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: OutlinedButton.icon(
                        onPressed: _isGettingLocation ? null : _getCurrentLocation,
                        icon: _isGettingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              )
                            : const Icon(Icons.my_location, size: 20),
                        label: Text(_isGettingLocation ? 'Getting Location...' : 'Use Current Location'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    // Address Field
                    _buildTextField(
                      controller: _addressController,
                      label: 'Complete Address',
                      hint: 'House/Flat No., Building Name, Street',
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your address';
                        }
                        if (value.trim().length < 10) {
                          return 'Please enter a complete address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // City Field
                    _buildTextField(
                      controller: _cityController,
                      label: 'City',
                      hint: 'Enter your city',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your city';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Pincode Field
                    _buildTextField(
                      controller: _pincodeController,
                      label: 'Pincode',
                      hint: 'Enter 6-digit pincode',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter pincode';
                        }
                        if (value.trim().length != 6) {
                          return 'Please enter a valid 6-digit pincode';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Landmark Field (Optional)
                    _buildTextField(
                      controller: _landmarkController,
                      label: 'Landmark (Optional)',
                      hint: 'Nearby landmark for easy identification',
                      required: false,
                    ),
                  ],
                ),
              ),
            ),

            // Save Button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.existingAddress != null ? 'Update Address' : 'Save Address',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.primary),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}