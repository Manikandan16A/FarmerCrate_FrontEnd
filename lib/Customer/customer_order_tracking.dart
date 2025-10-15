import 'package:flutter/material.dart';
import 'dart:async';
import 'customer_order_service.dart';
import 'navigation_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/cloudinary_upload.dart';

class CustomerOrderTrackingPage extends StatefulWidget {
  final String? token;
  final String? orderId;

  const CustomerOrderTrackingPage({
    super.key,
    this.token,
    this.orderId,
  });

  @override
  State<CustomerOrderTrackingPage> createState() => _CustomerOrderTrackingPageState();
}

class _CustomerOrderTrackingPageState extends State<CustomerOrderTrackingPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _activeShipments = [];
  Map<String, dynamic>? _selectedOrder;
  List<dynamic> _trackingSteps = [];
  // Timer? _refreshTimer; // Disabled auto-refresh
  
  @override
  void initState() {
    super.initState();
    _fetchActiveShipments();
    // Auto-refresh disabled - uncomment below line to enable
    // _startAutoRefresh();
  }

  @override
  void dispose() {
    // _refreshTimer?.cancel(); // Disabled since auto-refresh is not active
    super.dispose();
  }

  // Auto-refresh method disabled
  /*
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _fetchActiveShipments();
        if (_selectedOrder != null) {
          _fetchOrderTracking(_selectedOrder!['order_id'].toString());
        }
      }
    });
  }
  */

  Future<String?> _resolveToken() async {
    if (widget.token != null && widget.token!.trim().isNotEmpty) {
      print('DEBUG: Using provided token, length: ${widget.token!.length}');
      return widget.token;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      final jwtToken = prefs.getString('jwt_token');
      final resolvedToken = authToken ?? jwtToken;
      print('DEBUG: Resolved token from SharedPreferences, length: ${resolvedToken?.length ?? 0}');
      return resolvedToken;
    } catch (_) {
      print('DEBUG: Failed to resolve token from SharedPreferences');
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

    print('DEBUG: About to fetch active shipments');
    final result = await CustomerOrderService.getActiveShipments(token);
    print('DEBUG: Got result: ${result['success']}, error: ${result['error']}');
    
    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _activeShipments = result['data'] as List<dynamic>;
          _error = null;
          
          // Auto-select first order if none selected and we have shipments
          if (_selectedOrder == null && _activeShipments.isNotEmpty && widget.orderId == null) {
            _selectedOrder = _activeShipments.first;
            _fetchOrderTracking(_selectedOrder!['order_id'].toString());
          } else if (widget.orderId != null) {
            // Select specific order if orderId provided
            final specificOrder = _activeShipments.firstWhere(
              (order) => order['order_id'].toString() == widget.orderId,
              orElse: () => <String, dynamic>{},
          );
            if (specificOrder != null && specificOrder.isNotEmpty) {
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

  Future<void> _fetchOrderTracking(String orderId) async {
    final token = await _resolveToken();
    if (token == null) return;

    final result = await CustomerOrderService.trackOrder(token, orderId);
    
    if (mounted && result['success'] == true) {
      setState(() {
        final data = result['data'] as Map<String, dynamic>;
        _trackingSteps = data['tracking_steps'] as List<dynamic> ?? [];
      });
    }
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

  Widget _buildShipmentCard(Map<String, dynamic> shipment) {
    final isSelected = _selectedOrder?['order_id'] == shipment['order_id'];
    final statusColor = _getStatusColor(shipment['current_status'] ?? 'unknown');
    
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
          'Order #${shipment['order_id']}',
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
              shipment['current_status'] ?? 'Unknown',
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

    // Filter out "Transporter Assigned" step
    final filteredSteps = _trackingSteps.where((step) => 
      (step['status']?.toUpperCase() != 'ASSIGNED')).toList();

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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredSteps.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final step = filteredSteps[index];
              return _buildTrackingStep(step, index == filteredSteps.length - 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStep(Map<String, dynamic> step, bool isLast) {
    final isCompleted = step['completed'] ?? false;
    final isCurrent = step['current'] ?? false;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? (isCurrent ? Colors.orange : Colors.green)
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  _getStepIcon(step['status']),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step['label'] ?? 'Unknown Step',
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted || isCurrent ? Colors.black : Colors.grey,
                ),
              ),
              if (isCurrent)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Current Status',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (step['location'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  step['location'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
              if (step['timestamp'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatDate(step['timestamp']),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (isCompleted)
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
      ],
    );
  }

  IconData _getStepIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
        return Icons.shopping_cart;
      case 'ACCEPTED':
        return Icons.check_circle;
      case 'ASSIGNED':
        return Icons.person_add; // Keep for internal use, but won't be shown in timeline
      case 'SHIPPED':
        return Icons.local_shipping;
      case 'IN_TRANSIT':
        return Icons.directions_transit;
      case 'OUT_FOR_DELIVERY':
        return Icons.delivery_dining;
      case 'DELIVERED':
        return Icons.done_all;
      default:
        return Icons.circle;
    }
  }

  Widget _buildOrderHeader() {
    if (_selectedOrder == null) return const SizedBox.shrink();
    
    final order = _selectedOrder!;
    final statusColor = _getStatusColor(order['current_status'] ?? 'unknown');
    
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
          const Text(
            'Your Order',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (order['current_status'] ?? 'Unknown').replaceAll('_', ' '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
    print('DEBUG: Building product card for order: ${order['order_id']}');
    print('DEBUG: Order data: $order');
    print('DEBUG: Total price: ${order['total_price']} (${order['total_price'].runtimeType})');
    print('DEBUG: Quantity: ${order['quantity']} (${order['quantity'].runtimeType})');
    
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
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
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
    final farmer = order['farmer'] ?? {};
    
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
            'Farmer Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Farmer Name', farmer['name'] ?? 'Unknown'),
          _buildDetailRow('Farm Location', farmer['farm_location'] ?? 'N/A'),
          _buildDetailRow('Contact', farmer['mobile_number'] ?? 'N/A'),
          _buildDetailRow('Pickup Address', order['pickup_address'] ?? 'N/A'),
          _buildDetailRow('Delivery Address', order['delivery_address'] ?? 'N/A'),
          _buildDetailRow('Payment Status', order['payment_status'] ?? 'Unknown'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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
      drawer: CustomerNavigationUtils.buildCustomerDrawer(
        parentContext: context,
        token: widget.token,
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
      bottomNavigationBar: CustomerNavigationUtils.buildCustomerBottomNav(
        currentIndex: 1, // Orders tab
        onTap: (index) => CustomerNavigationUtils.handleNavigation(index, context, widget.token),
      ),
    );
  }
}