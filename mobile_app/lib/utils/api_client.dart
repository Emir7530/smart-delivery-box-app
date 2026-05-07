part of '../app.dart';

class SmartBoxApiClient {
  SmartBoxApiClient({
    this.baseUrl = const String.fromEnvironment(
      'SMART_BOX_API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8080',
    ),
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    final data = await _post('/api/auth/register', {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'confirmPassword': confirmPassword,
    });
    return AuthSession.fromJson(data);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _post('/api/auth/login', {
      'email': email,
      'password': password,
    });
    return AuthSession.fromJson(data);
  }

  Future<UserProfile> me(String token) async {
    final data = await _get('/api/me', token: token);
    return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _httpClient.post(
      _uri(path),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _get(String path, {required String token}) async {
    final response = await _httpClient.get(
      _uri(path),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _decodeResponse(response);
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final error = body['error'];
    if (error is Map<String, dynamic>) {
      throw SmartBoxApiException(
        error['message']?.toString() ?? 'Request failed.',
      );
    }
    throw SmartBoxApiException('Request failed.');
  }

  void close() {
    _httpClient.close();
  }
}

class SmartBoxApiException implements Exception {
  const SmartBoxApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final UserProfile user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'].toString(),
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      fullName: json['fullName'].toString(),
      email: json['email'].toString(),
      phone: json['phone'].toString(),
    );
  }
}
