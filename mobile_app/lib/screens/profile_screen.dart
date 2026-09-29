import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _stateController;
  late TextEditingController _districtController;
  late TextEditingController _stCertController;

  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppState>(context, listen: false);
    final student = state.currentStudent;

    _nameController = TextEditingController(text: student?.name ?? state.userName);
    _phoneController = TextEditingController(text: student?.phone ?? '+91 9876543210');
    _stateController = TextEditingController(text: student?.state ?? 'Jharkhand');
    _districtController = TextEditingController(text: student?.district ?? 'Ranchi');
    _stCertController = TextEditingController(text: student?.stCertificateRef ?? 'JH/ST/2022/883920');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _stCertController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isUpdating = true);

    final state = Provider.of<AppState>(context, listen: false);
    final success = await state.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      state: _stateController.text.trim(),
      district: _districtController.text.trim(),
      stCertificateRef: _stCertController.text.trim(),
    );

    setState(() => isUpdating = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'Failed to update profile'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    final state = Provider.of<AppState>(context, listen: false);
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
    final student = state.currentStudent;
    final isStudent = state.userRole == 'STUDENT';

    return Scaffold(
      backgroundColor: AppTheme.bgSlate,
      appBar: AppBar(
        title: const Text('My Profile & Account Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Sign Out',
            onPressed: _handleSignOut,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Profile Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.primaryDarkBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Text(
                            (student?.name.isNotEmpty == true ? student!.name[0] : (state.userName.isNotEmpty ? state.userName[0] : 'U')).toUpperCase(),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          student?.name ?? (state.userName.isNotEmpty ? state.userName : 'District Verification Officer'),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isStudent ? 'Beneficiary ST Student' : 'Authorized Portal Verifier / Admin',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          student?.email ?? 'verifier@ekvidya.gov.in',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Edit Form Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Details & Preferences',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => v == null || v.trim().length < 2 ? 'Enter valid name' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Mobile Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (v) => v == null || v.trim().length < 10 ? 'Enter valid 10-digit phone' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _stateController,
                                decoration: const InputDecoration(
                                  labelText: 'State',
                                  prefixIcon: Icon(Icons.map_outlined),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Enter state' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _districtController,
                                decoration: const InputDecoration(
                                  labelText: 'District',
                                  prefixIcon: Icon(Icons.location_city_outlined),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Enter district' : null,
                              ),
                            ),
                          ],
                        ),
                        if (isStudent) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _stCertController,
                            decoration: const InputDecoration(
                              labelText: 'ST Certificate Reference',
                              prefixIcon: Icon(Icons.verified_outlined),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter ST Certificate reference' : null,
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Encrypted Info Display
                        if (student != null) ...[
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text('Encrypted Aadhaar & Bank Vault', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Aadhaar Number:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              Text(student.aadhaarMasked, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Seeded Bank Account:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              Text(student.bankAccountMasked, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],

                        ElevatedButton.icon(
                          onPressed: isUpdating ? null : _handleUpdateProfile,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: isUpdating
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.save_rounded),
                          label: const Text('Save Profile Changes'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign Out Button
                  OutlinedButton.icon(
                    onPressed: _handleSignOut,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: const BorderSide(color: AppTheme.errorRed),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign Out of Account', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
