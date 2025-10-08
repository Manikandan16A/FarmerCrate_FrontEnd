import 'package:flutter/material.dart';
import 'navigation_utils.dart';
import 'payment.dart';


class OrderConfirmPage extends StatefulWidget {
  final List cartItems;
  final String userAddress;
  final String userPhone;
  final String? token;

  const OrderConfirmPage({Key? key, required this.cartItems, required this.userAddress, required this.userPhone, this.token}) : super(key: key);

  @override
  State<OrderConfirmPage> createState() => _OrderConfirmPageState();
}

class _OrderConfirmPageState extends State<OrderConfirmPage> {
  late TextEditingController _addressController;
  late String _selectedAddress;
  bool _addingNewAddress = false;

  late TextEditingController _phoneController;
  late String _selectedPhone;
  bool _editingPhone = false;


  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.userAddress;
    _addressController = TextEditingController(text: widget.userAddress);
    _selectedPhone = widget.userPhone;
    _phoneController = TextEditingController(text: widget.userPhone);
  }


  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  double get subtotal => widget.cartItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  double get gst => subtotal * 0.05;
  double get total => subtotal + gst;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        title: const Text('Order Confirmation', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Default address and phone (non-editable)
            Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Default Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[800])),
                    Text(_selectedAddress.isNotEmpty ? _selectedAddress : 'No address found', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[800])),
                    Text(_selectedPhone.isNotEmpty ? _selectedPhone : 'No phone number found', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Button to add new address and phone
            if (!_addingNewAddress) ...[
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _addingNewAddress = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('New Address'),
                ),
              ),
            ] else ...[
              Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Enter new address',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Enter phone number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedAddress = _addressController.text;
                                _selectedPhone = _phoneController.text;
                                _addingNewAddress = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Save'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _addingNewAddress = false;
                                _addressController.text = widget.userAddress;
                                _phoneController.text = widget.userPhone;
                                _selectedAddress = widget.userAddress;
                                _selectedPhone = widget.userPhone;
                              });
                            },
                            child: Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green[800])),
            Expanded(
              child: ListView.builder(
                itemCount: widget.cartItems.length,
                itemBuilder: (context, index) {
                  final item = widget.cartItems[index];
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: item['images'] != null && item['images'].toString().isNotEmpty
                          ? Image.network(item['images'].toString().split(',')[0], width: 50, height: 50, fit: BoxFit.cover)
                          : Icon(Icons.image, size: 40, color: Colors.green[200]),
                      title: Text(item['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Qty: ${item['quantity']}  |  ₹${item['price']}'),
                      trailing: Text('₹${(item['price'] * item['quantity']).toStringAsFixed(2)}', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text('GST Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green[800])),
            Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _invoiceRow('Subtotal', subtotal),
                    _invoiceRow('GST (5%)', gst),
                    Divider(),
                    _invoiceRow('Total', total, isTotal: true),
                  ],
                ),
              ),
            ),
            // Payment options removed as requested
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: () {
                  // Navigate to payment page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FarmerCratePaymentPage(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Proceed to Payment - ₹${total.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: CustomerNavigationUtils.buildCustomerDrawer(
        parentContext: context,
        token: widget.token,
      ),
      bottomNavigationBar: CustomerNavigationUtils.buildCustomerBottomNav(
        currentIndex: 2, // Cart tab is most relevant for order confirmation
        onTap: (index) => CustomerNavigationUtils.handleNavigation(index, context, widget.token),
      ),
    );
  }

  Widget _invoiceRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14)),
          Text('₹${value.toStringAsFixed(2)}', style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14, color: isTotal ? Colors.green[700] : Colors.black)),
        ],
      ),
    );
  }
}

