import 'package:flutter/material.dart';
import '../auth/Signin.dart';

class DeliveryProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? deliveryStats;
  final List<Map<String, dynamic>> completedDeliveries;
  final bool notificationsEnabled;
  final String selectedLanguage;
  final String selectedTheme;
  final Function(bool) onNotificationsChanged;
  final Function(String) onLanguageChanged;
  final Function(String) onThemeChanged;
  final Function() onLogout;

  const DeliveryProfilePage({
    Key? key,
    required this.user,
    this.deliveryStats,
    required this.completedDeliveries,
    required this.notificationsEnabled,
    required this.selectedLanguage,
    required this.selectedTheme,
    required this.onNotificationsChanged,
    required this.onLanguageChanged,
    required this.onThemeChanged,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<DeliveryProfilePage> createState() => _DeliveryProfilePageState();
}

class _DeliveryProfilePageState extends State<DeliveryProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.delivery_dining, size: 60, color: Color(0xFF4CAF50)),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Edit profile picture coming soon!')),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.camera_alt, size: 16, color: Color(0xFF4CAF50)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.user['name'] ?? 'Delivery Partner',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text('Delivery Partner', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
                  SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Edit profile coming soon!')),
                      );
                    },
                    icon: Icon(Icons.edit, color: Colors.white, size: 16),
                    label: Text('Edit Profile', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            _buildProfileSection(
              'Personal Information',
              Icons.person,
              [
                _buildProfileItem('Name', widget.user['name'] ?? 'N/A'),
                _buildProfileItem('Mobile Number', widget.user['mobile_number'] ?? 'N/A'),
                _buildProfileItem('Delivery Person ID', widget.user['delivery_person_id']?.toString() ?? widget.user['id']?.toString() ?? 'N/A'),
                _buildProfileItem('Vehicle Type', widget.user['vehicle_type']?.toString().toUpperCase() ?? 'N/A'),
                _buildProfileItem('Vehicle Number', widget.user['vehicle_number'] ?? 'N/A'),
                _buildProfileItem('License Number', widget.user['license_number'] ?? 'N/A'),
              ],
            ),
            SizedBox(height: 16),
            _buildProfileSection(
              'Earnings & Payments',
              Icons.account_balance_wallet,
              [
                _buildProfileItem('Weekly Earnings', '₹${(widget.deliveryStats?['totalEarnings'] ?? 0).toStringAsFixed(0)}'),
                _buildProfileItem('Monthly Earnings', '₹${((widget.deliveryStats?['totalEarnings'] ?? 0) * 4).toStringAsFixed(0)}'),
                _buildProfileItem('Payment Status', 'Up to date', valueColor: Colors.green),
              ],
            ),
            SizedBox(height: 16),
            _buildProfileSection(
              'Performance Stats',
              Icons.bar_chart,
              [
                _buildProfileItem('Total Deliveries', widget.user['total_deliveries']?.toString() ?? '${widget.completedDeliveries.length}'),
                _buildProfileItem('Average Rating', '${widget.user['rating'] ?? widget.deliveryStats?['rating'] ?? 0.0} ⭐'),
                _buildProfileItem('Availability', widget.user['is_available'] == true ? 'Available' : 'Unavailable', valueColor: widget.user['is_available'] == true ? Colors.green : Colors.red),
                _buildProfileItem('Current Location', widget.user['current_location'] ?? 'Not set'),
              ],
            ),
            SizedBox(height: 16),
            _buildProfileMenuCard(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(String title, IconData icon, List<Widget> children) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF388E3C))),
            ],
          ),
          Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor ?? Color(0xFF388E3C))),
        ],
      ),
    );
  }

  Widget _buildProfileMenuCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFF0F8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(Icons.account_balance_wallet, 'Wallet / Earnings', () {}),
          _buildDivider(),
          _buildMenuItem(Icons.star_rate, 'My Ratings / Reviews', () {}),
          _buildDivider(),
          _buildMenuItem(Icons.notifications_outlined, 'Notifications', () {}),
          _buildDivider(),
          _buildMenuItem(Icons.settings_outlined, 'Settings', _showSettingsDialog),
          _buildDivider(),
          _buildMenuItem(Icons.info_outline, 'App Info / Privacy Policy', () {}),
          _buildDivider(),
          _buildMenuItem(Icons.help_outline, 'Help & Support / Contact Us', _showHelpSupportOptions),
          _buildDivider(),
          _buildMenuItem(Icons.share_outlined, 'Share App', () {}),
          _buildDivider(),
          _buildLogoutItem(),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: Color(0xFF2E7D32).withOpacity(0.1),
    );
  }

  Widget _buildLogoutItem() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _confirmLogout,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[50]!, Colors.red[100]!.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[700]!, Colors.red[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.logout, color: Colors.white, size: 20),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red[700]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF2E7D32)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.settings, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text('Settings', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold)),
            ],
          ),
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFF0F8F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text('Push Notifications', style: TextStyle(color: Color(0xFF2D3748))),
                  subtitle: Text('Receive order updates', style: TextStyle(color: Colors.grey[600])),
                  value: widget.notificationsEnabled,
                  onChanged: (value) {
                    setDialogState(() {});
                    widget.onNotificationsChanged(value);
                  },
                  activeColor: Color(0xFF2E7D32),
                  activeTrackColor: Color(0xFF2E7D32).withOpacity(0.5),
                ),
                Divider(color: Color(0xFF2E7D32).withOpacity(0.1)),
                ListTile(
                  leading: Icon(Icons.language, color: Color(0xFF2E7D32)),
                  title: Text('Language', style: TextStyle(color: Color(0xFF2D3748))),
                  subtitle: Text(widget.selectedLanguage, style: TextStyle(color: Colors.grey[600])),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF2E7D32)),
                  onTap: () {
                    Navigator.pop(context);
                    _showLanguageDialog();
                  },
                ),
                Divider(color: Color(0xFF2E7D32).withOpacity(0.1)),
                ListTile(
                  leading: Icon(Icons.palette, color: Color(0xFF2E7D32)),
                  title: Text('Theme', style: TextStyle(color: Color(0xFF2D3748))),
                  subtitle: Text(widget.selectedTheme, style: TextStyle(color: Colors.grey[600])),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF2E7D32)),
                  onTap: () {
                    Navigator.pop(context);
                    _showThemeDialog();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.language, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text('Select Language', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF0F8F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text('English', style: TextStyle(color: Color(0xFF2D3748))),
                value: 'English',
                groupValue: widget.selectedLanguage,
                activeColor: Color(0xFF2E7D32),
                onChanged: (value) {
                  widget.onLanguageChanged(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: Text('தமிழ் (Tamil)', style: TextStyle(color: Color(0xFF2D3748))),
                value: 'Tamil',
                groupValue: widget.selectedLanguage,
                activeColor: Color(0xFF2E7D32),
                onChanged: (value) {
                  widget.onLanguageChanged(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: Text('हिन्दी (Hindi)', style: TextStyle(color: Color(0xFF2D3748))),
                value: 'Hindi',
                groupValue: widget.selectedLanguage,
                activeColor: Color(0xFF2E7D32),
                onChanged: (value) {
                  widget.onLanguageChanged(value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.palette, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text('Select Theme', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF0F8F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text('Light Mode', style: TextStyle(color: Color(0xFF2D3748))),
                subtitle: Text('Bright and clear', style: TextStyle(color: Colors.grey[600])),
                value: 'Light Mode',
                groupValue: widget.selectedTheme,
                activeColor: Color(0xFF2E7D32),
                onChanged: (value) {
                  widget.onThemeChanged(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: Text('Dark Mode', style: TextStyle(color: Color(0xFF2D3748))),
                subtitle: Text('Easy on the eyes', style: TextStyle(color: Colors.grey[600])),
                value: 'Dark Mode',
                groupValue: widget.selectedTheme,
                activeColor: Color(0xFF2E7D32),
                onChanged: (value) {
                  widget.onThemeChanged(value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpSupportOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF0F8F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text('Help & Support', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
              ],
            ),
            SizedBox(height: 20),
            _buildHelpOption(Icons.question_answer, 'FAQ', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('FAQ coming soon!'), backgroundColor: Color(0xFF2E7D32)),
              );
            }),
            _buildHelpOption(Icons.feedback, 'Feedback', () {
              Navigator.pop(context);
            }),
            _buildHelpOption(Icons.contact_mail, 'Contact Us', () {
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpOption(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF2E7D32)),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFF0F8F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red[700]!, Colors.red[500]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.exit_to_app, color: Colors.white, size: 32),
                ),
                SizedBox(height: 20),
                Text('Ready to Leave?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                SizedBox(height: 12),
                Text('Are you sure you want to logout?', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4)),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: Text('Stay Here', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onLogout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
