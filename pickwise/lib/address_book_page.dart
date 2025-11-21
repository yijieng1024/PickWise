import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';
import 'addeditaddress_page.dart';

class AddressBookPage extends StatefulWidget {
  const AddressBookPage({super.key});

  @override
  State<AddressBookPage> createState() => _AddressBookPageState();
}

class _AddressBookPageState extends State<AddressBookPage> {
  List<dynamic> addresses = [];
  bool isLoading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchAddresses();
  }

  // Load token from SharedPreferences and fetch addresses
  Future<void> _loadTokenAndFetchAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('jwt_token'); // Key you used during login

    if (token == null || token!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication token missing. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        // Optionally redirect to login
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    if (token == null) return;

    try {
      setState(() => isLoading = true);

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/address'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("Token from SharedPrefs: $token");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          addresses = data is List ? data : [];
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        _handleUnauthorized();
      } else {
        setState(() => isLoading = false);
        _showError('Failed to load addresses');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Network error: $e');
    }
  }

  void _handleUnauthorized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token'); // Clear invalid token

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> deleteAddress(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Delete Address'),
          ],
        ),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/address/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        fetchAddresses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address deleted'), backgroundColor: Colors.green),
        );
      } else {
        _showError('Failed to delete: ${response.body}');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> setDefaultAddress(String id) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/address/$id/default'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        fetchAddresses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default address updated'), backgroundColor: Colors.green),
        );
      } else {
        _showError('Failed: ${response.body}');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void openAddEditPage({Map<String, dynamic>? address}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAddressPage(address: address, token: token!),
      ),
    );

    if (result == true) {
      fetchAddresses();
    }
  }

  // Reuse your existing _buildAddressCard and _buildEmptyState methods
  // (Copy them exactly as they were — no changes needed except using `token` from state)

  Widget _buildAddressCard(Map<String, dynamic> address) {
    final isDefault = address['isDefault'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDefault ? Border.all(color: const Color(0xFFB2DFDB), width: 2) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => openAddEditPage(address: address),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFFB2DFDB), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              address['fullName'] ?? '',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFB2DFDB), borderRadius: BorderRadius.circular(12)),
                              child: const Text('DEFAULT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Color(0xFF546E7A)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'edit') openAddEditPage(address: address);
                        if (value == 'delete') deleteAddress(address['_id']);
                        if (value == 'default') setDefaultAddress(address['_id']);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Color(0xFFB2DFDB)), SizedBox(width: 12), Text('Edit')])),
                        if (!isDefault) const PopupMenuItem(value: 'default', child: Row(children: [Icon(Icons.star, color: Color(0xFFB2DFDB)), SizedBox(width: 12), Text('Set as Default')])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFFB2DFDB), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(address['addressLine1'] ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFF263238), height: 1.5)),
                                if (address['addressLine2']?.isNotEmpty == true) Text(address['addressLine2'], style: const TextStyle(fontSize: 14, color: Color(0xFF263238), height: 1.5)),
                                const SizedBox(height: 4),
                                Text('${address['postalCode']} ${address['city']}, ${address['state']}, ${address['country']}', style: const TextStyle(fontSize: 14, color: Color(0xFF546E7A))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Color(0xFFB2DFDB), size: 20),
                          const SizedBox(width: 12),
                          Text(address['phoneNumber'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text('No addresses yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Add your first delivery address', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => openAddEditPage(),
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Add Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB2DFDB),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Address Book', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFFB2DFDB),
        foregroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: addresses.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => openAddEditPage(),
              label: const Text("Add Address", style: TextStyle(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.add_location_alt),
              backgroundColor: const Color(0xFFB2DFDB),
              foregroundColor: Colors.black,
            ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB2DFDB)))
          : addresses.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: const Color(0xFFB2DFDB),
                  onRefresh: fetchAddresses,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: addresses.length,
                    itemBuilder: (context, index) => _buildAddressCard(addresses[index]),
                  ),
                ),
    );
  }
}