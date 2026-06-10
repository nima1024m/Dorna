import 'dart:async';

import 'package:dorna/services/keyboard_service.dart';
import 'package:dorna/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/settings/settings_controller.dart';
import '../../widgets/instruction/instruction_background.dart';
import '../../widgets/instruction/instruction_button.dart';
import '../../widgets/instruction/instruction_card.dart';
import '../../widgets/instruction/instruction_list.dart';
import '../../widgets/instruction/terms_privacy_footer.dart';
import '../../widgets/ui/app_colors.dart';
import '../home/home_screen.dart';
import 'instruction_collect_data_screen.dart';

class InstructionSecondScreen extends StatefulWidget {
  const InstructionSecondScreen({super.key});

  static const routeName = '/instruction_second_screen';

  @override
  State<InstructionSecondScreen> createState() =>
      _InstructionSecondScreenState();
}

class _InstructionSecondScreenState extends State<InstructionSecondScreen> {
  final SettingsController settingsController = Get.find();
  bool isKeyboardEnabled = false;
  final KeyboardService _keyboardService = KeyboardService();
  final FocusNode _focusNode = FocusNode();
  Timer? _timer;
  bool isKeyboardSelected = false;
  bool loading = false;

  void navigateToNextScreen() async {
    if (!settingsController.isCollectDataSeen.value) {
      Get.offAllNamed(InstructionCollectDataScreen.routeName);
    } else {
      Get.offAllNamed(HomeScreen.routeName);
    }
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (isKeyboardSelected) return;
      _keyboardService.getCurrentSelectedKeyboardName().then((keyboardName) {
        if (isKeyboardSelected) return;
        if (keyboardName == 'Dorna') {
          setState(() {
            isKeyboardSelected = true;
          });
          settingsController.setIsKeyboardSelected(true);
          Future.delayed(const Duration(milliseconds: 1500)).then((t) {
            navigateToNextScreen();
          });
          t.cancel();
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  onOpenKeyboardTap() async {
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return InstructionBackground(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main white card
          InstructionCard(
            width: double.infinity,
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
                // Heading - "Just one more thing..."
                Text(
                  'Just one more thing...',
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
                InstructionButton(
                  onPressed: onOpenKeyboardTap,
                  text: 'Open keyboard',
                  border: Border.all(color: const Color(0xffFF9500), width: 1.5),
                  backgroundColor: Colors.transparent,
                  textColor: const Color(0xffFF9500),
                ),
                Offstage(
                    offstage: true,
                    child: TextField(
                      focusNode: _focusNode,
                    )),
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
      'Tap and hold the ',
      'Tap "Dorna" to switch keyboards',
      'Enjoy writing!',
    ];

    return InstructionList(
      instructions: instructions,
      isCompleted: isKeyboardEnabled,
      activeStep: 0,
      startIndex: 5,
      customWidgets: [
        Row(
          children: [
            Text(
              'Tap and hold the ',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.textMain(),
                    fontSize: 13.sp,
              ),
            ),
            Icon(
              Icons.language,
              color: AppColors.textMain(),
              size: 16,
            ),
          ],
        ),
        null,
        null,
      ],
    );
  }

}
