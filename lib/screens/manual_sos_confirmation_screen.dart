import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/sos_provider.dart';
import '../theme/app_theme.dart';

class ManualSosConfirmationScreen extends StatefulWidget {
  const ManualSosConfirmationScreen({super.key});

  @override
  State<ManualSosConfirmationScreen> createState() =>
      _ManualSosConfirmationScreenState();
}

class _ManualSosConfirmationScreenState
    extends State<ManualSosConfirmationScreen> {
  static const _initialSeconds = 10;

  Timer? _timer;
  int _secondsLeft = _initialSeconds;
  bool _isSending = false;
  bool _isSent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isSending || _isSent) {
        return;
      }
      if (_secondsLeft <= 1) {
        _send();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _send() async {
    if (_isSending || _isSent) {
      return;
    }

    _timer?.cancel();
    setState(() {
      _isSending = true;
      _error = null;
      _secondsLeft = 0;
    });

    try {
      await Provider.of<SOSProvider>(context, listen: false).sendSOS();
      if (!mounted) {
        return;
      }
      setState(() {
        _isSending = false;
        _isSent = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSending = false;
        _error = error.toString();
      });
    }
  }

  void _cancel() {
    _timer?.cancel();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = _secondsLeft / _initialSeconds;

    return Scaffold(
      backgroundColor: AppColors.emergency,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton.filled(
                  onPressed: _isSending ? null : _cancel,
                  icon: const Icon(Icons.close),
                  tooltip: 'İptal et',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isSent ? Icons.check : Icons.sos,
                  color: Colors.white,
                  size: 52,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _isSent ? 'SOS gönderildi' : 'Acil durum bildirimi',
                style: textTheme.displayMedium?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _isSent
                    ? 'Acil durum kişilerine uygulama bildirimi iletildi.'
                    : 'Yanlışlıkla bastıysan süre dolmadan iptal edebilirsin.',
                style: textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 34),
              if (!_isSent) ...[
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 132,
                      height: 132,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _isSending ? '...' : '$_secondsLeft',
                      style: textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 42,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
              ],
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SOS gönderilemedi: $_error',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending
                      ? null
                      : _isSent
                      ? () => Navigator.of(context).pop(true)
                      : _send,
                  icon: Icon(_isSent ? Icons.done : Icons.send),
                  label: Text(_isSent ? 'Tamam' : 'Şimdi gönder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.emergency,
                  ),
                ),
              ),
              if (!_isSent) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSending ? null : _cancel,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('İptal et'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
