import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Farmer/models/order_tracking.dart';
import '../Farmer/services/order_tracking_service.dart';
import '../../utils/cloudinary_upload.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;
  final String? token;

  const OrderTrackingPage({
    Key? key,
    required this.orderId,
    this.token,
  }) : super(key: key);

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  OrderTrackingDetail? trackingDetail;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTrackingData();
  }

  Future<void> _fetchTrackingData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await OrderTrackingService.getOrderTrack(
        widget.orderId,
        widget.token,
      );

      if (response != null && response.success && response.data != null) {
        setState(() {
          trackingDetail = response.data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load tracking information';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchTrackingData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : trackingDetail == null
                  ? const Center(child: Text('No tracking information available'))
                  : RefreshIndicator(
                      onRefresh: _fetchTrackingData,
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

  Widget _buildOrderHeader() {
    final order = trackingDetail!.order;
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.currentStatus.replaceAll('_', ' '),
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
            'Estimated delivery: ${order.estimatedDeliveryTime ?? 'Calculating...'}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    final order = trackingDetail!.order;
    final product = order.product;
    final primaryImage = product.images.firstWhere(
      (img) => img.isPrimary,
      orElse: () => product.images.isNotEmpty ? product.images.first : ProductImage(imageUrl: '', isPrimary: true),
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              child: primaryImage.imageUrl.isNotEmpty
                  ? Image.network(
                      CloudinaryUploader.optimizeImageUrl(primaryImage.imageUrl, width: 80, height: 80),
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
                  product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: ${order.quantity} kg',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${order.totalPrice.toStringAsFixed(2)}',
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

  Widget _buildTrackingTimeline() {
    // Filter out "Transporter Assigned" step and rename "Picked Up from Farm" to "Pickup from Farm"
    final filteredSteps = trackingDetail!.trackingSteps
        .where((step) => step.label != 'Transporter Assigned')
        .map((step) => step.label == 'Picked Up from Farm' 
            ? TrackingStep(
                status: step.status,
                label: 'Pickup from Farm',
                icon: step.icon,
                completed: step.completed,
                current: step.current,
              )
            : step)
        .toList();
    
    // If current status is ASSIGNED and we have a Pickup from Farm step, make it current
    if (trackingDetail!.order.currentStatus == 'ASSIGNED') {
      for (int i = 0; i < filteredSteps.length; i++) {
        if (filteredSteps[i].label == 'Pickup from Farm' && !filteredSteps[i].completed) {
          filteredSteps[i] = TrackingStep(
            status: filteredSteps[i].status,
            label: filteredSteps[i].label,
            icon: filteredSteps[i].icon,
            completed: true,
            current: true,
          );
        }
      }
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildTrackingStep(TrackingStep step, bool isLast) {
    final isCompleted = step.completed;
    final isCurrent = step.current;
    
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
                child: Text(
                  step.icon,
                  style: const TextStyle(fontSize: 20),
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
                step.label,
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
            ],
          ),
        ),
        if (isCompleted)
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
      ],
    );
  }

  Widget _buildOrderDetails() {
    final order = trackingDetail!.order;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            'Order Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Customer', order.customer.name),
          _buildDetailRow('Mobile', order.customer.mobileNumber),
          _buildDetailRow('Pickup Address', order.pickupAddress),
          _buildDetailRow('Delivery Address', order.deliveryAddress),
          _buildDetailRow('Payment Status', order.paymentStatus),
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



  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}