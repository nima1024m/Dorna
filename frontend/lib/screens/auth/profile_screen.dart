import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dorna/screens/auth/change_password_screen.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/auth/delete_account_dialog.dart';
import 'package:dorna/widgets/auth/profile_photo.dart';
import 'package:dorna/widgets/auth/sign_out_dialog.dart';
import 'package:dorna/widgets/ui/app_colors.dart';
import 'package:dorna/widgets/ui/back_header.dart';
import 'package:dorna/widgets/ui/custom_form_input.dart';
import 'package:dorna/widgets/ui/custom_list_tile.dart';
import 'package:dorna/widgets/ui/toast.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../controllers/auth/auth_controller.dart';
import '../../widgets/auth/delete_personal_data_dialog.dart';
import '../../widgets/ui/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile_screen';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController authController = Get.find();
  final TextEditingController _fullNameController = TextEditingController();
  final FocusNode _fullNameFocus = FocusNode();
  bool _isFullNameEditable = false;
  String _originalName = '';
  bool _isUpdatingProfile = false;
  bool _isUpdatingProfileHasError = false;
  bool _lastFocus = false;
  StreamSubscription? _keyboardSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize the name field with user's current name or default
    _initName();

    _fullNameController.addListener(() {
      setState(() {});
    });

    // Listen for focus changes to detect when keyboard closes
    var keyboardVisibilityController = KeyboardVisibilityController();
    _keyboardSubscription =
        keyboardVisibilityController.onChange.listen((bool visible) {
      print('Keyboard visibility update. Is visible: $visible');
      _onFocusChange(visible);
    });
  }

  void _initName() {
    // Initialize the name field with user's current name or default
    final user = authController.getUserDetails;
    _originalName = user.fullName ?? '';
    _fullNameController.text = _originalName;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _fullNameFocus.dispose();
    _keyboardSubscription?.cancel();
    super.dispose();
  }

  void _onFocusChange(bool visible) async {
    debugPrint('mylog visible ${visible} _lastFocus $_lastFocus');
    // When focus is lost (keyboard closes) and name was changed, update profile
    if ((!visible &&
            _lastFocus &&
            _isFullNameEditable &&
            _fullNameController.text.trim() != _originalName &&
            _fullNameController.text.trim().isNotEmpty) ||
        (_isUpdatingProfileHasError &&
            !visible &&
            _lastFocus &&
            _isFullNameEditable)) {
      EasyDebounce.cancel('updateName');
      EasyDebounce.debounce('updateName', const Duration(milliseconds: 600),
          () async {
        if (mounted) {
          setState(() {
            _isUpdatingProfile = true;
          });
        }
        _originalName = _fullNameController.text.trim();

        try {
          final success = await authController.updateProfile(
            name: _fullNameController.text.trim(),
          );

          if (success == true) {
            if (mounted) {
              setState(() {
                _isUpdatingProfileHasError = false;
                _isFullNameEditable = false;
              });
              showCustomToast('Your name updated successfully', context,
                  isSuccess: true);
            }
          } else if (success == false || success == null) {
            if (mounted) {
              setState(() {
                _isUpdatingProfileHasError = true;
              });
            }
          }
        } catch (e) {
          if (e.getDioBackendErrorMessage()?.isNotEmpty == true) {
            showCustomToast(e.getDioBackendErrorMessage()!, context,
                isError: true);
          } else if (e.getDioError()?.response?.statusCode == 500) {
            if (e
                    .getDioError()
                    ?.response
                    ?.data
                    .toString()
                    .contains('invalid_name_characters') ==
                true) {
              showCustomToast(
                  'Invalid name format. Please use only letters and spaces.',
                  context,
                  isError: true);
            } else {
              showNetworkToast(e: e.getDioError()!, context: Utils.appContext!);
            }
          } else if (e.getDioError()?.type != DioExceptionType.cancel) {
            showCustomToast(
                e.getDioBackendErrorMessage() ??
                    'Failed to update profile. Please try again.',
                context,
                isError: true);
          }

          if (mounted) {
            setState(() {
              _isUpdatingProfileHasError = true;
            });
          }

        } finally {
          if (mounted) {
            setState(() {
              _isUpdatingProfile = false;
            });
          }
        }
      });
    } else if (!visible) {
      setState(() {
        _isFullNameEditable = false;
      });
    }
    _lastFocus = visible;
  }

  void _onFullNamePencilTap() {
    _initName();
    setState(() {
      _isFullNameEditable = true;
    });
    _fullNameFocus.requestFocus();
  }

  void _onPasswordPencilTap() {
    Get.toNamed(ChangePasswordScreen.routeName);
  }

  void _onLogoutTap() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return const SignOutDialog();
      },
    );
  }

  void _onDeletePersonalDataTap() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return const DeletePersonalDataDialog();
      },
    );
  }

  void _onDeleteAccountTap() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return const DeleteAccountDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    var padding = const EdgeInsets.symmetric(horizontal: 16);
    Utils.appContext = context;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header with back button and logout
            Padding(
              padding: padding,
              child: BackHeader(
                title: 'Profile',
                trailingWidget: SizedBox(
                  width: 38,
                  height: 38,
                  child: CustomButton(
                    onPressed: _onLogoutTap,
                    backgroundColor: Colors.transparent,
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    buttonWidget: Icon(
                      Icons.logout,
                      color: AppColors.textMain(),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Column(
                  children: [
                    // Profile Picture Section
                    const ProfilePhoto(
                      key: Key('ProfilePhoto'),
                    ),

                    const SizedBox(height: 32),

                    // User Details Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      margin: padding,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.transparent : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email Field (Read-only)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.greySubtext()
                                          .withOpacity(0.5),
                                      fontSize: 13.sp,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Obx(() {
                                var user = authController.getUserDetails;
                                return Text(
                                  user.email.toString(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textMain(),
                                        fontSize: 13.sp,
                                      ),
                                );
                              }),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Full Name Field
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Full name',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.greySubtext()
                                                .withOpacity(0.5),
                                            fontSize: 13.sp,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    _isFullNameEditable
                                        ? CustomFormInput(
                                            controller: _fullNameController,
                                            hintText: 'Enter your full name',
                                            inputFocusNode: _fullNameFocus,
                                            isEnabled: true,
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: AppColors.greySubtext(),
                                                width: 1,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.only(
                                                    bottom: 8),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontSize: 13.sp,
                                                  color: AppColors.textMain(),
                                                ),
                                          )
                                        : Text(
                                            (_originalName.isNotEmpty
                                                ? _originalName
                                                : 'Add your name'),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: AppColors.textMain(),
                                                  fontSize: 13.sp,
                                                ),
                                          ),
                                  ],
                                ),
                              ),
                              if (!_isFullNameEditable) ...[
                                const SizedBox(width: 8),
                                buildEditButton(
                                  onPressed: _onFullNamePencilTap,
                                ),
                              ],
                            ],
                          ),

                          SizedBox(height: _isFullNameEditable ? 16 : 24),

                          // Password Field
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Password',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.greySubtext()
                                                .withOpacity(0.5),
                                            fontSize: 13.sp,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '************',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textMain(),
                                            fontSize: 13.sp,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              buildEditButton(
                                onPressed: _onPasswordPencilTap,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Delete Personal Data Section
                    CustomListTile(
                      title: 'Delete personal data',
                      subtitle:
                          'Remove all personal data linked to your account. You’ll still be able to keep and use your account.',
                      onTap: _onDeletePersonalDataTap,
                    ),

                    const SizedBox(height: 16),

                    // Delete Account Section
                    CustomListTile(
                      title: 'Delete account',
                      subtitle:
                          'Permanently delete your account and all personal data. This action can’t be undone.',
                      onTap: _onDeleteAccountTap,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 14.sp,
                            color: AppColors.errorText,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEditButton({
    required VoidCallback onPressed,
  }) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 38,
      height: 38,
      child: CustomButton(
        onPressed: onPressed,
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
        buttonWidget: SvgPicture.asset(
          'assets/icons/ic_pencil.svg',
          width: 20,
          height: 20,
        ),
      ),
    );
  }
}
