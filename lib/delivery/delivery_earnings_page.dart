import 'package:flutter/material.dart';

class DeliveryEarningsPage extends StatelessWidget {
  final List<Map<String, dynamic>> completedDeliveries;
  final String earningsPeriod;
  final Function(String) onPeriodChanged;
  final Function() onRefresh;

  const DeliveryEarningsPage({
    Key? key,
    required this.completedDeliveries,
    required this.earningsPeriod,
    required this.onPeriodChanged,
    required this.onRefresh,
  }) : super(key: key);

  void _showSnackBar(BuildContext context, String message, {bool isError = false, bool isWarning = false, bool isInfo = false}) {
    Color backgroundColor;
    IconData icon;
    
    if (isError) {
      backgroundColor = Color(0xFFD32F2F);
      icon = Icons.error_outline;
    } else if (isWarning) {
      backgroundColor = Color(0xFFFF9800);
      icon = Icons.warning_amber;
    } else if (isInfo) {
      backgroundColor = Color(0xFF2196F3);
      icon = Icons.info_outline;
    } else {
      backgroundColor = Color(0xFF4CAF50);
      icon = Icons.check_circle;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        elevation: 6,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalEarnings = completedDeliveries.fold(0.0, (sum, d) => sum + (d['totalAmount'] as double));
    final weeklyEarnings = totalEarnings * 0.7;
    final monthlyEarnings = totalEarnings * 4;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Earnings', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              onRefresh();
              _showSnackBar(context, 'Refreshing earnings...', isInfo: true);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Earnings', style: TextStyle(fontSize: 16, color: Colors.white70)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButton<String>(
                          value: earningsPeriod,
                          dropdownColor: Color(0xFF4CAF50),
                          underline: SizedBox(),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          items: [
                            DropdownMenuItem(value: 'week', child: Text('This Week')),
                            DropdownMenuItem(value: 'month', child: Text('This Month')),
                          ],
                          onChanged: (value) => onPeriodChanged(value!),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '₹${earningsPeriod == 'week' ? weeklyEarnings.toStringAsFixed(2) : monthlyEarnings.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text('Earnings Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF388E3C))),
            SizedBox(height: 12),
            _buildEarningsGraph(),
            SizedBox(height: 20),
            Text('Per Delivery Earnings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF388E3C))),
            SizedBox(height: 12),
            _buildDeliveryEarningsList(context),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _showWithdrawDialog(context, weeklyEarnings),
                icon: Icon(Icons.account_balance_wallet, size: 20),
                label: Text('Withdraw / Request Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
              ),
            ),
            SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => _showPaymentHistoryDialog(context),
                child: Text('Payment History', style: TextStyle(fontSize: 16, color: Color(0xFF4CAF50), decoration: TextDecoration.underline)),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsGraph() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final earnings = List.generate(7, (index) {
      final targetDay = now.subtract(Duration(days: 6 - index));
      return completedDeliveries
          .where((d) {
            final deliveryDate = DateTime.parse(d['deliveryDate'] ?? d['createdAt'] ?? now.toString());
            return deliveryDate.year == targetDay.year &&
                   deliveryDate.month == targetDay.month &&
                   deliveryDate.day == targetDay.day;
          })
          .fold(0.0, (sum, d) => sum + (d['totalAmount'] as double));
    });
    final maxEarning = earnings.isEmpty || earnings.every((e) => e == 0) ? 1.0 : earnings.reduce((a, b) => a > b ? a : b);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Earnings', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('₹${earnings.reduce((a, b) => a + b).toStringAsFixed(0)}', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final height = (earnings[index] / maxEarning) * 120;
              return Column(
                children: [
                  Text('₹${earnings[index].toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(days[index], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryEarningsList(BuildContext context) {
    if (completedDeliveries.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('No completed deliveries yet', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final deliveries = completedDeliveries.map((d) => {
      'date': (d['deliveryDate'] ?? d['createdAt'] ?? DateTime.now().toString()).toString().split(' ')[0],
      'orderId': d['orderId'].toString(),
      'amount': d['totalAmount'] as double,
      'status': 'Paid',
    }).toList();

    return Container(
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
        children: deliveries.map((delivery) {
          return Column(
            children: [
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: delivery['status'] == 'Paid' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    delivery['status'] == 'Paid' ? Icons.check_circle : Icons.pending,
                    color: delivery['status'] == 'Paid' ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ),
                title: Text('Order #${delivery['orderId']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(delivery['date'] as String, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${(delivery['amount'] as double).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4CAF50))),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: delivery['status'] == 'Paid' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(delivery['status'] as String, style: TextStyle(fontSize: 10, color: delivery['status'] == 'Paid' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              if (delivery != deliveries.last) Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, double availableBalance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Withdraw Earnings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available Balance: ₹${availableBalance.toStringAsFixed(2)}'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar(context, 'Withdrawal request submitted!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Request'),
          ),
        ],
      ),
    );
  }

  void _showPaymentHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Payment History'),
        content: Container(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildPaymentHistoryItem('2024-01-08', '₹2,450.00', 'Completed'),
              _buildPaymentHistoryItem('2024-01-01', '₹2,180.00', 'Completed'),
              _buildPaymentHistoryItem('2023-12-25', '₹2,650.00', 'Completed'),
              _buildPaymentHistoryItem('2023-12-18', '₹2,320.00', 'Completed'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Color(0xFF4CAF50))),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryItem(String date, String amount, String status) {
    return ListTile(
      leading: Icon(Icons.payment, color: Colors.green),
      title: Text(amount, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(date),
      trailing: Text(status, style: TextStyle(color: Colors.green, fontSize: 12)),
    );
  }
}
