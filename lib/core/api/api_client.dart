import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tectrackerbpm/features/auth/data/auth_api.dart';
import 'api_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _token;
  AuthResult? _authResult;

  // Getters útiles
  String? get token => _token;
  AuthResult? get authResult => _authResult;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    _authResult = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('auth_result');
  }

  Future<void> saveAuthResult(AuthResult authResult) async {
    _authResult = authResult;
    await saveToken(authResult.token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_result', jsonEncode(authResult.toJson()));
  }

  Future<AuthResult?> loadAuthResult() async {
    if (_authResult != null) return _authResult;

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('auth_result');
    if (jsonString == null || jsonString.isEmpty) return null;

    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    _authResult = AuthResult.fromJson(map);

    // IMPORTANTÍSIMO: aquí dejamos listo el token en memoria
    _token = _authResult!.token;

    return _authResult;
  }

  /// Garantiza token en memoria cuando auth=true
  Future<void> _ensureTokenLoaded() async {
    if (_token != null && _token!.isNotEmpty) return;

    // intenta cargar auth_result (si existe)
    await loadAuthResult();

    // si no existía auth_result, intenta jwt_token
    if (_token == null || _token!.isEmpty) {
      await loadToken();
    }
  }

  Map<String, String> _headers({bool withAuth = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final hasToken = _token != null && _token!.isNotEmpty;

    if (withAuth && hasToken) {
      headers['Authorization'] = 'Bearer $_token';
      final short = _token!.length > 20 ? _token!.substring(0, 20) : _token!;
      // ignore: avoid_print
      print('AUTH HEADER SENT: Bearer $short...');
    } else if (withAuth && !hasToken) {
      // ignore: avoid_print
      print('AUTH HEADER NOT SENT: token vacío/null');
    }

    return headers;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;

    final p = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse(base + p);

    if (query != null && query.isNotEmpty) {
      return uri.replace(queryParameters: query);
    }
    return uri;
  }

  Object? _encodeBody(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
    return jsonEncode(body);
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    if (auth) await _ensureTokenLoaded();
    return http.get(_uri(path, query), headers: _headers(withAuth: auth));
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    if (auth) await _ensureTokenLoaded();
    return http.post(
      _uri(path),
      headers: _headers(withAuth: auth),
      body: _encodeBody(body),
    );
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    if (auth) await _ensureTokenLoaded();
    return http.put(
      _uri(path),
      headers: _headers(withAuth: auth),
      body: _encodeBody(body),
    );
  }

  Future<http.Response> delete(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    if (auth) await _ensureTokenLoaded();
    return http.delete(
      _uri(path),
      headers: _headers(withAuth: auth),
      body: _encodeBody(body),
    );
  }
}
