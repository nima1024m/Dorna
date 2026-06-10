import 'package:dorna/screens/home/home_screen.dart';
import 'package:dorna/services/keyboard_service.dart';
import 'package:dorna/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../controllers/settings/settings_controller.dart';
import '../../widgets/instruction/instruction_background.dart';
import '../../widgets/instruction/instruction_bottom_sheet.dart';
import '../../widgets/instruction/instruction_button.dart';
import '../../widgets/instruction/instruction_card.dart';
import '../../widgets/instruction/instruction_list.dart';
import '../../widgets/instruction/terms_privacy_footer.dart';
import '../../widgets/ui/app_colors.dart';
import 'instruction_collect_data_screen.dart';
import 'instruction_second_screen.dart';

class InstructionFirstScreen extends StatefulWidget {
  const InstructionFirstScreen({super.key});

  static const routeName = '/instruction_first_screen';

  @override
  State<InstructionFirstScreen> createState() => _InstructionFirstScreenState();
}

class _InstructionFirstScreenState extends State<InstructionFirstScreen>
    with WidgetsBindingObserver {
  final SettingsController settingsController = Get.find();
  bool isKeyboardEnabled = false;
  bool justCheckFullAccess = Get.arguments != null
      ? (Get.arguments['justCheckFullAccess'] ?? false)
      : false;
  final KeyboardService _keyboardService = KeyboardService();
  bool loading = false;

  void onSkipTap() {
    Get.offAllNamed(HomeScreen.routeName);
  }

  void onInfoFullAccessTap() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) {
        return const InstructionBottomSheetContent();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkKeyboardStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkKeyboardStatus();
    }
  }

  void _checkKeyboardStatus() async {
    if (justCheckFullAccess) return;
    isKeyboardEnabled = await _keyboardService.isCustomKeyboardEnabled();
    setState(() {});
    if (isKeyboardEnabled) {
      var isCustomKeyboardHasFullAccess =
          await _keyboardService.hasFullAccessRuntime();
      if (isCustomKeyboardHasFullAccess) {
        if (!settingsController.isKeyboardSelected.value) {
          Get.offAllNamed(InstructionSecondScreen.routeName);
        } else if (!settingsController.isCollectDataSeen.value) {
          Get.offAllNamed(InstructionCollectDataScreen.routeName);
        } else {
          Get.offAllNamed(
            HomeScreen.routeName,
          );
        }
      } else {
      }
    }
  }

  onGoToSettingsTap() async {
    await _keyboardService.openKeyboardSettings();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InstructionBackground(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main white card
          InstructionCard(
            width: double.infinity,
            padding:
                const EdgeInsets.only(left: 32, right: 32, top: 50, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 80,
                  color: AppColors.primaryColor(),
                ),
                const SizedBox(height: 24),
                // Heading
                Text(
                  'To fully experience Dorna,\nPlease follow the instructions:',
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(
                        color: AppColors.textMain(),
                        fontSize: 14.sp,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 32),
                // Instructions list
                _buildInstructionsList(),
                const SizedBox(height: 48),
                // Button
                _buildActionButton(context),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: onSkipTap,
                    child: Text(
                      'Skip for now',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDarkMode
                                ? AppColors.textMain().withOpacity(0.4)
                                : AppColors.greySubtext(),
                            fontSize: 13.sp,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Terms and Privacy
          const TermsPrivacyFooter(),
        ],
      ),
    );
  }

  Widget _buildInstructionsList() {
    final instructions = [
      'Go to "Settings" / "Keyboards"',
      'Tap on "Keyboards"',
      'Tap on "Dorna"',
      'Enable "Dorna"',
      'Allow full access',
    ];
    return InstructionList(
      instructions: instructions,
      isCompleted: isKeyboardEnabled,
      activeStep: justCheckFullAccess ? 4 : 0,
      customWidgets: [
        null,
        null,
        null,
        null,
        Row(
          children: [
            Text(
              'Allow full access',
              style: justCheckFullAccess
                  ? Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.textMain(),
                        fontSize: 13.sp,
                      )
                  : Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMain(),
                        fontSize: 13.sp,
                      ),
            ),
            GestureDetector(
              onTap: onInfoFullAccessTap,
              child: Container(
                width: 40,
                height: 20,
                color: Colors.transparent,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_info.svg',
                    width: 20,
                    height: 20,
                    color: AppColors.textMain().withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return InstructionButton(
      onPressed: onGoToSettingsTap,
      text: 'Go to "Keyboards"',
      border: Border.all(color: const Color(0xffFF9500), width: 1.2),
      backgroundColor: Colors.transparent,
      textColor: const Color(0xffFF9500),
      loading: loading,
    );
  }
}
