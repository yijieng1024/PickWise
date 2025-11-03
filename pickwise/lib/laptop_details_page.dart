import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'api_constants.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LaptopDetailsPage extends StatelessWidget {
  final Map<String, dynamic> laptop;

  const LaptopDetailsPage({super.key, required this.laptop});

  Future<Map<String, String?>> getUserIdFromToken(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    // Check if token exists and is still valid
    if (token != null && !JwtDecoder.isExpired(token)) {
      final decoded = JwtDecoder.decode(token);
      debugPrint("🔍 Decoded JWT: $decoded");
      return {
        'userId': decoded['id']?.toString(),
        'userName': decoded['name']?.toString()
      };
    }

    // If no valid token, redirect to login
    debugPrint("⚠️ No valid JWT token found. Redirecting to login...");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed('/login');
    });

    return {'userId': null, 'userName': null};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(laptop['product_name'] ?? 'Laptop Details'),
      ),

      // 🧱 Main scrollable content
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLaptopImage(laptop),
            const SizedBox(height: 12),
            Text(
              laptop['brand'] ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              laptop['product_name'] ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
          if (laptop['model_code'] != null && laptop['model_code'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text(
                "Model Code:",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: laptop['model_code']
                    .toString()
                    .split(';')
                    .map((code) => Text(
                          '• ${code.trim()}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                (laptop['price_rm'] != null)
                    ? 'RM ${laptop['price_rm']}'
                    : 'N/A',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00ACC1),
                ),
              ),
            ),
            Text(
              "Release Year:",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              laptop['release_year']?.toString() ?? 'Unknown Year',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 15),
            const Text(
              "Specification",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            _buildSpecsList(laptop),
            const SizedBox(height: 8),
            Text(
              "Warranty:", 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              laptop['warranty']?.toString() ?? 'Unknown Warranty',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 100), // spacing so content doesn’t get hidden under buttons
          ],
        ),
      ),

      // 🧠 & 🛒 Buttons (moved out of body)
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 🧠 Ask Chatbot button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // 👉 navigate to chatbot page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ask Chatbot Feature Coming Soon!")),
                  );
                    /*
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatbotPage(
                        userId: widget.userId,
                        userName: widget.userName,
                      ),
                    ),*/
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text("Ask Chatbot"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF00ACC1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 🛒 Add to Cart button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final userId = await getUserIdFromToken(context);
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Added to Cart Successfully!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Failed to add to cart"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text("Add to Cart"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }


  Widget _buildSpecsList(Map<String, dynamic> laptop) {
    final rawSsd = laptop['ssd_gb']?.toString().trim().toLowerCase() ?? '0';

    // Extract numeric portion (handles “512”, “512.0GB”, “SSD 1.0 TB”)
    final numericPart =
        RegExp(r'(\d+(\.\d+)?)').firstMatch(rawSsd)?.group(0) ?? '0';

    // Convert safely to double
    final ssdValue = double.tryParse(numericPart) ?? 0.0;

    // Format without decimals
    String formattedSsd;
    if (ssdValue >= 1000) {
      formattedSsd = '${(ssdValue / 1000).round()}TB';
    } else {
      formattedSsd = '${ssdValue.round()}GB';
    }

    // copilot support bool to Yes/No
    final copilotSupport = laptop['copilot_support'] == true ? 'Yes' : 'No';

    // if expansion slots is empty, show None
    if (laptop['expansion_slots'] == null ||
        laptop['expansion_slots'].toString().isEmpty ||
        laptop['expansion_slots'].toString() == '-') {
      laptop['expansion_slots'] = 'None';
    }

    String formatPorts(String? ports) {
      if (ports == null || ports.trim().isEmpty) {
        return "Unknown Ports";
      }

      // Split by semicolon and trim spaces
      List<String> portList = ports.split(';').map((p) => p.trim()).toList();

      // Combine back into multiline bullet list
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
  {"title": "Bluetooth", "value": laptop['bluetooth'] ?? 'Unknown Bluetooth'},
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
          .map((spec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    children: [
                      const TextSpan(text: '• '), // bullet
                      TextSpan(
                        text: "${spec['title']}: ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: spec['value']),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildLaptopImage(Map<String, dynamic> laptop) {
    final List<String> imagePaths =
        laptop['imageURL']
            ?.toString()
            .split(RegExp(r'[;,]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    // Prefix assets/ to each path
    final assetPaths = imagePaths.map((path) => 'assets/$path').toList();

    if (assetPaths.isEmpty) {
      // Show placeholder when no image available
      return Container(
        height: 350,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CarouselSlider(
        options: CarouselOptions(
          autoPlay: assetPaths.length > 1, // autoplay only if more than one image
          enlargeCenterPage: true,
          height: 400, // Set specific height in pixels
          viewportFraction: 1.0, // Use 1.0 for full-width display
        ),
        items: assetPaths.map((assetPath) {
          return Builder(
            builder: (BuildContext context) {
              return Image.asset(
                assetPath,
                fit: BoxFit.cover,
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
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
