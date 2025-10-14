import 'package:farmer_crate/Customer/transpoterlive.dart';
import 'package:flutter/material.dart';
import 'dart:async';


class DeliveryTrackingPage extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String customerAddress; // Added customer address parameter

  const DeliveryTrackingPage({
    Key? key,
    required this.orderId,
    required this.customerName,
    required this.customerAddress, // Added this parameter
  }) : super(key: key);

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage>
    with TickerProviderStateMixin {
  bool isSearching = true;
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Mock delivery agent data
  final DeliveryAgent agent = DeliveryAgent(
    name: "Ravi Kumar",
    phone: "+91 98765 43210",
    vehicleNumber: "TN45AB1234",
    vehicleType: "Bike",
    currentLocation: "Near Market Road",
    estimatedPickup: "10 mins",
    estimatedDelivery: "30 mins",
    status: "Assigned",
    profileImage: "assets/images/agent_profile.jpg", // Add your asset
    rating: 4.8,
  );

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Simulate 5 seconds searching then show agent details
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: Text(
          'Order Tracking',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: isSearching ? _buildSearchingScreen() : _buildAgentDetailsScreen(),
      ),
    );
  }

  Widget _buildSearchingScreen() {
    return Center(
      key: const ValueKey('searching'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated searching icon
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * 3.14159,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.search,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),

          // Searching text with dots animation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Searching for nearby delivery agent',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2E7D32),
                ),
              ),
              _buildAnimatedDots(),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            'Order ID: ${widget.orderId}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 60),

          // Progress indicator
          Container(
            width: 250,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: null,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF2E7D32),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDots() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        int dots = ((_rotationController.value * 4) % 4).floor();
        return Text(
          '.' * (dots + 1),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        );
      },
    );
  }

  Widget _buildAgentDetailsScreen() {
    return FadeTransition(
      key: const ValueKey('agent_details'),
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Delivery agent assigned successfully!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Agent details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Agent profile section
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: const Color(0xFF2E7D32),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agent.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${agent.rating}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    agent.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Call button
                      GestureDetector(
                        onTap: () => _makePhoneCall(agent.phone),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Vehicle details
                  _buildDetailRow(
                    Icons.motorcycle,
                    'Vehicle',
                    '${agent.vehicleNumber} - ${agent.vehicleType}',
                  ),

                  const SizedBox(height: 16),

                  // Current location
                  _buildDetailRow(
                    Icons.location_on,
                    'Current Location',
                    agent.currentLocation,
                  ),

                  const SizedBox(height: 16),

                  // Contact number
                  _buildDetailRow(
                    Icons.phone,
                    'Contact',
                    agent.phone,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Estimated times card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery Timeline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTimelineItem(
                          Icons.access_time,
                          'Pickup',
                          agent.estimatedPickup,
                          const Color(0xFF2E7D32),
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 40,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: _buildTimelineItem(
                          Icons.local_shipping,
                          'Delivery',
                          agent.estimatedDelivery,
                          const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Track order button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LiveDeliveryTrackingPage(
                        orderId: widget.orderId,
                        deliveryAgentName: agent.name,
                        deliveryAgentPhone: agent.phone,
                        customerAddress: widget.customerAddress,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Track Live Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(IconData icon, String label, String time, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _makePhoneCall(String phoneNumber) {
    // Implement phone call functionality
    // You can use url_launcher package: launch("tel:$phoneNumber")
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phoneNumber...'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }

// Removed confirmation dialog; navigation happens directly from button
}

// Delivery Agent Data Model
class DeliveryAgent {
  final String name;
  final String phone;
  final String vehicleNumber;
  final String vehicleType;
  final String currentLocation;
  final String estimatedPickup;
  final String estimatedDelivery;
  final String status;
  final String profileImage;
  final double rating;

  DeliveryAgent({
    required this.name,
    required this.phone,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.currentLocation,
    required this.estimatedPickup,
    required this.estimatedDelivery,
    required this.status,
    required this.profileImage,
    required this.rating,
  });
}

// Placeholder for LiveDeliveryTrackingPage - you'll need to implement this
// Removed local placeholder LiveDeliveryTrackingPage to avoid conflict with real page