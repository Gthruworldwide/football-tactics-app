import 'package:flutter/material.dart';

import '../../core/services/app_language.dart';

class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = AppLanguage.instance.locale.languageCode;
    return PopupMenuButton<String>(
      tooltip: selected == 'ar' ? 'تغيير اللغة' : 'Change language',
      icon: const Icon(Icons.language, color: Colors.white),
      onSelected: AppLanguage.instance.setLanguage,
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: 'ar',
          checked: selected == 'ar',
          child: const Text('العربية'),
        ),
        CheckedPopupMenuItem(
          value: 'en',
          checked: selected == 'en',
          child: const Text('English'),
        ),
      ],
    );
  }
}
