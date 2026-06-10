import 'package:dorna/controllers/auth/auth_controller.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ui/toast.dart';

class DeletePersonalDataDialog extends StatefulWidget {
  const DeletePersonalDataDialog({Key? key}) : super(key: key);

  @override
  State<DeletePersonalDataDialog> createState() =>
      _DeletePersonalDataDialogState();
}

class _DeletePersonalDataDialogState extends State<DeletePersonalDataDialog> {
  final AuthController authController = Get.find();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return CupertinoAlertDialog(
      title: Text(
        'Delete personal data?',
        style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 13.sp,
            ),
      ),
      content: Text(
        'All your personal data will be removed from this account',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12.sp,
            ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: _isSubmitting
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: Text(
            'Cancel',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode
                      ? CupertinoColors.white
                      : CupertinoColors.label,
                  fontSize: 13.sp,
                ),
          ),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: _isSubmitting
              ? null
              : () async {
                  setState(() => _isSubmitting = true);
                  try {
                    final result = await authController.deletePersonalData();

                    if (result == true) {
                      showCustomToast(
                        'Your personal data has been deleted',
                        context,
                        isSuccess: true,
                      );
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    } else if (result == false) {
                      showCustomToast(
                        'Failed to delete personal data. Please try again.',
                        context,
                        isError: true,
                      );
                    }
                  } catch (e) {
                    showCustomToast(
                      e.getDioBackendErrorMessage() ??
                          'Failed to delete personal data. Please try again.',
                      context,
                      isError: true,
                    );
                  } finally {
                    if (mounted) {
                      setState(() => _isSubmitting = false);
                    }
                  }
                },
          child: _isSubmitting
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CupertinoActivityIndicator(),
                    const SizedBox(width: 8),
                    Text(
                      'Deleting…',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppColors.errorText,
                            fontSize: 13.sp,
                          ),
                    ),
                  ],
                )
              : Text(
                  'Delete',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.errorText,
                        fontSize: 13.sp,
                      ),
                ),
        ),
      ],
    );
  }
}
