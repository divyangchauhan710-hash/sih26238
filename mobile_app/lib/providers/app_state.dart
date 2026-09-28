import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/student.dart';
import '../models/scheme.dart';
import '../models/application.dart';
import '../models/document.dart';
import '../models/review_item.dart';

class AppState extends ChangeNotifier {
  final ApiService api = ApiService();

  bool isLoading = false;
  String? error;
  String currentLanguage = 'en';

  // Auth User Info
  String? userId;
  String? studentId;
  String userRole = 'STUDENT';
  String userName = '';

  // Dashboard Data
  Student? currentStudent;
  Map<String, dynamic>? summary;
  List<SchemeOverview> schemes = [];
  List<ApplicationDetail> applications = [];
  List<WalletDocument> documents = [];
  List<ReviewQueueItem> reviewQueue = [];

  void setLanguage(String lang) {
    currentLanguage = lang;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final res = await api.login(email, password);
    isLoading = false;

    if (res['success']) {
      final user = res['data']['user'];
      userId = user['id'];
      studentId = user['studentId'];
      userRole = user['role'];
      userName = user['name'];

      if (userRole == 'STUDENT' && studentId != null) {
        await loadDashboard();
      } else if (userRole == 'ADMIN' || userRole == 'VERIFIER') {
        await loadReviewQueue();
      }

      notifyListeners();
      return true;
    } else {
      error = res['error'];
      notifyListeners();
      return false;
    }
  }

  Future<void> loadDashboard() async {
    if (studentId == null) return;
    isLoading = true;
    notifyListeners();

    final res = await api.fetchDashboard(studentId!);
    isLoading = false;

    if (res['success']) {
      currentStudent = res['student'];
      summary = res['summary'];
      schemes = res['schemes'];
      applications = res['applications'];
    } else {
      error = res['error'];
    }

    await loadDocuments();
    notifyListeners();
  }

  Future<void> loadDocuments() async {
    if (studentId == null) return;
    documents = await api.fetchDocuments(studentId!);
    notifyListeners();
  }

  Future<void> loadReviewQueue() async {
    isLoading = true;
    notifyListeners();
    reviewQueue = await api.fetchReviewQueue();
    isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> applyForScheme(String schemeId) async {
    if (studentId == null) return {'success': false, 'message': 'No student session'};
    final res = await api.applyForScheme(studentId!, schemeId);
    if (res['success']) {
      await loadDashboard();
    }
    return res;
  }

  Future<void> triggerVerificationCheck(String checkId) async {
    await api.triggerVerification(checkId);
    await loadDashboard();
  }

  Future<bool> resolveReview(String queueId, String status, String notes) async {
    final success = await api.resolveReviewItem(queueId, status, notes);
    if (success) {
      await loadReviewQueue();
    }
    return success;
  }
}
