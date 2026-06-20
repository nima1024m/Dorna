import 'package:dorna/screens/settings/terms_screen.dart';
import 'package:dorna/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../screens/settings/privacy_policy_screen.dart';
import '../ui/custom_underline_text.dart';

class TermsPrivacyFooter extends StatelessWidget {

  const TermsPrivacyFooter({
    super.key,
  });

  onTermsTap() {
    Get.toNamed(TermsScreen.routeName);
  }

  onPrivacyTap() {
    Get.toNamed(PrivacyPolicyScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    var style = Theme.of(context).textTheme.bodySmall!.copyWith(
          fontSize: 12.sp,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Column(
      children: [
        Text(
          'By installing, you are agreeing to Dorna\'s',
          style: style,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onTermsTap,
              child: CustomUnderlineText(
                'Terms of Service',
                style: style,
              ),
            ),
            Text(
              ' and ',
              style: style,
            ),
            GestureDetector(
              onTap: onPrivacyTap,
              child: CustomUnderlineText(
                'Privacy Policy',
                style: style,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
