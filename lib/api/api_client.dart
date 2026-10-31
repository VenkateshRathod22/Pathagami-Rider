import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bus_driver/api/api_constants.dart';
import 'package:bus_driver/api/auth_storage.dart';

/// Standard API Result Wrapper
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String message;
  final int statusCode;
  final Map<String, dynamic>? rawJson;

  ApiResponse({
    required this.isSuccess,
    this.data,
    required this.message,
    required this.statusCode,
    this.rawJson,
  });

  factory ApiResponse.success({
    required T data,
    String message = 'Success',
    int statusCode = 200,
    Map<String, dynamic>? rawJson,
  }) {
    return ApiResponse(
      isSuccess: true,
      data: data,
      message: message,
      statusCode: statusCode,
      rawJson: rawJson,
    );
  }

  factory ApiResponse.error({
    required String message,
    int statusCode = 400,
    Map<String, dynamic>? rawJson,
  }) {
    return ApiResponse(
      isSuccess: false,
      data: null,
      message: message,
      statusCode: statusCode,
      rawJson: rawJson,
    );
  }
}

/// Generic HTTP Client for SPINGO API Services
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Execute POST Request
  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
    bool attachAuth = true,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    try {
      String? token;
      if (attachAuth) {
        token = await AuthStorage.getToken();
      }

      final headers = ApiConstants.defaultHeaders(token: token);
      if (extraHeaders != null) {
        headers.addAll(extraHeaders);
      }

      final response = await _client
          .post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.timeoutDuration);

      return _processResponse(response);
    } on SocketException catch (_) {
      return ApiResponse.error(
        message: 'No internet connection. Please check your network and try again.',
        statusCode: 0,
      );
    } on TimeoutException catch (_) {
      return ApiResponse.error(
        message: 'Connection timed out. Server is taking too long to respond.',
        statusCode: 408,
      );
    } on FormatException catch (e) {
      return ApiResponse.error(
        message: 'Unexpected server response format: ${e.message}',
        statusCode: 500,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Network error occurred: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Execute PUT Request
  Future<ApiResponse<Map<String, dynamic>>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
    bool attachAuth = true,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    try {
      String? token;
      if (attachAuth) {
        token = await AuthStorage.getToken();
      }

      final headers = ApiConstants.defaultHeaders(token: token);
      if (extraHeaders != null) {
        headers.addAll(extraHeaders);
      }

      final response = await _client
          .put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.timeoutDuration);

      return _processResponse(response);
    } on SocketException catch (_) {
      return ApiResponse.error(
        message: 'No internet connection. Please check your network and try again.',
        statusCode: 0,
      );
    } on TimeoutException catch (_) {
      return ApiResponse.error(
        message: 'Connection timed out. Server is taking too long to respond.',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Network error occurred: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Execute GET Request
  Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, String>? extraHeaders,
    bool attachAuth = true,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    try {
      String? token;
      if (attachAuth) {
        token = await AuthStorage.getToken();
      }

      final headers = ApiConstants.defaultHeaders(token: token);
      if (extraHeaders != null) {
        headers.addAll(extraHeaders);
      }

      final response = await _client
          .get(url, headers: headers)
          .timeout(ApiConstants.timeoutDuration);

      return _processResponse(response);
    } on SocketException catch (_) {
      return ApiResponse.error(
        message: 'No internet connection. Please check your network and try again.',
        statusCode: 0,
      );
    } on TimeoutException catch (_) {
      return ApiResponse.error(
        message: 'Connection timed out. Server is taking too long to respond.',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Network error occurred: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Parse and normalize HTTP response
  ApiResponse<Map<String, dynamic>> _processResponse(http.Response response) {
    Map<String, dynamic> jsonMap = {};
    try {
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          jsonMap = decoded;
        }
      }
    } catch (_) {
      // Body is not JSON (e.g. 502 HTML)
    }

    final isSuccessCode = response.statusCode >= 200 && response.statusCode < 300;
    final bool apiFlagSuccess = jsonMap['success'] is bool
        ? jsonMap['success'] as bool
        : isSuccessCode;

    final String message = jsonMap['message']?.toString() ??
        (isSuccessCode ? 'Request successful' : 'Server error: ${response.statusCode}');

    if (isSuccessCode && apiFlagSuccess) {
      return ApiResponse.success(
        data: jsonMap,
        message: message,
        statusCode: response.statusCode,
        rawJson: jsonMap,
      );
    } else {
      // Check if there are field-specific error messages
      String detailedMessage = message;
      if (jsonMap['errors'] is Map) {
        final errors = jsonMap['errors'] as Map;
        for (final entry in errors.entries) {
          if (entry.value is List && (entry.value as List).isNotEmpty) {
            detailedMessage = (entry.value as List).first.toString();
            break;
          } else if (entry.value is String) {
            detailedMessage = entry.value as String;
            break;
          }
        }
      }

      return ApiResponse.error(
        message: detailedMessage,
        statusCode: response.statusCode,
        rawJson: jsonMap,
      );
    }
  }

  void close() {
    _client.close();
  }
}
