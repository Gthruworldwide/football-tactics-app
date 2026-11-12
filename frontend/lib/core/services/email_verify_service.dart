import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailVerifyResult {
  final bool isValid;
  final String message;

  EmailVerifyResult({required this.isValid, required this.message});
}

class EmailVerifyService {
  static const String _accessKey = '995febc8029e43409f2cc90312bcf45e';
  static const String _baseUrl = 'https://api.apilayer.net/mailboxlayer/api/check';

  static Future<EmailVerifyResult> verifyEmail(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      return EmailVerifyResult(isValid: true, message: 'Skipped');
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl?access_key=$_accessKey&email=${Uri.encodeComponent(cleanEmail)}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 7));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final bool formatValid = data['format_valid'] == true;
        final bool mxFound = data['mx_found'] == true;
        final bool isDisposable = data['disposable'] == true;

        if (!formatValid || !mxFound) {
          final didYouMean = (data['did_you_mean'] ?? '').toString();
          final hint = didYouMean.isNotEmpty ? ' Did you mean $didYouMean?' : '';
          return EmailVerifyResult(
            isValid: false,
            message: 'Invalid email domain or address.$hint',
          );
        }

        if (isDisposable) {
          return EmailVerifyResult(
            isValid: false,
            message: 'Temporary/disposable emails are not allowed.',
          );
        }

        return EmailVerifyResult(isValid: true, message: 'Verified');
      }
    } catch (_) {}

    // في حال تعذر الوصول للخدمة مؤقتاً، نسمح بالمرور إذا كانت صيغة البريد صحيحة
    final basicRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return EmailVerifyResult(
      isValid: basicRegex.hasMatch(cleanEmail),
      message: basicRegex.hasMatch(cleanEmail)
          ? 'Format valid'
          : 'Invalid email format.',
    );
  }
}
