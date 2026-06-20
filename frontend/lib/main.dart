import 'dart:async';
import 'dart:io';

import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:dorna/controllers/keyboard_status/keyboard_status_controller.dart';
import 'package:dorna/routes/routes.dart';
import 'package:dorna/screens/splash/splash_screen.dart';
import 'package:dorna/services/deep_link_service.dart';
import 'package:dorna/services/keyboard_service.dart';
import 'package:dorna/utils/custom_http_override.dart';
import 'package:dorna/widgets/ui/app_colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import 'controllers/auth/auth_controller.dart';
import 'controllers/settings/settings_controller.dart';
import 'firebase_options.dart';

bool isLimitedVersion = false;

/// A RouteObserver to notify route-aware widgets of navigation events
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initSystemChrome();
  await clearSecureStorageOnReinstall();
  final SettingsController settingsController = Get.put(SettingsController());
  await settingsController.loadAll();
  try {
    await initFirebase();
    await _initNotifications();
  } catch (e) {
    debugPrint('mylog firebase error=${e.toString()}');
  }

  if (!kIsWeb) {
    CustomHttpOverrides.init();
  }

  /// for showing native splash screen
  await Future.delayed(const Duration(milliseconds: 800));
  DeepLinkService().initUniLinks();

  runApp(const MyApp());
}

Future<void> initFirebase() async {
  var app = await Firebase.initializeApp(
      options: Platform.isIOS ? null : DefaultFirebaseOptions.currentPlatform);
  debugPrint('mylog firebase app=${app.options.appId}');
  //
  // String? token = await FirebaseMessaging.instance.getToken();
  // FirebaseMessaging.instance.subscribeToTopic('allDevices');
  //
  // print('mylog firebase messaging token=$token');
  //
  // var settings = await FirebaseMessaging.instance.requestPermission(
  //     alert: true,
  //     announcement: false,
  //     badge: true,
  //     carPlay: false,
  //     criticalAlert: false,
  //     provisional: false,
  //     sound: true);
  // await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
  //   alert: true,
  //   badge: true,
  //   sound: true,
  // );
  //
  // if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  //   print('User granted permission');
  // } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
  //   print('User granted provisional permission');
  // } else {
  //   print('User declined or has not accepted permission');
  // }
}

Future _initNotifications() async {
  // FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  // FlutterLocalNotificationsPlugin();
  //
  // var initializationSettingsAndroid =
  // const AndroidInitializationSettings('@mipmap/launcher_icon');
  // var initializationSettingsIOS = const DarwinInitializationSettings();
  // var initializationSettings = InitializationSettings(
  //     android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  // flutterLocalNotificationsPlugin.initialize(
  //   initializationSettings,
  // );
  // FirebaseMessaging.onMessage.listen((message) async {
  //   log('mylog FirebaseMessaging.onMessage=${jsonEncode(message.data)}');
  //   _showNotification(
  //     message.notification?.title ?? message.data['title'] ?? '',
  //     message.notification?.body ?? message.data['message'] ?? '',
  //     flutterLocalNotificationsPlugin,
  //   );
  // });
}

Future<void> _showNotification(
    String title, String body, flutterLocalNotificationsPlugin) async {
  // var androidPlatformChannelSpecifics = AndroidNotificationDetails(
  //     '$title channel_ID sbody', '$title channel name sbody',
  //     importance: Importance.max,
  //     channelDescription: 'channel description',
  //     playSound: true,
  //     showProgress: true,
  //     priority: Priority.high,
  //     ticker: 'sbody ticker');
  //
  // var iOSChannelSpecifics = const DarwinNotificationDetails();
  // var platformChannelSpecifics = NotificationDetails(
  //     android: androidPlatformChannelSpecifics, iOS: iOSChannelSpecifics);
  // await flutterLocalNotificationsPlugin.show(
  //     title.hashCode, title, body, platformChannelSpecifics,
  //     payload: 'sbody');
}

clearSecureStorageOnReinstall() async {
  if (Platform.isIOS) {
    String key = 'hasRunBefore';
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(key) != true) {
      FlutterSecureStorage storage = const FlutterSecureStorage();
      await storage.deleteAll();

      // Also clear all app group data
      final keyboardService = KeyboardService();
      await keyboardService.clearAppGroupData();

      prefs.setBool(key, true);
    }
  }
}

void _initSystemChrome() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  ); // to re-show bars// to only hide the status bar  LocalPlatformStorage storage = const LocalPlatformStorage();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: defaultTargetPlatform == TargetPlatform.iOS
        ? Colors.white
        : AppColors.mainBlack.withOpacity(0.5),
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: null,
    statusBarColor: defaultTargetPlatform == TargetPlatform.iOS
        ? Colors.white
        : AppColors.mainBlack.withOpacity(0.5),
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AuthController authController = Get.put(AuthController());
  final KeyboardStatusController keyboardStatusController =
      Get.put(KeyboardStatusController());
  final SettingsController settingsController = Get.find();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DeepLinkService().dispose();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    // Update theme when system theme changes, but only if user hasn't set it manually
    if (!settingsController.isThemeSetManually.value) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      settingsController.isDarkTheme.value = brightness == Brightness.dark;
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, deviceType) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1),
          boldText: false,
        ),
        child: Obx(() {
          AppColors.isDarkMode = settingsController.isDarkTheme.value;
          return ThemeProvider(
            initTheme: settingsController.currentTheme,
            builder: (context, theme) {
              return Directionality(
                textDirection: TextDirection.ltr,
                child: ThemeSwitchingArea(
                  child: Container(
                    color:
                        settingsController.currentTheme.scaffoldBackgroundColor,
                    child: GetMaterialApp(
                      // Register the observer to detect when routes change
                      navigatorObservers: [routeObserver],
                      textDirection: TextDirection.ltr,
                      debugShowCheckedModeBanner: false,
                      title: 'Dorna',
                      defaultTransition: kIsWeb
                          ? Transition.fadeIn
                          : Transition.rightToLeftWithFade,
                      scrollBehavior: MyCustomScrollBehavior(),
                      theme: _buildTheme(
                          settingsController.lightTheme, Brightness.light),
                      darkTheme: _buildTheme(
                          settingsController.darkTheme, Brightness.dark),
                      themeMode: settingsController.isDarkTheme.value
                          ? ThemeMode.dark
                          : ThemeMode.light,
                      builder: (context, widget) =>
                          ResponsiveBreakpoints.builder(
                        child: widget!,
                        breakpoints: const [
                          Breakpoint(start: 0, end: 480, name: MOBILE),
                          Breakpoint(start: 481, end: 800, name: TABLET),
                          Breakpoint(
                              start: 801, end: double.infinity, name: DESKTOP),
                        ],
                      ),
                      initialRoute: SplashScreen.routeName,
                      getPages: routes,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      );
    });
  }

  ThemeData _buildTheme(ThemeData baseTheme, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    var displayLarge = TextStyle(
      fontSize: 14.sp,
      color: isDark ? const Color(0xffCCCCCC) : AppColors.subtitle,
      fontWeight: Platform.isIOS ? FontWeight.w500 : FontWeight.w700,
      letterSpacing: Platform.isIOS ? -0.7 : -0.2,
      fontFamily: 'SFProDisplayBold',
    );
    return baseTheme.copyWith(
      brightness: brightness,
      inputDecorationTheme: InputDecorationTheme(
        errorStyle:
            displayLarge.copyWith(fontSize: 11.sp, color: AppColors.errorText),
      ),
      textTheme: baseTheme.textTheme.copyWith(
        displayLarge: displayLarge,
        titleLarge: TextStyle(
          fontSize: 14.sp,
          color: isDark ? const Color(0xffCCCCCC) : AppColors.text2,
          fontWeight: FontWeight.w700,
          letterSpacing: Platform.isIOS ? -1.0 : -0.2,
          fontFamily: 'SFProDisplayBold',
        ),
        titleSmall: TextStyle(
          fontSize: 11.sp,
          color: isDark ? const Color(0xffCCCCCC) : AppColors.text2,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
          fontFamily: 'SFProDisplayRegular',
        ),
        bodyLarge: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xffCCCCCC) : AppColors.text2,
          letterSpacing: -0.2,
          fontFamily: 'SFProDisplayMedium',
        ),
        bodyMedium: TextStyle(
          fontSize: 12.sp,
          color: isDark ? const Color(0xffFFFFFF) : AppColors.mainBlack,
          letterSpacing: -0.2,
          fontFamily: 'SFProDisplayRegular',
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          fontSize: 12.sp,
          color: isDark ? const Color(0xffAAAAAA) : AppColors.text2,
          letterSpacing: -0.2,
          fontFamily: 'SFProDisplayLight',
          fontWeight: FontWeight.w100,
        ),
        titleMedium: TextStyle(
          fontSize: 10.sp,
          color: isDark ? const Color(0xffCCCCCC) : const Color(0xff3D3D3D),
          fontFamily: 'SFProDisplayMedium',
          letterSpacing: -0.2,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
