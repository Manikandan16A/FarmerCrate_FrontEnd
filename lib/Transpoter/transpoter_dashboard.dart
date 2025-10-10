import 'package:flutter/material.dart';
import 'adddeliveryperson.dart';



class TransporterApp extends StatelessWidget {
  final String? token;
  
  const TransporterApp({super.key, this.token, required int customerId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transporter Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Inter',
      ),
      home: TransporterDashboard(token: token),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DeliveryPerson {
  String id;
  String name;
  String email;
  String phone;
  String vehicleType;
  String licenseNumber;
  bool isActive;
  int deliveriesCompleted;
  double rating;
  String profileImage;

  DeliveryPerson({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.licenseNumber,
    this.isActive = true,
    this.deliveriesCompleted = 0,
    this.rating = 5.0,
    this.profileImage = '',
  });
}

class TransporterDashboard extends StatefulWidget {
  final String? token;
  
  const TransporterDashboard({super.key, this.token});

  @override
  State<TransporterDashboard> createState() => _TransporterDashboardState();
}

class _TransporterDashboardState extends State<TransporterDashboard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<DeliveryPerson> deliveryPersons = [
    DeliveryPerson(
      id: '001',
      name: 'Alex Johnson',
      email: 'alex@delivery.com',
      phone: '+1234567890',
      vehicleType: 'Motorcycle',
      licenseNumber: 'DL123456789',
      deliveriesCompleted: 145,
      rating: 4.8,
    ),
    DeliveryPerson(
      id: '002',
      name: 'Maria Garcia',
      email: 'maria@delivery.com',
      phone: '+1234567891',
      vehicleType: 'Van',
      licenseNumber: 'DL987654321',
      deliveriesCompleted: 203,
      rating: 4.9,
    ),
    DeliveryPerson(
      id: '003',
      name: 'David Chen',
      email: 'david@delivery.com',
      phone: '+1234567892',
      vehicleType: 'Bicycle',
      licenseNumber: 'DL456789123',
      deliveriesCompleted: 87,
      rating: 4.7,
      isActive: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }


  void _deletePerson(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this delivery person?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                deliveryPersons.removeWhere((p) => p.id == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delivery person deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667EEA),
                      Color(0xFF764BA2),
                    ],
                  ),
                ),
                child: FlexibleSpaceBar(
                  title: const Text(
                    'Delivery Team',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF667EEA),
                          Color(0xFF764BA2),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        const Positioned(
                          right: -50,
                          top: -50,
                          child: CircleAvatar(
                            radius: 100,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                        Positioned(
                          left: -30,
                          bottom: -30,
                          child: CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatsCards(),
                    const SizedBox(height: 30),
                    _buildDeliveryPersonsList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddDeliveryAgentScreen(token: widget.token),
            ),
          );
        },
        backgroundColor: const Color(0xFF667EEA),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Driver', style: TextStyle(color: Colors.white)),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF667EEA),
                    Color(0xFF764BA2),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'TransporterCrate',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Delivery Management',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.dashboard, color: Colors.white, size: 20),
              ),
              title: const Text(
                'Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people, color: Colors.white, size: 20),
              ),
              title: const Text(
                'Delivery Team',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics, color: Colors.white, size: 20),
              ),
              title: const Text(
                'Qr Scan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Add analytics navigation here
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.settings, color: Colors.white, size: 20),
              ),
              title: const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Add settings navigation here
              },
            ),
            const Divider(color: Colors.white30, thickness: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout, color: Colors.white, size: 20),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF667EEA),
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        currentIndex: 0,
        elevation: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Dashboard - already on this page
              break;
            case 1:
              // Analytics
              break;
            case 2:
              // Settings
              break;
            case 3:
              // Logout
              _showLogoutDialog();
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard, size: 24),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics, size: 24),
            label: 'Qr Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 24),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout, size: 24),
            label: 'Logout',
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 12),
              Text('Logout'),
            ],
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Add logout logic here
                // For now, just show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Drivers',
            value: deliveryPersons.length.toString(),
            icon: Icons.people,
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Active Drivers',
            value: deliveryPersons.where((p) => p.isActive).length.toString(),
            icon: Icons.directions_bike,
            color: const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Avg Rating',
            value: (deliveryPersons.map((p) => p.rating).reduce((a, b) => a + b) / deliveryPersons.length).toStringAsFixed(1),
            icon: Icons.star,
            color: const Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPersonsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Delivery Personnel',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: deliveryPersons.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey[200],
            ),
            itemBuilder: (context, index) {
              final person = deliveryPersons[index];
              return _buildPersonCard(person);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPersonCard(DeliveryPerson person) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: person.isActive ? const Color(0xFF667EEA) : Colors.grey,
            child: Text(
              person.name.split(' ').map((e) => e[0]).join(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      person.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: person.isActive ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        person.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 10,
                          color: person.isActive ? Colors.green[800] : Colors.red[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  person.vehicleType,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${person.rating}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.local_shipping, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${person.deliveriesCompleted} deliveries',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
                onTap: () => Future.delayed(
                  Duration.zero,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddDeliveryAgentScreen(token: widget.token),
                      ),
                    );
                  },
                ),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(person.isActive ? Icons.pause : Icons.play_arrow, size: 18),
                    const SizedBox(width: 8),
                    Text(person.isActive ? 'Deactivate' : 'Activate'),
                  ],
                ),
                onTap: () {
                  setState(() {
                    person.isActive = !person.isActive;
                  });
                },
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
                onTap: () => Future.delayed(
                  Duration.zero,
                      () => _deletePerson(person.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddEditDeliveryPersonDialog extends StatefulWidget {
  final DeliveryPerson? person;
  final Function(DeliveryPerson) onSave;

  const AddEditDeliveryPersonDialog({
    super.key,
    this.person,
    required this.onSave,
  });

  @override
  State<AddEditDeliveryPersonDialog> createState() => _AddEditDeliveryPersonDialogState();
}

class _AddEditDeliveryPersonDialogState extends State<AddEditDeliveryPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _licenseController;
  String _selectedVehicle = 'Motorcycle';
  bool _isActive = true;

  final List<String> _vehicleTypes = [
    'Motorcycle',
    'Bicycle',
    'Van',
    'Car',
    'Scooter',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person?.name ?? '');
    _emailController = TextEditingController(text: widget.person?.email ?? '');
    _phoneController = TextEditingController(text: widget.person?.phone ?? '');
    _licenseController = TextEditingController(text: widget.person?.licenseNumber ?? '');
    _selectedVehicle = widget.person?.vehicleType ?? 'Motorcycle';
    _isActive = widget.person?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  void _savePerson() {
    if (_formKey.currentState!.validate()) {
      final person = DeliveryPerson(
        id: widget.person?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        vehicleType: _selectedVehicle,
        licenseNumber: _licenseController.text,
        isActive: _isActive,
        deliveriesCompleted: widget.person?.deliveriesCompleted ?? 0,
        rating: widget.person?.rating ?? 5.0,
      );

      widget.onSave(person);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              widget.person == null
                  ? 'Delivery person added successfully'
                  : 'Delivery person updated successfully'
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: Color(0xFF667EEA),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.person == null ? 'Add New Driver' : 'Edit Driver',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email address';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _licenseController,
                        label: 'License Number',
                        icon: Icons.credit_card,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter license number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(),
                      const SizedBox(height: 16),
                      _buildSwitchTile(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _savePerson,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.person == null ? 'Add Driver' : 'Update Driver',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF667EEA)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedVehicle,
      decoration: InputDecoration(
        labelText: 'Vehicle Type',
        prefixIcon: const Icon(Icons.directions_car, color: Color(0xFF667EEA)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: _vehicleTypes.map((String vehicle) {
        return DropdownMenuItem<String>(
          value: vehicle,
          child: Text(vehicle),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedVehicle = newValue!;
        });
      },
    );
  }

  Widget _buildSwitchTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.toggle_on, color: Color(0xFF667EEA)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Active Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (bool value) {
              setState(() {
                _isActive = value;
              });
            },
            activeColor: const Color(0xFF667EEA),
          ),
        ],
      ),
    );
  }
}