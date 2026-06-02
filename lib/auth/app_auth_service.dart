import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

class AppAuthService {
  AppAuthService._();

  static const _macAuthTokenKey = 'macos_auth_id_token';
  static const _macAuthEmailKey = 'macos_auth_email';

  static bool get usesNativeFirebaseAuth =>
      defaultTargetPlatform != TargetPlatform.macOS;

  static Future<bool> isSignedIn() async {
    if (usesNativeFirebaseAuth) {
      return FirebaseAuth.instance.currentUser != null;
    }

    final prefs = SharedPreferencesAsync();
    final token = await prefs.getString(_macAuthTokenKey);
    return token != null && token.isNotEmpty;
  }

  static Stream<User?> authStateChanges() {
    return FirebaseAuth.instance.authStateChanges();
  }

  static Future<void> register({
    required String email,
    required String password,
  }) async {
    if (usesNativeFirebaseAuth) {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return;
    }

    await _sendMacAuthRequest(
      endpoint: 'signUp',
      email: email,
      password: password,
    );
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (usesNativeFirebaseAuth) {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return;
    }

    await _sendMacAuthRequest(
      endpoint: 'signInWithPassword',
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    if (usesNativeFirebaseAuth) {
      await FirebaseAuth.instance.signOut();
      return;
    }

    final prefs = SharedPreferencesAsync();
    await prefs.remove(_macAuthTokenKey);
    await prefs.remove(_macAuthEmailKey);
  }

  static Future<void> _sendMacAuthRequest({
    required String endpoint,
    required String email,
    required String password,
  }) async {
    final options = DefaultFirebaseOptions.currentPlatform;
    final uri = Uri.https(
      'identitytoolkit.googleapis.com',
      '/v1/accounts:$endpoint',
      {'key': options.apiKey},
    );

    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      final error = data['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? 'AUTH_ERROR';
      throw MacAuthException(message);
    }

    final token = data['idToken'] as String?;
    if (token == null || token.isEmpty) {
      throw const MacAuthException('TOKEN_NOT_RETURNED');
    }

    final prefs = SharedPreferencesAsync();
    await prefs.setString(_macAuthTokenKey, token);
    await prefs.setString(_macAuthEmailKey, email);
  }
}

class MacAuthException implements Exception {
  const MacAuthException(this.code);

  final String code;

  @override
  String toString() => code;
}
