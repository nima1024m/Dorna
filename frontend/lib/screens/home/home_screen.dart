import 'package:dorna/services/keyboard_service.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/home/home_switch_view.dart';
import 'package:dorna/widgets/home/keyboard_status_view.dart';
import 'package:dorna/widgets/home/settings_view.dart';
import 'package:dorna/widgets/ui/custom_form_input.dart';
import 'package:dorna/widgets/ui/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';

import '../../controllers/keyboard_status/keyboard_status_controller.dart';
import '../../controllers/podcast/podcast_controller.dart';
import '../../widgets/ui/app_colors.dart';
import '../../widgets/ui/custom_list_tile.dart';
import '../languages/languages_screen.dart';
import '../tones/tones_screen.dart';

enum HomeViewType {
  keyboard,
  settings,
}

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  HomeViewType selectedHomeViewType = HomeViewType.keyboard;
  final KeyboardStatusController keyboardStatusController = Get.find();
  final PodcastController controller = Get.put(PodcastController());
  final PageController pageController = PageController(initialPage: 0);
  final KeyboardService _keyboardService = KeyboardService();

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool hasText = false;

  onHomeTypeChange(HomeViewType homeViewType) {
    setState(() {
      selectedHomeViewType = homeViewType;
    });
    pageController.animateToPage(
      homeViewType == HomeViewType.keyboard ? 0 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void onTextFieldTap() async {
    // await Utils.handleKeyboardPermissionNavigation(
    //     navigateToHomeOnGrantPermission: false);
  }

  void onTryKeyboardTap() async {
    bool hasAccess = await Utils.handleKeyboardPermissionNavigation(
        navigateToHomeOnGrantPermission: false);
    if (hasAccess) {
      _focusNode.requestFocus();
    }
  }

  void onKeyboardLanguagesTap() {
    Get.toNamed(LanguagesScreen.routeName);
  }

  void onWritingTonesTap() {
    Get.toNamed(TonesScreen.routeName);
  }

  void init() async {
    await keyboardStatusController.init();
    keyboardStatusController.retryHealthCheck();
    keyboardStatusController.initConnectivityMonitoring();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      keyboardStatusController.checkOnlyKeyboardHealth();
    }
  }

  @override
  void dispose() {
    keyboardStatusController.cancelRetryHealthCheck();
    keyboardStatusController.cancelConnectivitySubscription();
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      init();
    });
    WidgetsBinding.instance.addObserver(this);
    _textController.addListener(() {
      if (_textController.text.isNotEmpty && !hasText) {
        setState(() {
          hasText = true;
        });
      }
      if (_textController.text.isEmpty && hasText) {
        setState(() {
          hasText = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var padding = const EdgeInsets.symmetric(horizontal: 16);
    bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    bool isSmallScreen = Utils.isSmallDevice(context);
    Utils.appContext = context;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0, -0.2),
                  end: Offset.zero,
                ).animate(animation);
                return ClipRect(
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.vertical,
                    child: SlideTransition(
                      position: slide,
                      child: child,
                    ),
                  ),
                );
              },
              child: (isKeyboardOpen && isSmallScreen)
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: padding,
                      child: const Header(),
                    ),
            ),
            if (isKeyboardOpen && isSmallScreen)
              const SizedBox.shrink()
            else
              const SizedBox(height: 24),
            Padding(
              padding: padding,
              child: HomeSwitchView(
                selectedHomeViewType: selectedHomeViewType,
                onHomeTypeChange: onHomeTypeChange,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PageView(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  buildKeyboardView(context, isSmallScreen, padding),
                  Padding(
                    padding: padding,
                    child: const SettingsView(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildKeyboardView(
    BuildContext context,
    bool isSmallScreen,
    EdgeInsets padding,
  ) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        const KeyboardStatusView(),
        Expanded(
          child: Padding(
            padding: padding,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: AppColors.primaryColor().withOpacity(0.05),
                          border: GradientBoxBorder(
                            gradient: LinearGradient(colors: [
                              AppColors.primaryColor(),
                              const Color(0xff05C1E2),
                            ]),
                            width: 2,
                          ),
                        ),
                        child: CustomFormInput(
                          scrollController: _scrollController,
                          controller: _textController,
                          inputFocusNode: _focusNode,
                          textInputAction: TextInputAction.newline,
                          keyboardType: TextInputType.multiline,
                          contentPadding: const EdgeInsets.all(20),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 14.sp,
                                    color: AppColors.textMain(),
                                  ),
                          hintText:
                              'Type or select a text to translate, correct grammar mistakes or re-write the tone.',
                          hintStyle:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: isDarkMode
                                        ? Colors.white.withOpacity(0.5)
                                        : AppColors.greySubtext(),
                                    fontSize: 14.sp,
                                  ),
                          minLines: isSmallScreen ? 5 : 7,
                          maxLines: isSmallScreen ? 5 : 7,
                          onTap: onTextFieldTap,
                          borderColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                              width: 0,
                            ),
                          ),
                        ),
                      ),
                      if (!hasText)
                        const Positioned(
                          bottom: 16,
                          left: 16,
                          child: Row(
                            children: [
                              HomeItemView(
                                iconPath: 'assets/icons/ic_translate.svg',
                              ),
                              SizedBox(width: 12),
                              HomeItemView(
                                iconPath: 'assets/icons/ic_grammer.svg',
                              ),
                              SizedBox(width: 12),
                              HomeItemView(
                                iconPath: 'assets/icons/ic_tone.svg',
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CustomListTile(
                  title: 'Keyboard Languages',
                  onTap: onKeyboardLanguagesTap,
                ),
                const SizedBox(height: 24),
                CustomListTile(
                  title: 'Writing Tones',
                  onTap: onWritingTonesTap,
                ),
                const Spacer(),
                if (MediaQuery.viewInsetsOf(context).bottom < 1)
                  Center(
                    child: GestureDetector(
                      onTap: onTryKeyboardTap,
                      child: Container(
                        padding: const EdgeInsets.only(
                            bottom: 32.0, top: 8, left: 16, right: 16),
                        color: Colors.transparent,
                        child: Column(
                          children: [
                            Text(
                              'Try keyboard',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge!
                                  .copyWith(
                                    color: AppColors.primaryColor(),
                                    fontSize: 18.sp,
                                      fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 16),
                            SvgPicture.asset(
                              'assets/icons/ic_keyboard.svg',
                              width: 45,
                              height: 45,
                              color: AppColors.primaryColor(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HomeItemView extends StatelessWidget {
  final String iconPath;
  final VoidCallback? onTap;

  const HomeItemView({Key? key, required this.iconPath, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
              color: isDarkMode
                  ? const Color(0x1F82D233)
                  : const Color(0xFFB0D4F6),
              width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: SvgPicture.asset(
            iconPath,
            width: 28,
            height: 28,
            color: AppColors.primaryColor(),
          ),
        ),
      ),
    );
  }
}
