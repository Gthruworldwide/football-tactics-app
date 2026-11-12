import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/services/email_verify_service.dart';
import '../core/theme/app_theme.dart';
import 'matches_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nameController = TextEditingController(text: 'Nader Adel');
  final _emailController = TextEditingController();
  String _selectedRole = 'Tactical Analyst';
  bool _isVerifying = false;
  String? _emailError;

  Future<void> _completeLogin() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isVerifying = true;
      _emailError = null;
    });

    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      final check = await EmailVerifyService.verifyEmail(email);
      if (!check.isValid) {
        setState(() {
          _isVerifying = false;
          _emailError = check.message;
        });
        return;
      }
    }

    final box = Hive.isBoxOpen('user_prefs_box')
        ? Hive.box('user_prefs_box')
        : await Hive.openBox('user_prefs_box');

    await box.put('is_logged_in', true);
    await box.put(
      'user_name',
      _nameController.text.trim().isEmpty
          ? 'Analyst'
          : _nameController.text.trim(),
    );
    await box.put('user_email', email);
    await box.put('user_role', _selectedRole);

    if (!mounted) return;
    setState(() => _isVerifying = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MatchesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 36),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.accentEmerald.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.accentEmerald),
                ),
                child: const Icon(Icons.insights_rounded,
                    color: AppTheme.accentEmerald, size: 26),
              ),
              const SizedBox(height: 24),
              const Text(
                'TACTICS ENGINE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppTheme.accentEmerald,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Analyst Workspace Sign In',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure your scouting profile, tracked clubs, and live telemetry feed.',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              // Analyst Name
              _buildLabel('ANALYST NAME'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: _inputDecoration('Enter your name', Icons.person_outline),
              ),
              const SizedBox(height: 20),

              // Email (Optional)
              _buildLabel('EMAIL ADDRESS'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: _inputDecoration('analyst@domain.com', Icons.alternate_email).copyWith(
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 20),

              // Role Selector
              _buildLabel('PRIMARY FOCUS'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['Tactical Analyst', 'Match Scout', 'Data Engineer']
                    .map((role) {
                  final active = _selectedRole == role;
                  return ChoiceChip(
                    label: Text(role),
                    selected: active,
                    selectedColor: AppTheme.accentEmerald.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: active
                          ? AppTheme.accentEmerald
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedRole = role),
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentEmerald,
                    foregroundColor: AppTheme.bgObsidian,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isVerifying ? null : _completeLogin,
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.bgObsidian,
                          ),
                        )
                      : const Text(
                          'ENTER WORKSPACE',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: AppTheme.textSecondary,
        ),
      );

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.accentEmerald, size: 20),
        filled: true,
        fillColor: AppTheme.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.borderSubtle),
        ),
      );
}
