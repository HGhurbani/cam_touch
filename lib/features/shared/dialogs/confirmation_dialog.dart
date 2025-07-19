// lib/features/shared/dialogs/confirmation_dialog.dart

import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'تأكيد',
    this.cancelText = 'إلغاء',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // إرجاع false عند الإلغاء
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true), // إرجاع true عند التأكيد
          child: Text(confirmText),
        ),
      ],
    );
  }
}