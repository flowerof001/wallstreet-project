import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_config.dart';

/// 用户 API 服务 — 全部 HTTP 请求真实调用 Python 后端
class UserService {
  static const _tokenKey = 'wallstreet_jwt_token';

  // ---- Token Management ----

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferencesAsync();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferencesAsync();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferencesAsync();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> _get(String url) async {
    final resp = await http.get(
      Uri.parse(url),
      headers: await _authHeaders(),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw _apiError(resp);
  }

  static Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final resp = await http.post(
      Uri.parse(url),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw _apiError(resp);
  }

  static Future<Map<String, dynamic>> _put(
    String url,
    Map<String, dynamic> body,
  ) async {
    final resp = await http.put(
      Uri.parse(url),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw _apiError(resp);
  }

  static Future<Map<String, dynamic>> _delete(String url) async {
    final resp = await http.delete(
      Uri.parse(url),
      headers: await _authHeaders(),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw _apiError(resp);
  }

  static ApiException _apiError(http.Response resp) {
    String msg = 'Request failed: ${resp.statusCode}';
    try {
      final body = jsonDecode(resp.body);
      if (body is Map && body.containsKey('detail')) {
        msg = body['detail'] as String;
      }
    } catch (_) {}
    return ApiException(msg, resp.statusCode);
  }

  // ---- Auth APIs ----

  static Future<void> sendCode(String countryCode, String phone) async {
    await _post(ApiConfig.authSendCode, {
      'country_code': countryCode,
      'phone': phone,
    });
  }

  static Future<User> loginWithCode(
    String countryCode,
    String phone,
    String code,
  ) async {
    final data = await _post(ApiConfig.authLogin, {
      'country_code': countryCode,
      'phone': phone,
      'code': code,
    });
    final token = data['access_token'] as String;
    await saveToken(token);
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  static Future<User?> getMe() async {
    try {
      final token = await getToken();
      if (token == null) return null;
      final data = await _get(ApiConfig.userMe);
      return User.fromJson(data);
    } catch (_) {
      await clearToken();
      return null;
    }
  }

  // ---- User APIs ----

  static Future<Map<String, dynamic>> changePassword({
    String? oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return _post(ApiConfig.userChangePassword, {
      'old_password': oldPassword,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });
  }

  static Future<void> deleteAccount() async {
    await _delete(ApiConfig.userMe);
    await clearToken();
  }

  static Future<void> syncWatchlist(List<String> codes) async {
    await _put(ApiConfig.userWatchlist, {'codes': codes});
  }

  // ---- Market Pages APIs ----

  static Future<List<Map<String, dynamic>>> getPages() async {
    final data = await _get(ApiConfig.userPages);
    return (data as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<Map<String, dynamic>> createPage(String name) async {
    return _post(ApiConfig.userPages, {'name': name});
  }

  static Future<void> deletePage(String pageId) async {
    await _delete('${ApiConfig.userPages}/$pageId');
  }

  static Future<Map<String, dynamic>> addCard(
    String pageId,
    String stockCode, {
    String? stockName,
  }) async {
    return _post(ApiConfig.userPageCards(pageId), {
      'stock_code': stockCode,
      'stock_name': stockName ?? stockCode,
    });
  }

  static Future<void> removeCard(String pageId, String cardId) async {
    await _delete(ApiConfig.userPageCard(pageId, cardId));
  }

  static Future<void> updateCard(
    String pageId,
    String cardId, {
    double? width,
    double? height,
    int? position,
    String? chartType,
  }) async {
    await _put(ApiConfig.userPageCard(pageId, cardId), {
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (position != null) 'position': position,
      if (chartType != null) 'chart_type': chartType,
    });
  }

  // ---- Search APIs ----

  static Future<List<Map<String, dynamic>>> searchStocks(String keyword) async {
    final url = '${ApiConfig.searchStocks}?q=${Uri.encodeComponent(keyword)}';
    final data = await _get(url);
    final results = data['results'] as List?;
    if (results == null) return [];
    return results.cast<Map<String, dynamic>>();
  }

  // ---- Market Data ----

  static Future<List<Map<String, dynamic>>> getKLineHistory(
    String code, {
    String period = 'daily',
    int count = 60,
  }) async {
    final url = ApiConfig.history(code, period: period, count: count);
    final data = await _get(url);
    final kLines = data['k_lines'] as List?;
    if (kLines == null) return [];
    return kLines.cast<Map<String, dynamic>>();
  }
}

/// API 异常
class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(this.message, [this.statusCode = 500]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
