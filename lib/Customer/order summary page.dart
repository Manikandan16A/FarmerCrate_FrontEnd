import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class OrderSummaryPage extends StatefulWidget {
  final int orderId;
  final String? token;

  const OrderSummaryPage({
    Key? key,
    required this.orderId,
    this.token,
  }) : super(key: key);

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class OrderSummary {
  final int orderId;
  final int quantity;
  final double totalPrice;
  final String currentStatus;
  final String deliveryAddress;
  final DateTime estimatedDeliveryTime;
  final Product product;
  final Transporter sourceTransporter;
  final Transporter destinationTransporter;

  OrderSummary({
    required this.orderId,
    required this.quantity,
    required this.totalPrice,
    required this.currentStatus,
    required this.deliveryAddress,
    required this.estimatedDeliveryTime,
    required this.product,
    required this.sourceTransporter,
    required this.destinationTransporter,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      orderId: json['order_id'] as int,
      quantity: json['quantity'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      currentStatus: json['current_status'] as String,
      deliveryAddress: json['delivery_address'] as String,
      estimatedDeliveryTime: DateTime.parse(json['estimated_delivery_time'] as String),
      product: Product.fromJson(json['Product'] as Map<String, dynamic>),
      sourceTransporter: Transporter.fromJson(json['sourceTransporter'] as Map<String, dynamic>),
      destinationTransporter: Transporter.fromJson(json['destinationTransporter'] as Map<String, dynamic>),
    );
  }
}

class Product {
  final String name;
  final List<String> images;
  final double currentPrice;
  final Farmer farmer;

  Product({
    required this.name,
    required this.images,
    required this.currentPrice,
    required this.farmer,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'] as String,
      images: List<String>.from(json['images'] as List),
      currentPrice: (json['current_price'] as num).toDouble(),
      farmer: Farmer.fromJson(json['farmer'] as Map<String, dynamic>),
    );
  }
}

class Farmer {
  final String name;
  final String zone;
  final String address;

  Farmer({
    required this.name,
    required this.zone,
    required this.address,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) {
    return Farmer(
      name: json['name'] as String,
      zone: json['zone'] as String,
      address: json['address'] as String,
    );
  }
}

class Transporter {
  final String name;
  final String mobileNumber;
  final String zone;

  Transporter({
    required this.name,
    required this.mobileNumber,
    required this.zone,
  });

  factory Transporter.fromJson(Map<String, dynamic> json) {
    return Transporter(
      name: json['name'] as String,
      mobileNumber: json['mobile_number'] as String,
      zone: json['zone'] as String,
    );
  }
}

class TrackingStep {
  final String status;
  final String label;
  final String icon;
  final bool completed;
  final bool current;
  final DateTime? timestamp;
  final String? location;
  final String? notes;

  TrackingStep({
    required this.status,
    required this.label,
    required this.icon,
    required this.completed,
    required this.current,
    this.timestamp,
    this.location,
    this.notes,
  });

  factory TrackingStep.fromJson(Map<String, dynamic> json) {
    return TrackingStep(
      status: json['status'] as String,
      label: json['label'] as String,
      icon: json['icon'] as String,
      completed: json['completed'] as bool,
      current: json['current'] as bool,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : null,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  bool _isLoading = true;
  String? _error;
  OrderSummary? _orderSummary;
  List<TrackingStep> _trackingSteps = [];
  DateTime? _estimatedDelivery;

  @override
  void initState() {
    super.initState();
    _fetchOrderSummary();
  }

  Future<String?> _resolveToken() async {
    if (widget.token != null && widget.token!.trim().isNotEmpty) return widget.token;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token') ?? prefs.getString('jwt_token');
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchOrderSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final token = await _resolveToken();
    if (token == null || token.trim().isEmpty) {
      setState(() {
        _error = 'Authentication required. Please sign in.';
        _isLoading = false;
      });
      return;
    }

    try {
      final uri = Uri.parse('https://farmercrate.onrender.com/api/customers/orders/${widget.orderId}/track');
      final resp = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body['success'] == true) {
          final data = body['data'] as Map<String, dynamic>;
          final order = data['order'] as Map<String, dynamic>;
          final trackingSteps = data['tracking_steps'] as List<dynamic>;
          final estimatedDelivery = data['estimated_delivery'] as String?;

          setState(() {
            _orderSummary = OrderSummary.fromJson(order);
            _trackingSteps = trackingSteps.map((step) => TrackingStep.fromJson(step as Map<String, dynamic>)).toList();
            _estimatedDelivery = estimatedDelivery != null ? DateTime.parse(estimatedDelivery) : null;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Failed to load order summary';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load order summary (${resp.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching order summary: $e';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.blue;
      case 'ASSIGNED':
        return Colors.purple;
      case 'SHIPPED':
        return Colors.indigo;
      case 'IN_TRANSIT':
        return Colors.teal;
      case 'RECEIVED':
        return Colors.cyan;
      case 'OUT_FOR_DELIVERY':
        return Colors.amber;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderDetails() {
    if (_orderSummary == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStatusColor(_orderSummary!.currentStatus).withOpacity(0.1),
                    _getStatusColor(_orderSummary!.currentStatus).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_orderSummary!.currentStatus).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shopping_bag,
                      color: _getStatusColor(_orderSummary!.currentStatus),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${_orderSummary!.orderId}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_orderSummary!.currentStatus).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _orderSummary!.currentStatus,
                            style: TextStyle(
                              color: _getStatusColor(_orderSummary!.currentStatus),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Product Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _orderSummary!.product.images.isNotEmpty
                          ? _orderSummary!.product.images.first
                          : 'https://via.placeholder.com/80x80?text=No+Image',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _orderSummary!.product.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildProductInfo('Quantity', '${_orderSummary!.quantity}'),
                            ),
                            Expanded(
                              child: _buildProductInfo('Each', '₹${_orderSummary!.product.currentPrice.toStringAsFixed(2)}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '₹${_orderSummary!.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Farmer Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.person, color: Colors.blue[700], size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Farmer Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildEnhancedInfoRow('Name', _orderSummary!.product.farmer.name),
                  _buildEnhancedInfoRow('Zone', _orderSummary!.product.farmer.zone),
                  _buildEnhancedInfoRow('Farm Address', _orderSummary!.product.farmer.address),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Delivery Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.local_shipping, color: Colors.orange[700], size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Delivery Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildEnhancedInfoRow('Delivery Address', _orderSummary!.deliveryAddress),
                  if (_estimatedDelivery != null)
                    _buildEnhancedInfoRow(
                      'Estimated Delivery',
                      _estimatedDelivery!.toLocal().toString().split('.').first,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700]),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(String label, String value) {
    return Column(
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
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTransporterCard(String title, Transporter transporter, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_shipping, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildEnhancedInfoRow('Name', transporter.name),
          _buildEnhancedInfoRow('Zone', transporter.zone),
          _buildEnhancedInfoRow('Contact', transporter.mobileNumber),
        ],
      ),
    );
  }

  Widget _buildEnhancedTrackingStep(TrackingStep step, int index) {
    final isCompleted = step.completed;
    final isCurrent = step.current;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green[50]
            : isCurrent
            ? Colors.blue[50]
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? Colors.green[200]!
              : isCurrent
              ? Colors.blue[200]!
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? Colors.green
                  : isCurrent
                  ? Colors.blue
                  : Colors.grey[300],
            ),
            child: Center(
              child: Text(
                step.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Status Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCompleted || isCurrent ? Colors.black87 : Colors.grey[600],
                  ),
                ),

                if (step.timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.timestamp!.toLocal().toString().split('.').first,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],

                if (step.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          step.location!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (step.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransporterDetails() {
    if (_orderSummary == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.local_shipping, color: Colors.purple[700], size: 24),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Transport Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Source Transporter
            _buildEnhancedTransporterCard('Source Transporter', _orderSummary!.sourceTransporter, Colors.blue),

            const SizedBox(height: 16),

            // Destination Transporter
            _buildEnhancedTransporterCard('Destination Transporter', _orderSummary!.destinationTransporter, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildTransporterCard(String title, Transporter transporter) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text('Name: ${transporter.name}'),
          Text('Zone: ${transporter.zone}'),
          Text('Contact: ${transporter.mobileNumber}'),
        ],
      ),
    );
  }

  Widget _buildTrackingSteps() {
    if (_trackingSteps.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.timeline, color: Colors.teal[700], size: 24),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Order Tracking',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _trackingSteps.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final step = _trackingSteps[index];
                return _buildEnhancedTrackingStep(step, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingStep(TrackingStep step, int index) {
    final isCompleted = step.completed;
    final isCurrent = step.current;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.green
                : isCurrent
                ? Colors.blue
                : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              step.icon,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Status Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isCompleted || isCurrent ? Colors.black : Colors.grey[600],
                ),
              ),

              if (step.timestamp != null) ...[
                const SizedBox(height: 4),
                Text(
                  step.timestamp!.toLocal().toString().split('.').first,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],

              if (step.location != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        step.location!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (step.notes != null) ...[
                const SizedBox(height: 4),
                Text(
                  step.notes!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDF8),
      appBar: AppBar(
        title: const Text(
          'Order Summary',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchOrderSummary,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrderSummary,
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Loading order details...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        )
            : _error != null
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Oops! Something went wrong',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.red[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchOrderSummary,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildOrderDetails(),
              _buildTransporterDetails(),
              _buildTrackingSteps(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}