import 'package:dorna/screens/settings/privacy_policy_screen.dart';
import 'package:dorna/screens/settings/terms_screen.dart';
import 'package:dorna/widgets/ui/back_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../widgets/ui/app_colors.dart';
import '../../widgets/ui/custom_list_tile.dart';

class TermsAndPrivacyScreen extends StatelessWidget {
  static const String routeName = '/terms_and_privacy_screen';

  const TermsAndPrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const BackHeader(title: 'Terms and Privacy'),
              const SizedBox(height: 24),
              CustomListTile(
                title: 'Terms and conditions',
                onTap: () {
                  Get.toNamed(TermsScreen.routeName);
                },
                leading: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: SvgPicture.asset(
                    'assets/icons/ic_terms.svg',
                    width: 18,
                    height: 18,
                    color: AppColors.textMain(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomListTile(
                title: 'Privacy policy',
                onTap: () {
                  Get.toNamed(PrivacyPolicyScreen.routeName);
                },
                leading: SvgPicture.asset(
                  'assets/icons/ic_privacy.svg',
                  width: 22,
                  height: 22,
                  color: AppColors.textMain(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
