import 'package:flutter/material.dart';
import 'dart:async';

class LiveDeliveryTrackingPage extends StatefulWidget {
  final String orderId;
  final String deliveryAgentName;
  final String deliveryAgentPhone;
  final String customerAddress;

  const LiveDeliveryTrackingPage({
    Key? key,
    required this.orderId,
    required this.deliveryAgentName,
    required this.deliveryAgentPhone,
    required this.customerAddress,
  }) : super(key: key);

  @override
  State<LiveDeliveryTrackingPage> createState() => _LiveDeliveryTrackingPageState();
}

class _LiveDeliveryTrackingPageState extends State<LiveDeliveryTrackingPage>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  Timer? _statusUpdateTimer;

  int currentStage = 3; // Current stage (0-5)
  String estimatedDeliveryTime = "11:20 AM";

  // Order tracking stages
  List<OrderStage> orderStages = [
    OrderStage(
      title: "Order Placed & Paid",
      subtitle: "Customer completes online payment",
      emoji: "✅",
      time: "10:00 AM",
      isCompleted: true,
      description: "Order confirmed in system",
    ),
    OrderStage(
      title: "Farmer Preparing",
      subtitle: "Farmer gets order notification",
      emoji: "🌱",
      time: "10:10 AM",
      isCompleted: true,
      description: "Farmer starts packing the produce",
    ),
    OrderStage(
      title: "Picked from Farmer",
      subtitle: "Delivery agent assigned",
      emoji: "🛵",
      time: "10:25 AM",
      isCompleted: true,
      description: "Agent picks up items from farmer",
    ),
    OrderStage(
      title: "Arrived at Hub",
      subtitle: "Hub staff receive items",
      emoji: "🏬",
      time: "10:40 AM",
      isCompleted: true,
      description: "Quality & quantity check completed",
    ),
    OrderStage(
      title: "Out for Delivery",
      subtitle: "On the way to customer",
      emoji: "🚚",
      time: "11:00 AM",
      isCompleted: false,
      description: "Order leaves hub for customer",
    ),
    OrderStage(
      title: "Delivered",
      subtitle: "Customer receives produce",
      emoji: "📦",
      time: "11:20 AM",
      isCompleted: false,
      description: "Feedback option available",
    ),
  ];

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _progressController.forward();
    _simulateRealTimeUpdates();
  }

  void _simulateRealTimeUpdates() {
    // Simulate real-time status updates
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (currentStage < orderStages.length - 1) {
        setState(() {
          if (currentStage < orderStages.length - 1) {
            currentStage++;
            orderStages[currentStage].isCompleted = true;
            orderStages[currentStage].time = _getCurrentTime();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progressPercentage = ((currentStage + 1) / orderStages.length) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: Column(
          children: [
            Text(
              'Order Tracking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.orderId,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                // Refresh tracking info
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Current Status Header
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4CAF50),
                    const Color(0xFF2E7D32),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_pulseController.value * 0.1),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: Text(
                                  orderStages[currentStage].emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orderStages[currentStage].title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              orderStages[currentStage].subtitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${progressPercentage.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Estimated Delivery: $estimatedDeliveryTime',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Progress Timeline
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Journey',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orderStages.length,
                    itemBuilder: (context, index) {
                      final stage = orderStages[index];
                      bool isActive = index <= currentStage;
                      bool isCurrent = index == currentStage;
                      bool isUpcoming = index > currentStage;

                      return AnimatedContainer(
                        duration: Duration(milliseconds: 500 + (index * 100)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timeline indicator
                            Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFF4CAF50)
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(20),
                                    border: isCurrent ? Border.all(
                                      color: const Color(0xFF2E7D32),
                                      width: 3,
                                    ) : null,
                                    boxShadow: isCurrent ? [
                                      BoxShadow(
                                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ] : null,
                                  ),
                                  child: Center(
                                    child: isActive
                                        ? Text(
                                      stage.emoji,
                                      style: const TextStyle(fontSize: 18),
                                    )
                                        : Icon(
                                      Icons.circle,
                                      size: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                                if (index < orderStages.length - 1)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    width: 3,
                                    height: 50,
                                    color: isActive
                                        ? const Color(0xFF4CAF50)
                                        : Colors.grey[300],
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Stage details
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.only(bottom: 30),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            stage.title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isCurrent
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              color: isActive
                                                  ? const Color(0xFF1B5E20)
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                        if (isActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              stage.time,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF2E7D32),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      stage.subtitle,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isActive
                                            ? Colors.grey[700]
                                            : Colors.grey[500],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      stage.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isActive
                                            ? Colors.grey[600]
                                            : Colors.grey[400],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),

                                    // Show live indicator for current stage
                                    if (isCurrent && !stage.isCompleted)
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        child: Row(
                                          children: [
                                            AnimatedBuilder(
                                              animation: _pulseController,
                                              builder: (context, child) {
                                                return Transform.scale(
                                                  scale: 1.0 + (_pulseController.value * 0.2),
                                                  child: Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.orange,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'In Progress...',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Delivery Agent Info
            if (currentStage >= 2) // Show when picked up
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Agent',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFF2E7D32),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.deliveryAgentName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '4.8',
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(
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
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _makePhoneCall(widget.deliveryAgentPhone),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.message,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Delivery Address
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF4CAF50),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.customerAddress,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Support Section
            Container(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showSupportOptions(),
                      icon: const Icon(Icons.support_agent, color: Color(0xFF2E7D32)),
                      label: const Text(
                        'Need Help?',
                        style: TextStyle(color: Color(0xFF2E7D32)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: currentStage == orderStages.length - 1
                          ? () => _showFeedbackDialog()
                          : null,
                      icon: const Icon(Icons.rate_review, color: Colors.white),
                      label: const Text(
                        'Rate Order',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentStage == orderStages.length - 1
                            ? const Color(0xFF4CAF50)
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phoneNumber...'),
        backgroundColor: const Color(0xFF2E7D32),
        action: SnackBarAction(
          label: 'Cancel',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _sendMessage() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Messages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.access_time, color: Color(0xFF2E7D32)),
              title: const Text('Where are you?'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Color(0xFF2E7D32)),
              title: const Text('Need help finding the address?'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: Color(0xFF2E7D32)),
              title: const Text('How long will it take?'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How can we help you?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF2E7D32)),
              title: const Text('Call Customer Support'),
              subtitle: const Text('+91 1800 123 4567'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF2E7D32)),
              title: const Text('Live Chat'),
              subtitle: const Text('Chat with our support team'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report_problem, color: Color(0xFF2E7D32)),
              title: const Text('Report Issue'),
              subtitle: const Text('Report a problem with your order'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rate Your Experience'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How was your delivery experience?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) =>
                  GestureDetector(
                    onTap: () {},
                    child: Icon(
                      Icons.star_border,
                      color: Colors.amber,
                      size: 30,
                    ),
                  ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your feedback!'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Order Stage Model
class OrderStage {
  final String title;
  final String subtitle;
  final String emoji;
  String time;
  bool isCompleted;
  final String description;

  OrderStage({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.time,
    required this.isCompleted,
    required this.description,
  });
}