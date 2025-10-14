class OrderUpdate {
  final String orderId;
  final String currentStatus;
  final String? latestUpdate;
  final String lastUpdated;
  final int? sourceTransporterId;
  final int? destinationTransporterId;

  OrderUpdate({
    required this.orderId,
    required this.currentStatus,
    this.latestUpdate,
    required this.lastUpdated,
    this.sourceTransporterId,
    this.destinationTransporterId,
  });

  factory OrderUpdate.fromJson(Map<String, dynamic> json) {
    return OrderUpdate(
      orderId: json['order_id']?.toString() ?? '',
      currentStatus: json['current_status'] ?? '',
      latestUpdate: json['latest_update'],
      lastUpdated: json['last_updated'] ?? '',
      sourceTransporterId: json['source_transporter_id'],
      destinationTransporterId: json['destination_transporter_id'],
    );
  }
}

class OrderTrackingResponse {
  final bool success;
  final OrderUpdate? data;

  OrderTrackingResponse({
    required this.success,
    this.data,
  });

  factory OrderTrackingResponse.fromJson(Map<String, dynamic> json) {
    return OrderTrackingResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? OrderUpdate.fromJson(json['data']) : null,
    );
  }
}

class TrackingProduct {
  final int productId;
  final String name;
  final String currentPrice;
  final List<ProductImage> images;

  TrackingProduct({
    required this.productId,
    required this.name,
    required this.currentPrice,
    required this.images,
  });

  factory TrackingProduct.fromJson(Map<String, dynamic> json) {
    return TrackingProduct(
      productId: json['product_id'] ?? 0,
      name: json['name'] ?? '',
      currentPrice: json['current_price']?.toString() ?? '0.00',
      images: (json['images'] as List<dynamic>?)
              ?.map((img) => ProductImage.fromJson(img))
              .toList() ??
          [],
    );
  }
}

class ProductImage {
  final String imageUrl;
  final bool isPrimary;

  ProductImage({
    required this.imageUrl,
    required this.isPrimary,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      imageUrl: json['image_url'] ?? '',
      isPrimary: json['is_primary'] ?? false,
    );
  }
}

class TrackingCustomer {
  final String name;
  final String mobileNumber;
  final String address;
  final String? zone;

  TrackingCustomer({
    required this.name,
    required this.mobileNumber,
    required this.address,
    this.zone,
  });

  factory TrackingCustomer.fromJson(Map<String, dynamic> json) {
    return TrackingCustomer(
      name: json['name'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      address: json['address'] ?? '',
      zone: json['zone'],
    );
  }
}

class TrackingStep {
  final String status;
  final String label;
  final String icon;
  final bool completed;
  final bool current;

  TrackingStep({
    required this.status,
    required this.label,
    required this.icon,
    required this.completed,
    required this.current,
  });

  factory TrackingStep.fromJson(Map<String, dynamic> json) {
    return TrackingStep(
      status: json['status'] ?? '',
      label: json['label'] ?? '',
      icon: json['icon'] ?? '',
      completed: json['completed'] ?? false,
      current: json['current'] ?? false,
    );
  }
}

class TrackedOrder {
  final int orderId;
  final int customerId;
  final int productId;
  final int? sourceTransporterId;
  final int? destinationTransporterId;
  final int? deliveryPersonId;
  final int? permanentVehicleId;
  final int? tempVehicleId;
  final int quantity;
  final double totalPrice;
  final double farmerAmount;
  final double adminCommission;
  final double transportCharge;
  final String paymentStatus;
  final String currentStatus;
  final String qrCode;
  final String billUrl;
  final String pickupAddress;
  final String deliveryAddress;
  final String? estimatedDistance;
  final String? estimatedDeliveryTime;
  final String createdAt;
  final String updatedAt;
  final TrackingProduct product;
  final TrackingCustomer customer;

  TrackedOrder({
    required this.orderId,
    required this.customerId,
    required this.productId,
    this.sourceTransporterId,
    this.destinationTransporterId,
    this.deliveryPersonId,
    this.permanentVehicleId,
    this.tempVehicleId,
    required this.quantity,
    required this.totalPrice,
    required this.farmerAmount,
    required this.adminCommission,
    required this.transportCharge,
    required this.paymentStatus,
    required this.currentStatus,
    required this.qrCode,
    required this.billUrl,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.estimatedDistance,
    this.estimatedDeliveryTime,
    required this.createdAt,
    required this.updatedAt,
    required this.product,
    required this.customer,
  });

  factory TrackedOrder.fromJson(Map<String, dynamic> json) {
    return TrackedOrder(
      orderId: json['order_id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      sourceTransporterId: json['source_transporter_id'],
      destinationTransporterId: json['destination_transporter_id'],
      deliveryPersonId: json['delivery_person_id'],
      permanentVehicleId: json['permanent_vehicle_id'],
      tempVehicleId: json['temp_vehicle_id'],
      quantity: json['quantity'] ?? 0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0.00') ?? 0.00,
      farmerAmount: double.tryParse(json['farmer_amount']?.toString() ?? '0.00') ?? 0.00,
      adminCommission: double.tryParse(json['admin_commission']?.toString() ?? '0.00') ?? 0.00,
      transportCharge: double.tryParse(json['transport_charge']?.toString() ?? '0.00') ?? 0.00,
      paymentStatus: json['payment_status'] ?? '',
      currentStatus: json['current_status'] ?? '',
      qrCode: json['qr_code'] ?? '',
      billUrl: json['bill_url'] ?? '',
      pickupAddress: json['pickup_address'] ?? '',
      deliveryAddress: json['delivery_address'] ?? '',
      estimatedDistance: json['estimated_distance'],
      estimatedDeliveryTime: json['estimated_delivery_time'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      product: TrackingProduct.fromJson(json['product'] ?? {}),
      customer: TrackingCustomer.fromJson(json['customer'] ?? {}),
    );
  }
}

class OrderTrackingDetail {
  final TrackedOrder order;
  final List<TrackingStep> trackingSteps;
  final List<dynamic> trackingHistory;
  final String? estimatedDelivery;

  OrderTrackingDetail({
    required this.order,
    required this.trackingSteps,
    required this.trackingHistory,
    this.estimatedDelivery,
  });

  factory OrderTrackingDetail.fromJson(Map<String, dynamic> json) {
    return OrderTrackingDetail(
      order: TrackedOrder.fromJson(json['order'] ?? {}),
      trackingSteps: (json['tracking_steps'] as List<dynamic>?)
              ?.map((step) => TrackingStep.fromJson(step))
              .toList() ??
          [],
      trackingHistory: json['tracking_history'] as List<dynamic>? ?? [],
      estimatedDelivery: json['estimated_delivery'],
    );
  }
}

class OrderTrackingFullResponse {
  final bool success;
  final OrderTrackingDetail? data;

  OrderTrackingFullResponse({
    required this.success,
    this.data,
  });

  factory OrderTrackingFullResponse.fromJson(Map<String, dynamic> json) {
    return OrderTrackingFullResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? OrderTrackingDetail.fromJson(json['data']) : null,
    );
  }
}

class ActiveOrder {
  final int orderId;
  final int customerId;
  final int productId;
  final int? sourceTransporterId;
  final int? destinationTransporterId;
  final int? deliveryPersonId;
  final int? permanentVehicleId;
  final int? tempVehicleId;
  final int quantity;
  final double totalPrice;
  final double farmerAmount;
  final double adminCommission;
  final double transportCharge;
  final String paymentStatus;
  final String currentStatus;
  final String qrCode;
  final String billUrl;
  final String pickupAddress;
  final String deliveryAddress;
  final String? estimatedDistance;
  final String? estimatedDeliveryTime;
  final String createdAt;
  final String updatedAt;
  final TrackingProduct product;
  final TrackingCustomer customer;

  ActiveOrder({
    required this.orderId,
    required this.customerId,
    required this.productId,
    this.sourceTransporterId,
    this.destinationTransporterId,
    this.deliveryPersonId,
    this.permanentVehicleId,
    this.tempVehicleId,
    required this.quantity,
    required this.totalPrice,
    required this.farmerAmount,
    required this.adminCommission,
    required this.transportCharge,
    required this.paymentStatus,
    required this.currentStatus,
    required this.qrCode,
    required this.billUrl,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.estimatedDistance,
    this.estimatedDeliveryTime,
    required this.createdAt,
    required this.updatedAt,
    required this.product,
    required this.customer,
  });

  factory ActiveOrder.fromJson(Map<String, dynamic> json) {
    return ActiveOrder(
      orderId: json['order_id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      sourceTransporterId: json['source_transporter_id'],
      destinationTransporterId: json['destination_transporter_id'],
      deliveryPersonId: json['delivery_person_id'],
      permanentVehicleId: json['permanent_vehicle_id'],
      tempVehicleId: json['temp_vehicle_id'],
      quantity: json['quantity'] ?? 0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0.00') ?? 0.00,
      farmerAmount: double.tryParse(json['farmer_amount']?.toString() ?? '0.00') ?? 0.00,
      adminCommission: double.tryParse(json['admin_commission']?.toString() ?? '0.00') ?? 0.00,
      transportCharge: double.tryParse(json['transport_charge']?.toString() ?? '0.00') ?? 0.00,
      paymentStatus: json['payment_status'] ?? '',
      currentStatus: json['current_status'] ?? '',
      qrCode: json['qr_code'] ?? '',
      billUrl: json['bill_url'] ?? '',
      pickupAddress: json['pickup_address'] ?? '',
      deliveryAddress: json['delivery_address'] ?? '',
      estimatedDistance: json['estimated_distance'],
      estimatedDeliveryTime: json['estimated_delivery_time'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      product: TrackingProduct.fromJson(json['product'] ?? {}),
      customer: TrackingCustomer.fromJson(json['customer'] ?? {}),
    );
  }
}

class ActiveOrdersResponse {
  final bool success;
  final List<ActiveOrder> data;

  ActiveOrdersResponse({
    required this.success,
    required this.data,
  });

  factory ActiveOrdersResponse.fromJson(Map<String, dynamic> json) {
    return ActiveOrdersResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((order) => ActiveOrder.fromJson(order))
              .toList() ??
          [],
    );
  }
}