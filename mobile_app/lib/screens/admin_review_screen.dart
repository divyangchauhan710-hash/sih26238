import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/state_view.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'chatbot_screen.dart';

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({Key? key}) : super(key: key);

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  final TextEditingController _notesController = TextEditingController();

  void _handleDecision(String queueId, String status) async {
    final state = Provider.of<AppState>(context, listen: false);
    final notes = _notesController.text.trim().isEmpty
        ? 'Verified by District Officer during portal review'
        : _notesController.text.trim();

    final success = await state.resolveReview(queueId, status, notes);
    _notesController.clear();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item marked as $status successfully! Application database updated.'),
            backgroundColor: status == 'APPROVED' ? AppTheme.successGreen : AppTheme.errorRed,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update review decision')),
        );
      }
    }
  }

  void _handleSignOut(AppState state) async {
    await state.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final queue = state.reviewQueue;

    return Scaffold(
      backgroundColor: AppTheme.bgSlate,
      appBar: AppBar(
        backgroundColor: Colors.purple.shade900,
        title: const Text('Verifier Manual Review Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Queue',
            onPressed: () => state.loadReviewQueue(),
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
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => _handleSignOut(state),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade900, Colors.purple.shade700],
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
                state.userName.isNotEmpty ? state.userName : 'District Verifier Officer',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: const Text('verifier@ekvidya.gov.in'),
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
                    state.userName.isNotEmpty ? state.userName[0].toUpperCase() : 'V',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
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
                    subtitle: const Text('View & edit verifier profile'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_rounded, color: Colors.purple),
                    title: const Text('Verifier Manual Queue'),
                    subtitle: const Text('Resolve flagged mismatches'),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.smart_toy_rounded, color: AppTheme.accentTeal),
                    title: const Text('EkVidya AI Chatbot'),
                    subtitle: const Text('Bhashini Multilingual Assistant'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
              title: const Text('Sign Out', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
              onTap: () => _handleSignOut(state),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      body: StateView(
        isLoading: state.isLoading,
        errorMessage: state.error,
        onRetry: () => state.loadReviewQueue(),
        child: queue.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 64, color: AppTheme.successGreen),
                    SizedBox(height: 12),
                    Text('No pending mismatches in manual review queue!', style: TextStyle(fontSize: 15, color: AppTheme.textMuted)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final item = queue[index];

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'MISMATCH: ${item.checkType}',
                                  style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                              Text(
                                'Confidence: ${(item.confidenceScore * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('Beneficiary: ${item.studentName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                          const SizedBox(height: 4),
                          Text('Scheme: ${item.schemeName}', style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
                          Text('Source System: ${item.sourceSystem}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          const Divider(height: 20),
                          Text(
                            'Flagged Notes: ${item.notes ?? 'Fuzzy match discrepancy detected'}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.warningOrange, fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              hintText: 'Enter verifier resolution notes...',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _handleDecision(item.id, 'REJECTED'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.errorRed,
                                  side: const BorderSide(color: AppTheme.errorRed),
                                ),
                                icon: const Icon(Icons.cancel_outlined, size: 16),
                                label: const Text('Reject Application'),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () => _handleDecision(item.id, 'APPROVED'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successGreen,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.check_circle_outlined, size: 16),
                                label: const Text('Approve Override'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
