import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/profile_service.dart';
import 'package:mse_market_connect/core/services/subscription_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/shared/models/profile_model.dart';
import 'package:mse_market_connect/features/profile/presentation/edit_profile_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/change_password_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/kyc_status_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/settings_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/support_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/upgrade_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  ProfileModel? _profile;
  bool _isPremium = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await _profileService.getCurrentProfile();
    final sub = await _subscriptionService.getOrCreateMySubscription();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _isPremium = sub.isPremium;
      _loading = false;
    });
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This action is irreversible. All data will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.lossColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('profiles').delete().eq('id', user.id);
        await Supabase.instance.client.auth.admin.deleteUser(user.id);
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _ProfileHeader(profile: _profile),
                  const SizedBox(height: 20),
                  _StatsRow(isPremium: _isPremium),
                  const SizedBox(height: 24),
                  _FeatureList(
                    profile: _profile,
                    isPremium: _isPremium,
                    onProfileUpdated: () => _loadProfile(),
                  ),
                  const SizedBox(height: 24),
                  // Delete account button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _deleteAccount,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete Account'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.lossColor,
                        side: const BorderSide(color: AppTheme.lossColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (!mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.lossColor,
                        side: const BorderSide(color: AppTheme.lossColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

// ─── Profile Header (unchanged) ──
class _ProfileHeader extends StatelessWidget {
  final ProfileModel? profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?.fullName ?? 'No Name';
    final email = profile?.email ?? '';
    final role = (profile?.role ?? 'investor').toUpperCase();
    final kyc = profile?.kycStatus ?? 'pending';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _RoleBadge(label: role),
                      const SizedBox(width: 8),
                      _KYCStatusBadge(status: kyc),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  const _RoleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

class _KYCStatusBadge extends StatelessWidget {
  final String status;
  const _KYCStatusBadge({required this.status});

  Color _color(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return AppTheme.gainColor;
      case 'rejected':
        return AppTheme.lossColor;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color(status).withValues(alpha: 0.4)),
      ),
      child: Text(
        'KYC ${status.toUpperCase()}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _color(status),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final bool isPremium;
  const _StatsRow({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Subscription',
            value: isPremium ? 'Premium' : 'Free',
            icon: Icons.workspace_premium,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(title: 'Portfolio Value', value: '-', icon: Icons.account_balance_wallet)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(title: 'Orders', value: '-', icon: Icons.receipt_long)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  final ProfileModel? profile;
  final bool isPremium;
  final VoidCallback onProfileUpdated;

  const _FeatureList({
    required this.profile,
    required this.isPremium,
    required this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    if (profile == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.grey[600])),
        const SizedBox(height: 8),
        _FeatureTile(
          icon: Icons.person,
          title: 'Edit Profile',
          subtitle: 'Name, email, phone number',
          onTap: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile!)),
            );
            if (changed == true) onProfileUpdated();
          },
        ),
        _FeatureTile(
          icon: Icons.lock,
          title: 'Change Password',
          subtitle: 'Update your login password',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
        ),
        _FeatureTile(
          icon: Icons.verified_user,
          title: 'KYC Status',
          subtitle: 'View / update your verification',
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => KycStatusScreen(profile: profile!)));
            onProfileUpdated(); // refresh after possible submission
          },
        ),
        const Divider(),
        Text('Premium', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.grey[600])),
        const SizedBox(height: 8),
        _FeatureTile(
          icon: Icons.workspace_premium,
          title: isPremium ? 'Manage Subscription' : 'Upgrade to Premium',
          subtitle: isPremium ? 'View or cancel your plan' : 'Unlock advanced features',
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));
            onProfileUpdated();
          },
        ),
        const Divider(),
        Text('Preferences', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.grey[600])),
        const SizedBox(height: 8),
        _FeatureTile(
          icon: Icons.notifications,
          title: 'Notifications',
          subtitle: 'Price alerts, push notifications',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        _FeatureTile(
          icon: Icons.settings,
          title: 'Settings',
          subtitle: 'App preferences, theme, etc.',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        const Divider(),
        Text('Support', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.grey[600])),
        const SizedBox(height: 8),
        _FeatureTile(
          icon: Icons.support_agent,
          title: 'Help & Support',
          subtitle: 'FAQs, contact us',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportScreen())),
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
