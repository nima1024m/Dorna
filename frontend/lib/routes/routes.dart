import 'package:dorna/screens/home/home_screen.dart';
import 'package:dorna/screens/onboarding/onboarding_screen.dart';
import 'package:get/get.dart';

import '../screens/auth/auth_screen.dart';
import '../screens/auth/auth_suggestion_screen.dart';
import '../screens/auth/change_password_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/profile_screen.dart';
import '../screens/auth/reset_password_email_screen.dart';
import '../screens/auth/reset_password_form_screen.dart';
import '../screens/auth/reset_password_otp_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/brief/brief_player_screen.dart';
import '../screens/instruction/instruction_collect_data_screen.dart';
import '../screens/phrase/phrase_library_screen.dart';
import '../screens/phrase/saved_phrases_screen.dart';
import '../screens/instruction/instruction_first_screen.dart';
import '../screens/instruction/instruction_second_screen.dart';
import '../screens/keyboard_debug_screen.dart';
import '../screens/languages/languages_screen.dart';
import '../screens/podcast/connect_sources_screen.dart';
import '../screens/podcast/language_level_screen.dart';
import '../screens/podcast/learning_goals_screen.dart';
import '../screens/podcast/podcast_dashboard_screen.dart';
import '../screens/podcast/podcast_onboarding_screen.dart';
import '../screens/podcast/podcast_player_screen.dart';
import '../screens/podcast/preparing_briefing_screen.dart';
import '../screens/podcast/preparing_podcast_screen.dart';
import '../screens/settings/about_us_screen.dart';
import '../screens/settings/contact_us_screen.dart';
import '../screens/settings/privacy_policy_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/terms_and_privacy_screen.dart';
import '../screens/settings/terms_screen.dart';
import '../screens/onboarding/building_brief_screen.dart';
import '../screens/onboarding/interests_screen.dart';
import '../screens/onboarding/permissions_screen.dart';
import '../screens/onboarding/situations_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/tones/tones_screen.dart';
import '../screens/webview/webview_screen.dart';

List<GetPage> routes = [
  GetPage(
    name: SplashScreen.routeName,
    page: () => const SplashScreen(),
  ),
  GetPage(
    name: PodcastOnboardingScreen.routeName,
    page: () => const PodcastOnboardingScreen(),
  ),
  GetPage(
    name: InstructionFirstScreen.routeName,
    page: () => const InstructionFirstScreen(),
  ),
  GetPage(
    name: InstructionSecondScreen.routeName,
    page: () => const InstructionSecondScreen(),
  ),
  GetPage(
    name: InstructionCollectDataScreen.routeName,
    page: () => const InstructionCollectDataScreen(),
  ),
  GetPage(
    name: KeyboardDebugScreen.routeName,
    page: () => const KeyboardDebugScreen(),
  ),
  GetPage(
    name: HomeScreen.routeName,
    page: () => const HomeScreen(),
  ),
  GetPage(
    name: MainShell.routeName,
    page: () => const MainShell(),
  ),
  GetPage(
    name: BriefPlayerScreen.routeName,
    page: () => const BriefPlayerScreen(),
  ),
  GetPage(
    name: SettingsScreen.routeName,
    page: () => const SettingsScreen(),
  ),
  GetPage(
    name: PhraseLibraryScreen.routeName,
    page: () => const PhraseLibraryScreen(),
  ),
  GetPage(
    name: SavedPhrasesScreen.routeName,
    page: () => const SavedPhrasesScreen(),
  ),
  GetPage(
    name: WelcomeScreen.routeName,
    page: () => const WelcomeScreen(),
  ),
  GetPage(
    name: InterestsScreen.routeName,
    page: () => const InterestsScreen(),
  ),
  GetPage(
    name: SituationsScreen.routeName,
    page: () => const SituationsScreen(),
  ),
  GetPage(
    name: PermissionsScreen.routeName,
    page: () => const PermissionsScreen(),
  ),
  GetPage(
    name: BuildingBriefScreen.routeName,
    page: () => const BuildingBriefScreen(),
  ),
  GetPage(
    name: LanguagesScreen.routeName,
    page: () => const LanguagesScreen(),
  ),
  GetPage(
    name: TonesScreen.routeName,
    page: () => const TonesScreen(),
  ),
  GetPage(
    name: ContactUsScreen.routeName,
    page: () => const ContactUsScreen(),
  ),
  GetPage(
    name: TermsScreen.routeName,
    page: () => const TermsScreen(),
  ),
  GetPage(
    name: PrivacyPolicyScreen.routeName,
    page: () => const PrivacyPolicyScreen(),
  ),
  GetPage(
    name: TermsAndPrivacyScreen.routeName,
    page: () => const TermsAndPrivacyScreen(),
  ),
  GetPage(
    name: AboutUsScreen.routeName,
    page: () => const AboutUsScreen(),
  ),
  GetPage(
    name: WebViewScreen.routeName,
    page: () => const WebViewScreen(),
  ),
  GetPage(
    name: AuthScreen.routeName,
    page: () => const AuthScreen(),
  ),
  GetPage(
    name: SignUpScreen.routeName,
    page: () => const SignUpScreen(),
  ),
  GetPage(
    name: SignInScreen.routeName,
    page: () => const SignInScreen(),
  ),
  GetPage(
    name: EmailVerificationScreen.routeName,
    page: () => const EmailVerificationScreen(),
  ),
  GetPage(
    name: ResetPasswordEmailScreen.routeName,
    page: () => const ResetPasswordEmailScreen(),
  ),
  GetPage(
    name: ResetPasswordOtpScreen.routeName,
    page: () => const ResetPasswordOtpScreen(),
  ),
  GetPage(
    name: ResetPasswordFormScreen.routeName,
    page: () => const ResetPasswordFormScreen(),
  ),
  GetPage(
    name: ProfileScreen.routeName,
    page: () => const ProfileScreen(),
  ),
  GetPage(
    name: ChangePasswordScreen.routeName,
    page: () => const ChangePasswordScreen(),
  ),
  GetPage(
    name: AuthSuggestionScreen.routeName,
    page: () => const AuthSuggestionScreen(),
  ),
  GetPage(
    name: PodcastaDashboardScreen.routeName,
    page: () => const PodcastaDashboardScreen(),
  ),
  GetPage(
    name: PodcastPlayerScreen.routeName,
    page: () => PodcastPlayerScreen(),
  ),
  GetPage(
    name: ConnectSourcesScreen.routeName,
    page: () => const ConnectSourcesScreen(),
  ),
  GetPage(
    name: LanguageLevelScreen.routeName,
    page: () => const LanguageLevelScreen(),
  ),
  GetPage(
    name: LearningGoalsScreen.routeName,
    page: () => LearningGoalsScreen(),
  ),
  GetPage(
    name: PreparingBriefingScreen.routeName,
    page: () => const PreparingBriefingScreen(),
  ),
  GetPage(
    name: PreparingPodcastScreen.routeName,
    page: () => const PreparingPodcastScreen(),
  ),
  GetPage(
    name: OnboardingScreen.routeName,
    page: () => const OnboardingScreen(),
  ),
];
