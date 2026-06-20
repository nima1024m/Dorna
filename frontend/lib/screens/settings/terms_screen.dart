import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/back_header.dart';
import 'package:flutter/material.dart';

class TermsScreen extends StatefulWidget {
  static const String routeName = '/terms_screen';

  const TermsScreen({Key? key}) : super(key: key);

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
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
                title: 'Terms & Conditions  |  Dorna Keyboard',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      bottom: 16, left: 8, right: 8, top: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildTitle('''Welcome to Dorna!'''),
                      buildBody(
                          '''These terms and conditions (“Terms”) govern your use of the Dorna keyboard
application and related services (“the App”). By downloading, installing, or using the App, you acknowledge that you have read, understood, and agree to be bound by these Terms. If you do not
agree, you should not use the App.'''),
                      buildTitle('''1. Use of the App'''),
                      buildBody(
                          '''- The App is provided for your personal, non-commercial use only.
- You agree to use the App in compliance with all applicable laws and not to engage in any activity that
could harm the App, its users, or Dorna Technology LTD.
- You are responsible for maintaining the security of your device and any activities conducted through
the App.'''),
                      buildTitle('''2. Permissions and Full Access'''),
                      buildBody(
                          '''- The Dorna keyboard may request Full Access in order to deliver features such as grammar correction,
spelling suggestions, translations, and personalized learning tools.
- Granting Full Access allows the App to analyze the text you type to improve your user experience.
- Your data is not sold, shared, or transferred to third parties. All analysis is performed securely using
artificial intelligence technologies.
'''),
                      buildTitle('''3. Data Processing and Privacy'''),
                      buildBody('''- The App processes text data to:
- Identify common grammar and spelling issues.
- Provide personalized corrections and suggestions.
- Build tailored learning features such as the Lightning Box.
- Data is processed only for these purposes and is not permanently stored or linked to your identity.
- Please refer to our Privacy Policy for detailed information about how your data is collected, used, and
protected.'''),
                      buildTitle('''4. Intellectual Property'''),
                      buildBody(
                          '''- All rights, title, and interest in and to the App, including its design, software, trademarks, and related
content, are owned by Dorna Technology LTD.
- You may not copy, modify, reverse-engineer, distribute, or create derivative works based on the App
without prior written consent.'''),
                      buildTitle('''5. Disclaimer of Warranties'''),
                      buildBody(
                          '''- The App is provided “as is” and “as available” without any warranties of any kind, whether express or
implied.
- Dorna Technology LTD does not guarantee that the App will always function without interruption,
errors, or defects.'''),
                      buildTitle('''6. Limitation of Liability'''),
                      buildBody(
                          '''- To the maximum extent permitted by law, Dorna Technology LTD shall not be liable for any damages
arising from or related to your use of the App.
- This includes, without limitation, loss of data, device malfunctions, or reliance on suggestions provided
by the App.'''),
                      buildTitle('''7. Termination'''),
                      buildBody(
                          '''- We reserve the right to suspend or terminate your access to the App at any time, with or without
notice, if you violate these Terms or engage in misuse of the App.
- Upon termination, your right to use the App will cease immediately.'''),
                      buildTitle('''8. Updates and Changes'''),
                      buildBody(
                          '''- We may update or modify these Terms at any time. Updates will be posted within the App and/or on
our website.
- Continued use of the App following updates constitutes your acceptance of the revised Terms.'''),
                      buildTitle('''9. Governing Law'''),
                      buildBody(
                          '''- These Terms are governed by and construed in accordance with the laws of British Columbia,
Canada, without regard to conflict of law principles.
- Any disputes arising under these Terms shall be subject to the exclusive jurisdiction of the courts
located in Victoria, British Columbia.'''),
                      buildTitle('''10. Contact Us'''),
                      buildBody(
                          '''If you have any questions about these Terms, please contact us at:
Dorna Technology LTD
Email: support@thedorna.com
Address: 777 Fort Street, Victoria, BC V8W 1G9, Canada'''),
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
          fontSize: 13.sp, color: Theme.of(context).colorScheme.onSurface),
    );
  }

  buildTitle(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
          fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurface),
    );
  }
}
