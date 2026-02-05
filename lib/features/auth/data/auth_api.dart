import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';

class AuthResult {
  final String token;
  final String userName;
  final String email;
  final String identification;
  final String company;

  AuthResult({
    required this.token,
    required this.userName,
    required this.email,
    required this.identification,
    required this.company,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['Token'] ?? '',
      userName: json['Identification'] ?? '',
      email: json['Email'] ?? '',
      identification: json['DisplayName'] ?? '',
      company: json['Company'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'userName': userName,
      'email': email,
      'identification': identification,
      'company': company,
    };
  }
}

class AuthApi {
  final ApiClient _client = ApiClient();

  Future<AuthResult> login(String username, String password) async {
    final body = {
      "userName": username,
      "password": password,
    };

    final resp = await _client.post(ApiConfig.authLogin, body: body, auth: false);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final auth = AuthResult.fromJson(data);
      if (auth.token.isNotEmpty) {
        await _client.saveAuthResult(auth);
      }
      return auth;
    } else {
      print(resp.body);
      throw Exception('Login failed (${resp.statusCode}): ${resp.body}');
    }
  }

  Future<void> registerDeviceToken(String fcmToken) async {
    await _client.post(
      '/api/Auth/register-device',
      body: {
        'token': fcmToken,
        'platform': 'android',
      },
    );
  }

  Future<void> logout() async {
    await _client.clearToken();
  }
}
