import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';
import 'dashboard_screen.dart';
import 'admin_review_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isRegisterTab = false;
  bool isOtpStep = false;

  // Controllers
  final _emailController = TextEditingController(text: 'ramesh.munda@example.com');
  final _passwordController = TextEditingController(text: 'Password@123');
  final _otpController = TextEditingController(text: '123456');

  // Register Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _stCertController = TextEditingController();
  final _stateController = TextEditingController(text: 'Jharkhand');
  final _districtController = TextEditingController(text: 'Ranchi');
  final _bankController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void _onDemoSelect(String email) {
    setState(() {
      isRegisterTab = false;
      isOtpStep = false;
      _emailController.text = email;
      _passwordController.text = 'Password@123';
    });
  }

  void _showServerUrlDialog() {
    final urlController = TextEditingController(text: AppConfig.apiBaseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure Backend API URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set host URL for physical device or tunnel (e.g. http://10.131.76.76:5000/api or https://localtunnel.me/api):',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Backend API URL',
                hintText: 'http://10.131.76.76:5000/api',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              AppConfig.setBaseUrl(urlController.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Backend API URL set to: ${AppConfig.apiBaseUrl}'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            child: const Text('Save URL'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final state = Provider.of<AppState>(context, listen: false);

    if (!isOtpStep) {
      setState(() => isOtpStep = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification OTP sent to registered Aadhaar mobile: 123456'),
          backgroundColor: AppTheme.infoBlue,
        ),
      );
      return;
    }

    final success = await state.login(_emailController.text.trim(), _passwordController.text.trim());
    if (mounted) {
      if (success) {
        if (state.userRole == 'ADMIN' || state.userRole == 'VERIFIER') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminReviewScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'Authentication failed'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final state = Provider.of<AppState>(context, listen: false);

    final success = await state.register(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      dob: '2004-06-15',
      gender: 'MALE',
      aadhaarNumber: _aadhaarController.text.trim(),
      stCertificateRef: _stCertController.text.trim(),
      phone: _phoneController.text.trim(),
      state: _stateController.text.trim(),
      district: _districtController.text.trim(),
      bankAccountNumber: _bankController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Welcome to EkVidya Portal.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'Registration failed'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isHindi = state.currentLanguage == 'hi';

    return Scaffold(
      backgroundColor: AppTheme.bgSlate,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Government Brand Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school_rounded, size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isHindi ? 'एकविद्या - एकीकृत छात्रवृत्ति' : 'EkVidya',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isHindi
                          ? 'जनजातीय कार्य मंत्रालय, भारत सरकार'
                          : 'Ministry of Tribal Affairs, Govt. of India',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Language Selector & Server Settings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('English'),
                          selected: state.currentLanguage == 'en',
                          onSelected: (_) => state.setLanguage('en'),
                          selectedColor: AppTheme.infoBg,
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('हिंदी (Hindi)'),
                          selected: state.currentLanguage == 'hi',
                          onSelected: (_) => state.setLanguage('hi'),
                          selectedColor: AppTheme.infoBg,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.settings_ethernet_rounded, color: AppTheme.primaryBlue),
                          tooltip: 'Configure Backend Server URL',
                          onPressed: _showServerUrlDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Auth Card Container
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Tab Toggle (Login vs Register)
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      isRegisterTab = false;
                                      isOtpStep = false;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: !isRegisterTab ? AppTheme.primaryBlue : Colors.transparent,
                                            width: 2.5,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        isHindi ? 'लॉगिन' : 'Beneficiary Login',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: !isRegisterTab ? FontWeight.bold : FontWeight.normal,
                                          color: !isRegisterTab ? AppTheme.primaryBlue : AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      isRegisterTab = true;
                                      isOtpStep = false;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: isRegisterTab ? AppTheme.primaryBlue : Colors.transparent,
                                            width: 2.5,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        isHindi ? 'पंजीकरण' : 'New Registration',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: isRegisterTab ? FontWeight.bold : FontWeight.normal,
                                          color: isRegisterTab ? AppTheme.primaryBlue : AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            if (!isRegisterTab) ...[
                              // LOGIN FORM
                              if (!isOtpStep) ...[
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: isHindi ? 'ईमेल / मोबाइल नंबर' : 'Email Address',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Please enter your email';
                                    if (!val.contains('@')) return 'Enter a valid email address';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: isHindi ? 'पासवर्ड' : 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Please enter your password';
                                    if (val.length < 6) return 'Password must be at least 6 characters';
                                    return null;
                                  },
                                ),
                              ] else ...[
                                const Text(
                                  'Aadhaar OTP Verification',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Enter 6-digit code sent to your registered Aadhaar mobile',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    hintText: '123456',
                                  ),
                                  validator: (val) {
                                    if (val == null || val.length < 6) return 'Enter 6-digit OTP';
                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: state.isLoading ? null : _handleLogin,
                                child: state.isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(isOtpStep ? (isHindi ? 'सत्यापित करें और प्रवेश करें' : 'Verify & Login') : (isHindi ? 'ओटीपी प्राप्त करें' : 'Get OTP & Login')),
                              ),
                              if (isOtpStep)
                                TextButton(
                                  onPressed: () => setState(() => isOtpStep = false),
                                  child: const Text('Back to Login'),
                                )
                            ] else ...[
                              // REGISTRATION FORM
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(labelText: 'Full Name (as in Aadhaar)', prefixIcon: Icon(Icons.person_outline)),
                                validator: (v) => v == null || v.trim().length < 2 ? 'Enter full name' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                                validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(labelText: 'Password (min 6 chars)', prefixIcon: Icon(Icons.lock_outline)),
                                validator: (v) => v == null || v.length < 6 ? 'Password must be min 6 characters' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(labelText: 'Mobile Number (10 digits)', prefixIcon: Icon(Icons.phone_outlined)),
                                validator: (v) => v == null || v.trim().length != 10 ? 'Enter 10-digit mobile' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _aadhaarController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Aadhaar Number (12 digits)', prefixIcon: Icon(Icons.badge_outlined)),
                                validator: (v) => v == null || v.trim().length != 12 ? 'Enter 12-digit Aadhaar' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _stCertController,
                                decoration: const InputDecoration(labelText: 'ST Certificate Reg Ref No.', prefixIcon: Icon(Icons.verified_outlined)),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Enter ST Certificate Ref' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _bankController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Bank Account Number', prefixIcon: Icon(Icons.account_balance_outlined)),
                                validator: (v) => v == null || v.trim().length < 6 ? 'Enter bank account number' : null,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: state.isLoading ? null : _handleRegister,
                                child: state.isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Complete ST Registration'),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Demo Accounts
                    const Text(
                      'Demo Accounts (Live Backend & Offline Standalone):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.check_circle, size: 14, color: AppTheme.successGreen),
                          label: const Text('Ramesh (Disbursed)', style: TextStyle(fontSize: 12)),
                          onPressed: () => _onDemoSelect('ramesh.munda@example.com'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.warning, size: 14, color: AppTheme.warningOrange),
                          label: const Text('Sunita (Mismatch)', style: TextStyle(fontSize: 12)),
                          onPressed: () => _onDemoSelect('sunita.marandi@example.com'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.hourglass_bottom, size: 14, color: AppTheme.infoBlue),
                          label: const Text('Birsa (Pending)', style: TextStyle(fontSize: 12)),
                          onPressed: () => _onDemoSelect('birsa.oraon@example.com'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.admin_panel_settings, size: 14, color: Colors.purple),
                          label: const Text('Verifier Portal', style: TextStyle(fontSize: 12)),
                          onPressed: () => _onDemoSelect('admin@ekvidya.gov.in'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
