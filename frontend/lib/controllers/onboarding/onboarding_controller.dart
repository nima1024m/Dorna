import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One selectable interest in the onboarding "What are you into?" step.
class OnboardingInterest {
  final String id;
  final String label;
  const OnboardingInterest(this.id, this.label);
}

/// One selectable everyday situation in the "What do you want to talk about?" step.
class OnboardingSituation {
  final String id;
  final String label;
  final IconData icon;
  final String example;
  const OnboardingSituation(this.id, this.label, this.icon, this.example);
}

/// State for the redesigned onboarding flow
/// (welcome → interests → situations → calendar/location → building).
///
/// UI-only for now: selections are held locally. Persisting them needs the new
/// interests/situations taxonomy + calendar/location backend, which land in the
/// F-phases — wire persistence there.
class OnboardingController extends GetxController {
  static const List<OnboardingInterest> interests = [
    OnboardingInterest('soccer', 'Soccer'),
    OnboardingInterest('tech', 'Tech'),
    OnboardingInterest('movies', 'Movies'),
    OnboardingInterest('music', 'Music'),
    OnboardingInterest('food', 'Food & cooking'),
    OnboardingInterest('travel', 'Travel'),
    OnboardingInterest('fitness', 'Fitness'),
    OnboardingInterest('art', 'Art'),
    OnboardingInterest('business', 'Business'),
    OnboardingInterest('cars', 'Cars'),
    OnboardingInterest('gaming', 'Gaming'),
    OnboardingInterest('books', 'Books'),
    OnboardingInterest('nature', 'Nature'),
    OnboardingInterest('photography', 'Photography'),
    OnboardingInterest('startups', 'Startups'),
    OnboardingInterest('immigration', 'Immigration life'),
  ];

  static const List<OnboardingSituation> situations = [
    OnboardingSituation('small_talk', 'Small talk & making friends',
        Icons.chat_bubble_outline, "Hi, how's your day going?"),
    OnboardingSituation('networking', 'Networking events',
        Icons.groups_outlined, 'So, what brings you here today?'),
    OnboardingSituation('work', 'At work / with coworkers', Icons.work_outline,
        'Do you have a moment to sync?'),
    OnboardingSituation('cafe', 'Coffee shops & cafes',
        Icons.local_cafe_outlined, 'Can I get a medium latte, please?'),
    OnboardingSituation('neighbours', 'Neighbours & community',
        Icons.home_outlined, "Beautiful weather we're having!"),
    OnboardingSituation('shopping', 'Shopping & services',
        Icons.shopping_bag_outlined, 'Do you have this in a smaller size?'),
    OnboardingSituation('doctor', 'Doctor & appointments',
        Icons.medical_services_outlined, "I've been having some back pain."),
  ];

  // A few interests start selected, matching the design.
  final RxSet<String> selectedInterests = <String>{'soccer', 'tech', 'travel'}.obs;
  final RxSet<String> selectedSituations = <String>{}.obs;
  final RxBool calendarConnected = false.obs;
  final RxBool locationEnabled = false.obs;

  void toggleInterest(String id) =>
      selectedInterests.contains(id) ? selectedInterests.remove(id) : selectedInterests.add(id);

  void toggleSituation(String id) =>
      selectedSituations.contains(id) ? selectedSituations.remove(id) : selectedSituations.add(id);
}
