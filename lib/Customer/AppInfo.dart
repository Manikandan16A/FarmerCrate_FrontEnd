import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({Key? key}) : super(key: key);

  static const String _appName = 'FarmerCrate';
  static const String _version = '1.0.0';
  static const String _supportEmail = 'support@farmercrate.example';

  void _showPrivacyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Privacy & Data',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'This app collects minimal personal data required to provide the service. '
                'Any images or contact details you provide are used only to support ordering and profile features. '
                'We do not sell your personal information. For full details please refer to the formal policy (placeholder).',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _copySupportEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support email copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Info'),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.shopping_basket_outlined, color: Colors.white, size: 36),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(_appName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Delivering farm-fresh produce', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                  Text('v$_version', style: const TextStyle(color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 24),

              const Text('What\'s new', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('- Initial release with product browsing, cart, and profile features.'),
                      SizedBox(height: 6),
                      Text('- Improved image upload and profile management.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text('Legal & Support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF4CAF50)),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPrivacyDialog(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_outlined, color: Color(0xFF4CAF50)),
                title: const Text('Contact Support'),
                subtitle: const Text(_supportEmail),
                trailing: IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: () => _copySupportEmail(context),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: _appName,
                  applicationVersion: _version,
                ),
                icon: const Icon(Icons.article_outlined),
                label: const Text('Open Licenses'),
              ),

              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text('Built with ❤️ • © ${DateTime.now().year} $_appName', style: TextStyle(color: Colors.grey[600])),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
