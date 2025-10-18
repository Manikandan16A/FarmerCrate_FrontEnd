import 'package:farmer_crate/Admin/user_management.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:excel/excel.dart' as excel_pkg;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../auth/Signin.dart';
import 'common_navigation.dart';
import 'admin_homepage.dart';
import 'total_order.dart';
import 'ConsumerManagement.dart';
import 'transpoter_mang.dart';
import 'admin_orders_page.dart';
import 'admin_sidebar.dart';


class ReportsPage extends StatefulWidget {
  final String token;
  final dynamic user;
  const ReportsPage({super.key, required this.token, required this.user});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isWeeklyView = false;
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 3; // Reports tab is index 3 in the new navigation

  // Aggregated order count by calendar day
  final Map<DateTime, int> _orderData = {};

  // Recent orders list built from API
  List<_SimpleOrder> _recentOrders = [];
  List<_SimpleOrder> _allOrders = [];
  String _filterType = 'all'; // all, today, week, month

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/orders/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch orders (${response.statusCode})');
      }

      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> dataList = decoded is Map<String, dynamic>
          ? (decoded['data'] as List<dynamic>? ?? [])
          : (decoded as List<dynamic>? ?? []);

      // Reset
      _orderData.clear();
      final List<_SimpleOrder> recent = [];

      for (final dynamic item in dataList) {
        if (item is Map<String, dynamic>) {
          final createdAtStr = item['created_at']?.toString() ?? '';
          if (createdAtStr.isEmpty) continue;
          DateTime? created;
          try {
            created = DateTime.parse(createdAtStr).toLocal();
          } catch (_) {
            created = null;
          }
          if (created == null) continue;
          final day = DateTime(created.year, created.month, created.day);
          _orderData[day] = (_orderData[day] ?? 0) + 1;

          // For recent list
          final product = item['product'] as Map<String, dynamic>?;
          final productName = product?['name']?.toString() ?? 'Product';
          final quantity = item['quantity']?.toString() ?? '1';
          final id = item['order_id']?.toString() ?? item['id']?.toString() ?? '-';
          final images = product?['images'] as List?;
          String? imageUrl;
          if (images != null && images.isNotEmpty) {
            try {
              final primaryImage = images.firstWhere((img) => img['is_primary'] == true, orElse: () => images.first);
              imageUrl = primaryImage['image_url'];
            } catch (_) {}
          }
          final totalPrice = item['total_price']?.toString() ?? '0';
          final status = item['current_status']?.toString() ?? 'N/A';
          
          final customer = item['customer'] as Map<String, dynamic>?;
          final deliveryPerson = item['delivery_person'];
          final farmer = product?['farmer'] as Map<String, dynamic>?;
          final sourceTransporter = item['source_transporter'] as Map<String, dynamic>?;
          final destTransporter = item['destination_transporter'] as Map<String, dynamic>?;
          
          recent.add(
            _SimpleOrder(
              id: id,
              item: productName,
              qty: quantity,
              date: day,
              imageUrl: imageUrl,
              totalPrice: totalPrice,
              status: status,
              customerName: customer?['name']?.toString() ?? 'N/A',
              customerEmail: customer?['email']?.toString() ?? 'N/A',
              customerPhone: customer?['mobile_number']?.toString() ?? 'N/A',
              deliveryAddress: item['delivery_address']?.toString() ?? 'N/A',
              deliveryPersonName: deliveryPerson != null ? (deliveryPerson['name']?.toString() ?? 'Wait for assigning') : 'Wait for assigning',
              deliveryPersonPhone: deliveryPerson != null ? (deliveryPerson['mobile_number']?.toString() ?? 'N/A') : 'N/A',
              farmerName: farmer?['name']?.toString() ?? 'N/A',
              farmerPhone: farmer?['mobile_number']?.toString() ?? 'N/A',
              sourceTransporter: sourceTransporter?['name']?.toString() ?? 'N/A',
              destTransporter: destTransporter?['name']?.toString() ?? 'N/A',
              pickupAddress: item['pickup_address']?.toString() ?? 'N/A',
            ),
          );
        }
      }

      // Sort recent orders by date desc
      recent.sort((a, b) => b.date.compareTo(a.date));
      _allOrders = recent;
      _recentOrders = recent.take(10).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getOrderColor(int orderCount) {
    if (orderCount >= 40) return Colors.green;
    if (orderCount >= 20) return Colors.orange;
    return Colors.red;
  }

  String _getOrderStatus(int orderCount) {
    if (orderCount >= 40) return 'High';
    if (orderCount >= 20) return 'Medium';
    return 'Low';
  }

  List<_SimpleOrder> _getRecentOrders([int count = 10]) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(Duration(days: 7));
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    List<_SimpleOrder> filtered;
    switch (_filterType) {
      case 'today':
        filtered = _recentOrders.where((o) => o.date.isAtSameMomentAs(today) || o.date.isAfter(today)).toList();
        break;
      case 'week':
        filtered = _recentOrders.where((o) => o.date.isAfter(weekAgo) || o.date.isAtSameMomentAs(weekAgo)).toList();
        break;
      case 'month':
        filtered = _recentOrders.where((o) => o.date.isAfter(monthAgo) || o.date.isAtSameMomentAs(monthAgo)).toList();
        break;
      default:
        filtered = _recentOrders;
    }
    return filtered.take(count).toList();
  }

  void _showAdminProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF2E7D32),
              child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
            ),
            SizedBox(height: 16),
            Text(widget.user['name'] ?? 'Admin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
            SizedBox(height: 4),
            Text(widget.user['email'] ?? 'admin@farmercrate.com', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text('Administrator', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginPage()), (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminManagementPage(token: widget.token, user: widget.user),
          ),
        );
        return false;
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 8,
        shadowColor: Colors.black26,
        leading: Builder(
          builder: (context) => Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.15)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.analytics_rounded, color: Colors.white, size: 26),
            ),
            SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Reports & Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Order Insights',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.download_rounded, color: Colors.white, size: 22),
              onPressed: _exportToExcel,
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
              onPressed: _fetchOrders,
            ),
          ),
        ],
      ),
      drawer: AdminSidebar(token: widget.token, user: widget.user),
      body: _isLoading
          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          : _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red))))
          : SingleChildScrollView(
        child: Column(
          children: [
            // Header with toggle
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // View toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleButton('Monthly', !_isWeeklyView, () {
                          setState(() {
                            _isWeeklyView = false;
                            _calendarFormat = CalendarFormat.month;
                          });
                        }),
                        _buildToggleButton('Weekly', _isWeeklyView, () {
                          setState(() {
                            _isWeeklyView = true;
                            _calendarFormat = CalendarFormat.week;
                          });
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem('High', Colors.green),
                      _buildLegendItem('Medium', Colors.orange),
                      _buildLegendItem('Low', Colors.red),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // Today button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _focusedDay = DateTime.now();
                        _selectedDay = DateTime.now();
                      });
                      _fetchOrders();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.today,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Today',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Calendar (no Expanded, no fixed height)
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(color: Colors.red),
                  holidayTextStyle: TextStyle(color: Colors.red),
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  defaultDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  weekendDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  holidayDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  outsideDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  markersMaxCount: 1,
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF50),
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: Color(0xFF4CAF50),
                    size: 28,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: Color(0xFF4CAF50),
                    size: 28,
                  ),
                  formatButtonShowsNext: false,
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: Color(0xFF2D3748),
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, date, _) {
                    final orderCount = _orderData[DateTime(date.year, date.month, date.day)];
                    if (orderCount != null) {
                      final color = _getOrderColor(orderCount);
                      return Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: color.darken(0.2),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  selectedBuilder: (context, date, _) {
                    final orderCount = _orderData[DateTime(date.year, date.month, date.day)];
                    final color = orderCount != null ? _getOrderColor(orderCount) : Colors.white;
                    return Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: orderCount != null
                            ? Border.all(
                          color: color,
                          width: 3,
                        )
                            : null,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${date.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (orderCount != null)
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  todayBuilder: (context, date, _) {
                    final orderCount = _orderData[DateTime(date.year, date.month, date.day)];
                    final color = orderCount != null ? _getOrderColor(orderCount) : const Color(0xFF4CAF50);
                    return Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4CAF50),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${date.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (orderCount != null)
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_selectedDay != null) _buildSelectedDayDetails(),
            // Recent Orders Section (label fixed, orders scrollable)
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Orders',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _getRecentOrders().length,
                    itemBuilder: (context, index) {
                      final order = _getRecentOrders()[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Color(0xFF4CAF50).withOpacity(0.3)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: order.imageUrl != null
                                      ? Image.network(
                                          order.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(Icons.shopping_bag, color: Color(0xFF4CAF50), size: 30),
                                        )
                                      : Icon(Icons.shopping_bag, color: Color(0xFF4CAF50), size: 30),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.item,
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text('Order ID: ${order.id}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.shopping_cart, size: 14, color: Colors.grey[600]),
                                        SizedBox(width: 4),
                                        Text('Qty: ${order.qty}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                        SizedBox(width: 12),
                                        Icon(Icons.currency_rupee, size: 14, color: Colors.grey[600]),
                                        Text('${order.totalPrice}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order.status),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      order.status,
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '${order.date.day}/${order.date.month}/${order.date.year}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        elevation: 8,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminManagementPage(user: widget.user, token: widget.token)));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminUserManagementPage(token: widget.token, user: widget.user)));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminOrdersPage(token: widget.token, user: widget.user)));
          } else if (index == 3) {
            // Already on reports page
          } else if (index == 4) {
            _showAdminProfile();
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts_rounded), label: 'Management'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDayDetails() {
    final orderCount = _selectedDay != null
        ? _orderData[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]
        : null;
    final orders = _allOrders.where((o) =>
    o.date.year == _selectedDay!.year && o.date.month == _selectedDay!.month && o.date.day == _selectedDay!.day
    ).toList();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Orders for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: orderCount != null
                          ? _getOrderColor(orderCount).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: orderCount != null
                                ? _getOrderColor(orderCount)
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          orderCount != null
                              ? '${orderCount} orders (${_getOrderStatus(orderCount)})'
                              : 'No orders',
                          style: TextStyle(
                            color: orderCount != null
                                ? _getOrderColor(orderCount)
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (orders.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Color(0xFF4CAF50).withOpacity(0.3)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: order.imageUrl != null
                                    ? Image.network(
                                        order.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(Icons.shopping_bag, color: Color(0xFF4CAF50), size: 35),
                                      )
                                    : Icon(Icons.shopping_bag, color: Color(0xFF4CAF50), size: 35),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.item,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text('Order ID: ${order.id}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                  SizedBox(height: 4),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order.status),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      order.status,
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 24),
                        Row(
                          children: [
                            Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 6),
                            Text('Qty: ${order.qty}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                            SizedBox(width: 16),
                            Icon(Icons.currency_rupee, size: 16, color: Colors.grey[600]),
                            Text('${order.totalPrice}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text('Customer: ${order.customerName}', style: TextStyle(fontSize: 13, color: Colors.grey[700]), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        if (order.customerPhone != 'N/A') ...[
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 6),
                              Text('Phone: ${order.customerPhone}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                            ],
                          ),
                        ],
                        if (order.deliveryAddress != 'N/A') ...[
                          SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text('Address: ${order.deliveryAddress}', style: TextStyle(fontSize: 13, color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                        if (order.deliveryPersonName != 'Wait for assigning') ...[
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.delivery_dining, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 6),
                              Text('Delivery: ${order.deliveryPersonName}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          )
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PLACED': return Color(0xFFFFA726);
      case 'ASSIGNED': return Color(0xFF66BB6A);
      case 'SHIPPED': return Color(0xFF42A5F5);
      case 'IN_TRANSIT': return Color(0xFFAB47BC);
      case 'RECEIVED': return Color(0xFF66BB6A);
      case 'OUT_FOR_DELIVERY': return Color(0xFFFF9800);
      case 'COMPLETED': return Color(0xFF4CAF50);
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _exportToExcel() async {
    try {
      var excel = excel_pkg.Excel.createExcel();
      excel_pkg.Sheet sheet = excel['Orders'];
      
      sheet.appendRow([
        excel_pkg.TextCellValue('Order ID'),
        excel_pkg.TextCellValue('Product'),
        excel_pkg.TextCellValue('Quantity'),
        excel_pkg.TextCellValue('Total Price'),
        excel_pkg.TextCellValue('Status'),
        excel_pkg.TextCellValue('Customer Name'),
        excel_pkg.TextCellValue('Customer Email'),
        excel_pkg.TextCellValue('Customer Phone'),
        excel_pkg.TextCellValue('Farmer Name'),
        excel_pkg.TextCellValue('Farmer Phone'),
        excel_pkg.TextCellValue('Pickup Address'),
        excel_pkg.TextCellValue('Delivery Address'),
        excel_pkg.TextCellValue('Source Transporter'),
        excel_pkg.TextCellValue('Destination Transporter'),
        excel_pkg.TextCellValue('Delivery Person'),
        excel_pkg.TextCellValue('Delivery Phone'),
        excel_pkg.TextCellValue('Order Date'),
      ]);

      for (var order in _allOrders) {
        sheet.appendRow([
          excel_pkg.TextCellValue(order.id),
          excel_pkg.TextCellValue(order.item),
          excel_pkg.TextCellValue(order.qty),
          excel_pkg.TextCellValue(order.totalPrice),
          excel_pkg.TextCellValue(order.status),
          excel_pkg.TextCellValue(order.customerName),
          excel_pkg.TextCellValue(order.customerEmail),
          excel_pkg.TextCellValue(order.customerPhone),
          excel_pkg.TextCellValue(order.farmerName),
          excel_pkg.TextCellValue(order.farmerPhone),
          excel_pkg.TextCellValue(order.pickupAddress),
          excel_pkg.TextCellValue(order.deliveryAddress),
          excel_pkg.TextCellValue(order.sourceTransporter),
          excel_pkg.TextCellValue(order.destTransporter),
          excel_pkg.TextCellValue(order.deliveryPersonName),
          excel_pkg.TextCellValue(order.deliveryPersonPhone),
          excel_pkg.TextCellValue('${order.date.day}/${order.date.month}/${order.date.year}'),
        ]);
      }

      var fileBytes = excel.save();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/orders_report_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(fileBytes!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Excel downloaded to: ${file.path}', style: TextStyle(fontWeight: FontWeight.w500))),
              ],
            ),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: Duration(seconds: 3),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Export failed: $e', style: TextStyle(fontWeight: FontWeight.w500))),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: Duration(seconds: 3),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}

extension on Color {
  Color darken([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

class _SimpleOrder {
  final String id;
  final String item;
  final String qty;
  final DateTime date;
  final String? imageUrl;
  final String totalPrice;
  final String status;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String deliveryAddress;
  final String deliveryPersonName;
  final String deliveryPersonPhone;
  final String farmerName;
  final String farmerPhone;
  final String sourceTransporter;
  final String destTransporter;
  final String pickupAddress;
  
  _SimpleOrder({
    required this.id,
    required this.item,
    required this.qty,
    required this.date,
    this.imageUrl,
    required this.totalPrice,
    required this.status,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.deliveryPersonName,
    required this.deliveryPersonPhone,
    required this.farmerName,
    required this.farmerPhone,
    required this.sourceTransporter,
    required this.destTransporter,
    required this.pickupAddress,
  });
}