import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/back_header.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  static const String routeName = '/privacy_policy_screen';

  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const BackHeader(
                title: 'Privacy Policy  |  Dorna Keyboard',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      bottom: 16, left: 8, right: 8, top: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildBody(
                          '''Dorna Technology LTD (“we,” “our,” “us”) is committed to protecting your privacy. This privacy policy explains how we collect, use, and safeguard information when you use our application Dorna (“the App”). By downloading or using the App, you agree to the practices described in this Privacy Policy.'''),
                      buildTitle('''1. Information We Collect'''),
                      buildBody(
                          '''- Text Input Data: The text you type may be analyzed to provide grammar correction, spelling suggestions, translations, and personalized learning tools (such as the Lightning Box). - Usage Data: We may collect non-identifiable usage patterns (e.g., common grammar mistakes, feature usage frequency) for improving performance and user experience. - Device Information: Limited technical info (device model, OS version, app version) may be collected for compatibility and app stability. We do not collect any personal identifiers such as your name, email, or contact information.'''),
                      buildTitle('''2. How We Collect and Use Information'''),
                      buildBody(
                          '''- Data is collected only if you grant the necessary permissions (e.g., Full Access for keyboard functionality). - All processing occurs securely within the app or our systems, using AI to enhance grammar suggestions and learning. - We do not store your text permanently or associate it with your identity.'''),
                      buildTitle('''3. Data Sharing and Third Parties'''),
                      buildBody(
                          '''- We do not sell or trade your personal data. - Any third-party service we may use for analytics (if any) will receive only anonymized data and adhere to privacy protections not less strict than ours.'''),
                      buildTitle(
                          '''4. Data Retention, Consent Withdrawal, and Deletion'''),
                      buildBody(
                          '''- Text is processed in real time and discarded immediately after analysis. - Anonymous usage data may be stored only as long as it benefits app functionality. - You can revoke consent or delete your data at any time through the app’s Settings → Privacy or Legal menu.'''),
                      buildTitle('''5. Security'''),
                      buildBody(
                          '''- We implement industry-standard security, including encryption and secure channels. - No system is completely secure; we cannot guarantee absolute protection.'''),
                      buildTitle('''6. Children’s Privacy'''),
                      buildBody(
                          '''- We do not direct our app to children under 13. - We do not knowingly collect data from children. If you believe such data has been collected, contact us for immediate deletion.'''),
                      buildTitle('''7. App Store Compliance & Transparency'''),
                      buildBody(
                          '''- A link to this Privacy Policy will be provided in the App Store metadata and accessible within the app’s Legal or Settings section. - In App Store Connect, you will also provide the required App Privacy details (e.g., “Data Not Collected” or “Processed On Device”, etc.), accurately reflecting this policy.'''),
                      buildTitle('''8. Changes to the Privacy Policy'''),
                      buildBody(
                          '''- We may update this Privacy Policy, with changes posted in the app and/or announced via App Store Connect. - Continued use of the App signifies acceptance of any changes.'''),
                      buildTitle('''9. Contact Us'''),
                      buildBody(
                          '''Dorna Technology LTD Email: support@thedorna.com Address: 777 Fort Street, Victoria, BC V8W 1G9, Canada'''),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  buildBody(String text) {
    return Text(
      '$text\n',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 13.sp,
          ),
    );
  }

  buildTitle(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 14.sp,
          ),
    );
  }
}
