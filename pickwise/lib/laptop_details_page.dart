import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'api_constants.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LaptopDetailsPage extends StatefulWidget {
  final Map<String, dynamic> laptop;

  const LaptopDetailsPage({super.key, required this.laptop});

  @override
  State<LaptopDetailsPage> createState() => _LaptopDetailsPageState();
}

class _LaptopDetailsPageState extends State<LaptopDetailsPage> {
  int _currentImageIndex = 0;
  bool _isAddingToCart = false;

  Future<Map<String, String?>> getUserIdFromToken(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token != null && !JwtDecoder.isExpired(token)) {
      final decoded = JwtDecoder.decode(token);
      debugPrint("🔍 Decoded JWT: $decoded");
      return {
        'userId': decoded['id']?.toString(),
        'userName': decoded['name']?.toString()
      };
    }

    debugPrint("⚠️ No valid JWT token found. Redirecting to login...");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed('/login');
    });

    return {'userId': null, 'userName': null};
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00ACC1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconForSection(title),
                  color: const Color(0xFF00ACC1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
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
    );
  }

  IconData _getIconForSection(String title) {
    switch (title) {
      case 'Specifications':
        return Icons.memory;
      case 'Warranty':
        return Icons.verified_user;
      case 'Release Year':
        return Icons.calendar_today;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final laptop = widget.laptop;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          laptop['product_name'] ?? 'Laptop Details',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFFB2DFDB),
        foregroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            Stack(
              children: [
                _buildLaptopImage(laptop),
                // Image indicator dots
                if (_getImagePaths(laptop).length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _getImagePaths(laptop).length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentImageIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index
                                ? const Color(0xFF00ACC1)
                                : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
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
                        // Brand Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00ACC1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            laptop['brand'] ?? 'Unknown Brand',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00ACC1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Product Name
                        Text(
                          laptop['product_name'] ?? 'Unnamed Laptop',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF263238),
                          ),
                        ),
                        
                        // Model Codes
                        if (laptop['model_code'] != null &&
                            laptop['model_code'].toString().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.qr_code,
                                      size: 16,
                                      color: Color(0xFF546E7A),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Model Codes:",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF546E7A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ...laptop['model_code']
                                    .toString()
                                    .split(';')
                                    .map((code) => Padding(
                                          padding: const EdgeInsets.only(
                                              left: 20, top: 2),
                                          child: Text(
                                            '• ${code.trim()}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF546E7A),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Price',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF546E7A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              (laptop['price_rm'] != null)
                                  ? 'RM ${laptop['price_rm']}'
                                  : 'N/A',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00ACC1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Release Year
                  _buildInfoCard(
                    title: 'Release Year',
                    child: Text(
                      laptop['release_year']?.toString() ?? 'Unknown Year',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF263238),
                      ),
                    ),
                  ),

                  // Specifications
                  _buildInfoCard(
                    title: 'Specifications',
                    child: _buildSpecsList(laptop),
                  ),

                  // Warranty
                  _buildInfoCard(
                    title: 'Warranty',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF00ACC1),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            laptop['warranty']?.toString() ??
                                'Unknown Warranty',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF263238),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Action Bar
      bottomNavigationBar: Container(
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
          child: Row(
            children: [
              // Ask Chatbot button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Ask Chatbot Feature Coming Soon!"),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: const Text(
                    "Ask Chatbot",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF00ACC1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Add to Cart button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isAddingToCart
                      ? null
                      : () async {
                          setState(() => _isAddingToCart = true);

                          final user = await getUserIdFromToken(context);
                          final userId = user['userId'];

                          try {
                            final response = await http.post(
                              Uri.parse('${ApiConstants.baseUrl}/api/cart/add'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'userId': userId,
                                'laptopId': laptop['_id'],
                                'quantity': 1,
                              }),
                            );

                            if (response.statusCode == 200) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: Colors.white),
                                        SizedBox(width: 8),
                                        Text("Added to Cart Successfully!"),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Failed to add to cart"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isAddingToCart = false);
                            }
                          }
                        },
                  icon: _isAddingToCart
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.add_shopping_cart, size: 20),
                  label: Text(
                    _isAddingToCart ? "Adding..." : "Add to Cart",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getImagePaths(Map<String, dynamic> laptop) {
    return laptop['imageURL']
            ?.toString()
            .split(RegExp(r'[;,]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
  }

  Widget _buildSpecsList(Map<String, dynamic> laptop) {
    final rawSsd = laptop['ssd_gb']?.toString().trim().toLowerCase() ?? '0';
    final numericPart =
        RegExp(r'(\d+(\.\d+)?)').firstMatch(rawSsd)?.group(0) ?? '0';
    final ssdValue = double.tryParse(numericPart) ?? 0.0;

    String formattedSsd;
    if (ssdValue >= 1000) {
      formattedSsd = '${(ssdValue / 1000).round()}TB';
    } else {
      formattedSsd = '${ssdValue.round()}GB';
    }

    final copilotSupport = laptop['copilot_support'] == true ? 'Yes' : 'No';

    if (laptop['expansion_slots'] == null ||
        laptop['expansion_slots'].toString().isEmpty ||
        laptop['expansion_slots'].toString() == '-') {
      laptop['expansion_slots'] = 'None';
    }

    String formatPorts(String? ports) {
      if (ports == null || ports.trim().isEmpty) {
        return "Unknown Ports";
      }
      List<String> portList = ports.split(';').map((p) => p.trim()).toList();
      return portList.map((p) => "\t - $p").join('\n');
    }

    final List<Map<String, String>> specs = [
      {"title": "Color", "value": laptop['color'] ?? 'Unknown'},
      {"title": "Copilot Support", "value": copilotSupport},
      {
        "title": "Processor",
        "value":
            "${laptop['processor_name'] ?? 'Unknown CPU'} ${(laptop['processor_ghz']?.toString() ?? '')} Ghz"
      },
      {"title": "RAM", "value": "${laptop['ram_gb']?.toString() ?? ''} GB"},
      {"title": "SSD", "value": formattedSsd},
      {"title": "GPU Brand", "value": laptop['gpu_brand'] ?? ''},
      {"title": "GPU Model", "value": laptop['gpu_model'] ?? ''},
      {
        "title": "Display",
        "value":
            "${laptop['display_type'] ?? ''} ${(laptop['display_resolution']?.toString().isNotEmpty ?? false) ? laptop['display_resolution'] : 'Unknown Resolution'} ${(laptop['display_size_inches'] ?? 'Unknown Size')} inches"
      },
      {"title": "I/O Ports", "value": "\n${formatPorts(laptop['io_ports'])}"},
      {"title": "Network", "value": laptop['network'] ?? 'Unknown Network'},
      {
        "title": "Bluetooth",
        "value": laptop['bluetooth'] ?? 'Unknown Bluetooth'
      },
      {
        "title": "Battery",
        "value": laptop['battery_capacity_wh'] != null
            ? "${laptop['battery_capacity_wh']} Wh"
            : 'Unknown Battery'
      },
      {
        "title": "Power Supply",
        "value": laptop['power_supply'] ?? 'Unknown Power Supply'
      },
      {
        "title": "Weight",
        "value": "${laptop['weight_kg']?.toString() ?? 'Unknown'} kg"
      },
      {"title": "Dimensions", "value": laptop['dimension_cm'] ?? 'Unknown'},
      {"title": "Expansion Slots", "value": laptop['expansion_slots'] ?? ''},
      {"title": "Operating System", "value": laptop['os'] ?? 'Unknown OS'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: specs
          .where((spec) => spec['value'] != null && spec['value']!.isNotEmpty)
          .map((spec) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00ACC1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF263238),
                          ),
                          children: [
                            TextSpan(
                              text: "${spec['title']}: ",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263238),
                              ),
                            ),
                            TextSpan(
                              text: spec['value'],
                              style: const TextStyle(
                                color: Color(0xFF546E7A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildLaptopImage(Map<String, dynamic> laptop) {
    final List<String> imagePaths = _getImagePaths(laptop);
    final assetPaths = imagePaths.map((path) => 'assets/$path').toList();

    if (assetPaths.isEmpty) {
      return Container(
        height: 350,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: CarouselSlider(
        options: CarouselOptions(
          autoPlay: assetPaths.length > 1,
          enlargeCenterPage: false,
          height: 400,
          viewportFraction: 1.0,
          onPageChanged: (index, reason) {
            setState(() {
              _currentImageIndex = index;
            });
          },
        ),
        items: assetPaths.map((assetPath) {
          return Builder(
            builder: (BuildContext context) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}