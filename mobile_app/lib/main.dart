import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_review_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const EkVidyaApp(),
    ),
  );
}

class EkVidyaApp extends StatelessWidget {
  const EkVidyaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return MaterialApp(
          title: 'EkVidya - Unified ST Scholarship Mobile App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: const Color(0xFF0D47A1),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D47A1),
              secondary: Colors.teal.shade700,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          locale: Locale(state.currentLanguage),
          supportedLocales: const [
            Locale('en', ''),
            Locale('hi', ''),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: state.userId == null
              ? const LoginScreen()
              : (state.userRole == 'ADMIN' || state.userRole == 'VERIFIER'
                  ? const AdminReviewScreen()
                  : const DashboardScreen()),
        );
      },
    );
  }
}
