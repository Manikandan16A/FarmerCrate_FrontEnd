import 'package:flutter/material.dart';
import 'dart:async';
import 'admin_order_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/cloudinary_upload.dart';
import 'farmer_details_page.dart';
import 'transporter_details_page.dart';
import 'customer_details_page.dart';
import 'delivery_person_details_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminOrderTrackingPage extends StatefulWidget {
  final String? token;
  final String? orderId;

  const AdminOrderTrackingPage({
    super.key,
    this.token,
    this.orderId,
  });

  @override
  State<AdminOrderTrackingPage> createState() => _AdminOrderTrackingPageState();
}

class _AdminOrderTrackingPageState extends State<AdminOrderTrackingPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _activeShipments = [];
  Map<String, dynamic>? _selectedOrder;
  List<dynamic> _trackingSteps = [];
  Timer? _refreshTimer;
  AnimationController? _vehicleAnimationController;
  Animation<double>? _vehicleAnimation;
  
  @override
  void initState() {
    super.initState();
    _fetchActiveShipments();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _vehicleAnimationController?.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 40), (timer) {
      if (mounted) {
        _fetchActiveShipments();
        if (_selectedOrder != null) {
          _fetchOrderTracking(_selectedOrder!['order_id'].toString());
        }
      }
    });
  }

  void _startVehicleAnimation(int currentStepIndex, int totalSteps) {
    _vehicleAnimationController?.dispose();
    _vehicleAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _vehicleAnimation = Tween<double>(begin: 0.0, end: currentStepIndex / (totalSteps - 1))
        .animate(CurvedAnimation(parent: _vehicleAnimationController!, curve: Curves.easeInOut));
    _vehicleAnimationController!.forward();
  }

  IconData _getVehicleIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
      case 'ACCEPTED':
      case 'PICKED_UP':
        return Icons.two_wheeler;
      case 'SHIPPED':
      case 'IN_TRANSIT':
      case 'REACHED_HUB':
      case 'RECEIVED':
        return Icons.local_shipping;
      case 'OUT_FOR_DELIVERY':
      case 'COMPLETED':
      case 'DELIVERED':
        return Icons.two_wheeler;
      default:
        return Icons.two_wheeler;
    }
  }

  Future<String?> _resolveToken() async {
    if (widget.token != null && widget.token!.trim().isNotEmpty) {
      return widget.token;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      final jwtToken = prefs.getString('jwt_token');
      return authToken ?? jwtToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchActiveShipments() async {
    final token = await _resolveToken();
    if (token == null) {
      setState(() {
        _error = 'Authentication required. Please sign in.';
        _isLoading = false;
      });
      return;
    }

    final result = await AdminOrderService.getActiveShipments(token);
    print('DEBUG: Active Shipments Result: $result');
    
    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _activeShipments = result['data'] as List<dynamic>;
          _error = null;
          
          if (_selectedOrder == null && _activeShipments.isNotEmpty && widget.orderId == null) {
            _selectedOrder = _activeShipments.first;
            _fetchOrderTracking(_selectedOrder!['order_id'].toString());
          } else if (widget.orderId != null) {
            final specificOrder = _activeShipments.firstWhere(
              (order) => order['order_id'].toString() == widget.orderId,
              orElse: () => <String, dynamic>{},
            );
            if (specificOrder.isNotEmpty) {
              _selectedOrder = specificOrder;
              _fetchOrderTracking(widget.orderId!);
            }
          }
        } else {
          _error = result['error'];
        }
        _isLoading = false;
      });
    }
  }

  String _mapStatusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'PLACED': return 'Order Placed';
      case 'ASSIGNED': return 'Pickup from Farm';
      case 'SHIPPED': return 'Shipped';
      case 'IN_TRANSIT': return 'Reached Hub';
      case 'RECEIVED': return 'Reached Hub';
      case 'OUT_FOR_DELIVERY': return 'Out for Delivery';
      case 'COMPLETED': return 'Delivered';
      case 'DELIVERED': return 'Delivered';
      default: return status ?? 'Unknown';
    }
  }

  Future<void> _fetchOrderTracking(String orderId) async {
    final token = await _resolveToken();
    if (token == null) return;

    final result = await AdminOrderService.trackOrder(token, orderId);
    
    if (mounted && result['success'] == true) {
      setState(() {
        final data = result['data'] as Map<String, dynamic>;
        final steps = (data['tracking_steps'] as List<dynamic>? ?? [])
            .where((step) => step['status']?.toUpperCase() != 'IN_TRANSIT')
            .toList();
        
        // Always generate tracking steps from current order status since API doesn't provide them
        _trackingSteps = _generateTrackingSteps(_selectedOrder!['current_status']);
        
        final currentIndex = _trackingSteps.indexWhere((step) => step['current'] == true);
        if (currentIndex >= 0 && _trackingSteps.isNotEmpty) {
          _startVehicleAnimation(currentIndex, _trackingSteps.length);
        }
      });
    }
  }

  List<Map<String, dynamic>> _generateTrackingSteps(String? currentStatus) {
    final allSteps = [
      {'status': 'PLACED', 'label': 'Order Placed', 'timestamp': null, 'current': false},
      {'status': 'ASSIGNED', 'label': 'Pickup from Farm', 'timestamp': null, 'current': false},
      {'status': 'SHIPPED', 'label': 'Shipped', 'timestamp': null, 'current': false},
      {'status': 'RECEIVED', 'label': 'Reached Hub', 'timestamp': null, 'current': false},
      {'status': 'OUT_FOR_DELIVERY', 'label': 'Out for Delivery', 'timestamp': null, 'current': false},
      {'status': 'COMPLETED', 'label': 'Delivered', 'timestamp': null, 'current': false},
    ];
    
    final currentStatusUpper = currentStatus?.toUpperCase();
    int currentIndex = -1;
    
    // Find current step index
    for (int i = 0; i < allSteps.length; i++) {
      if (allSteps[i]['status'] == currentStatusUpper || 
          (currentStatusUpper == 'IN_TRANSIT' && allSteps[i]['status'] == 'RECEIVED')) {
        currentIndex = i;
        allSteps[i]['current'] = true;
        break;
      }
    }
    
    // If status not found, default to first step
    if (currentIndex == -1) {
      currentIndex = 0;
      allSteps[0]['current'] = true;
    }
    
    return allSteps;
  }

  Future<void> _refreshData() async {
    await _fetchActiveShipments();
    if (_selectedOrder != null) {
      await _fetchOrderTracking(_selectedOrder!['order_id'].toString());
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

  String _displayStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'PLACED': return 'Order Placed';
      case 'ASSIGNED': return 'Pickup from Farm';
      case 'SHIPPED': return 'Shipped';
      case 'IN_TRANSIT': return 'Reached Hub';
      case 'RECEIVED': return 'Reached Hub';
      case 'OUT_FOR_DELIVERY': return 'Out for Delivery';
      case 'COMPLETED': return 'Delivered';
      default: return status ?? 'Unknown';
    }
  }

  Widget _buildShipmentCard(Map<String, dynamic> shipment) {
    final isSelected = _selectedOrder?['order_id'] == shipment['order_id'];
    final displayStatus = _displayStatus(shipment['current_status']);
    final statusColor = _getStatusColor(displayStatus);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.local_shipping,
            color: statusColor,
            size: 24,
          ),
        ),
        title: Text(
          'Order Details',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              displayStatus,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Est. Delivery: ${_formatDate(shipment['estimated_delivery_time'])}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          setState(() {
            _selectedOrder = shipment;
          });
          _fetchOrderTracking(shipment['order_id'].toString());
        },
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    if (_trackingSteps.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tracking information available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select an order to view tracking details',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = _trackingSteps.indexWhere((step) => step['current'] == true);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _trackingSteps.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final step = _trackingSteps[index];
                    final isActive = index <= currentIndex;
                    final isCurrent = step['current'] ?? false;
                    return Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isActive ? _getStatusColor(step['status'] ?? '') : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getStepIcon(step['status'] ?? ''),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step['label'] ?? 'Unknown Step',
                                style: TextStyle(
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  color: isActive ? Colors.black : Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              if (step['timestamp'] != null)
                                Text(
                                  _formatDate(step['timestamp']),
                                  style: TextStyle(
                                    color: isActive ? Colors.grey[600] : Colors.grey[400],
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(
                width: 60,
                height: _trackingSteps.length * 56.0,
                child: Stack(
                  children: [
                    Positioned(
                      right: 20,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    if (_vehicleAnimation != null && currentIndex >= 0)
                      AnimatedBuilder(
                        animation: _vehicleAnimation!,
                        builder: (context, child) {
                          final progress = _vehicleAnimation!.value;
                          final stepHeight = 56.0;
                          final topPosition = progress * (_trackingSteps.length - 1) * stepHeight;
                          final greenHeight = topPosition + 20;
                          return Positioned(
                            right: 20,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: greenHeight,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        },
                      ),
                    if (_vehicleAnimation != null && currentIndex >= 0)
                      AnimatedBuilder(
                        animation: _vehicleAnimation!,
                        builder: (context, child) {
                          final progress = _vehicleAnimation!.value;
                          final stepHeight = 56.0;
                          final topPosition = progress * (_trackingSteps.length - 1) * stepHeight;
                          final animatedIndex = (progress * (_trackingSteps.length - 1)).round().clamp(0, _trackingSteps.length - 1);
                          final animatedStatus = _trackingSteps[animatedIndex]['status'] ?? '';
                          final vehicleIcon = _getVehicleIcon(animatedStatus);
                          return Positioned(
                            right: 0,
                            top: topPosition,
                            child: Icon(
                              vehicleIcon,
                              color: Colors.orange,
                              size: 40,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getStepIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
        return Icons.shopping_cart;
      case 'ACCEPTED':
        return Icons.check_circle;
      case 'ASSIGNED':
        return Icons.person_add;
      case 'PICKED_UP':
      case 'SHIPPED':
        return Icons.local_shipping;
      case 'IN_TRANSIT':
        return Icons.directions_transit;
      case 'REACHED_HUB':
      case 'RECEIVED':
        return Icons.warehouse;
      case 'OUT_FOR_DELIVERY':
        return Icons.delivery_dining;
      case 'DELIVERED':
      case 'COMPLETED':
        return Icons.done_all;
      default:
        return Icons.circle;
    }
  }

  Widget _buildOrderHeader() {
    if (_selectedOrder == null) return const SizedBox.shrink();
    
    final order = _selectedOrder!;
    final displayStatus = _displayStatus(order['current_status']);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[600],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  displayStatus.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 8),
          Text(
            'Estimated delivery: ${_formatDate(order['estimated_delivery_time'])}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    if (_selectedOrder == null) return const SizedBox.shrink();
    
    final order = _selectedOrder!;
    final product = order['product'] ?? {};
    final images = product['images'] as List<dynamic>? ?? [];
    final primaryImage = images.firstWhere(
      (img) => img['is_primary'] == true,
      orElse: () => images.isNotEmpty ? images.first : {'image_url': '', 'is_primary': true},
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: primaryImage['image_url']?.isNotEmpty == true
                  ? Image.network(
                      CloudinaryUploader.optimizeImageUrl(primaryImage['image_url'], width: 80, height: 80),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: 40,
                      ),
                    )
                  : Icon(
                      Icons.inventory,
                      color: Colors.grey[400],
                      size: 40,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? 'Unknown Product',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: ${order['quantity'] != null ? double.tryParse(order['quantity'].toString()) ?? 0.0 : 0.0} kg',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${(order['total_price'] != null ? double.tryParse(order['total_price'].toString()) ?? 0.0 : 0.0).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    if (_selectedOrder == null) return const SizedBox.shrink();
    
    final order = _selectedOrder!;
    print('DEBUG: Full Order Data: $order');
    
    final product = order['product'] ?? {};
    print('DEBUG: Product Data: $product');
    
    final farmer = product['farmer'] ?? {};
    print('DEBUG: Farmer Data: $farmer');
    
    final customer = order['customer'] ?? {};
    print('DEBUG: Customer Data: $customer');
    
    final sourceTransporter = order['source_transporter'] ?? {};
    print('DEBUG: Source Transporter Data: $sourceTransporter');
    
    final destTransporter = order['destination_transporter'] ?? {};
    print('DEBUG: Destination Transporter Data: $destTransporter');
    
    final deliveryPerson = order['delivery_person'] ?? {};
    print('DEBUG: Delivery Person Data: $deliveryPerson');
    
    final hasSourceTransporter = sourceTransporter.isNotEmpty && sourceTransporter['name'] != null;
    final hasDestTransporter = destTransporter.isNotEmpty && destTransporter['name'] != null;
    final hasDeliveryPerson = deliveryPerson.isNotEmpty && deliveryPerson['name'] != null;
    
    print('DEBUG: Has Source Transporter: $hasSourceTransporter');
    print('DEBUG: Has Dest Transporter: $hasDestTransporter');
    print('DEBUG: Has Delivery Person: $hasDeliveryPerson');
    
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[50]!, Colors.green[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.2),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.agriculture, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Farmer Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  if (farmer['farmer_id'] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FarmerDetailsPage(
                          farmerId: farmer['farmer_id'].toString(),
                          token: widget.token ?? '',
                          user: farmer,
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      _buildEnhancedDetailRow(Icons.person, 'Name', farmer['name'] ?? 'N/A'),
                      _buildEnhancedDetailRow(Icons.email, 'Email', farmer['email'] ?? 'N/A'),
                      _buildEnhancedDetailRow(Icons.phone, 'Contact', farmer['mobile_number'] ?? 'N/A'),
                      if (farmer['farmer_id'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('View Details', style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 12, color: Colors.green[700]),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.2),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Customer Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  if (customer['customer_id'] != null) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (loadingContext) => Center(child: CircularProgressIndicator(color: Colors.blue)),
                    );
                    
                    final customerId = customer['customer_id'].toString();
                    final fullData = await _fetchCustomerDetails(customerId);
                    
                    Navigator.of(context, rootNavigator: true).pop();
                    
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerDetailsPage(
                            customerId: customerId,
                            token: widget.token ?? '',
                            customer: fullData ?? {
                              'name': customer['name'] ?? 'Unknown',
                              'email': 'N/A',
                              'phone': customer['mobile_number'] ?? 'N/A',
                              'age': 0,
                              'address': customer['address'] ?? 'N/A',
                              'district': 'N/A',
                              'state': 'N/A',
                              'orders': 0,
                              'spent': 0,
                              'imageUrl': null,
                            },
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      _buildEnhancedDetailRow(Icons.person, 'Name', customer['name'] ?? 'N/A', color: Colors.blue),
                      _buildEnhancedDetailRow(Icons.email, 'Email', customer['email'] ?? 'N/A', color: Colors.blue),
                      _buildEnhancedDetailRow(Icons.phone, 'Contact', customer['mobile_number'] ?? 'N/A', color: Colors.blue),
                      if (customer['customer_id'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('View Details', style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue[700]),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[50]!, Colors.purple[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.2),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.store, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Source Transporter',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  if (hasSourceTransporter && sourceTransporter['transporter_id'] != null) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (loadingContext) => Center(child: CircularProgressIndicator(color: Colors.orange)),
                    );
                    
                    final transporterId = sourceTransporter['transporter_id'].toString();
                    final fullData = await _fetchTransporterDetails(transporterId);
                    
                    Navigator.of(context, rootNavigator: true).pop();
                    
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransporterDetailsPage(
                            transporterId: transporterId,
                            token: widget.token ?? '',
                            transporter: fullData ?? {
                              'name': sourceTransporter['name'] ?? 'Unknown',
                              'email': 'N/A',
                              'phone': sourceTransporter['mobile_number'] ?? 'N/A',
                              'age': 0,
                              'zone': 'N/A',
                              'district': 'N/A',
                              'state': 'N/A',
                              'verifiedStatus': false,
                              'totalOrders': 0,
                              'totalAmount': 0.0,
                              'sourceOrders': 0,
                              'destOrders': 0,
                              'imageUrl': null,
                            },
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      _buildEnhancedDetailRow(Icons.person, 'Name', hasSourceTransporter ? sourceTransporter['name'] : 'Wait for assigning', color: Colors.purple),
                      _buildEnhancedDetailRow(Icons.location_on, 'Address', hasSourceTransporter ? sourceTransporter['address'] ?? 'N/A' : 'N/A', color: Colors.purple),
                      if (hasSourceTransporter && sourceTransporter['transporter_id'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('View Details', style: TextStyle(color: Colors.purple[700], fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 12, color: Colors.purple[700]),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo[50]!, Colors.indigo[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withValues(alpha: 0.2),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Destination Transporter',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF283593),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  if (hasDestTransporter && destTransporter['transporter_id'] != null) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (loadingContext) => Center(child: CircularProgressIndicator(color: Colors.orange)),
                    );
                    
                    final transporterId = destTransporter['transporter_id'].toString();
                    final fullData = await _fetchTransporterDetails(transporterId);
                    
                    Navigator.of(context, rootNavigator: true).pop();
                    
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransporterDetailsPage(
                            transporterId: transporterId,
                            token: widget.token ?? '',
                            transporter: fullData ?? {
                              'name': destTransporter['name'] ?? 'Unknown',
                              'email': 'N/A',
                              'phone': destTransporter['mobile_number'] ?? 'N/A',
                              'age': 0,
                              'zone': 'N/A',
                              'district': 'N/A',
                              'state': 'N/A',
                              'verifiedStatus': false,
                              'totalOrders': 0,
                              'totalAmount': 0.0,
                              'sourceOrders': 0,
                              'destOrders': 0,
                              'imageUrl': null,
                            },
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      _buildEnhancedDetailRow(Icons.person, 'Name', hasDestTransporter ? destTransporter['name'] : 'Wait for assigning', color: Colors.indigo),
                      _buildEnhancedDetailRow(Icons.location_on, 'Address', hasDestTransporter ? destTransporter['address'] ?? 'N/A' : 'N/A', color: Colors.indigo),
                      if (hasDestTransporter && destTransporter['transporter_id'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('View Details', style: TextStyle(color: Colors.indigo[700], fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 12, color: Colors.indigo[700]),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal[50]!, Colors.teal[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withValues(alpha: 0.2),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delivery_dining, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Delivery Person',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00796B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  if (hasDeliveryPerson && deliveryPerson['delivery_person_id'] != null) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (loadingContext) => Center(child: CircularProgressIndicator(color: Colors.purple)),
                    );
                    
                    final deliveryPersonId = deliveryPerson['delivery_person_id'].toString();
                    final fullData = await _fetchDeliveryPersonDetails(deliveryPersonId);
                    
                    Navigator.of(context, rootNavigator: true).pop();
                    
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeliveryPersonDetailsPage(
                            deliveryPersonId: deliveryPersonId,
                            token: widget.token ?? '',
                            deliveryPerson: fullData ?? {
                              'id': deliveryPerson['delivery_person_id'],
                              'name': deliveryPerson['name'] ?? 'Unknown',
                              'vehicleNumber': deliveryPerson['vehicle_number'] ?? 'N/A',
                              'isAvailable': false,
                              'totalOrders': 0,
                              'rating': '0.0',
                              'phone': deliveryPerson['mobile_number'] ?? 'N/A',
                              'licenseNumber': 'N/A',
                              'currentLocation': 'N/A',
                              'vehicleType': 'bike',
                              'totalAmount': 0.0,
                            },
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      _buildEnhancedDetailRow(Icons.person, 'Name', hasDeliveryPerson ? deliveryPerson['name'] : 'Wait for assigning', color: Colors.teal),
                      _buildEnhancedDetailRow(Icons.phone, 'Contact', hasDeliveryPerson ? deliveryPerson['mobile_number'] ?? 'N/A' : 'N/A', color: Colors.teal),
                      if (hasDeliveryPerson && deliveryPerson['delivery_person_id'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('View Details', style: TextStyle(color: Colors.teal[700], fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 12, color: Colors.teal[700]),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.info, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Order Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildEnhancedDetailRow(Icons.location_on, 'Pickup Address', order['pickup_address'] ?? 'N/A', color: Colors.orange),
              _buildEnhancedDetailRow(Icons.location_on, 'Delivery Address', order['delivery_address'] ?? 'N/A', color: Colors.orange),
              _buildEnhancedDetailRow(Icons.payment, 'Payment Status', order['payment_status'] ?? 'Unknown', color: Colors.orange),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedDetailRow(IconData icon, String label, String value, {MaterialColor? color}) {
    final iconColor = color ?? Colors.green;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchCustomerDetails(String customerId) async {
    try {
      final token = await _resolveToken();
      if (token == null) return null;
      
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/customers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final customers = data['data'] as List;
        final customer = customers.firstWhere(
          (c) => c['customer_id'].toString() == customerId,
          orElse: () => null,
        );
        
        if (customer != null) {
          final stats = customer['order_stats'] ?? {};
          return {
            'name': customer['name'],
            'email': customer['email'] ?? 'N/A',
            'phone': customer['mobile_number'],
            'age': customer['age'] ?? 0,
            'address': customer['address'],
            'district': customer['district'],
            'state': customer['state'],
            'orders': stats['total_orders'] ?? 0,
            'spent': stats['total_spent'] ?? 0,
            'imageUrl': customer['image_url'],
          };
        }
      }
    } catch (e) {
      print('Error fetching customer details: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchTransporterDetails(String transporterId) async {
    try {
      final token = await _resolveToken();
      if (token == null) return null;
      
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/transporters'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transporters = data['data'] as List;
        final transporter = transporters.firstWhere(
          (t) => t['transporter_id'].toString() == transporterId,
          orElse: () => null,
        );
        
        if (transporter != null) {
          final stats = transporter['order_stats'] ?? {};
          return {
            'name': transporter['name'],
            'email': transporter['email'] ?? 'N/A',
            'phone': transporter['mobile_number'],
            'age': transporter['age'] ?? 0,
            'zone': transporter['zone'] ?? 'N/A',
            'district': transporter['district'],
            'state': transporter['state'],
            'verifiedStatus': transporter['is_verified'] ?? false,
            'totalOrders': stats['total_orders'] ?? 0,
            'totalAmount': (stats['total_amount'] ?? 0.0).toDouble(),
            'sourceOrders': stats['source_orders'] ?? 0,
            'destOrders': stats['destination_orders'] ?? 0,
            'imageUrl': transporter['image_url'],
          };
        }
      }
    } catch (e) {
      print('Error fetching transporter details: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchDeliveryPersonDetails(String deliveryPersonId) async {
    try {
      final token = await _resolveToken();
      if (token == null) return null;
      
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/delivery-persons'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final deliveryPersons = data['data'] as List;
        final deliveryPerson = deliveryPersons.firstWhere(
          (dp) => dp['delivery_person_id'].toString() == deliveryPersonId,
          orElse: () => null,
        );
        
        if (deliveryPerson != null) {
          final stats = deliveryPerson['order_stats'] ?? {};
          return {
            'id': deliveryPerson['delivery_person_id'],
            'name': deliveryPerson['name'],
            'vehicleNumber': deliveryPerson['vehicle_number'],
            'isAvailable': deliveryPerson['is_available'] ?? false,
            'totalOrders': stats['total_orders'] ?? 0,
            'rating': (stats['average_rating'] ?? 0.0).toString(),
            'phone': deliveryPerson['mobile_number'],
            'licenseNumber': deliveryPerson['license_number'] ?? 'N/A',
            'currentLocation': deliveryPerson['current_location'] ?? 'N/A',
            'vehicleType': deliveryPerson['vehicle_type'] ?? 'bike',
            'totalAmount': (stats['total_amount'] ?? 0.0).toDouble(),
          };
        }
      }
    } catch (e) {
      print('Error fetching delivery person details: $e');
    }
    return null;
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return '';
    try {
      DateTime date;
      if (dateTime is String) {
        date = DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        date = dateTime;
      } else {
        return '';
      }
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Order Tracking'),
        backgroundColor: Colors.green[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _selectedOrder == null
                  ? const Center(child: Text('No order selected'))
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildOrderHeader(),
                            _buildProductCard(),
                            _buildTrackingTimeline(),
                            _buildOrderDetails(),
                          ],
                        ),
                      ),
                    ),
    );
  }
}