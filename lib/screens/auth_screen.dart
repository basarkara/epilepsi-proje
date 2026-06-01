import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../emergency/emergency_app_settings_store.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onSignedIn});

  final Future<void> Function() onSignedIn;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _pairingCodeController = TextEditingController();

  EmergencyAppMode _mode = EmergencyAppMode.patient;
  bool _isRegisterMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _pairingCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isRegisterMode) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await EmergencyAppSettingsStore.save(
          EmergencyAppSettings(
            mode: _mode,
            pairingCode: _pairingCodeController.text,
            displayName: _nameController.text,
          ),
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      await widget.onSignedIn();
    } on FirebaseAuthException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_firebaseAuthMessage(error)),
          backgroundColor: AppColors.emergency,
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('İşlem tamamlanamadı: $error'),
          backgroundColor: AppColors.emergency,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _firebaseAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Bu e-posta ile daha önce kayıt olunmuş.';
      case 'invalid-email':
        return 'E-posta adresi geçerli değil.';
      case 'weak-password':
        return 'Şifre daha güçlü olmalı. En az 6 karakter kullan.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'network-request-failed':
        return 'İnternet bağlantısı yok veya Firebase erişilemiyor.';
      default:
        return error.message ?? 'Kimlik doğrulama hatası oluştu.';
    }
  }

  void _toggleMode() {
    setState(() => _isRegisterMode = !_isRegisterMode);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  _isRegisterMode ? 'Hesap oluştur' : 'Giriş yap',
                  style: textTheme.displayLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  _isRegisterMode
                      ? 'E-posta ve şifrenle kayıt ol. Rolünü şimdi seçebilirsin; daha sonra ayarlardan değiştirebilirsin.'
                      : 'Kayıtlı e-posta ve şifrenle devam et.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.grey,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.mail_outline),
                    labelText: 'E-posta',
                    hintText: 'ornek@mail.com',
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty || !email.contains('@')) {
                      return 'Geçerli bir e-posta gir';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    labelText: 'Şifre',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').length < 6) {
                      return 'Şifre en az 6 karakter olmalı';
                    }
                    return null;
                  },
                ),
                if (_isRegisterMode) ...[
                  const SizedBox(height: 24),
                  Text('Rolünü seç', style: textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SegmentedButton<EmergencyAppMode>(
                    segments: const [
                      ButtonSegment(
                        value: EmergencyAppMode.patient,
                        icon: Icon(Icons.personal_injury),
                        label: Text('Hastayım'),
                      ),
                      ButtonSegment(
                        value: EmergencyAppMode.responder,
                        icon: Icon(Icons.volunteer_activism),
                        label: Text('Acil kişiyim'),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (selection) {
                      setState(() => _mode = selection.first);
                    },
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.badge_outlined),
                      labelText: _mode == EmergencyAppMode.patient
                          ? 'Hasta adı'
                          : 'Adın',
                      hintText: _mode == EmergencyAppMode.patient
                          ? 'Örn. Ceren'
                          : 'Örn. Annem',
                    ),
                    validator: (value) {
                      if (!_isRegisterMode) {
                        return null;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return 'İsim gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _pairingCodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.link),
                      labelText: 'Eşleşme kodu',
                      hintText: 'Örn. CEREN2026',
                    ),
                    validator: (value) {
                      if (!_isRegisterMode) {
                        return null;
                      }
                      final code = (value ?? '')
                          .trim()
                          .toUpperCase()
                          .replaceAll(RegExp(r'[^A-Z0-9]'), '');
                      if (code.length < 4) {
                        return 'En az 4 karakterlik kod gir';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isRegisterMode
                                ? Icons.person_add_alt
                                : Icons.login,
                          ),
                    label: Text(_isRegisterMode ? 'Kayıt ol' : 'Giriş yap'),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _toggleMode,
                    child: Text(
                      _isRegisterMode
                          ? 'Zaten hesabın var mı? Giriş yap'
                          : 'Hesabın yok mu? Kayıt ol',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
