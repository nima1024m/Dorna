import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/back_header.dart';
import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  static const String routeName = '/about_us_screen';

  const AboutUsScreen({Key? key}) : super(key: key);

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
                title: 'About Dorna',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8,top: 24),
                  child: Text(
                    '''At Dorna Technology LTD, we believe that language should never be a barrier to building a new life.

Dorna was founded in Canada with one clear mission: to support newcomers, especially Persian-speaking immigrants, in integrating smoothly into Canadian society by improving their communication skills and confidence in everyday life.

Our journey started when we noticed that many newcomers face difficulties in expressing themselves—whether in writing emails, applying for jobs, or simply having day-to-day conversations.
These challenges affect not only their professional opportunities but also their sense of belonging.

That is why we created Dorna Keyboard and the Dorna Learning Platform, proudly developed in Victoria, British Columbia.
With AI-powered tools such as instant grammar correction, tone adjustment, fast translation, and personalized learning modules, we make communication easier, faster, and more accurate.

As a Canadian solution, Dorna is designed in alignment with the multicultural and diverse values of Canada. Our platform reflects the unique needs of newcomers, combining advanced technology with local insights, ensuring that every user feels supported in their settlement journey.

Our vision goes beyond technology. We aim to be a supportive companion in every newcomer’s path, helping them not only to learn but also to feel included, valued, and prepared for success in Canada.
''',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13.sp,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
