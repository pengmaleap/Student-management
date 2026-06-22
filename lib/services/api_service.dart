import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5001/api';
    }
    return 'http://localhost:5001/api';
  }

  final http.Client _client;
  static const _tokenKey = 'auth_token';
  static String? authToken;

  static bool get isAuthenticated => authToken?.isNotEmpty == true;

  Future<bool> restoreSession() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      authToken = preferences.getString(_tokenKey);
    } on MissingPluginException {
      authToken = null;
    }
    if (!isAuthenticated) return false;
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) return true;
    } catch (_) {
      // Invalid or unreachable sessions are cleared below.
    }
    await logout();
    return false;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _jsonHeaders,
      body: jsonEncode({'username': username, 'password': password}),
    );
    final result = _decodeMap(response);
    await _storeToken(result['token'].toString());
    return result;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    String? email,
    String? fullName,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'username': username,
        'password': password,
        if (email != null) 'email': email,
        if (fullName != null) 'fullName': fullName,
      }),
    );
    final result = _decodeMap(response);
    await _storeToken(result['token'].toString());
    return result;
  }

  Future<void> _storeToken(String token) async {
    authToken = token;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_tokenKey, token);
    } on MissingPluginException {
      // Keep the authenticated session in memory for stale native builds.
    }
  }

  Future<void> logout() async {
    authToken = null;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_tokenKey);
    } on MissingPluginException {
      // There is no persisted token to remove in this runtime.
    }
  }

  String formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<List<dynamic>> getClasses() async {
    return _decodeList(
      await _client.get(Uri.parse('$baseUrl/classes'), headers: _authHeaders),
    );
  }

  Future<Map<String, dynamic>> getDashboard(
    DateTime date, {
    int? classId,
  }) async {
    final uri = Uri.parse('$baseUrl/dashboard').replace(
      queryParameters: {
        'date': formatDate(date),
        if (classId != null) 'classId': '$classId',
      },
    );
    final response = await _client.get(uri, headers: _authHeaders);
    return _decodeMap(response);
  }

  Future<void> initializeDailyData(DateTime date) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/daily/initialize'),
      headers: _jsonHeaders,
      body: jsonEncode({'date': formatDate(date)}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiError(response);
    }
  }

  Future<List<dynamic>> getAttendance(
    DateTime date, {
    String search = '',
    int? classId,
  }) async {
    final uri = Uri.parse('$baseUrl/attendance').replace(
      queryParameters: {
        'date': formatDate(date),
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (classId != null) 'classId': '$classId',
      },
    );
    return _decodeList(await _client.get(uri, headers: _authHeaders));
  }

  Future<Map<String, dynamic>> updateAttendance({
    required int studentId,
    required String date,
    required String status,
    String? checkIn,
    String? checkOut,
    String? note,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/attendance'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'studentId': studentId,
        'date': date,
        'status': status,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'note': note,
      }),
    );
    return _decodeMap(response);
  }

  Future<List<dynamic>> getStudents({String search = '', int? classId}) async {
    final uri = Uri.parse('$baseUrl/students').replace(
      queryParameters: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (classId != null) 'classId': '$classId',
      },
    );
    return _decodeList(await _client.get(uri, headers: _authHeaders));
  }

  Future<Map<String, dynamic>> createStudent(
    Map<String, dynamic> student,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/students'),
      headers: _jsonHeaders,
      body: jsonEncode(student),
    );
    return _decodeMap(response);
  }

  Future<List<dynamic>> getNotes({String search = ''}) async {
    final uri = Uri.parse('$baseUrl/notes').replace(
      queryParameters: {if (search.trim().isNotEmpty) 'search': search.trim()},
    );
    return _decodeList(await _client.get(uri, headers: _authHeaders));
  }

  Future<List<dynamic>> getNoteTypes() async {
    return _decodeList(
      await _client.get(
        Uri.parse('$baseUrl/note-types'),
        headers: _authHeaders,
      ),
    );
  }

  Future<Map<String, dynamic>> saveNote(Map<String, dynamic> note) async {
    final id = note['id'];
    final response = id == null
        ? await _client.post(
            Uri.parse('$baseUrl/notes'),
            headers: _jsonHeaders,
            body: jsonEncode(note),
          )
        : await _client.put(
            Uri.parse('$baseUrl/notes/$id'),
            headers: _jsonHeaders,
            body: jsonEncode(note),
          );
    return _decodeMap(response);
  }

  Future<void> deleteNote(int id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/notes/$id'),
      headers: _authHeaders,
    );
    if (response.statusCode != 204) _throwApiError(response);
  }

  static Map<String, String> get _authHeaders => {
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  static Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    ..._authHeaders,
  };

  Map<String, dynamic> _decodeMap(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiError(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  List<dynamic> _decodeList(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiError(response);
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  Never _throwApiError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(body['error']?.toString() ?? 'Request failed');
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException('Request failed (${response.statusCode})');
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
