import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grocery_app/controllers/language_controller.dart';
import '../../generated/l10n.dart';

class TranslatePage extends StatelessWidget {
  const TranslatePage({Key? key}) : super(key: key);

  final List<Map<String, String>> languages = const [
    {'name': 'English', 'code': 'en'},
    {'name': 'ខ្មែរ', 'code': 'km'},
  ];

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).select_language)),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final lang = languages[index];
          final code = lang['code']!;
          final name = lang['name']!;

          return Obx(() {
            final isSelected =
                languageController.currentLanguageCode.value == code;

            return ListTile(
              title: Text(name),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                languageController.setLanguage(name, code);
                Navigator.pop(context);
              },
            );
          });
        },
      ),
    );
  }
}
