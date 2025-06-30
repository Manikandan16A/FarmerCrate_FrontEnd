import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isWeeklyView = false;

  // Sample order data - replace with API call
  final Map<DateTime, int> _orderData = {
    // December 2024
    DateTime(2024, 12, 1): 45,   // High - Green
    DateTime(2024, 12, 3): 25,   // Medium - Yellow
    DateTime(2024, 12, 5): 12,   // Low - Red
    DateTime(2024, 12, 8): 38,   // Medium - Yellow
    DateTime(2024, 12, 10): 52,  // High - Green
    DateTime(2024, 12, 12): 8,   // Low - Red
    DateTime(2024, 12, 15): 41,  // High - Green
    DateTime(2024, 12, 18): 22,  // Medium - Yellow
    DateTime(2024, 12, 20): 15,  // Low - Red
    DateTime(2024, 12, 22): 48,  // High - Green
    DateTime(2024, 12, 25): 30,  // Medium - Yellow
    DateTime(2024, 12, 28): 55,  // High - Green
    DateTime(2024, 12, 30): 18,  // Medium - Yellow
    DateTime(2024, 12, 31): 62,  // High - Green (New Year's Eve)

    // January 2025
    DateTime(2025, 1, 1): 35,    // Medium - Yellow (New Year's Day)
    DateTime(2025, 1, 5): 28,    // Medium - Yellow
    DateTime(2025, 1, 10): 45,   // High - Green
    DateTime(2025, 1, 15): 18,   // Medium - Yellow
    DateTime(2025, 1, 20): 52,   // High - Green
    DateTime(2025, 1, 25): 12,   // Low - Red
    DateTime(2025, 1, 30): 38,   // Medium - Yellow

    // February 2025
    DateTime(2025, 2, 3): 42,    // High - Green
    DateTime(2025, 2, 8): 15,    // Low - Red
    DateTime(2025, 2, 14): 58,   // High - Green (Valentine's Day)
    DateTime(2025, 2, 20): 25,   // Medium - Yellow
    DateTime(2025, 2, 25): 35,   // Medium - Yellow
    DateTime(2025, 2, 28): 48,   // High - Green

    // March 2025
    DateTime(2025, 3, 5): 22,    // Medium - Yellow
    DateTime(2025, 3, 10): 55,   // High - Green
    DateTime(2025, 3, 15): 18,   // Medium - Yellow
    DateTime(2025, 3, 20): 42,   // High - Green
    DateTime(2025, 3, 25): 30,   // Medium - Yellow
    DateTime(2025, 3, 30): 38,   // Medium - Yellow

    // November 2024 (Previous month)
    DateTime(2024, 11, 5): 32,   // Medium - Yellow
    DateTime(2024, 11, 10): 48,  // High - Green
    DateTime(2024, 11, 15): 15,  // Low - Red
    DateTime(2024, 11, 20): 42,  // High - Green
    DateTime(2024, 11, 25): 28,  // Medium - Yellow
    DateTime(2024, 11, 30): 35,  // Medium - Yellow
  };

  // Sample orders data for demo
  final Map<DateTime, List<Map<String, String>>> _ordersData = {
    DateTime(2024, 12, 1): [
      {'id': 'ORD1001', 'item': 'Tomato', 'qty': '5kg'},
      {'id': 'ORD1002', 'item': 'Potato', 'qty': '10kg'},
      {'id': 'ORD1003', 'item': 'Onion', 'qty': '3kg'},
    ],
    DateTime(2024, 12, 3): [
      {'id': 'ORD1004', 'item': 'Carrot', 'qty': '2kg'},
      {'id': 'ORD1005', 'item': 'Beans', 'qty': '1kg'},
    ],
    DateTime(2024, 12, 10): [
      {'id': 'ORD1006', 'item': 'Cabbage', 'qty': '4kg'},
      {'id': 'ORD1007', 'item': 'Chili', 'qty': '0.5kg'},
      {'id': 'ORD1008', 'item': 'Pumpkin', 'qty': '2kg'},
    ],
    DateTime(2024, 12, 25): [
      {'id': 'ORD1009', 'item': 'Apple', 'qty': '6kg'},
      {'id': 'ORD1010', 'item': 'Banana', 'qty': '12kg'},
    ],
  };

  // API call placeholder (commented out)
  /*
  Future<void> _fetchOrderData() async {
    try {
      // final response = await http.get(Uri.parse('your-api-endpoint/reports'));
      // final data = json.decode(response.body);
      // Process the data and update _orderData
    } catch (e) {
      print('Error fetching order data: $e');
    }
  }
  */

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

  List<Map<String, String>> _getRecentOrders([int count = 10]) {
    final List<Map<String, String>> allOrders = [];
    _ordersData.forEach((date, orders) {
      for (final order in orders) {
        allOrders.add({
          'id': order['id']!,
          'item': order['item']!,
          'qty': order['qty']!,
          'date': '${date.day}/${date.month}/${date.year}',
          'dateSort': date.toIso8601String(),
        });
      }
    });
    allOrders.sort((a, b) => b['dateSort']!.compareTo(a['dateSort']!));
    return allOrders.take(count).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
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
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF4CAF50),
                            child: Text(order['item']![0], style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text('${order['item']} (${order['qty']})'),
                          subtitle: Text('Order ID: ${order['id']}'),
                          trailing: Text(order['date']!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
    final orders = _selectedDay != null
        ? _ordersData[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]
        : null;

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
        if (orders != null && orders.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Details:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 10),
                ...orders.map((order) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Text(
                        order['id']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        order['item']!,
                        style: const TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order['qty']!,
                        style: const TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          )
      ],
    );
  }
}

extension on Color {
  darken(double d) {}
}