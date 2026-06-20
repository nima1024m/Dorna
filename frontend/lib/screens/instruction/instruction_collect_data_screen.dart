import 'package:dorna/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/settings/settings_controller.dart';
import '../../widgets/instruction/instruction_background.dart';
import '../../widgets/instruction/instruction_button.dart';
import '../../widgets/instruction/instruction_card.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/ui/custom_switch_tile.dart';
import '../shell/main_shell.dart';

class InstructionCollectDataScreen extends StatefulWidget {
  const InstructionCollectDataScreen({super.key});

  static const routeName = '/instruction_collect_data_screen';

  @override
  State<InstructionCollectDataScreen> createState() =>
      _InstructionCollectDataScreenState();
}

class _InstructionCollectDataScreenState
    extends State<InstructionCollectDataScreen> {
  final SettingsController settingsController = Get.find();
  bool loading = false;

  void onContinueTap() async {
    settingsController.isCollectDataSeen.value = true;
    settingsController.setCollectData(settingsController.collectData.value);
    settingsController.setCollectDataSeen(true);
    Get.offAllNamed(MainShell.routeName);
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InstructionBackground(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main card
          InstructionCard(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 80,
                  color: cs.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Done and ready to go!',
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(
                        color: cs.onSurface,
                        fontSize: 18.sp,
                      ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Just one last thing...',
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(
                        color: cs.onSurface,
                        fontSize: 14.sp,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We use a smart system to help you get the most out of your daily writing. By learning from your mistakes, we can show you which grammar issues to improve and how to get better at both writing and speaking. Just turn this option on, and we’ll only store your grammar mistakes—never your personal information.',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: cs.onSurface,
                        fontSize: 13.sp,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 32),
                CustomSwitchTile(
                  title: 'Collect data',
                  value: settingsController.collectData.value,
                  onChanged: settingsController.setCollectData,
                  leadingIcon: 'assets/icons/ic_database.svg',
                  subtitle:
                      'You can always disbale this in settings if you change your mind.',
                  margin: EdgeInsets.zero,
                ),

                const SizedBox(height: 48),
                // Button

                InstructionButton(
                  onPressed: onContinueTap,
                  text: 'Continue',
                  loading: loading,
                  border: Border.all(color: DornaColors.warning, width: 1.5),
                  backgroundColor: Colors.transparent,
                  textColor: DornaColors.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
