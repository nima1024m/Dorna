import 'package:dorna/controllers/auth/auth_controller.dart';
import 'package:dorna/screens/auth/auth_suggestion_screen.dart';
import 'package:dorna/screens/podcast/podcast_onboarding_screen.dart';
import 'package:dorna/widgets/ui/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../screens/auth/profile_screen.dart';

class Header extends StatefulWidget {
  const Header({Key? key}) : super(key: key);

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  final AuthController authController = Get.find();

  onProfileTap() async {
    if (!await authController.isLoggedIn()) {
      Get.toNamed(AuthSuggestionScreen.routeName);
    } else {
      Get.toNamed(ProfileScreen.routeName);
    }
  }

  onPodcastTap() async {
    if (!await authController.isLoggedIn()) {
      Get.toNamed(AuthSuggestionScreen.routeName);
    } else {
      Get.toNamed(PodcastOnboardingScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 24,
          ),
          Row(
            children: [
              Image.asset(
                'assets/images/logotype.png',
                width: 240,
                fit: BoxFit.contain,
                color: cs.primary,
              ),
              const Spacer(),
              SizedBox(
                width: 38,
                height: 38,
                child: CustomButton(
                  onPressed: onPodcastTap,
                  backgroundColor: Colors.transparent,
                  border: Border.all(
                    color: cs.outlineVariant,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  buttonWidget: Center(
                    child: Icon(
                      Icons.podcasts,
                      color: cs.onSurface,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              SizedBox(
                width: 38,
                height: 38,
                child: CustomButton(
                  onPressed: onProfileTap,
                  backgroundColor: Colors.transparent,
                  border: Border.all(
                    color: cs.outlineVariant,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  buttonWidget: Center(
                    child: FutureBuilder(
                        future: authController.isLoggedIn(),
                        builder: (context, data) {
                          bool isLoggedIn = data.data == true;
                          double size = isLoggedIn ? 22 : 20;
                          return SvgPicture.asset(
                            isLoggedIn
                                ? 'assets/icons/ic_user.svg'
                                : 'assets/icons/ic_login.svg',
                            width: size,
                            height: size,
                            color: cs.onSurface,
                          );
                        }),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
