import 'package:dorna/controllers/auth/auth_controller.dart';
import 'package:dorna/screens/auth/auth_screen.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({Key? key}) : super(key: key);

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final AuthController authController = Get.find();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CupertinoAlertDialog(
      title: Text(
        'Delete account?',
        style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 13.sp,
            ),
      ),
      content: Text(
        'Your account will be deleted and can’t be undone or restored',
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
                  color: cs.onSurface,
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
                    final result = await authController.deleteAccount();

                    if (result == true) {
                      showCustomToast('Your account has been deleted', context,
                          isSuccess: true);
                      // Clear local state and navigate to auth screen
                      await authController.logout(sendLogoutRequest: false);
                      if (mounted) {
                        Navigator.of(context).pop();
                        Get.offAllNamed(AuthScreen.routeName);
                      }
                    } else if (result == false) {
                      showCustomToast(
                        'Failed to delete account. Please try again.',
                        context,
                        isError: true,
                      );
                    }
                  } catch (e) {
                    showCustomToast(
                      e.getDioBackendErrorMessage() ??
                          'Failed to delete account. Please try again.',
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
                            color: cs.error,
                            fontSize: 13.sp,
                          ),
                    ),
                  ],
                )
              : Text(
                  'Delete',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: cs.error,
                        fontSize: 13.sp,
                      ),
                ),
        ),
      ],
    );
  }
}
