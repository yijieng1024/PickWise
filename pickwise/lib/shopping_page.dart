import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'api_constants.dart';
import 'laptop_details_page.dart';
import 'cart_page.dart';
import 'chatbot_page.dart';

class ShoppingPage extends StatefulWidget {
  final String userName;
  final String? userAvatar;
  final String userId;
  const ShoppingPage({
    super.key,
    required this.userName,
    this.userAvatar,
    required this.userId,
  });

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  int _selectedIndex = 0; // set index to 0 for Home tab
  List<Map<String, dynamic>> laptops = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = true;
  String? token;
  final ScrollController _scrollController = ScrollController();
  int itemsPerPage = 20;
  int currentMax = 20;

  void _onItemTapped(int index) async {
    if (index == 2) {
      // 🗨 Navigate to Chatbot Page
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || JwtDecoder.isExpired(token)) {
        // Redirect to login if not logged in
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatbotPage(
                userId: widget.userId,
                userName: widget.userName,
              ),
            ),
          );
        }
      }
    } else if (index == 3) {
      // 🛒 Navigate to Cart Page
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || JwtDecoder.isExpired(token)) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CartPage()),
          );
        }
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }


  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreLaptops();
      }
    });
    _validateTokenAndFetchData();
  }

  void _loadMoreLaptops() {
    setState(() {
      if (currentMax + itemsPerPage < laptops.length) {
        currentMax += itemsPerPage;
      } else {
        currentMax = laptops.length;
      }
    });
  }


  /// ✅ Step 1: Validate JWT token before fetching data
  Future<void> _validateTokenAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('jwt_token');

    if (savedToken == null || JwtDecoder.isExpired(savedToken)) {
      _showSessionExpiredDialog();
      return;
    }

    setState(() {
      token = savedToken;
    });

    _fetchLaptopsFromDatabase();
  }

  /// ✅ Step 2: Fetch laptops using the JWT token in header
  Future<void> _fetchLaptopsFromDatabase() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/laptops'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          laptops = data.map((item) => item as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _showSessionExpiredDialog();
      } else {
        setState(() => isLoading = false);
        debugPrint('Error fetching laptops: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error fetching laptops: $e');
    }
  }

  /// ✅ Step 3: Show dialog and redirect if token expired
  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('Please log in again to continue.'),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('jwt_token');
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Screens for each bottom tab
  
  final List<Widget> _pages = [
    const Center(child: Text('Home Page')), // Home tab
    const Center(child: Text('Search Page')), // Search tab
    const Center(child: Text('Chatbot Page')), // Chatbot tab
    const Center(child: Text('Shopping Cart Page')), // Cart tab
    const Center(child: Text('Profile Page')), // Profile tab
  ];

  @override
  Widget build(BuildContext context) {
    late String userName;
    String? userAvatar;
    userName = widget.userName;
    userAvatar = widget.userAvatar;

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: const Color(0xFFB2DFDB),
        elevation: 0,
        automaticallyImplyLeading:
            false, // since you already have a custom menu
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo + title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/pickwise_logo_middle_rmbg.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'PickWise',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF37474F),
                      ),
                    ),
                  ],
                ),

                // 👤 User avatar or first letter + logout logic
                IconButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove("jwt_token");
                    // Navigate back to login screen
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                  icon: (userAvatar != null && userAvatar.isNotEmpty)
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(userAvatar),
                          radius: 20,
                        )
                      : CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF707274),
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : "G",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
      ),

      // 👇 your main content remains the same
      body: 
        _selectedIndex == 0 ? _buildHomePage() : _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00ACC1),
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chatbot',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return RefreshIndicator(
      onRefresh: _fetchLaptopsFromDatabase,
      color: Colors.teal,
      backgroundColor: Colors.white,
      displacement: 40, //distance from top

      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // ensure scroll works even if content short
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Hi, ${widget.userName.isNotEmpty ? widget.userName : 'Guest'}!',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'What can I help you with?',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Featured Laptops',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : LaptopGrid(laptops: laptops.take(currentMax).toList(),
                    scrollController: _scrollController),
            const SizedBox(height: 16),
            if (currentMax < laptops.length)
              Center(
                child: ElevatedButton(
                  onPressed: _loadMoreLaptops,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ACC1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Load More'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LaptopGrid extends StatelessWidget {
  final List<Map<String, dynamic>> laptops;
  final ScrollController scrollController;

  const LaptopGrid({super.key, required this.laptops, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    if (laptops.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No laptops available',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    return GridView.builder(
      controller: scrollController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 380,
      ),
      itemCount: laptops.length,
      itemBuilder: (context, index) {
        final laptop = laptops[index];
        return InkWell(
          borderRadius: BorderRadius.circular(16), // match your card radius
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LaptopDetailsPage(laptop: laptop),
              ),
            );
          },
          child: LaptopCard(laptop: laptop),
        );
      },
    );
  }
}

class LaptopCard extends StatelessWidget {
  final Map<String, dynamic> laptop;

  const LaptopCard({super.key, required this.laptop});

  Widget _buildLaptopImage(Map<String, dynamic> laptop) {
    final imageField = laptop['imageURL']?.toString().trim() ?? '';

    // split by ; or , and clean up
    final imageList = imageField
        .split(RegExp(r'[;,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // first image or null
    final firstImagePath = imageList.isNotEmpty ? imageList.first : null;

    if (firstImagePath == null) {
      // if no image, return placeholder
      return const Icon(Icons.broken_image, size: 80, color: Colors.grey);
    }

    final assetPath = 'assets/$firstImagePath';

    // 输出 debug 信息
    debugPrint('DEBUG _buildLaptopImage: Using assetPath = $assetPath');

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('⚠️ Image load failed: $assetPath');
          return const Icon(Icons.broken_image, size: 80, color: Colors.grey);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
      'DEBUG LaptopCard: ${laptop['product_name']} - price_rm type: ${laptop['price_rm'].runtimeType}',
    );

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

    // String gpuModel = laptop['gpu_brand'] + ' ' + (laptop['gpu_model'] ?? '');

    final specs = [
      laptop['processor_name'] ?? 'Unknown CPU',
      '${laptop['ram_gb'] ?? ''}GB RAM',
      formattedSsd,
      laptop['gpu_model'] ?? '',
      // gpu_model,
      laptop['display_size_inches'] != null &&
              laptop['display_size_inches'].toString().isNotEmpty
          ? '${laptop['display_size_inches']}" Display'
          : '',
      laptop['os'] ?? '',
      laptop['weight_kg'] != null && laptop['weight_kg'].toString().isNotEmpty
          ? '${laptop['weight_kg']}kg'
          : '',
      laptop['bluetooth'] != null && laptop['bluetooth'].toString().isNotEmpty
          ? 'Bluetooth'
          : '',
    ].join(' | ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                height: 400,
                color: const Color(0xFFF5F5F5),
                width: double.infinity,
                child: _buildLaptopImage(laptop),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  laptop['brand'] ?? 'Unknown Brand',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  laptop['product_name'] ?? 'Unnamed Laptop',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  laptop['model_code'] ?? 'Unknown Model',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true, // ✅ allow wrapping
                  overflow: TextOverflow.visible, // ✅ don't cut off text
                ),
                const SizedBox(height: 4),
                Text(
                  specs.toString().isNotEmpty ? specs : 'No specs available',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  softWrap: true, // allows line breaks
                  overflow: TextOverflow.visible, // ensures full text shown
                  maxLines: null, // no limit on lines
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      (laptop['price_rm'] != null &&
                              laptop['price_rm'].toString().isNotEmpty)
                          ? 'RM ${laptop['price_rm'].toString()}'
                          : 'N/A',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00ACC1),
                      ),
                    ),
                    Row(
                      children: [
                        // const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          // TODO: replace with actual pick score
                          'Pick Score',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
