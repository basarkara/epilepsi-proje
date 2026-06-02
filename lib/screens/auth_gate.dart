import 'package:flutter/material.dart';

import '../auth/app_auth_service.dart';
import '../emergency/app_to_app_alert_service.dart';
import 'app_startup_screen.dart';
import 'auth_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.onConfigured});

  final Future<void> Function() onConfigured;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<bool> _firebaseReady;
  int _authRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _firebaseReady = AppToAppAlertService.initializeFirebase();
  }

  Future<void> _handleSignedOut() async {
    if (mounted) {
      setState(() => _authRefreshKey++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _firebaseReady,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != true) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Firebase bağlantısı yapılandırılmamış. Lütfen Firebase ayarlarını kontrol et.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (!AppAuthService.usesNativeFirebaseAuth) {
          return FutureBuilder<bool>(
            key: ValueKey(_authRefreshKey),
            future: AppAuthService.isSignedIn(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState != ConnectionState.done) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (authSnapshot.data == true) {
                return AppStartupScreen(
                  onConfigured: widget.onConfigured,
                  onSignedOut: _handleSignedOut,
                );
              }

              return AuthScreen(
                onSignedIn: () async {
                  await widget.onConfigured();
                  if (mounted) {
                    setState(() => _authRefreshKey++);
                  }
                },
              );
            },
          );
        }

        return StreamBuilder(
          stream: AppAuthService.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (authSnapshot.data == null) {
              return AuthScreen(onSignedIn: widget.onConfigured);
            }

            return AppStartupScreen(
              onConfigured: widget.onConfigured,
              onSignedOut: _handleSignedOut,
            );
          },
        );
      },
    );
  }
}
