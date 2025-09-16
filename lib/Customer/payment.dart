import 'package:flutter/material.dart';

class FarmerCratePaymentPage extends StatefulWidget {
  @override
  _FarmerCratePaymentPageState createState() => _FarmerCratePaymentPageState();
}

class _FarmerCratePaymentPageState extends State<FarmerCratePaymentPage> {
  String selectedPaymentMethod = '';
  String selectedBank = '';
  bool showOffers = true;
  bool isNetBankingExpanded = false;
  bool showOrderDetails = false;

  // Form controllers
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _walletIdController = TextEditingController();

  // List of valid UPI handles
  final List<String> validUpiHandles = [
    'oksbi', 'okicici', 'okaxis', 'okhdfcbank', 'okhdfc', 'okicicibank',
    'okyesbank', 'okbob', 'okindusind', 'okpaytm', 'okphonepe', 'okgpay',
    'okfederal', 'oksib', 'okcanara', 'okunionbank', 'okuco'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F8F0),
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.agriculture, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Secure Payment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.security, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  '100% Safe',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Order Summary Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fresh Organic Vegetable Box',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showOrderDetails = !showOrderDetails;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        Row(
                          children: [
                            Text(
                              '₹850',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              showOrderDetails ? Icons.expand_less : Icons.expand_more,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (showOrderDetails) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildOrderDetailRow('Base Price', '₹750'),
                          _buildOrderDetailRow('Delivery Charges', '₹50'),
                          _buildOrderDetailRow('Taxes & Fees', '₹50'),
                          Divider(color: Colors.white70),
                          _buildOrderDetailRow('Total', '₹850', isTotal: true),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Special Offers Banner
                  if (showOffers)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFE8F5E8), Color(0xFFC8E6C9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF4CAF50), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.eco, color: Colors.white, size: 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🌱 Farm Fresh Discount!',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Get 10% cashback on organic orders',
                                  style: TextStyle(
                                    color: Color(0xFF388E3C),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() {
                                showOffers = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                  // UPI Payment
                  _buildPaymentOption(
                    icon: Icons.account_balance_wallet,
                    title: 'UPI Payment',
                    subtitle: 'Pay using any UPI app',
                    offers: 'Get up to 5% cashback',
                    onTap: () => _selectPaymentMethod('upi'),
                  ),

                  // UPI Form
                  if (selectedPaymentMethod == 'upi')
                    _buildUpiForm(),

                  // Credit/Debit Card
                  _buildPaymentOption(
                    icon: Icons.credit_card,
                    title: 'Credit / Debit / ATM Card',
                    subtitle: 'Secure card payment',
                    offers: 'Up to 3% cashback available',
                    onTap: () => _selectPaymentMethod('card'),
                  ),

                  // Card Form
                  if (selectedPaymentMethod == 'card')
                    _buildCardForm(),

                  // Net Banking
                  _buildNetBankingSection(),

                  // Digital Wallet
                  _buildPaymentOption(
                    icon: Icons.wallet,
                    title: 'Digital Wallets',
                    subtitle: 'Paytm, PhonePe, Google Pay & more',
                    onTap: () => _selectPaymentMethod('wallet'),
                  ),

                  // Wallet Form
                  if (selectedPaymentMethod == 'wallet')
                    _buildWalletForm(),

                  SizedBox(height: 20),

                  // Trust Indicators
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildTrustIndicator(
                              Icons.security,
                              'SSL Encrypted',
                              Color(0xFF4CAF50),
                            ),
                            _buildTrustIndicator(
                              Icons.verified,
                              'PCI Compliant',
                              Color(0xFF4CAF50),
                            ),
                            _buildTrustIndicator(
                              Icons.support_agent,
                              '24/7 Support',
                              Color(0xFF4CAF50),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '50,000+ Happy Farmers & Customers',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Payment Button
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: selectedPaymentMethod.isEmpty ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock),
                        SizedBox(width: 8),
                        Text(
                          selectedPaymentMethod.isEmpty
                              ? 'Select Payment Method'
                              : 'Pay ₹850 Securely',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardForm() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card Details',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _cardNumberController,
            decoration: InputDecoration(
              labelText: 'Card Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cardExpiryController,
                  decoration: InputDecoration(
                    labelText: 'MM/YY',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cardCvvController,
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _cardHolderController,
            decoration: InputDecoration(
              labelText: 'Cardholder Name',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiForm() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPI Details',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _upiIdController,
            decoration: InputDecoration(
              labelText: 'UPI ID (e.g., name@oksbi)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletForm() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wallet Details',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _walletIdController,
            decoration: InputDecoration(
              labelText: 'Wallet ID/Phone Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildNetBankingSection() {
    final List<Map<String, dynamic>> banks = [
      {'name': 'State Bank of India', 'icon': Icons.account_balance, 'color': Color(0xFF1976D2)},
      {'name': 'HDFC Bank', 'icon': Icons.account_balance, 'color': Color(0xFF0D47A1)},
      {'name': 'ICICI Bank', 'icon': Icons.account_balance, 'color': Color(0xFFFF5722)},
      {'name': 'Axis Bank', 'icon': Icons.account_balance, 'color': Color(0xFF9C27B0)},
      {'name': 'Punjab National Bank', 'icon': Icons.account_balance, 'color': Color(0xFF795548)},
      {'name': 'Bank of Baroda', 'icon': Icons.account_balance, 'color': Color(0xFF3F51B5)},
      {'name': 'Canara Bank', 'icon': Icons.account_balance, 'color': Color(0xFFE91E63)},
      {'name': 'Union Bank of India', 'icon': Icons.account_balance, 'color': Color(0xFF607D8B)},
      {'name': 'Bank of India', 'icon': Icons.account_balance, 'color': Color(0xFF2196F3)},
      {'name': 'Central Bank of India', 'icon': Icons.account_balance, 'color': Color(0xFF009688)},
      {'name': 'Indian Bank', 'icon': Icons.account_balance, 'color': Color(0xFF8BC34A)},
      {'name': 'Indian Overseas Bank', 'icon': Icons.account_balance, 'color': Color(0xFFCDDC39)},
      {'name': 'UCO Bank', 'icon': Icons.account_balance, 'color': Color(0xFFFF9800)},
      {'name': 'Bank of Maharashtra', 'icon': Icons.account_balance, 'color': Color(0xFF673AB7)},
      {'name': 'Yes Bank', 'icon': Icons.account_balance, 'color': Color(0xFF4CAF50)},
      {'name': 'Kotak Mahindra Bank', 'icon': Icons.account_balance, 'color': Color(0xFFE53935)},
      {'name': 'IndusInd Bank', 'icon': Icons.account_balance, 'color': Color(0xFF1565C0)},
      {'name': 'Federal Bank', 'icon': Icons.account_balance, 'color': Color(0xFF7B1FA2)},
      {'name': 'South Indian Bank', 'icon': Icons.account_balance, 'color': Color(0xFFD32F2F)},
      {'name': 'Karur Vysya Bank', 'icon': Icons.account_balance, 'color': Color(0xFF388E3C)},
    ];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedPaymentMethod.startsWith('netbanking') ? Color(0xFF4CAF50) : Colors.grey.shade200,
          width: selectedPaymentMethod.startsWith('netbanking') ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.account_balance,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
            ),
            title: Text(
              'Net Banking',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF333333),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  selectedBank.isEmpty
                      ? 'Choose your bank to pay securely'
                      : 'Selected: $selectedBank',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'All major Indian banks supported',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                isNetBankingExpanded ? Icons.expand_less : Icons.expand_more,
                color: Color(0xFF4CAF50),
              ),
              onPressed: () {
                setState(() {
                  isNetBankingExpanded = !isNetBankingExpanded;
                });
              },
            ),
            onTap: () {
              setState(() {
                isNetBankingExpanded = !isNetBankingExpanded;
              });
            },
          ),
          if (isNetBankingExpanded) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select your bank:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: banks.length,
                    itemBuilder: (context, index) {
                      final bank = banks[index];
                      final isSelected = selectedBank == bank['name'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedBank = bank['name'];
                            selectedPaymentMethod = 'netbanking_${bank['name']}';
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0xFF4CAF50).withOpacity(0.1) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Color(0xFF4CAF50) : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: bank['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  bank['icon'],
                                  size: 16,
                                  color: bank['color'],
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  bank['name'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? Color(0xFF4CAF50) : Color(0xFF333333),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    String? offers,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedPaymentMethod == title.toLowerCase().replaceAll(' ', '_') ? Color(0xFF4CAF50) : Colors.grey.shade200,
            width: selectedPaymentMethod == title.toLowerCase().replaceAll(' ', '_') ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Color(0xFF4CAF50),
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor ?? Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 14,
                ),
              ),
              if (offers != null) ...[
                SizedBox(height: 4),
                Text(
                  offers,
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustIndicator(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _selectPaymentMethod(String method) {
    setState(() {
      selectedPaymentMethod = method;
      if (!method.startsWith('netbanking')) {
        selectedBank = '';
        isNetBankingExpanded = false;
      }
    });
  }

  void _processPayment() {
    bool isValid = true;
    String errorMessage = '';

    // Validate based on payment method
    if (selectedPaymentMethod == 'card') {
      if (!RegExp(r'^\d{16}$').hasMatch(_cardNumberController.text)) {
        isValid = false;
        errorMessage = 'Please enter a valid 16-digit card number';
      } else if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(_cardExpiryController.text)) {
        isValid = false;
        errorMessage = 'Please enter a valid expiry date (MM/YY)';
      } else if (!RegExp(r'^\d{3}$').hasMatch(_cardCvvController.text)) {
        isValid = false;
        errorMessage = 'Please enter a valid 3-digit CVV';
      } else if (_cardHolderController.text.isEmpty) {
        isValid = false;
        errorMessage = 'Please enter cardholder name';
      }
    } else if (selectedPaymentMethod == 'upi') {
      final upiParts = _upiIdController.text.split('@');
      if (upiParts.length != 2 || upiParts[0].isEmpty || !validUpiHandles.contains(upiParts[1].toLowerCase())) {
        isValid = false;
        errorMessage = 'Please enter a valid UPI ID (e.g., name@oksbi). Valid handles: ${validUpiHandles.join(', ')}';
      }
    } else if (selectedPaymentMethod == 'wallet') {
      if (!RegExp(r'^\d{10}$').hasMatch(_walletIdController.text)) {
        isValid = false;
        errorMessage = 'Please enter a valid 10-digit phone number';
      }
    } else if (selectedPaymentMethod.startsWith('netbanking') && selectedBank.isEmpty) {
      isValid = false;
      errorMessage = 'Please select a bank';
    }

    if (!isValid) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Payment Failed'),
            ],
          ),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(color: Color(0xFF4CAF50)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Simulate payment success
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 50),
            SizedBox(height: 16),
            Text(
              'Payment Successful!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF4CAF50),
              ),
            ),
            SizedBox(height: 8),
            Text('Your payment of ₹850 was processed successfully.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardHolderController.dispose();
    _upiIdController.dispose();
    _walletIdController.dispose();
    super.dispose();
  }
}