import 'package:flutter/material.dart';

class DeliveryHistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> completedDeliveries;
  final String historyFilter;
  final Function(String) onFilterChanged;

  const DeliveryHistoryPage({
    Key? key,
    required this.completedDeliveries,
    required this.historyFilter,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filteredHistory = _getFilteredHistory();
    final totalEarnings = filteredHistory.fold(0.0, (sum, d) => sum + (d['totalAmount'] as double));
    final avgTime = filteredHistory.isEmpty ? 0 : 35;

    return Scaffold(
      appBar: AppBar(
        title: Text('History', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHistorySummaryCards(filteredHistory.length, totalEarnings, avgTime),
            SizedBox(height: 16),
            _buildHistoryFilters(),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Export feature coming soon!')),
                    );
                  },
                  icon: Icon(Icons.download, size: 16),
                  label: Text('Download Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (filteredHistory.isEmpty)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey[400]),
                      SizedBox(height: 8),
                      Text('No delivery history for selected period', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: filteredHistory.map((delivery) => _buildHistoryCard(delivery)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredHistory() {
    final now = DateTime.now();
    return completedDeliveries.where((delivery) {
      final deliveryDate = DateTime.tryParse(delivery['deliveredAt'] ?? '') ?? now;
      switch (historyFilter) {
        case 'today':
          return deliveryDate.day == now.day && deliveryDate.month == now.month && deliveryDate.year == now.year;
        case 'week':
          final weekAgo = now.subtract(Duration(days: 7));
          return deliveryDate.isAfter(weekAgo);
        case 'month':
          return deliveryDate.month == now.month && deliveryDate.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildHistorySummaryCards(int totalDeliveries, double totalEarnings, int avgTime) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Deliveries', '$totalDeliveries', Icons.check_circle, Colors.green)),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard('Total Earnings', '₹${totalEarnings.toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.blue)),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard('Avg Time', '$avgTime min', Icons.timer, Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildHistoryFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filter by:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildHistoryFilterChip('today', 'Today'),
              SizedBox(width: 8),
              _buildHistoryFilterChip('week', 'This Week'),
              SizedBox(width: 8),
              _buildHistoryFilterChip('month', 'This Month'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryFilterChip(String value, String label) {
    bool isSelected = historyFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) => onFilterChanged(value),
      backgroundColor: Colors.white,
      selectedColor: Color(0xFF4CAF50),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: Color(0xFF4CAF50), width: 1.5),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> delivery) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #${delivery['id']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF388E3C))),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('DELIVERED', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Divider(height: 20),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text('Customer: ${delivery['customerName']}', style: TextStyle(fontSize: 14)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text('Delivered: ${delivery['deliveredAt']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Earnings: ₹${delivery['totalAmount'].toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                ],
              ),
              IconButton(
                icon: Icon(Icons.share, size: 18, color: Colors.blue),
                onPressed: () {},
                tooltip: 'Share',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
