import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsSection extends StatefulWidget {
  const SettingsSection({super.key});

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  bool _notificationsEnabled = true;
  bool _saveAnalysisHistory = true;
  bool _autoSaveResults = true;
  String _selectedTheme = 'System';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _saveAnalysisHistory = prefs.getBool('save_analysis_history') ?? true;
      _autoSaveResults = prefs.getBool('auto_save_results') ?? true;
      _selectedTheme = prefs.getString('selected_theme') ?? 'System';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App Settings
          _buildSettingsCard(
            'App Settings',
            Icons.settings_outlined,
            [
              _buildSwitchTile(
                'Enable Notifications',
                'Receive alerts and updates',
                Icons.notifications_outlined,
                _notificationsEnabled,
                (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _saveSetting('notifications_enabled', value);
                },
              ),
              _buildSwitchTile(
                'Save Analysis History',
                'Store analysis results in your account',
                Icons.history_outlined,
                _saveAnalysisHistory,
                (value) {
                  setState(() {
                    _saveAnalysisHistory = value;
                  });
                  _saveSetting('save_analysis_history', value);
                },
              ),
              _buildSwitchTile(
                'Auto-save Results',
                'Automatically save analysis results',
                Icons.save_outlined,
                _autoSaveResults,
                (value) {
                  setState(() {
                    _autoSaveResults = value;
                  });
                  _saveSetting('auto_save_results', value);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Privacy & Security
          _buildSettingsCard(
            'Privacy & Security',
            Icons.security_outlined,
            [
              _buildListTile(
                'Data Privacy',
                'Manage your data and privacy settings',
                Icons.privacy_tip_outlined,
                () {
                  _showPrivacyDialog();
                },
              ),
              _buildListTile(
                'Export Data',
                'Download your analysis history',
                Icons.download_outlined,
                () {
                  _showExportDialog();
                },
              ),
              _buildListTile(
                'Delete Account',
                'Permanently delete your account and data',
                Icons.delete_forever_outlined,
                () {
                  _showDeleteAccountDialog();
                },
                isDestructive: true,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // About
          _buildSettingsCard(
            'About',
            Icons.info_outlined,
            [
              _buildListTile(
                'App Version',
                '1.0.0',
                Icons.info_outlined,
                null,
              ),
              _buildListTile(
                'Terms of Service',
                'Read our terms and conditions',
                Icons.description_outlined,
                () {
                  _showTermsDialog();
                },
              ),
              _buildListTile(
                'Privacy Policy',
                'Read our privacy policy',
                Icons.policy_outlined,
                () {
                  _showPrivacyPolicyDialog();
                },
              ),
              _buildListTile(
                'Contact Support',
                'Get help and support',
                Icons.support_agent_outlined,
                () {
                  _showSupportDialog();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Privacy'),
        content: const Text(
          'Your medical data is encrypted and stored securely. We never share your personal information with third parties without your explicit consent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'This feature will be available in a future update. You will be able to export your analysis history as a PDF or CSV file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion will be available in a future update'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using AnesthesiaSafe, you agree to use this application for medical assessment purposes only. This tool is designed to assist medical professionals and should not replace clinical judgment or proper medical examination.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'We are committed to protecting your privacy. All medical data is encrypted and stored securely. We collect only the minimum data necessary to provide our services and never share personal information without consent.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'For technical support or questions about AnesthesiaSafe, please contact our support team at support@anesthesiasafe.com',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}