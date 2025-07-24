class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String images;
  final String category;
  final String status;
  final String lastPriceUpdate;
  final int views;
  final String createdAt;
  final String updatedAt;
  final Farmer? farmer;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.images,
    required this.category,
    required this.status,
    required this.lastPriceUpdate,
    required this.views,
    required this.createdAt,
    required this.updatedAt,
    this.farmer,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? 'Not Available',
      description: json['description'] ?? 'Not Available',
      price: json['price'] is double ? json['price'] : double.tryParse(json['price'].toString()) ?? 0.0,
      quantity: json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity'].toString()) ?? 0,
      images: json['images']?.toString() ?? '',
      category: json['category'] ?? 'Not Available',
      status: json['status'] ?? 'Not Available',
      lastPriceUpdate: json['last_price_update'] ?? 'Not Available',
      views: json['views'] is int ? json['views'] : int.tryParse(json['views'].toString()) ?? 0,
      createdAt: json['created_at'] ?? 'Not Available',
      updatedAt: json['updated_at'] ?? 'Not Available',
      farmer: json['farmer'] != null ? Farmer.fromJson(json['farmer']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'quantity': quantity,
    'images': images,
    'category': category,
    'status': status,
    'last_price_update': lastPriceUpdate,
    'views': views,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'farmer': farmer?.toJson(),
  };
}

class Farmer {
  final String name;
  final String mobileNumber;
  final String email;
  final String address;
  final String zone;
  final String state;
  final String district;
  final int age;
  final String imageUrl;
  final String createdAt;
  final String updatedAt;

  Farmer({
    required this.name,
    required this.mobileNumber,
    required this.email,
    required this.address,
    required this.zone,
    required this.state,
    required this.district,
    required this.age,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) {
    return Farmer(
      name: json['name'] ?? 'Not Available',
      mobileNumber: json['mobile_number'] ?? 'Not Available',
      email: json['email'] ?? 'Not Available',
      address: json['address'] ?? 'Not Available',
      zone: json['zone'] ?? 'Not Available',
      state: json['state'] ?? 'Not Available',
      district: json['district'] ?? 'Not Available',
      age: json['age'] is int ? json['age'] : int.tryParse(json['age'].toString()) ?? 0,
      imageUrl: json['image_url'] ?? '',
      createdAt: json['created_at'] ?? 'Not Available',
      updatedAt: json['updated_at'] ?? 'Not Available',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'mobile_number': mobileNumber,
    'email': email,
    'address': address,
    'zone': zone,
    'state': state,
    'district': district,
    'age': age,
    'image_url': imageUrl,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}