import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfarmer/auth/signin.dart';
import 'package:smartfarmer/profile/widget.dart';
import 'package:smartfarmer/provider/lang_provider.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langProvider = Provider.of<LanguageProvider>(context, listen: true);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, theme, langProvider),
          _buildTabBar(context, theme, langProvider),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ProfileWidget.buildProfileTabContent(context, theme),
                ProfileWidget.buildSettingsTabContent(
                  context,
                  Theme.of(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    LanguageProvider langProvider,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20.0,
        right: 20.0,
      ),
      color: theme.primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    langProvider.getText('profile'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    langProvider.getText('manage_account'),
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
     
              
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabBar(
    BuildContext context,
    ThemeData theme,
    LanguageProvider langProvider,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: theme.hintColor.withOpacity(0.1),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: theme.hintColor,
        unselectedLabelColor: theme.textTheme.bodyLarge?.color,
        labelStyle: theme.textTheme.labelLarge,
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.normal,
        ),
        tabs: [
          Tab(text: langProvider.getText('profile_tab')),
          Tab(text: langProvider.getText('settings_tab')),
        ],
        dividerColor: Colors.transparent,
      ),
    );
  }
}
