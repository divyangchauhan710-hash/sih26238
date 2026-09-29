import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/state_view.dart';
import '../widgets/summary_strip.dart';
import '../widgets/scheme_card.dart';
import 'application_detail_screen.dart';
import 'document_wallet_screen.dart';
import 'chatbot_screen.dart';
import 'admin_review_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  void _handleApply(BuildContext context, AppState state, String schemeId, String schemeName) async {
    final res = await state.applyForScheme(schemeId);

    if (res['success']) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application submitted for $schemeName! Automated verifications initiated.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } else {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange, size: 26),
                SizedBox(width: 8),
                Text('Single Active Scheme Policy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              res['message'] ?? 'Only one active scheme application is permitted at a time under Ministry of Tribal Affairs rules.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('I Understand'),
              )
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final student = state.currentStudent;
    final summary = state.summary ?? {};

    return Scaffold(
      backgroundColor: AppTheme.bgSlate,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.currentLanguage == 'hi' ? 'एकविद्या - एकीकृत पोर्टल' : 'EkVidya Portal',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (student != null)
              Text(
                '${student.name} • ${student.district}, ${student.state}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language_rounded),
            tooltip: 'Toggle Language',
            onPressed: () {
              state.setLanguage(state.currentLanguage == 'en' ? 'hi' : 'en');
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => state.loadDashboard(),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryDarkBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              onDetailsPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              accountName: Text(
                student?.name ?? state.userName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Text(student?.email ?? 'beneficiary@ekvidya.gov.in'),
              currentAccountPicture: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    student?.name.isNotEmpty == true ? student!.name[0] : 'S',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_rounded, color: AppTheme.primaryBlue),
                    title: const Text('My Profile & Settings'),
                    subtitle: const Text('View and update profile details'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder_shared_rounded, color: AppTheme.primaryBlue),
                    title: const Text('Digital Document Wallet'),
                    subtitle: const Text('DigiLocker verified certificates'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DocumentWalletScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.smart_toy_rounded, color: AppTheme.accentTeal),
                    title: const Text('EkVidya AI Chatbot'),
                    subtitle: const Text('Bhashini Multilingual & FAQs'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                      );
                    },
                  ),
                  if (state.userRole == 'ADMIN' || state.userRole == 'VERIFIER') ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_rounded, color: Colors.purple),
                      title: const Text('Verifier Manual Queue'),
                      subtitle: const Text('Resolve flagged mismatches'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminReviewScreen()),
                        );
                      },
                    ),
                  ],
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: AppTheme.textMuted),
                    title: const Text('Encrypted Vault Status'),
                    subtitle: Text(student != null ? 'Aadhaar: ${student.aadhaarMasked}' : 'Session encrypted'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
              title: const Text('Sign Out', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
              onTap: () async {
                await state.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      body: StateView(
        isLoading: state.isLoading,
        errorMessage: state.error,
        onRetry: () => state.loadDashboard(),
        child: RefreshIndicator(
          onRefresh: () => state.loadDashboard(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // Financial Summary Strip
              SummaryStrip(
                totalSanctioned: (summary['totalSanctionedAmount'] as num?)?.toDouble() ?? 0.0,
                totalDisbursed: (summary['totalDisbursedAmount'] as num?)?.toDouble() ?? 0.0,
                pendingVerifications: (summary['pendingVerificationCount'] as num?)?.toInt() ?? 0,
              ),

              // Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.currentLanguage == 'hi' ? 'एकीकृत योजनाएं' : 'Ministry ST Schemes',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.successBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'One-Stop Gateway',
                        style: TextStyle(fontSize: 10, color: AppTheme.successGreen, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),

              // Schemes ListView
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.schemes.length,
                itemBuilder: (context, index) {
                  final scheme = state.schemes[index];
                  return SchemeCard(
                    scheme: scheme,
                    onApply: () => _handleApply(context, state, scheme.schemeId, scheme.schemeName),
                    onViewDetails: () {
                      final app = state.applications.firstWhere(
                        (a) => a.schemeId == scheme.schemeId,
                        orElse: () => state.applications.first,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ApplicationDetailScreen(application: app),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatbotScreen()),
          );
        },
        backgroundColor: AppTheme.accentTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.smart_toy_rounded),
        label: const Text('AI Help'),
      ),
    );
  }
}
