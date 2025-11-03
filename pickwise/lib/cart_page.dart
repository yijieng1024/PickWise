import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<dynamic> cartItems = [];
  bool isLoading = true;
  String? userId;

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

    // print("🧾 Cart API Response: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      // print("🧩 Decoded JSON: $decoded");

      setState(() {
        cartItems = decoded['items']; // ✅ Extract only the items array
        isLoading = false;
      });

      // print("🛒 Cart items loaded: $cartItems");
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
      });
    } else {
      debugPrint('Failed to remove item: ${response.statusCode}');
    }
  }

  double get totalPrice {
    return cartItems.fold(0.0, (sum, item) {
      final laptop = item['laptopId'];
      if (laptop != null && laptop['price_rm'] != null) {
        return sum + (laptop['price_rm'] as num).toDouble() * (item['quantity'] ?? 1);
      }
      return sum;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Cart", style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: Colors.black,
        backgroundColor: const Color(0xFFB2DFDB),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? const Center(
                  child: Text(
                    "Your cart is empty.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final laptop = item['laptopId'];
                    final quantity = item['quantity'];
                    final price = double.tryParse(laptop['price_rm'].toString()) ?? 0.0;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: laptop['imageURL'] != null
                            ? Image.asset(
                                'assets/${laptop['imageURL'].split(";").first.trim()}',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image),
                              )
                            : const Icon(Icons.laptop, size: 50),
                        title: Text(
                          laptop['product_name'] ?? 'Unnamed Laptop',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("RM ${price.toStringAsFixed(2)}"),
                            const SizedBox(height: 4),
                            Text("Qty: $quantity"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeItem(laptop['_id']),
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Total: RM ${totalPrice.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Checkout logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Checkout feature coming soon!")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ACC1),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Checkout"),
            ),
          ],
        ),
      ),
    );
  }
}
