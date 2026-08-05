import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/profile_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/shared/models/profile_model.dart';
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
  ProfileModel? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await _profileService.getCurrentProfile();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loading = false;
    });
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
                  // ─── Profile Header Card ─────────────────────
                  _ProfileHeader(profile: _profile),
                  const SizedBox(height: 20),
                  // ─── Account Stats ───────────────────────────
                  _StatsRow(profile: _profile),
                  const SizedBox(height: 24),
                  // ─── Quick Links / Menu ──────────────────────
                  const _MenuSection(),
                  const SizedBox(height: 16),
                  // ─── Logout Button ───────────────────────────
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

// ─── Profile Header ─────────────────────────────────────────
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
            // Avatar
            CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
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
            // Name, email, role
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
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
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
        color: _color(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color(status).withOpacity(0.4)),
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

// ─── Stats Row ──────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final ProfileModel? profile;
  const _StatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    // Replace with actual data from your portfolio/subs if available
    return Row(
      children: [
        Expanded(child: _StatCard(title: 'Subscription', value: 'N/A')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(title: 'Portfolio Value', value: '-')),   // placeholder
        const SizedBox(width: 12),
        Expanded(child: _StatCard(title: 'Orders', value: '-')),           // placeholder
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
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

// ─── Menu / Quick Links ─────────────────────────────────────
class _MenuSection extends StatelessWidget {
  const _MenuSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MenuTile(
          icon: Icons.workspace_premium,
          title: 'Upgrade to Premium',
          subtitle: 'Unlock advanced features and unlimited alerts',
          screen: UpgradeScreen(),
        ),
        const Divider(),
        const _MenuTile(
          icon: Icons.settings,
          title: 'Settings',
          subtitle: 'App preferences, notifications, appearance',
          screen: SettingsScreen(),
        ),
        const Divider(),
        const _MenuTile(
          icon: Icons.support_agent,
          title: 'Help & Support',
          subtitle: 'FAQs, contact us, report a problem',
          screen: SupportScreen(),
        ),
        // Add more tiles if needed (e.g., Edit Profile)
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => screen),
      ),
    );
  }
}
