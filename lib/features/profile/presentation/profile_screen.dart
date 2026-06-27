import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/auth_service.dart';
import 'package:mse_market_connect/core/services/broker_user_service.dart';
import 'package:mse_market_connect/core/services/profile_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:mse_market_connect/features/admin/presentation/broker_approvals_screen.dart';
import 'package:mse_market_connect/features/admin/presentation/manage_ads_screen.dart';
import 'package:mse_market_connect/features/admin/presentation/admin_sync_prices_screen.dart';
import 'package:mse_market_connect/features/brokers/presentation/broker_dashboard_screen.dart';
import 'package:mse_market_connect/features/market/presentation/my_alerts_screen.dart';
import 'package:mse_market_connect/features/notifications/presentation/notifications_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/settings_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/support_screen.dart';
import 'package:mse_market_connect/shared/models/profile_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final authService = AuthService();
  final profileService = ProfileService();
  final brokerUserService = BrokerUserService();

  late Future<_ProfileAndBroker> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProfileAndBroker> _load() async {
    final profile = await profileService.getCurrentProfile();
    Map<String, dynamic>? brokerRow;
    try {
      brokerRow = await brokerUserService.getMyBrokerUserRow();
    } catch (_) {
      brokerRow = null;
    }
    return _ProfileAndBroker(profile: profile, brokerRow: brokerRow);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<_ProfileAndBroker>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 40),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 30),
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.lossColor,
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  Text('Failed to load profile:\n${snapshot.error}'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _reload,
                      child: const Text('Try again'),
                    ),
                  ),
                ],
              );
            }

            final data = snapshot.data!;
            final profile = data.profile;
            final brokerRow = data.brokerRow;

            final email =
                profile?.email ?? authService.currentUser?.email ?? 'User';
            final fullName = profile?.fullName ?? 'No name added';
            final role = profile?.role ?? 'investor';
            final kycStatus = profile?.kycStatus ?? 'pending';

            final isAdmin = role == 'admin';
            final isApprovedBroker = brokerRow?['is_approved'] == true;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: AppTheme.primaryColor,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _InfoChip(label: 'Role', value: role),
                          _InfoChip(label: 'KYC', value: kycStatus),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        // ===== ADMIN TOOLS (admin only) =====
                        if (isAdmin) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 4,
                              bottom: 8,
                              top: 4,
                            ),
                            child: Text(
                              'Admin Tools',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.campaign_outlined),
                              title: const Text('Manage Adverts'),
                              subtitle: const Text('Add, edit, remove banners'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ManageAdsScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.verified_user_outlined),
                              title: const Text('Approve Brokers'),
                              subtitle: const Text(
                                'Approve broker registrations',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const BrokerApprovalsScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.admin_panel_settings_outlined,
                              ),
                              title: const Text('Admin Dashboard'),
                              subtitle: const Text(
                                'Subscriptions, premium, approvals',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AdminDashboardScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.sync),
                              title: const Text('Sync MSE Data'),
                              subtitle: const Text(
                                'Prices and News from MSE/GDELT',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AdminSyncPricesScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 24),
                        ],

                        // ===== SETTINGS =====
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.settings_outlined),
                            title: const Text('Settings'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ===== NOTIFICATIONS =====
                        Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.notifications_none_outlined,
                            ),
                            title: const Text('Notifications'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ===== WATCHLIST =====
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.track_changes_outlined),
                            title: const Text('Watch'),
                            subtitle: const Text('Price targets & alerts'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MyAlertsScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ===== SUPPORT =====
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.support_agent_outlined),
                            title: const Text('Help & Support'),
                            subtitle: const Text('FAQs and contact support'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SupportScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ===== BROKER DASHBOARD (admin OR approved broker) =====
                        if (isAdmin || isApprovedBroker) ...[
                          Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.business_center_outlined,
                              ),
                              title: const Text('Broker Dashboard'),
                              subtitle: Text(
                                isAdmin
                                    ? 'Admin view of broker inbox'
                                    : 'Manage incoming client requests',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const BrokerDashboardScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await authService.signOut();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Signed out successfully'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileAndBroker {
  final ProfileModel? profile;
  final Map<String, dynamic>? brokerRow;
  const _ProfileAndBroker({required this.profile, required this.brokerRow});
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
