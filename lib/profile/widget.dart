import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfarmer/auth/authscreen.dart';
import 'package:smartfarmer/profile/change_pass.dart';
import 'package:smartfarmer/profile/edit_profile.dart';
import 'package:smartfarmer/profile/models/edit_profile.dart';
import 'package:smartfarmer/provider/lang_provider.dart';

class ProfileWidget {
  static StateSetter? _setState;

  static Widget buildProfileTabContent(BuildContext context, ThemeData theme) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: true);
    return StatefulBuilder(
      builder: (context, setState) {
        _setState = setState;
        return FutureBuilder<Map<String, String>>(
          future: _loadUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  langProvider.getText('error') + ': ${snapshot.error}',
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                children: [
                  _buildInfoCard(
                    context,
                    theme,
                    title: langProvider.getText('personal_information'),
                    onEdit:
                        () => _navigateToEditScreen(context, snapshot.data!),
                    children: [
                      _buildInfoRow(
                        langProvider.getText('full_name'),
                        snapshot.data?['fullName'] ??
                            langProvider.getText('not_set'),
                        theme,
                      ),
                      _buildInfoRow(
                        langProvider.getText('email'),
                        snapshot.data?['email'] ??
                            langProvider.getText('not_set'),
                        theme,
                      ),
                      _buildInfoRow(
                        langProvider.getText('location'),
                        snapshot.data?['country'] ??
                            langProvider.getText('not_set'),
                        theme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildInfoCard(
    BuildContext context,
    ThemeData theme, {
    required String title,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: true);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        langProvider.getText('edit'),
                        style: TextStyle(
                          color: theme.hintColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.edit_outlined,
                        color: theme.hintColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  static Widget _buildInfoRow(
    String label,
    String value,
    ThemeData theme, {
    bool hasDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyLarge),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (hasDivider) const Divider(),
      ],
    );
  }

  static Future<Map<String, String>> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString('userId') ?? '',
      'fullName': prefs.getString('fullName') ?? 'Not set',
      'email': prefs.getString('email') ?? 'Not set',
      'country': prefs.getString('country') ?? 'Not set',
    };
  }

  static Future<void> _navigateToEditScreen(
    BuildContext context,
    Map<String, String> userData,
  ) async {
     print('Navigating to EditProfileScreen with the following data:');
    userData.forEach((key, value) {
      print('$key: $value');
    });
    
    final updatedProfile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditProfileScreen(
              currentUserProfile: UserProfile(
                id: userData['userId'] ?? '',
                name: userData['fullName'] ?? 'Not set',
                email: userData['email'] ?? 'Not set',
                location: userData['country'] ?? 'Not set',
              ),
            ),
      ),
    );

    if (updatedProfile != null && _setState != null) {
      _setState!(() {});
    }
  }

  static Widget buildSettingsTabContent(BuildContext context, ThemeData theme) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: true);
    final Color iconColor = theme.primaryColor.withOpacity(0.8);
    final Color chevronColor = Colors.grey[400]!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            langProvider.getText('account_settings'),
            style: theme.textTheme.headlineSmall?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            context: context,
            icon: Icons.lock_outline,
            iconColor: iconColor,
            title: langProvider.getText('change_password'),
            subtitle: langProvider.getText('update_password'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
            chevronColor: chevronColor,
            theme: theme,
          ),
          _buildSettingsItem(
            context: context,
            icon: Icons.language,
            iconColor: iconColor,
            title: langProvider.getText('change_language'),
            subtitle: langProvider.getText('update_language'),
            onTap: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 20),
                        Text(langProvider.getText('changing_language')),
                      ],
                    ),
                  );
                },
              );

              await Future.delayed(const Duration(seconds: 2));

              langProvider.changeLanguage(
                langProvider.currentLanguage == 'en' ? 'hi' : 'en',
              );

              Navigator.of(context, rootNavigator: true).pop();

              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(langProvider.getText('language_changed')),
                    content: Text(
                      langProvider.getText('language_changed_message'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(langProvider.getText('ok')),
                      ),
                    ],
                  );
                },
              );
            },
            chevronColor: chevronColor,
            theme: theme,
          ),
          const SizedBox(height: 30),
         
          ElevatedButton.icon(
            icon: const Icon(Icons.logout, size: 20, color: Colors.white),
            label: Text(langProvider.getText('logout')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () => _showLogoutDialog(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static void _showLogoutDialog(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(langProvider.getText('logout')),
          content: Text(langProvider.getText('are_you_sure_logout')),
          actions: [
            TextButton(
              child: Text(langProvider.getText('cancel')),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text(
                langProvider.getText('logout'),
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout(context);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> _performLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/authscreen', (route) => false);
 
  }

  static Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color chevronColor,
    required ThemeData theme,
    bool isLastItemInSection = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        margin: EdgeInsets.only(bottom: isLastItemInSection ? 0 : 10),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: Colors.grey[200]!, width: 0.8),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16, color: chevronColor),
          ],
        ),
      ),
    );
  }
}
