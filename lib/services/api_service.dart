import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

  String formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<Map<String, dynamic>> getDashboard(DateTime date) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/dashboard?date=${formatDate(date)}'),
    );
    return _decodeMap(response);
  }

  Future<List<dynamic>> getAttendance(
    DateTime date, {
    String search = '',
  }) async {
    final uri = Uri.parse('$baseUrl/attendance').replace(
      queryParameters: {
        'date': formatDate(date),
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return _decodeList(await _client.get(uri));
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

  Future<List<dynamic>> getStudents({String search = ''}) async {
    final uri = Uri.parse('$baseUrl/students').replace(
      queryParameters: {if (search.trim().isNotEmpty) 'search': search.trim()},
    );
    return _decodeList(await _client.get(uri));
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
    return _decodeList(await _client.get(uri));
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
    final response = await _client.delete(Uri.parse('$baseUrl/notes/$id'));
    if (response.statusCode != 204) _throwApiError(response);
  }

  static const _jsonHeaders = {'Content-Type': 'application/json'};

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
