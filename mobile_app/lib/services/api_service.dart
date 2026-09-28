import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student.dart';
import '../models/scheme.dart';
import '../models/application.dart';
import '../models/document.dart';
import '../models/review_item.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  String? authToken;

  void setToken(String token) {
    authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  // Auth: Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        authToken = data['accessToken'];
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Dashboard Aggregation
  Future<Map<String, dynamic>> fetchDashboard(String studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students/$studentId/dashboard'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final student = Student.fromJson(data['student']);
        final schemes = (data['schemes'] as List)
            .map((s) => SchemeOverview.fromJson(s))
            .toList();
        final apps = (data['applications'] as List)
            .map((a) => ApplicationDetail.fromJson(a))
            .toList();

        return {
          'success': true,
          'student': student,
          'summary': data['summary'],
          'schemes': schemes,
          'applications': apps,
        };
      } else {
        return {'success': false, 'error': 'Failed to load dashboard'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Submit Application with business rule check
  Future<Map<String, dynamic>> applyForScheme(String studentId, String schemeId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/applications'),
        headers: _headers,
        body: jsonEncode({
          'studentId': studentId,
          'schemeId': schemeId,
          'academicYear': '2025-2026',
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message'], 'application': data['application']};
      } else {
        return {
          'success': false,
          'isRuleViolation': data['error'] == 'BUSINESS_RULE_VIOLATION',
          'message': data['message'] ?? data['error'] ?? 'Application failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Fetch Application Verifications
  Future<List<VerificationItem>> fetchVerifications(String applicationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/applications/$applicationId/verifications'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['verifications'] as List)
            .map((v) => VerificationItem.fromJson(v))
            .toList();
      }
    } catch (e) {
      print('Fetch verifications error: $e');
    }
    return [];
  }

  // Trigger Verification Check
  Future<Map<String, dynamic>> triggerVerification(String checkId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/applications/verifications/$checkId/trigger'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
    } catch (e) {
      print('Trigger verification error: $e');
    }
    return {'success': false};
  }

  // Document Wallet
  Future<List<WalletDocument>> fetchDocuments(String studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/documents/student/$studentId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['documents'] as List)
            .map((d) => WalletDocument.fromJson(d))
            .toList();
      }
    } catch (e) {
      print('Fetch documents error: $e');
    }
    return [];
  }

  // Upload Document
  Future<bool> uploadDocument({
    required String studentId,
    required String docType,
    required String digilockerUri,
    String? reusedFromApplicationId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/documents'),
        headers: _headers,
        body: jsonEncode({
          'studentId': studentId,
          'docType': docType,
          'digilockerUri': digilockerUri,
          'reusedFromApplicationId': reusedFromApplicationId,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Chatbot Query
  Future<Map<String, dynamic>> askChatbot(String query, String lang) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chatbot/query'),
        headers: _headers,
        body: jsonEncode({'query': query, 'language': lang}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Chatbot query error: $e');
    }
    return {
      'answer': 'EkVidya Assistant: Unable to reach verification server right now.',
      'confidence': 0.5
    };
  }

  // Admin Manual Review Queue
  Future<List<ReviewQueueItem>> fetchReviewQueue() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/manual-review-queue'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['queue'] as List)
            .map((q) => ReviewQueueItem.fromJson(q))
            .toList();
      }
    } catch (e) {
      print('Fetch review queue error: $e');
    }
    return [];
  }

  // Resolve Review Queue Item
  Future<bool> resolveReviewItem(String queueId, String status, String notes) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/manual-review-queue/$queueId'),
        headers: _headers,
        body: jsonEncode({'status': status, 'notes': notes}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
