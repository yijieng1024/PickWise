import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<dynamic> cartItems = [];
  Set<String> selectedItems = {};
  bool isLoading = true;
  String? userId;
  bool selectAll = false;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || JwtDecoder.isExpired(token)) {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    final decoded = JwtDecoder.decode(token);
    userId = decoded['id'];

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/cart/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          cartItems = decoded['items'];
          isLoading = false;
        });
      } else {
        debugPrint('❌ Error loading cart: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching cart: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _removeItem(String laptopId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Remove Item'),
          ],
        ),
        content: const Text('Remove this item from your cart?'),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || userId == null) return;

    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/api/cart/remove/$userId/$laptopId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        cartItems.removeWhere((item) => item['laptopId']?['_id'] == laptopId);
        selectedItems.remove(laptopId);
        _updateSelectAll();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Item removed from cart'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      debugPrint('Failed to remove item: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to remove item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (selectAll) {
        selectedItems.clear();
        selectAll = false;
      } else {
        selectedItems = cartItems.map((item) => item['laptopId']['_id'] as String).toSet();
        selectAll = true;
      }
    });
  }

  void _updateSelectAll() {
    setState(() {
      selectAll = cartItems.isNotEmpty && selectedItems.length == cartItems.length;
    });
  }

  double get totalSelectedPrice {
    double total = 0.0;
    for (var item in cartItems) {
      final laptop = item['laptopId'];
      if (selectedItems.contains(laptop['_id'])) {
        final price = double.tryParse(laptop['price_rm'].toString()) ?? 0.0;
        total += price * (item['quantity'] ?? 1);
      }
    }
    return total;
  }

  Widget _buildCartItem(dynamic item) {
    final laptop = item['laptopId'];
    final quantity = item['quantity'];
    final price = double.tryParse(laptop['price_rm'].toString()) ?? 0.0;
    final laptopId = laptop['_id'];
    final isSelected = selectedItems.contains(laptopId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
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
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedItems.remove(laptopId);
              } else {
                selectedItems.add(laptopId);
              }
              _updateSelectAll();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFB2DFDB) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xFFB2DFDB) : Colors.grey[400]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.black)
                      : null,
                ),

                const SizedBox(width: 16),

                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: laptop['imageURL'] != null
                        ? Image.asset(
                            'assets/${laptop['imageURL'].split(";").first.trim()}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.laptop_mac,
                              size: 40,
                              color: Color(0xFFB2DFDB),
                            ),
                          )
                        : const Icon(
                            Icons.laptop_mac,
                            size: 40,
                            color: Color(0xFFB2DFDB),
                          ),
                  ),
                ),

                const SizedBox(width: 16),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        laptop['product_name'] ?? 'Unnamed Laptop',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "RM ${price.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB2DFDB),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Qty: $quantity",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF546E7A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Delete Button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                  onPressed: () => _removeItem(laptopId),
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
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Start Shopping'),
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
          "Shopping Cart",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        foregroundColor: Colors.black,
        backgroundColor: const Color(0xFFB2DFDB),
        centerTitle: true,
        elevation: 0,
        actions: cartItems.isEmpty
            ? null
            : [
                TextButton.icon(
                  onPressed: _toggleSelectAll,
                  icon: Icon(
                    selectAll ? Icons.check_box : Icons.check_box_outline_blank,
                    color: Colors.black,
                  ),
                  label: const Text(
                    'Select All',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
              ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB2DFDB),
              ),
            )
          : cartItems.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Cart Summary Header
                    if (cartItems.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB2DFDB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFB2DFDB).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFF00897B)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${cartItems.length} item${cartItems.length > 1 ? 's' : ''} in cart',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF263238),
                                ),
                              ),
                            ),
                            if (selectedItems.isNotEmpty)
                              Text(
                                '${selectedItems.length} selected',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF546E7A),
                                ),
                              ),
                          ],
                        ),
                      ),

                    // Cart Items List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          return _buildCartItem(cartItems[index]);
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Total Amount Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Amount",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF546E7A),
                              ),
                            ),
                            SizedBox(height: 4),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (selectedItems.isNotEmpty)
                              Text(
                                "${selectedItems.length} item${selectedItems.length > 1 ? 's' : ''}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF546E7A),
                                ),
                              ),
                            Text(
                              "RM ${totalSelectedPrice.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB2DFDB),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Checkout Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: selectedItems.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CheckoutPage(
                                      selectedItems: cartItems
                                          .where((item) =>
                                              selectedItems.contains(item['laptopId']['_id']))
                                          .toList(),
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedItems.isEmpty
                              ? Colors.grey[300]
                              : const Color(0xFFB2DFDB),
                          foregroundColor: selectedItems.isEmpty ? Colors.grey : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_bag, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              selectedItems.isEmpty ? "Select items to checkout" : "Proceed to Checkout",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}