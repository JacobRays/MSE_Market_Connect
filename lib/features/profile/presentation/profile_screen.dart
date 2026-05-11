import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/auth_service.dart';
import 'package:mse_market_connect/core/services/profile_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:mse_market_connect/features/market/presentation/my_alerts_screen.dart';
import 'package:mse_market_connect/features/notifications/presentation/notifications_screen.dart';
import 'package:mse_market_connect/shared/models/profile_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final authService = AuthService();
  final profileService = ProfileService();

  late Future<ProfileModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = profileService.getCurrentProfile();
  }

  Future<void> _reload() async {
    setState(() {
      _future = profileService.getCurrentProfile();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<ProfileModel?>(
          future: _future,
          builder: (context, snapshot) {
            // Loading
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

            // Error (don’t default to investor silently)
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 30),
                  const Icon(Icons.error_outline, color: AppTheme.lossColor, size: 64),
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

            final profile = snapshot.data;
            final email = profile?.email ?? authService.currentUser?.email ?? 'User';
            final fullName = profile?.fullName ?? 'No name added';
            final role = profile?.role ?? 'investor';
            final kycStatus = profile?.kycStatus ?? 'pending';

            final isAdmin = role == 'admin';

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
                            child: Icon(Icons.person, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(fullName, style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 4),
                                Text(email, style: Theme.of(context).textTheme.bodyMedium),
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
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.notifications_none_outlined),
                            title: const Text('Notifications'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.track_changes_outlined),
                            title: const Text('Watch'),
                            subtitle: const Text('Price alerts and targets'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const MyAlertsScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (isAdmin) ...[
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.admin_panel_settings_outlined),
                              title: const Text('Admin Dashboard'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
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
                          const SnackBar(content: Text('Signed out successfully')),
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
