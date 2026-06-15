import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = 'https://sio-be.mysztechnology.com';
  static const String _apiBaseUrl = '$_baseUrl/api';
  static const int _stockInPageSize = 15;
  static const int _bulkFetchSize = 500;

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ),
      _mainDio = Dio(
        BaseOptions(
          baseUrl: _apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ),
      _healthDio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {'Accept': 'application/json'},
        ),
      ) {
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

  final Dio _dio;
  final Dio _mainDio;
  final Dio _healthDio;

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
      final res = await _healthDio.get(
        '/up',
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

  Map<String, dynamic> _mapPayload(dynamic payload) {
    return payload is Map ? Map<String, dynamic>.from(payload) : {};
  }

  List<Map<String, dynamic>> _mapList(dynamic payload) {
    if (payload is! List) return const [];

    return payload
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> _extractDataMap(dynamic payload) {
    final map = _mapPayload(payload);
    return map['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(map['data'])
        : map['data'] is Map
        ? Map<String, dynamic>.from(map['data'])
        : {};
  }

  List<Map<String, dynamic>> _extractDataList(dynamic payload) {
    final map = _mapPayload(payload);

    if (map['data'] is List) {
      return _mapList(map['data']);
    }

    return _mapList(payload);
  }

  String _errorMessage(DioException error, String fallback) {
    final payload = _mapPayload(error.response?.data);
    final message = payload['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return message;

    final errors = payload['errors'];
    if (errors is Map) {
      final text = errors.values
          .expand((v) => v is List ? v : [v])
          .map((v) => v.toString())
          .where((v) => v.trim().isNotEmpty)
          .join('\n');
      if (text.isNotEmpty) return text;
    }

    return fallback;
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    return token.isEmpty ? {} : {'Authorization': 'Bearer $token'};
  }

  bool _isWithinDate(String? dateValue, String? fromDate, String? toDate) {
    if (dateValue == null || dateValue.isEmpty) return true;

    final normalized = dateValue.split('T').first;
    if (fromDate != null &&
        fromDate.isNotEmpty &&
        normalized.compareTo(fromDate) < 0) {
      return false;
    }
    if (toDate != null &&
        toDate.isNotEmpty &&
        normalized.compareTo(toDate) > 0) {
      return false;
    }

    return true;
  }

  Future<List<Map<String, dynamic>>> _fetchStockIns({
    int perPage = _bulkFetchSize,
  }) async {
    final headers = await _authHeaders();
    final res = await _mainDio.get(
      '/stock-ins',
      queryParameters: {'per_page': perPage},
      options: Options(headers: headers),
    );

    return _extractDataList(res.data);
  }

  Map<String, dynamic> _toLegacyStockInRow(Map<String, dynamic> item) {
    final lines = _mapList(item['lines']);
    final totalQuantity = lines.fold<int>(0, (sum, line) {
      return sum + (int.tryParse('${line['received_qty'] ?? 0}') ?? 0);
    });

    return {
      'id': item['id'],
      'DO_Number': item['stock_in_number'],
      'SupplierName': item['supplier_name'] ?? '-',
      'ReceiveDate': item['stock_in_date']?.toString().split('T').first ?? '',
      'TotalProducts': lines.length,
      'TotalQuantity': totalQuantity,
    };
  }

  Future<Map<String, dynamic>?> _findStockInByNumber(
    String stockInNumber,
  ) async {
    final items = await _fetchStockIns();

    try {
      return items.firstWhere(
        (item) => item['stock_in_number']?.toString() == stockInNumber,
      );
    } catch (_) {
      return null;
    }
  }

  String _stockItemStatus(Map<String, dynamic> stockItem) {
    final currentStatus = stockItem['current_status']?.toString();
    if (currentStatus != null && currentStatus.isNotEmpty) {
      return currentStatus
          .split('_')
          .map((part) {
            if (part.isEmpty) return part;
            return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
          })
          .join(' ');
    }

    return (stockItem['is_available'] == true) ? 'Available' : 'Unavailable';
  }

  List<Map<String, dynamic>> _toLegacyLots(Map<String, dynamic> stockInData) {
    final lines = _mapList(stockInData['lines']);
    final lots = <Map<String, dynamic>>[];

    for (final line in lines) {
      final stockItems = _mapList(line['stock_items']);
      for (final item in stockItems) {
        lots.add({
          'ProductName': line['product_name'] ?? '-',
          'RefNum': line['product_code'] ?? '',
          'LotNumber': item['serial_number'] ?? '-',
          'ExpiryDate': '',
          'Status': _stockItemStatus(item),
        });
      }
    }

    return lots;
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
        data: {
          'email': email,
          'password': password,
          'device_name': 'flutter-app',
        },
      );

      final payload = _mapPayload(res.data);
      final data = _extractDataMap(payload);
      final token = data['access_token']?.toString();
      final user = data['user'] is Map
          ? Map<String, dynamic>.from(data['user'])
          : null;

      if (res.statusCode == 200 && token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        if (user != null) {
          await prefs.setString('user_role', user['role']?.toString() ?? '');
          await prefs.setString('user_name', user['name']?.toString() ?? '');
          await prefs.setInt('user_id', int.tryParse('${user['id']}') ?? 0);
        }

        // Preserve the legacy shape expected by the current login screen.
        payload['token'] = token;
        if (user != null) payload['user'] = user;
        res.data = payload;
      }

      return res;
    } on DioException catch (e) {
      _snack(context, _errorMessage(e, 'Invalid credentials.'));
      return null;
    }
  }

  Future<void> logout() async {
    final headers = await _authHeaders();
    final prefs = await SharedPreferences.getInstance();

    try {
      await _dio.post('/logout', options: Options(headers: headers));
    } catch (_) {}

    await prefs.remove('token');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    await prefs.remove('user_id');
  }

  Future<List<Map<String, dynamic>>> getStockInList(
    BuildContext context, {
    int page = 1,
    String? search,
    String? fromDate,
    String? toDate,
  }) async {
    final result = await getStockInListFull(
      context,
      page: page,
      search: search,
      fromDate: fromDate,
      toDate: toDate,
    );

    final items = result['data'] as List? ?? const [];
    return items
        .whereType<Map>()
        .map((item) => _toLegacyStockInRow(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Map<String, dynamic>> getDoLots(
    BuildContext context, {
    required String doId,
  }) async {
    if (!await _hasConnection()) {
      _snack(context, 'No internet connection.');
      return {'header': {}, 'lots': []};
    }
    if (!await _isBackendReachable()) {
      _snack(context, 'Cannot reach server.');
      return {'header': {}, 'lots': []};
    }

    try {
      final stockIn = await _findStockInByNumber(doId);
      if (stockIn == null) {
        return {'header': {}, 'lots': []};
      }

      final detail = await getStockInDetail(
        context,
        id: int.tryParse('${stockIn['id']}') ?? 0,
      );

      final data = detail?['data'] is Map
          ? Map<String, dynamic>.from(detail!['data'])
          : <String, dynamic>{};
      final lots = _toLegacyLots(data);
      final header = {
        'DO_Number': data['stock_in_number'] ?? doId,
        'TotalLots': lots.length,
        'SupplierName': data['supplier_name'] ?? '-',
        'ReceiveDate': data['stock_in_date']?.toString().split('T').first ?? '',
      };

      return {'header': header, 'lots': lots};
    } on DioException catch (e) {
      _snack(context, _errorMessage(e, 'Failed to load DO details.'));
      return {'header': {}, 'lots': []};
    }
  }

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

    try {
      final items = await _fetchStockIns();
      final q = search?.trim().toLowerCase() ?? '';

      final filtered = items.where((item) {
        final stockInNumber =
            item['stock_in_number']?.toString().toLowerCase() ?? '';
        final supplierName =
            item['supplier_name']?.toString().toLowerCase() ?? '';
        final matchesText =
            q.isEmpty || stockInNumber.contains(q) || supplierName.contains(q);
        final matchesDate = _isWithinDate(
          item['stock_in_date']?.toString(),
          fromDate,
          toDate,
        );
        final matchesSupplier =
            supplierId == null ||
            '${item['supplier_id']}' == supplierId.toString();
        final lines = _mapList(item['lines']);
        final matchesProduct =
            productId == null ||
            lines.any(
              (line) => '${line['product_id']}' == productId.toString(),
            );
        final matchesBatch = batch == null || batch.trim().isEmpty;

        return matchesText &&
            matchesDate &&
            matchesSupplier &&
            matchesProduct &&
            matchesBatch;
      }).toList();

      final lastPage = filtered.isEmpty
          ? 1
          : ((filtered.length - 1) ~/ _stockInPageSize) + 1;
      final safePage = page.clamp(1, lastPage);
      final start = (safePage - 1) * _stockInPageSize;
      final end = (start + _stockInPageSize).clamp(0, filtered.length);
      final pageItems = filtered.sublist(start, end);

      return {
        'data': pageItems,
        'current_page': safePage,
        'last_page': lastPage,
      };
    } on DioException catch (e) {
      _snack(context, _errorMessage(e, 'Failed to load Stock-In list.'));
      return {'data': [], 'current_page': 1, 'last_page': 1};
    }
  }

  Future<Map<String, dynamic>?> getStockInDetail(
    BuildContext context, {
    required int id,
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
        '/stock-ins/$id',
        options: Options(headers: headers),
      );
      return _mapPayload(res.data);
    } on DioException catch (e) {
      _snack(context, _errorMessage(e, 'Failed to load DO details.'));
      return null;
    }
  }

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
      'stock_in_number': doNumber,
      'supplier_id': supplierId,
      'stock_in_date': receiveDate,
      'lines': items.map((item) {
        return {
          'product_id': item['ProductID'],
          'received_qty': item['QuantityReceived'],
          'remarks': item['Remarks'] ?? '',
          'allow_generated_serials': true,
        };
      }).toList(),
    };

    try {
      final res = await _mainDio.post(
        '/stock-ins',
        data: payload,
        options: Options(headers: headers),
      );
      return _mapPayload(res.data);
    } on DioException catch (e) {
      _snack(context, _errorMessage(e, 'Failed to create Stock-In.'));
      return null;
    }
  }

  Future<bool> deleteStockInDo(BuildContext context, String doNumber) async {
    _snack(context, 'Delete stock-in is not supported by the current backend.');
    return false;
  }

  Future<Map<String, dynamic>> getStockInDoLots(
    BuildContext context, {
    required String doNumber,
  }) async {
    final result = await getDoLots(context, doId: doNumber);
    final lots = (result['lots'] as List?) ?? const [];
    final header = Map<String, dynamic>.from(result['header'] ?? {});

    return {
      'DO_Number': header['DO_Number'] ?? doNumber,
      'TotalLots': header['TotalLots'] ?? lots.length,
      'Lots': lots,
    };
  }

  Future<List<Map<String, dynamic>>> getSuppliers(BuildContext context) async {
    if (!await _hasConnection()) return [];
    if (!await _isBackendReachable()) return [];

    final headers = await _authHeaders();

    try {
      final res = await _mainDio.get(
        '/suppliers',
        queryParameters: {'per_page': _bulkFetchSize},
        options: Options(headers: headers),
      );

      return _extractDataList(res.data).map((supplier) {
        return {
          'SupplierID': supplier['id'],
          'SupplierName': supplier['supplier_name'] ?? '-',
          'SupplierCode': supplier['supplier_code'] ?? '',
          'Status': supplier['status'] ?? '',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPics(BuildContext context) async {
    final user = await getCurrentUser(context);
    if (user == null || user.isEmpty) return [];

    final data = user['data'] is Map
        ? Map<String, dynamic>.from(user['data'])
        : user;

    return [
      {
        'UserID': data['id'],
        'FullName': data['name'] ?? '-',
        'Email': data['email'] ?? '',
        'Role': data['role'] ?? '',
        'Status': data['status'] ?? '',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> getClients(BuildContext context) async {
    return [];
  }

  Future<List<Map<String, dynamic>>> searchProducts(
    BuildContext context, {
    String? search,
    int? supplierId,
  }) async {
    if (!await _hasConnection()) return [];
    if (!await _isBackendReachable()) return [];

    final headers = await _authHeaders();
    final query = <String, dynamic>{
      'per_page': 50,
      if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
      if (supplierId case final supplierId?) 'supplier_id': supplierId,
    };

    try {
      final res = await _mainDio.get(
        '/products',
        queryParameters: query,
        options: Options(headers: headers),
      );

      return _extractDataList(res.data).map((product) {
        return {
          'ProductID': product['id'],
          'ProductName': product['product_name'] ?? '-',
          'ProductCode': product['product_code'] ?? '',
          'SupplierID': product['supplier_id'],
          'Status': product['status'] ?? '',
          'RequiresSerialNumber': product['requires_serial_number'] == true,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser(BuildContext context) async {
    if (!await _hasConnection()) return null;
    if (!await _isBackendReachable()) return null;

    final headers = await _authHeaders();

    try {
      final res = await _mainDio.get('/me', options: Options(headers: headers));
      return _mapPayload(res.data);
    } catch (_) {
      return null;
    }
  }
}
