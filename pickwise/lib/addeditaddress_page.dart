import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class AddEditAddressPage extends StatefulWidget {
  final Map<String, dynamic>? address;
  final String token;

  const AddEditAddressPage({super.key, this.address, required this.token});

  @override
  State<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends State<AddEditAddressPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController fullNameController;
  late TextEditingController phoneController;
  late TextEditingController line1Controller;
  late TextEditingController line2Controller;
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController postalController;
  late TextEditingController countryController;

  bool isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    fullNameController = TextEditingController(
      text: address?['fullName'] ?? '',
    );
    phoneController = TextEditingController(
      text: address?['phoneNumber'] ?? '',
    );
    line1Controller = TextEditingController(
      text: address?['addressLine1'] ?? '',
    );
    line2Controller = TextEditingController(
      text: address?['addressLine2'] ?? '',
    );
    cityController = TextEditingController(text: address?['city'] ?? '');
    stateController = TextEditingController(text: address?['state'] ?? '');
    postalController = TextEditingController(
      text: address?['postalCode'] ?? '',
    );
    countryController = TextEditingController(text: address?['country'] ?? '');
    isDefault = address?['isDefault'] ?? false;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    line1Controller.dispose();
    line2Controller.dispose();
    cityController.dispose();
    stateController.dispose();
    postalController.dispose();
    countryController.dispose();
    super.dispose();
  }

  Future<void> saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    setState(() => _isLoading = true);

    final body = json.encode({
      'fullName': fullNameController.text.trim(),
      'phoneNumber': phoneController.text.trim(),
      'addressLine1': line1Controller.text.trim(),
      'addressLine2': line2Controller.text.trim(),
      'city': cityController.text.trim(),
      'state': stateController.text.trim(),
      'postalCode': postalController.text.trim(),
      'country': countryController.text.trim(),
      'isDefault': isDefault,
    });

    final isEdit = widget.address != null;
    final url = isEdit
        ? Uri.parse('${ApiConstants.baseUrl}/address/${widget.address!['_id']}')
        : Uri.parse('${ApiConstants.baseUrl}/address');

    try {
      final response = await (isEdit
          ? http.put(
              url,
              headers: {
                'Authorization': 'Bearer ${widget.token}',
                'Content-Type': 'application/json',
              },
              body: body,
            )
          : http.post(
              url,
              headers: {
                'Authorization': 'Bearer ${widget.token}',
                'Content-Type': 'application/json',
              },
              body: body,
            ));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar(
          isEdit ? '✓ Address updated successfully' : '✓ Address added successfully',
          Colors.green,
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showSnackBar('Failed to save address: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Network error. Please try again.', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF2596BE),
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            icon,
            color: Color(0xFF2596BE),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2596BE), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
        textCapitalization: textCapitalization,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2596BE).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2596BE), size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.address != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Address' : 'Add New Address',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFFB2DFDB),
        foregroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Contact Information Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Contact Information', Icons.person_outline),
                  
                  _buildTextField(
                    controller: fullNameController,
                    label: 'Receiver Name',
                    icon: Icons.person,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Receiver name is required';
                      }
                      return null;
                    },
                  ),

                  _buildTextField(
                    controller: phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value.trim())) {
                        return 'Enter a valid phone number (10–15 digits)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Address Details Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Address Details', Icons.location_on_outlined),

                  _buildTextField(
                    controller: line1Controller,
                    label: 'Address Line 1',
                    icon: Icons.home,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Address Line 1 is required';
                      }
                      return null;
                    },
                  ),

                  _buildTextField(
                    controller: line2Controller,
                    label: 'Address Line 2 (Optional)',
                    icon: Icons.home_outlined,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: cityController,
                          label: 'City',
                          icon: Icons.location_city,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'City is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: postalController,
                          label: 'Postal Code',
                          icon: Icons.markunread_mailbox,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: stateController,
                          label: 'State',
                          icon: Icons.map,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'State is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: countryController,
                          label: 'Country',
                          icon: Icons.public,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Default Address Toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.star, color: Color(0xFF2596BE), size: 22),
                    SizedBox(width: 12),
                    Text(
                      'Set as default address',
                      style: TextStyle(
                        color: Color(0xFF263238),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(left: 34, top: 4),
                  child: Text(
                    'This will be used for new orders',
                    style: TextStyle(
                      color: Color(0xFF546E7A),
                      fontSize: 13,
                    ),
                  ),
                ),
                value: isDefault,
                activeThumbColor: const Color(0xFF2596BE),
                onChanged: (val) => setState(() => isDefault = val),
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2596BE),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isEdit ? Icons.check_circle : Icons.add_location_alt, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            isEdit ? 'Update Address' : 'Save Address',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}