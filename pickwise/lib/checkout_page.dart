import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'dart:async';
import 'card_payment_page.dart';
import 'online_banking_page.dart';
import 'ewallet_payment_page.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  final List<dynamic> selectedItems;

  const CheckoutPage({super.key, required this.selectedItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // USER & AUTH
  String username = "";
  String userId = "";
  String? token;

  // ADDRESS
  List<Map<String, dynamic>> addresses = [];
  bool isAddressLoading = true;
  String? selectedAddressId;
  String address = "";

  // ORDER DETAILS
  String remark = "";
  String selectedDelivery = "Standard Delivery";
  String selectedPayment = "Online Banking";
  String appliedVoucher = "";
  final TextEditingController _voucherController = TextEditingController();

  double merchandiseSubtotal = 0;
  double shippingFee = 5.00;
  double sstRate = 0.06;
  double discount = 0;
  double totalPay = 0;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    fetchUserFromToken();
    calculateTotals();
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> fetchUserFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('jwt_token');

    if (storedToken == null) {
      setState(() {
        username = "Guest";
        isAddressLoading = false;
      });
      return;
    }

    try {
      final decoded = JwtDecoder.decode(storedToken);
      setState(() {
        username = decoded['userName'] ?? 'User';
        token = storedToken;
      });

      await _fetchAddresses();
    } catch (e) {
      setState(() => isAddressLoading = false);
      _showError('Error decoding token: $e');
    }
  }

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('jwt_token');
    if (t == null) return;

    final decoded = JwtDecoder.decode(t);
    userId = decoded['id']?.toString() ?? '';
  }

  Future<void> _fetchAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('jwt_token');

    if (t == null) {
      setState(() => isAddressLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/address'),
        headers: {'Authorization': 'Bearer $t'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> raw = json.decode(response.body);
        setState(() {
          addresses = raw.cast<Map<String, dynamic>>();
          isAddressLoading = false;

          if (addresses.isNotEmpty) {
            final defaultAddr = addresses.firstWhere(
              (a) => a['isDefault'] == true,
              orElse: () => addresses.first,
            );
            selectedAddressId = defaultAddr['_id'] as String;
            address = _formatAddress(defaultAddr);
          }
        });
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } on TimeoutException {
      _showError("Request timed out. Check your internet.");
      setState(() => isAddressLoading = false);
    } catch (e) {
      _showError("Failed to load addresses: $e");
      setState(() => isAddressLoading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  String _formatAddress(Map<String, dynamic> addr) {
    final line1 = addr['addressLine1']?.toString().trim() ?? '';
    final line2 = (addr['addressLine2']?.toString().trim().isNotEmpty == true)
        ? '${addr['addressLine2']}, '
        : '';
    final city = addr['city']?.toString().trim() ?? '';
    final state = addr['state']?.toString().trim() ?? '';
    final postal = addr['postalCode']?.toString().trim() ?? '';
    final country = addr['country']?.toString().trim() ?? '';

    return '$line1, $line2$city, $state $postal, $country'
        .replaceAll(', ,', ',')
        .replaceAll(RegExp(r',\s*$'), '')
        .trim();
  }

  void calculateTotals() {
    double total = 0;
    
    print('=== DEBUG: Calculate Totals ===');
    print('Selected Items Count: ${widget.selectedItems.length}');
    
    for (var item in widget.selectedItems) {
      print('Item: $item');
      
      final laptop = item['laptopId'];
      print('Laptop data: $laptop');
      
      if (laptop != null) {
        // Try different possible field names for price
        var priceValue = laptop['price_rm'] ?? laptop['price'] ?? laptop['Price_RM'];
        print('Price value found: $priceValue (type: ${priceValue.runtimeType})');
        
        double price = 0.0;
        
        if (priceValue != null) {
          if (priceValue is num) {
            price = priceValue.toDouble();
          } else {
            // Remove RM prefix and any spaces if present
            String priceStr = priceValue.toString().trim();
            priceStr = priceStr.replaceAll('RM', '').replaceAll(' ', '').trim();
            price = double.tryParse(priceStr) ?? 0.0;
          }
        }
        
        int qty = item['quantity'] ?? 1;
        print('Parsed price: $price, Quantity: $qty, Subtotal: ${price * qty}');
        
        total += price * qty;
      } else {
        print('Laptop is null for this item');
      }
    }
    
    print('Final total: $total');
    print('=== END DEBUG ===');

    setState(() {
      merchandiseSubtotal = total;
      _recalculateTotal();
    });
  }

  void _recalculateTotal() {
    double sst = merchandiseSubtotal * sstRate;
    double total = merchandiseSubtotal + shippingFee + sst - discount;
    setState(() => totalPay = total);
  }

  void _applyVoucher(String code) {
    setState(() {
      if (code.trim().toUpperCase() == "PICK10") {
        discount = merchandiseSubtotal * 0.1;
        appliedVoucher = code;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Voucher applied successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        discount = 0;
        appliedVoucher = "";
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid voucher code"),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      _recalculateTotal();
    });
  }

 Future<void> handleCheckout() async {
  if (widget.selectedItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select at least one product")),
    );
    return;
  }

  if (selectedAddressId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select a delivery address")),
    );
    return;
  }

  try {
    // Step 1: Create Order
    final orderId = await _createOrder();
    
    if (orderId == null) return;

    // Step 2: Initiate Payment
    final paymentId = await _initiatePayment(orderId);
    
    if (paymentId == null) return;

    // Step 3: Navigate to appropriate payment page
    final result = await _navigateToPaymentPage(paymentId);

    if (result == true) {
      // Payment successful - navigate to success page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderSuccessPage(orderId: orderId),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<String?> _createOrder() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    print('=== Creating Order ===');
    print('Token: ${token?.substring(0, 20)}...');
    print('Address ID: $selectedAddressId');
    print('Items: ${widget.selectedItems.length}');

    final items = widget.selectedItems.map((item) {
      print('Item: ${item['laptopId']['_id']} x ${item['quantity']}');
      return {
        'laptopId': item['laptopId']['_id'],
        'quantity': item['quantity']
      };
    }).toList();

    final orderData = {
      'addressId': selectedAddressId,
      'items': items,
      'merchandiseSubtotal': merchandiseSubtotal,
      'shippingFee': shippingFee,
      'sstRate': sstRate,
      'sstAmount': merchandiseSubtotal * sstRate,
      'discount': discount,
      'totalAmount': totalPay,
      'deliveryOption': selectedDelivery,
      'paymentMethod': selectedPayment,
      'appliedVoucher': appliedVoucher,
      'remark': remark,
    };

    print('Order Data: ${json.encode(orderData)}');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/order'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(orderData),
    ).timeout(const Duration(seconds: 15));

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 201) {
      final result = json.decode(response.body);
      return result['order']['_id'];
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to create order');
    }
  } catch (e) {
    print('Error creating order: $e');
    _showError('Failed to create order: $e');
    return null;
  }
}

Future<String?> _initiatePayment(String orderId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

  print('=== Initiating Payment ===');
  print('URL: ${ApiConstants.baseUrl}/api/payment/initiate');
  print('Order ID: $orderId');
  print('Payment Method: $selectedPayment');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/payment/initiate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'orderId': orderId,
        'paymentMethod': selectedPayment,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return result['paymentId'];
    } else {
      throw Exception('Failed to initiate payment');
    }
  } catch (e) {
    _showError('Failed to initiate payment: $e');
    return null;
  }
}

Future<bool?> _navigateToPaymentPage(String paymentId) async {
  Widget paymentPage;

  switch (selectedPayment) {
    case 'Credit/Debit Card':
      paymentPage = CardPaymentPage(
        paymentId: paymentId,
        amount: totalPay,
      );
      break;
    case 'Online Banking':
      paymentPage = OnlineBankingPage(
        paymentId: paymentId,
        amount: totalPay,
      );
      break;
    case 'E-Wallet':
      paymentPage = EWalletPaymentPage(
        paymentId: paymentId,
        amount: totalPay,
      );
      break;
    default:
      _showError('Invalid payment method');
      return null;
  }

  return await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (context) => paymentPage),
  );
}

  // UI HELPERS
  Widget _buildSectionCard({required String title, required Widget child, IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: const Color(0xFF00897B), size: 24),
                  const SizedBox(width: 12),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic item) {
    final laptop = item['laptopId'];
    final productName = laptop?['product_name'] ?? "Unknown Laptop";
    final price = double.tryParse(laptop?['price_rm']?.toString() ?? '') ?? 0.0;
    final quantity = item['quantity'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: laptop['imageURL'] != null
                  ? Image.asset(
                      'assets/${laptop['imageURL'].split(";").first.trim()}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.laptop_mac,
                        color: Color(0xFF00897B),
                        size: 32,
                      ),
                    )
                  : const Icon(Icons.laptop_mac, color: Color(0xFF00897B), size: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF263238),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "RM ${price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00897B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFB2DFDB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "x$quantity",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddAddressPrompt() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/address_book'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD54F)),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_location_alt, color: Color(0xFFF57C00)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "No address saved",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFE65100)),
                  ),
                  Text(
                    "Tap to add a delivery address",
                    style: TextStyle(fontSize: 13, color: Color(0xFF795548)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF795548)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedAddressId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00897B)),
          style: const TextStyle(color: Color(0xFF263238), fontSize: 14),
          itemHeight: null, // Allow dynamic height
          selectedItemBuilder: (BuildContext context) {
            // Compact view when dropdown is closed
            return addresses.map((addr) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          addr['fullName'] ?? 'No Name',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF263238),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (addr['isDefault'] == true)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB2DFDB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "Default",
                            style: TextStyle(fontSize: 10, color: Colors.black87),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatAddress(addr),
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            }).toList();
          },
          items: addresses.map((addr) {
            return DropdownMenuItem<String>(
              value: addr['_id']?.toString(),
              child: Container(
                constraints: const BoxConstraints(minHeight: 80),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            addr['fullName'] ?? 'No Name',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 15,
                              color: Color(0xFF263238),
                            ),
                          ),
                        ),
                        if (addr['isDefault'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB2DFDB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "Default",
                              style: TextStyle(fontSize: 10, color: Colors.black87),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatAddress(addr),
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedAddressId = value;
              final selected = addresses.firstWhere((a) => a['_id'] == value);
              address = _formatAddress(selected);
            });
          },
        ),
      ),
    );
  }

  Widget _summaryRow(String title, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: const Color(0xFF546E7A),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? const Color(0xFF263238),
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
        title: const Text("Checkout", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFFB2DFDB),
        foregroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DELIVERY INFORMATION
                _buildSectionCard(
                  title: "Delivery Information",
                  icon: Icons.location_on,
                  child: isAddressLoading
                      ? const Center(child: CircularProgressIndicator())
                      : addresses.isEmpty
                          ? _buildAddAddressPrompt()
                          : _buildAddressDropdown(),
                ),

                // ORDER ITEMS
                _buildSectionCard(
                  title: "Order Items",
                  icon: Icons.shopping_bag,
                  child: Column(
                    children: widget.selectedItems.map((item) => _buildProductCard(item)).toList(),
                  ),
                ),

                // VOUCHER
                _buildSectionCard(
                  title: "Apply Voucher",
                  icon: Icons.confirmation_number,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _voucherController,
                          decoration: InputDecoration(
                            hintText: "Enter code (e.g., PICK10)",
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _applyVoucher(_voucherController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text("Apply", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // DELIVERY OPTION
                _buildSectionCard(
                  title: "Delivery Option",
                  icon: Icons.local_shipping,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedDelivery,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00897B)),
                      items: const [
                        DropdownMenuItem(value: "Standard Delivery", child: Text("Standard Delivery (3-5 days)")),
                        DropdownMenuItem(value: "Express Delivery", child: Text("Express Delivery (1-2 days)")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedDelivery = value!;
                          shippingFee = (value == "Express Delivery") ? 10.00 : 5.00;
                          _recalculateTotal();
                        });
                      },
                    ),
                  ),
                ),

                // PAYMENT METHOD
                _buildSectionCard(
                  title: "Payment Method",
                  icon: Icons.payment,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedPayment,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00897B)),
                      items: const [
                        DropdownMenuItem(value: "Online Banking", child: Text("Online Banking")),
                        // N/A
                        //DropdownMenuItem(value: "Credit/Debit Card", child: Text("Credit/Debit Card")),
                        //DropdownMenuItem(value: "E-Wallet", child: Text("E-Wallet (Touch 'n Go, GrabPay)")),
                      ],
                      onChanged: (value) => setState(() => selectedPayment = value!),
                    ),
                  ),
                ),

                // PAYMENT SUMMARY
                _buildSectionCard(
                  title: "Payment Summary",
                  icon: Icons.receipt_long,
                  child: Column(
                    children: [
                      _summaryRow("Merchandise Subtotal", "RM ${merchandiseSubtotal.toStringAsFixed(2)}"),
                      _summaryRow("Shipping Fee", "RM ${shippingFee.toStringAsFixed(2)}"),
                      _summaryRow("SST (6%)", "RM ${(merchandiseSubtotal * sstRate).toStringAsFixed(2)}"),
                      if (discount > 0)
                        _summaryRow("Discount", "- RM ${discount.toStringAsFixed(2)}", color: Colors.green),
                      const Divider(height: 24, thickness: 1.5),
                      _summaryRow(
                        "Total Payment",
                        "RM ${totalPay.toStringAsFixed(2)}",
                        isBold: true,
                        color: const Color(0xFF00897B),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),

          // PLACE ORDER BUTTON
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2)),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: handleCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        "Place Order • RM ${totalPay.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}