import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'addeditaddress_page.dart';

class AddressBookPage extends StatefulWidget {
  final String token;
  const AddressBookPage({super.key, required this.token});

  @override
  State<AddressBookPage> createState() => _AddressBookPageState();
}

class _AddressBookPageState extends State<AddressBookPage> {
  List<dynamic> addresses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/address'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      print("Token: ${widget.token}");

      if (response.statusCode == 200) {
        setState(() {
          addresses = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load addresses'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteAddress(String id) async {
    // Show confirmation dialog
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        fetchAddresses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Address deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> setDefaultAddress(String id) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/address/$id/default'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        fetchAddresses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Default address updated'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set default: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void openAddEditPage({Map<String, dynamic>? address}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEditAddressPage(address: address, token: widget.token),
      ),
    );

    if (result == true) {
      fetchAddresses();
    }
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    final isDefault = address['isDefault'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDefault
            ? Border.all(color: const Color(0xFFB2DFDB), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
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
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name and Default Badge
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: Color(0xFFB2DFDB),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              address['fullName'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263238),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB2DFDB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'DEFAULT',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Menu Button
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Color(0xFF546E7A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          openAddEditPage(address: address);
                        } else if (value == 'delete') {
                          deleteAddress(address['_id']);
                        } else if (value == 'default') {
                          setDefaultAddress(address['_id']);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20, color: Color(0xFFB2DFDB)),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        if (!isDefault)
                          const PopupMenuItem(
                            value: 'default',
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 20, color: Color(0xFFB2DFDB)),
                                SizedBox(width: 12),
                                Text('Set as Default'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Address Details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address Icon and Lines
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFFB2DFDB),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  address['addressLine1'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF263238),
                                    height: 1.5,
                                  ),
                                ),
                                if (address['addressLine2']?.isNotEmpty == true)
                                  Text(
                                    address['addressLine2'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF263238),
                                      height: 1.5,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  '${address['postalCode']} ${address['city']}, '
                                  '${address['state']}, ${address['country']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF546E7A),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Phone Number
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            color: Color(0xFFB2DFDB),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            address['phoneNumber'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF263238),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
          Icon(
            Icons.location_off,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No addresses yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first delivery address',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => openAddEditPage(),
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Add Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB2DFDB),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
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
        title: const Text(
          'Address Book',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFFB2DFDB),
        foregroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: addresses.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => openAddEditPage(),
              label: const Text(
                "Add Address",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.add_location_alt),
              backgroundColor: const Color(0xFFB2DFDB),
              foregroundColor: Colors.black,
              elevation: 4,
            ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB2DFDB),
              ),
            )
          : addresses.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: const Color(0xFFB2DFDB),
                  onRefresh: fetchAddresses,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      return _buildAddressCard(addresses[index]);
                    },
                  ),
                ),
    );
  }
}