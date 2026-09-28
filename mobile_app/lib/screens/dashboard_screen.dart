import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/summary_strip.dart';
import '../widgets/scheme_card.dart';
import 'application_detail_screen.dart';
import 'document_wallet_screen.dart';
import 'chatbot_screen.dart';
import 'admin_review_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  void _handleApply(BuildContext context, AppState state, String schemeId, String schemeName) async {
    final res = await state.applyForScheme(schemeId);

    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application submitted for $schemeName! Verification process started.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('Single Active Scheme Policy', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Text(
            res['message'] ?? 'Only one active scheme application permitted at a time.',
            style: const TextStyle(fontSize: 14),
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

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final student = state.currentStudent;
    final summary = state.summary ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            Text(
              state.currentLanguage == 'hi' ? 'एकविद्या - एसटी डैशबोर्ड' : 'EkVidya - Unified ST Dashboard',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (student != null)
              Text(
                'Welcome, ${student.name} (${student.district}, ${student.state})',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'Toggle Language',
            onPressed: () {
              state.setLanguage(state.currentLanguage == 'en' ? 'hi' : 'en');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => state.loadDashboard(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0D47A1)),
              accountName: Text(student?.name ?? 'Beneficiary'),
              accountEmail: Text(student?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  student?.name.isNotEmpty == true ? student!.name[0] : 'S',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder_shared, color: Color(0xFF0D47A1)),
              title: const Text('Digital Document Wallet'),
              subtitle: const Text('DigiLocker integrated certificates'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DocumentWalletScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.smart_toy, color: Colors.teal),
              title: const Text('EkVidya AI Chatbot'),
              subtitle: const Text('Multilingual Assistant & FAQs'),
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
                leading: const Icon(Icons.admin_panel_settings, color: Colors.purple),
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
              leading: const Icon(Icons.lock_reset),
              title: const Text('Encrypted Vault Info'),
              subtitle: Text(student != null ? 'Aadhaar: ${student.aadhaarMasked}' : ''),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => state.loadDashboard(),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
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
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          state.currentLanguage == 'hi'
                              ? 'एकीकृत योजनाएं (5 पोर्टल)'
                              : 'Ministry ST Schemes (5 Unified Portals)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Text(
                            'One-Stop Gateway',
                            style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),

                  // Lazy-loaded ListView for low-end device performance
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
                  const SizedBox(height: 30),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatbotScreen()),
          );
        },
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.smart_toy),
        label: const Text('AI Help'),
      ),
    );
  }
}
