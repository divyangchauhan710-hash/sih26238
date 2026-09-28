import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'ramesh.munda@example.com');
  final _passwordController = TextEditingController(text: 'Password@123');
  final _otpController = TextEditingController(text: '123456');

  bool isOtpStep = false;
  String selectedRole = 'STUDENT'; // STUDENT or ADMIN

  void _onDemoStudentSelect(String email) {
    setState(() {
      _emailController.text = email;
      selectedRole = 'STUDENT';
    });
  }

  void _onDemoAdminSelect() {
    setState(() {
      _emailController.text = 'admin@ekvidya.gov.in';
      selectedRole = 'ADMIN';
    });
  }

  Future<void> _handleLogin() async {
    final state = Provider.of<AppState>(context, listen: false);

    if (!isOtpStep) {
      setState(() {
        isOtpStep = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mock OTP sent to registered mobile: 123456')),
      );
      return;
    }

    final success = await state.login(_emailController.text, _passwordController.text);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Authentication failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isHindi = state.currentLanguage == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Government Brand Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D47A1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  isHindi ? 'एकविद्या - एकीकृत छात्रवृत्ति' : 'EkVidya',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isHindi
                      ? 'जनजातीय कार्य मंत्रालय, भारत सरकार'
                      : 'Ministry of Tribal Affairs, Govt. of India',
                  style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),

                // Language Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('English'),
                      selected: state.currentLanguage == 'en',
                      onSelected: (_) => state.setLanguage('en'),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('हिंदी (Hindi)'),
                      selected: state.currentLanguage == 'hi',
                      onSelected: (_) => state.setLanguage('hi'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Login Card Container
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAlignment.stretch,
                      children: [
                        Text(
                          isOtpStep
                              ? (isHindi ? 'ओटीपी सत्यापन' : 'Enter 6-Digit OTP')
                              : (isHindi ? 'लाभार्थी लॉगिन' : 'Student & Verifier Login'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (!isOtpStep) ...[
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: isHindi ? 'ईमेल / मोबाइल नंबर' : 'Email / Mobile Number',
                              prefixIcon: const Icon(Icons.person),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: isHindi ? 'पासवर्ड' : 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ] else ...[
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              hintText: '123456',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: state.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D47A1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: state.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  isOtpStep
                                      ? (isHindi ? 'सत्यापित करें और प्रवेश करें' : 'Verify & Submit')
                                      : (isHindi ? 'ओटीपी प्राप्त करें' : 'Get OTP & Login'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                        if (isOtpStep)
                          TextButton(
                            onPressed: () => setState(() => isOtpStep = false),
                            child: const Text('Back to Login'),
                          )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Demo User Selector (hackathon quick testing)
                const Text(
                  'SIH Demo Quick Login Shortcuts:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      label: const Text('Ramesh (Disbursed)'),
                      onPressed: () => _onDemoStudentSelect('ramesh.munda@example.com'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.warning, size: 16, color: Colors.orange),
                      label: const Text('Sunita (Mismatch)'),
                      onPressed: () => _onDemoStudentSelect('sunita.marandi@example.com'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.hourglass_bottom, size: 16, color: Colors.blue),
                      label: const Text('Birsa (Pending)'),
                      onPressed: () => _onDemoStudentSelect('birsa.oraon@example.com'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.admin_panel_settings, size: 16, color: Colors.purple),
                      label: const Text('Admin / Verifier'),
                      onPressed: _onDemoAdminSelect,
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
