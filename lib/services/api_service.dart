// lib/services/api_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiService {
  // Base URLs
  static const String _prodBaseUrl = 'https://msic.mysztechnology.com/api';
  static const String _devBaseUrl = 'http://msic_be.test/api';
  static const bool _useProd = true;

  static String get _baseUrl => _useProd ? _prodBaseUrl : _devBaseUrl;

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: '$_baseUrl/mobile',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ),
      ),
      _mainDio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ),
      ) {
    // 🔎 full wire logs to debug what's sent/received
    final logInterceptor = LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    );
    _dio.interceptors.add(logInterceptor);
    _mainDio.interceptors.add(logInterceptor);
  }

  final Dio _dio; // For mobile-specific endpoints
  final Dio _mainDio; // For main API endpoints

  Future<bool> _hasConnection() async {
    final c = await Connectivity().checkConnectivity();
    if (c.contains(ConnectivityResult.none) || c.isEmpty) return false;
    try {
      final r = await InternetAddress.lookup('google.com');
      return r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isBackendReachable() async {
    try {
      // Use HTTP request instead of raw socket for better HTTPS compatibility
      final res = await _mainDio.get(
        '/test',
        options: Options(receiveTimeout: const Duration(seconds: 3)),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _snack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {'Authorization': 'Bearer $token'};
  }

  Future<Response?> login(
    BuildContext context,
    String email,
    String password,
  ) async {
    if (!await _hasConnection()) {
      _snack(context, 'No internet connection.');
      return null;
    }
    if (!await _isBackendReachable()) {
      _snack(context, 'Cannot reach server. Check Wi-Fi or API host.');
      return null;
    }
    try {
      final res = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );
      final data = res.data;
      final token = (data is Map)
          ? (data['token'] ??
                (data['data'] is Map ? data['data']['token'] : null) ??
                data['access_token'])
          : null;
      if (res.statusCode == 200 && token is String && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        // Store user data for role checks
        final user = data['user'];
        if (user is Map) {
          await prefs.setString('user_role', user['role']?.toString() ?? '');
          await prefs.setString('user_name', user['name']?.toString() ?? '');
          await prefs.setInt('user_id', int.tryParse('${user['id']}') ?? 0);
        }
      }
      return res;
    } on DioException catch (e) {
      _snack(
        context,
        e.response?.data?['message']?.toString() ?? 'Invalid credentials.',
      );
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      await _dio.post(
        '/logout',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (_) {}
    await prefs.remove('token');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    await prefs.remove('user_id');
  }

  // ---------- STOCK-IN LIST ----------
  Future<List<Map<String, dynamic>>> getStockInList(
    BuildContext context, {
    int page = 1,
    String? search,
    String? fromDate,
    String? toDate,
  }) async {
    if (!await _hasConnection()) {
      _snack(context, 'No internet connection.');
      return [];
    }
    if (!await _isBackendReachable()) {
      _snack(context, 'Cannot reach server.');
      return [];
    }

    final headers = await _authHeaders();

    // Send common aliases too (some backends use q/from/to)
    final query = <String, dynamic>{
      'page': page,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (search != null && search.trim().isNotEmpty)
        'q': search.trim(), // alias
      if (fromDate != null && fromDate.trim().isNotEmpty)
        'from_date': fromDate.trim(),
      if (fromDate != null && fromDate.trim().isNotEmpty)
        'from': fromDate.trim(), // alias
      if (toDate != null && toDate.trim().isNotEmpty) 'to_date': toDate.trim(),
      if (toDate != null && toDate.trim().isNotEmpty)
        'to': toDate.trim(), // alias
    };

    try {
      final res = await _dio.get(
        '/stockin',
        queryParameters: query,
        options: Options(headers: headers),
      );
      final payload = res.data;

      // Your API returns: { "data": [ { DO_Number, SupplierName, ... } ] }
      if (payload is Map && payload['data'] is List) {
        return List<Map<String, dynamic>>.from(payload['data']);
      } else if (payload is List) {
        return List<Map<String, dynamic>>.from(payload);
      }
      return [];
    } on DioException catch (e) {
      _snack(
        context,
        e.response?.data?['message']?.toString() ?? 'Failed to load DO list.',
      );
      return [];
    }
  }

  // ---------- DO LOTS ----------
  Future<Map<String, dynamic>> getDoLots(
    BuildContext context, {
    required String doId,
  }) async {
    if (!await _hasConnection()) {
      _snack(context, 'No internet connection.');
      return {};
    }
    if (!await _isBackendReachable()) {
      _snack(context, 'Cannot reach server.');
      return {};
    }

    final headers = await _authHeaders();

    try {
      final res = await _dio.get(
        '/stockin/$doId/lots',
        options: Options(headers: headers),
      );
      final payload = res.data;

      if (payload is Map) {
        final lots = (payload['Lots'] is List)
            ? List<Map<String, dynamic>>.from(payload['Lots'])
            : const [];
        final header = {
          'DO_Number': payload['DO_Number'] ?? doId,
          'TotalLots': payload['TotalLots'] ?? lots.length,
          // (if BE later adds SupplierName/ReceiveDate, we'll show them too)
          'SupplierName': payload['SupplierName'],
          'ReceiveDate': payload['ReceiveDate'],
        };
        return {'header': header, 'lots': lots};
      }
      return {'header': {}, 'lots': []};
    } on DioException catch (e) {
      _snack(
        context,
        e.response?.data?['message']?.toString() ??
            'Failed to load DO details.',
      );
      return {'header': {}, 'lots': []};
    }
  }

  // ========== MAIN API STOCK-IN METHODS ==========

  /// Get Stock-In list with full filters (uses main API)
  Future<Map<String, dynamic>> getStockInListFull(
    BuildContext context, {
    int page = 1,
    String? search,
    String? fromDate,
    String? toDate,
    int? supplierId,
    int? productId,
    String? batch,
  }) async {
    if (!await _hasConnection()) {
      _snack(context, 'No internet connection.');
      return {'data': [], 'current_page': 1, 'last_page': 1};
    }
    if (!await _isBackendReachable()) {
      _snack(context, 'Cannot reach server.');
      return {'data': [], 'current_page': 1, 'last_page': 1};
    }

    final headers = await _authHeaders();
    final query = <String, dynamic>{
      'page': page,
      if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
      if (fromDate != null && fromDate.isNotEmpty) 'date_from': fromDate,
      if (toDate != null && toDate.isNotEmpty) 'date_to': toDate,
      if (supplierId != null) 'supplier_id': supplierId,
      if (productId != null) 'product_id': productId,
      if (batch != null && batch.isNotEmpty) 'batch': batch,
    };

    try {
      final res = await _mainDio.get(
        '/stock-in',
        queryParameters: query,
        options: Options(headers: headers),
      );
      final payload = res.data;

      if (payload is Map) {
        return {
          'data': payload['data'] ?? [],
          'current_page': payload['current_page'] ?? 1,
          'last_page': payload['last_page'] ?? 1,
        };
      }
      return {'data': [], 'current_page': 1, 'last_page': 1};
    } on DioException catch (e) {
      _snack(
        context,
        e.response?.data?['message']?.toString() ??
            'Failed to load Stock-In list.',
      );
      return {'data': [], 'current_page': 1, 'last_page': 1};
    }
  }

  /// Get Stock-In detail by DO number (uses main API)
  Future<List<Map<String, dynamic>>> getStockInDetail(
    BuildContext context, {
    required String doNumber,
  }) async {
    if (!await _hasConnection()) {
      _snack(context, 'No internet connection.');
      return [];
    }
    if (!await _isBackendReachable()) {
      _snack(context, 'Cannot reach server.');
      return [];
    }

    final headers = await _authHeaders();

    try {
      final res = await _mainDio.get(
        '/stock-in',
        queryParameters: {'do': doNumber},
        options: Options(headers: headers),
      );
      final payload = res.data;

      if (payload is List) {
        return List<Map<String, dynamic>>.from(payload);
      }
      return [];
    } on DioException catch (e) {
      _snack(
        context,
        e.response?.data?['message']?.toString() ??
            'Failed to load DO details.',
      );
      return [];
    }
  }

  /// Create new Stock-In (uses main API)
  Future<Map<String, dynamic>?> createStockIn(
    BuildContext context, {
    required String doNumber,
    required int supplierId,
    required int picId,
    required String receiveDate,
    required List<Map<String, dynamic>> items,
  }) async {
    if (!await _hasConnection()) {
      _snack(context, 'No internet connection.');
      return null;
    }
    if (!await _isBackendReachable()) {
      _snack(context, 'Cannot reach server.');
      return null;
    }

    final headers = await _authHeaders();
    final payload = {
      'DO_Number': doNumber,
      'SupplierID': supplierId,
      'PIC_ID': picId,
      'ReceiveDate': receiveDate,
      'Items': items,
    };

    try {
      final res = await _mainDio.post(
        '/stock-in',
        data: payload,
        options: Options(headers: headers),
      );
      return res.data is Map ? Map<String, dynamic>.from(res.data) : null;
    } on DioException catch (e) {
      final errMsg =
          e.response?.data?['error'] ??
          (e.response?.data?['errors'] is Map
              ? (e.response?.data?['errors'] as Map).values
                    .expand((v) => v is List ? v : [v])
                    .join('\n')
              : null) ??
          'Failed to create Stock-In.';
      _snack(context, errMsg.toString());
      return null;
    }
  }

  /// Delete Stock-In by DO number (uses main API)
  Future<bool> deleteStockInDo(BuildContext context, String doNumber) async {
    if (!await _hasConnection()) {
      _snack(context, 'No internet connection.');
      return false;
    }
    if (!await _isBackendReachable()) {
      _snack(context, 'Cannot reach server.');
      return false;
    }

    final headers = await _authHeaders();

    try {
      await _mainDio.delete(
        '/stock-in/do/${Uri.encodeComponent(doNumber)}',
        options: Options(headers: headers),
      );
      return true;
    } on DioException catch (e) {
      _snack(
        context,
        e.response?.data?['message']?.toString() ?? 'Failed to delete DO.',
      );
      return false;
    }
  }

  /// Get DO lots (uses main API for full lot data)
  Future<Map<String, dynamic>> getStockInDoLots(
    BuildContext context, {
    required String doNumber,
  }) async {
    if (!await _hasConnection()) {
      _snack(context, 'No internet connection.');
      return {'DO_Number': doNumber, 'TotalLots': 0, 'Lots': []};
    }
    if (!await _isBackendReachable()) {
      _snack(context, 'Cannot reach server.');
      return {'DO_Number': doNumber, 'TotalLots': 0, 'Lots': []};
    }

    final headers = await _authHeaders();

    try {
      final res = await _mainDio.get(
        '/stock-in/do/${Uri.encodeComponent(doNumber)}/lots',
        options: Options(headers: headers),
      );
      final payload = res.data;

      if (payload is Map) {
        return {
          'DO_Number': payload['DO_Number'] ?? doNumber,
          'TotalLots': payload['TotalLots'] ?? 0,
          'Lots': payload['Lots'] ?? [],
        };
      }
      return {'DO_Number': doNumber, 'TotalLots': 0, 'Lots': []};
    } on DioException catch (e) {
      _snack(
        context,
        e.response?.data?['message']?.toString() ?? 'Failed to load lots.',
      );
      return {'DO_Number': doNumber, 'TotalLots': 0, 'Lots': []};
    }
  }

  // ========== DROPDOWN DATA METHODS ==========

  /// Get suppliers list
  Future<List<Map<String, dynamic>>> getSuppliers(BuildContext context) async {
    if (!await _hasConnection()) return [];
    if (!await _isBackendReachable()) return [];

    final headers = await _authHeaders();

    try {
      final res = await _mainDio.get(
        '/suppliers',
        options: Options(headers: headers),
      );
      final payload = res.data;
      final data = payload is Map ? payload['data'] : payload;
      return data is List ? List<Map<String, dynamic>>.from(data) : [];
    } catch (_) {
      return [];
    }
  }

  /// Get PICs list
  Future<List<Map<String, dynamic>>> getPics(BuildContext context) async {
    if (!await _hasConnection()) return [];
    if (!await _isBackendReachable()) return [];

    final headers = await _authHeaders();

    try {
      final res = await _mainDio.get(
        '/pics',
        options: Options(headers: headers),
      );
      final payload = res.data;
      final data = payload is Map ? payload['data'] : payload;
      return data is List ? List<Map<String, dynamic>>.from(data) : [];
    } catch (_) {
      return [];
    }
  }

  /// Get clients list
  Future<List<Map<String, dynamic>>> getClients(BuildContext context) async {
    if (!await _hasConnection()) return [];
    if (!await _isBackendReachable()) return [];

    final headers = await _authHeaders();

    try {
      final res = await _mainDio.get(
        '/clients',
        options: Options(headers: headers),
      );
      final payload = res.data;
      final data = payload is Map ? payload['data'] : payload;
      return data is List ? List<Map<String, dynamic>>.from(data) : [];
    } catch (_) {
      return [];
    }
  }

  /// Search products (optionally filter by supplier)
  Future<List<Map<String, dynamic>>> searchProducts(
    BuildContext context, {
    String? search,
    int? supplierId,
  }) async {
    if (!await _hasConnection()) return [];
    if (!await _isBackendReachable()) return [];

    final headers = await _authHeaders();
    final query = <String, dynamic>{
      if (search != null && search.isNotEmpty) 'search': search,
      if (supplierId != null) 'supplier_id': supplierId,
    };

    try {
      final res = await _mainDio.get(
        '/products',
        queryParameters: query,
        options: Options(headers: headers),
      );
      final payload = res.data;
      final data = payload is Map ? payload['data'] : payload;
      return data is List ? List<Map<String, dynamic>>.from(data) : [];
    } catch (_) {
      return [];
    }
  }

  /// Get user info from stored token (for role checks)
  Future<Map<String, dynamic>?> getCurrentUser(BuildContext context) async {
    if (!await _hasConnection()) return null;
    if (!await _isBackendReachable()) return null;

    final headers = await _authHeaders();

    try {
      final res = await _mainDio.get(
        '/auth/me',
        options: Options(headers: headers),
      );
      return res.data is Map ? Map<String, dynamic>.from(res.data) : null;
    } catch (_) {
      return null;
    }
  }

  // ========== STOCK-OUT API METHODS ==========

  /// Get Stock-Out list with filters
  Future<Map<String, dynamic>> getStockOutListFull(
    BuildContext context, {
    int page = 1,
    String? search,
    int? clientId,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    if (!await _hasConnection()) {
      _snack(context, 'No internet connection.');
      return {'data': [], 'current_page': 1, 'last_page': 1};
    }
    if (!await _isBackendReachable()) {
      _snack(context, 'Cannot reach server.');
      return {'data': [], 'current_page': 1, 'last_page': 1};
    }

    final headers = await _authHeaders();
    final query = <String, dynamic>{
      'page': page,
      if (search != null && search.isNotEmpty) 'consignment_no': search,
      if (clientId != null) 'client_id': clientId,
      if (status != null && status.isNotEmpty) 'status': status,
      if (fromDate != null && fromDate.isNotEmpty) 'date_from': fromDate,
      if (toDate != null && toDate.isNotEmpty) 'date_to': toDate,
    };

    try {
      final res = await _mainDio.get(
        '/stock-out',
        queryParameters: query,
        options: Options(headers: headers),
      );
      final payload = res.data;
      if (payload is Map) {
        return {
          'data': payload['data'] ?? [],
          'current_page': payload['current_page'] ?? 1,
          'last_page': payload['last_page'] ?? 1,
        };
      }
      return {'data': [], 'current_page': 1, 'last_page': 1};
    } on DioException catch (e) {
      _snack(
        context,
        e.response?.data?['message']?.toString() ??
            'Failed to load Stock-Out list.',
      );
      return {'data': [], 'current_page': 1, 'last_page': 1};
    }
  }

  /// Get Stock-Out detail by ID
  Future<Map<String, dynamic>?> getStockOutDetail(
    BuildContext context, {
    required int stockOutId,
  }) async {
    if (!await _hasConnection()) {
      _snack(context, 'No internet connection.');
      return null;
    }
    if (!await _isBackendReachable()) {
      _snack(context, 'Cannot reach server.');
      return null;
    }

    final headers = await _authHeaders();

    try {
      final res = await _mainDio.get(
        '/stock-out/$stockOutId',
        options: Options(headers: headers),
      );
      return res.data is Map ? Map<String, dynamic>.from(res.data) : null;
    } on DioException catch (e) {
      _snack(
        context,
        e.response?.data?['message']?.toString() ??
            'Failed to load Stock-Out detail.',
      );
      return null;
    }
  }

  /// Create Stock-Out draft
  Future<Map<String, dynamic>?> createStockOut(
    BuildContext context, {
    required String consignmentNumber,
    required int clientId,
    required int picId,
    int? checkerId,
    required String stockOutDate,
    String? remarks,
  }) async {
    if (!await _hasConnection()) {
      _snack(context, 'No internet connection.');
      return null;
    }
    if (!await _isBackendReachable()) {
      _snack(context, 'Cannot reach server.');
      return null;
    }

    final headers = await _authHeaders();

    try {
      final res = await _mainDio.post(
        '/stock-out',
        data: {
          'ConsignmentNumber': consignmentNumber,
          'ClientID': clientId,
          'PIC_ID': picId,
          if (checkerId != null) 'Checker_ID': checkerId,
          'StockOutDate': stockOutDate,
          if (remarks != null && remarks.isNotEmpty) 'Remarks': remarks,
        },
        options: Options(headers: headers),
      );
      return res.data is Map ? Map<String, dynamic>.from(res.data) : null;
    } on DioException catch (e) {
      final errMsg =
          e.response?.data?['message']?.toString() ??
          e.response?.data?['errors']?['ConsignmentNumber']?.first
              ?.toString() ??
          'Failed to create Stock-Out.';
      _snack(context, errMsg);
      return null;
    }
  }

  /// Add lot to Stock-Out
  Future<bool> addLotToStockOut(
    BuildContext context, {
    required int stockOutId,
    required String lotNumber,
  }) async {
    if (!await _hasConnection()) {
      _snack(context, 'No internet connection.');
      return false;
    }
    if (!await _isBackendReachable()) {
      _snack(context, 'Cannot reach server.');
      return false;
    }

    final headers = await _authHeaders();

    try {
      await _mainDio.post(
        '/stock-out/$stockOutId/details',
        data: {'LotNumber': lotNumber},
        options: Options(headers: headers),
      );
      return true;
    } on DioException catch (e) {
      _snack(
        context,
        e.response?.data?['message']?.toString() ?? 'Failed to add lot.',
      );
      return false;
    }
  }

  /// Remove lot from Stock-Out
  Future<bool> removeLotFromStockOut(
    BuildContext context, {
    required int stockOutId,
    required int detailId,
  }) async {
    if (!await _hasConnection()) {
      _snack(context, 'No internet connection.');
      return false;
    }
    if (!await _isBackendReachable()) {
      _snack(context, 'Cannot reach server.');
      return false;
    }

    final headers = await _authHeaders();

    try {
      await _mainDio.delete(
        '/stock-out/details/$detailId',
        options: Options(headers: headers),
      );
      return true;
    } on DioException catch (e) {
      _snack(
        context,
        e.response?.data?['message']?.toString() ?? 'Failed to remove lot.',
      );
      return false;
    }
  }

  /// Confirm Stock-Out (change status from Draft to Supplied)
  Future<bool> confirmStockOut(
    BuildContext context, {
    required int stockOutId,
  }) async {
    if (!await _hasConnection()) {
      _snack(context, 'No internet connection.');
      return false;
    }
    if (!await _isBackendReachable()) {
      _snack(context, 'Cannot reach server.');
      return false;
    }

    final headers = await _authHeaders();

    try {
      await _mainDio.post(
        '/stock-out/$stockOutId/confirm',
        options: Options(headers: headers),
      );
      return true;
    } on DioException catch (e) {
      _snack(
        context,
        e.response?.data?['message']?.toString() ??
            'Failed to confirm Stock-Out.',
      );
      return false;
    }
  }

  /// Delete Stock-Out (admin only)
  Future<bool> deleteStockOut(
    BuildContext context, {
    required int stockOutId,
  }) async {
    if (!await _hasConnection()) {
      _snack(context, 'No internet connection.');
      return false;
    }
    if (!await _isBackendReachable()) {
      _snack(context, 'Cannot reach server.');
      return false;
    }

    final headers = await _authHeaders();

    try {
      await _mainDio.delete(
        '/stock-out/$stockOutId',
        options: Options(headers: headers),
      );
      return true;
    } on DioException catch (e) {
      _snack(
        context,
        e.response?.data?['message']?.toString() ??
            'Failed to delete Stock-Out.',
      );
      return false;
    }
  }

  /// Validate lot number for Stock-Out
  Future<Map<String, dynamic>?> validateLot(
    BuildContext context, {
    required String lotNumber,
  }) async {
    if (!await _hasConnection()) return null;
    if (!await _isBackendReachable()) return null;

    final headers = await _authHeaders();

    try {
      final res = await _mainDio.get(
        '/lot-numbers/validate',
        queryParameters: {'lot_number': lotNumber},
        options: Options(headers: headers),
      );
      return res.data is Map ? Map<String, dynamic>.from(res.data) : null;
    } catch (_) {
      return null;
    }
  }
}
