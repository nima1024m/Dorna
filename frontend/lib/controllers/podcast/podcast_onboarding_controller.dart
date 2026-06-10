import 'package:dorna/config/api_client.dart';
import 'package:dorna/screens/podcast/language_level_screen.dart';
import 'package:dorna/screens/podcast/learning_goals_screen.dart';
import 'package:dorna/screens/podcast/podcast_onboarding_screen.dart';
import 'package:dorna/screens/podcast/preparing_podcast_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../screens/home/home_screen.dart';

class PodcastOnboardingController extends GetxController {
  final apiClient = ApiClient();
  var isLoading = false.obs;

  // Topics
  var selectedTopics = <String>{}.obs;
  var customTopics = <Map<String, String>>[].obs;

  // Language Level
  var selectedLanguageLevel = RxnString();

  // Goals
  var selectedGoals = <String>[].obs;

  // Data Sources
  final List<Map<String, dynamic>> categories = [
    {
      "title": "🚀 INNOVATION & GROWTH",
      "items": [
        {"id": "ai", "label": "AI & Future", "icon": Icons.memory},
        {"id": "money", "label": "Money & Hustle", "icon": Icons.attach_money},
        {"id": "startups", "label": "Startups", "icon": Icons.rocket_launch},
        {"id": "psychology", "label": "Psychology", "icon": Icons.psychology},
        {"id": "habits", "label": "Productivity", "icon": Icons.bolt},
        {"id": "digital", "label": "Digital Life", "icon": Icons.smartphone},
      ]
    },
    {
      "title": "🌍 WORLD & LIFESTYLE",
      "items": [
        {"id": "world", "label": "Global News", "icon": Icons.public},
        {
          "id": "history",
          "label": "Hidden History",
          "icon": Icons.auto_stories
        },
        {
          "id": "health",
          "label": "Biohacking & Health",
          "icon": Icons.monitor_heart
        },
        {"id": "travel", "label": "Travel Tales", "icon": Icons.explore},
        {"id": "relationships", "label": "Modern Love", "icon": Icons.favorite},
        {"id": "food", "label": "Food Culture", "icon": Icons.restaurant},
      ]
    },
    {
      "title": "🍿 CULTURE & CURIOSITY",
      "items": [
        {"id": "movies", "label": "Cinema Deep Dives", "icon": Icons.movie},
        {"id": "science", "label": "Fun Science", "icon": Icons.science},
        {"id": "pop", "label": "Pop Culture", "icon": Icons.star},
        {"id": "facts", "label": "Weird Facts", "icon": Icons.help_outline},
        {
          "id": "philosophy",
          "label": "Daily Philosophy",
          "icon": Icons.lightbulb_outline
        },
        {
          "id": "internet",
          "label": "Internet Mysteries",
          "icon": Icons.visibility_off_outlined
        },
      ]
    }
  ];

  final List<Map<String, dynamic>> levels = [
    {
      "id": "clb-4",
      "title": "CLB 4 | Basic",
      "desc": "I understand simple everyday phrases and common words.",
      "exam": "IELTS ~4.0–4.5 | TOEFL ~31–34 | PTE ~30–35",
      "icon": Icons.eco_outlined,
    },
    {
      "id": "clb-5",
      "title": "CLB 5 | Developing",
      "desc":
          "I can communicate in familiar daily situations but pause sometimes.",
      "exam": "IELTS ~5.0 | TOEFL ~35–45 | PTE ~36–42",
      "icon": Icons.trending_up,
    },
    {
      "id": "clb-6",
      "title": "CLB 6 | Functional",
      "desc": "I handle most daily conversations with reasonable confidence.",
      "exam": "IELTS ~5.5–6.0 | TOEFL ~46–59 | PTE ~43–50",
      "icon": Icons.chat_bubble_outline,
    },
    {
      "id": "clb-7",
      "title": "CLB 7 | Confident",
      "desc": "I can explain ideas and give opinions clearly.",
      "exam": "IELTS ~6.5 | TOEFL ~60–78 | PTE ~51–58",
      "icon": Icons.shield_outlined,
    },
    {
      "id": "clb-8",
      "title": "CLB 8 | Fluent",
      "desc": "I speak smoothly and understand fast conversations.",
      "exam": "IELTS ~7.0–7.5 | TOEFL ~79–93 | PTE ~59–64",
      "icon": Icons.bolt,
    },
    {
      "id": "clb-9",
      "title": "CLB 9 | Advanced",
      "desc": "I sound natural and professional, even in complex topics.",
      "exam": "IELTS 8.0+ | TOEFL 94+ | PTE 65+",
      "icon": Icons.workspace_premium_outlined,
    },
  ];

  final List<Map<String, dynamic>> goals = [
    {
      "id": "speak_confidently",
      "title": "I want to speak confidently",
      "desc": "Sound clear, natural, and comfortable when I talk",
      "icon": Icons.chat_bubble_outline
    },
    {
      "id": "work",
      "title": "I want to talk better at work",
      "desc": "Communicate with coworkers, managers, and clients",
      "icon": Icons.business_center_outlined
    },
    {
      "id": "friends",
      "title": "I want to make friends",
      "desc": "Start conversations and build social connections",
      "icon": Icons.people_outline
    },
    {
      "id": "professional",
      "title": "I want to sound professional",
      "desc": "Speak clearly in meetings, interviews, and presentations",
      "icon": Icons.military_tech_outlined
    },
    {
      "id": "understand_natives",
      "title": "I want to understand native speakers",
      "desc": "Follow fast, natural conversations without stress",
      "icon": Icons.headphones_outlined
    },
    {
      "id": "pronunciation",
      "title": "I want to improve my pronunciation",
      "desc": "Sound more natural and easier to understand",
      "icon": Icons.mic_none_outlined
    },
    {
      "id": "daily_life",
      "title": "I want to feel confident in daily life",
      "desc": "Shopping, appointments, phone calls, small talk",
      "icon": Icons.shopping_bag_outlined
    },
    {
      "id": "future",
      "title": "I want to prepare for my future",
      "desc": "Immigration, career growth, or long-term goals",
      "icon": Icons.school_outlined
    },
  ];

  List<Map<String, dynamic>> get allTopics => categories
      .expand((c) => c["items"] as List)
      .map((e) => e as Map<String, dynamic>)
      .toList();

  @override
  void onInit() {
    super.onInit();
    fetchPreferences();
  }

  Future<void> fetchPreferences() async {
    isLoading.value = true;
    try {
      final response = await apiClient.request(
        url: 'v1/podcast/preferences',
        method: ApiMethod.get,
      );

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        // Parse Language Level
        if (data['language_level'] != null) {
          int levelIndex = data['language_level'] as int;
          if (levelIndex > 0 && levelIndex <= levels.length) {
            selectedLanguageLevel.value = levels[levelIndex - 1]['id'];
          }
        }

        // Parse Categories (Topics)
        if (data['categories'] != null) {
          final cats = data['categories'];
          // Assuming categories are returned as list of objects or current backend behavior
          // But prompt says "response sample: categories: [], goal_ids: []"
          // If we receive data, we map logical indices if provided as IDs in some way,
          // or if they are objects, we might use them.
          // Since we send indices, maybe we receive indices?
          // The prompt says response sample has "categories": [] and "goal_ids": [].
          // I will assume if I receive goal_ids as [1, 5], I map to goals[0] and goals[4].

          // Wait, the Prompt response sample shows:
          // "categories": [], "goal_ids": []
          // But PUT example has "goal_ids": [1, 5]
          // I'll assume categories might come as indices or objects.
          // If Objects with 'id', I use ID.
          // If integers, I use index.

          if (cats is List) {
            for (var c in cats) {
              if (c is int) {
                // Index based
                if (c > 0 && c <= allTopics.length) {
                  selectedTopics.add(allTopics[c - 1]['id']);
                }
              } else if (c is Map && c['id'] != null) {
                selectedTopics.add(c['id']);
              }
            }
          }
        }

        // Parse Goal IDs
        if (data['goal_ids'] != null) {
          final gIds = data['goal_ids'] as List;
          for (var g in gIds) {
            if (g is int) {
              if (g > 0 && g <= goals.length) {
                selectedGoals.add(goals[g - 1]['id']);
              }
            }
          }
        }

        _navigateBasedOnData();
      }
    } catch (e) {
      debugPrint("Error fetching preferences: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _navigateBasedOnData() {
    // Logic: If data missing, go there.
    // If categories empty -> Stay at Onboarding (Topics)
    if (selectedTopics.isEmpty) {
      Get.toNamed(PodcastOnboardingScreen.routeName);
      return;
    }

    // If goals empty -> Go to Goals
    if (selectedGoals.isEmpty) {
      Get.toNamed(LearningGoalsScreen.routeName);
      return;
    }

    // If level null -> Go to Level
    if (selectedLanguageLevel.value == null) {
      Get.toNamed(LanguageLevelScreen.routeName);
      return;
    }

    // All data captured -> Preparing
    Get.offNamedUntil(PreparingPodcastScreen.routeName,
        (route) => route.settings.name == HomeScreen.routeName);
  }

  Future<void> submitPreferences() async {
    isLoading.value = true;
    try {
      // Categories: Send ID string directly (exclude custom topics)
      final categoryIds =
          selectedTopics.where((id) => !id.startsWith('custom_')).toList();

      // Goals: Send index + 1
      final goalIds = selectedGoals
          .map((id) {
            final index = goals.indexWhere((g) => g['id'] == id);
            return index + 1;
          })
          .where((idx) => idx > 0)
          .toList();

      // Language Level: Send index + 4
      final levelIndex =
          levels.indexWhere((l) => l['id'] == selectedLanguageLevel.value);
      final levelToSend = levelIndex != -1 ? levelIndex + 4 : null;

      final data = {
        "language_level": levelToSend,
        "category_ids": categoryIds, // Sending Strings
        "goal_ids": goalIds, // Sending Ints (index+1)
      };

      await apiClient.request(
        url: 'v1/podcast/preferences',
        method: ApiMethod.put,
        data: data,
      );

      Get.offNamedUntil(PreparingPodcastScreen.routeName,
          (route) => route.settings.name == HomeScreen.routeName);
    } catch (e) {
      debugPrint("Error submitting preferences: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void toggleTopic(String id) {
    if (selectedTopics.contains(id)) {
      selectedTopics.remove(id);
    } else {
      selectedTopics.add(id);
    }
  }

  bool isSelected(String id) => selectedTopics.contains(id);

  void addCustomTopic(String label) {
    if (label.trim().isEmpty) return;
    final id = "custom_${DateTime.now().millisecondsSinceEpoch}";
    customTopics.add({"id": id, "label": label.trim()});
    selectedTopics.add(id);
  }

  void setLanguageLevel(String id) {
    selectedLanguageLevel.value = id;
  }

  void toggleGoal(String id) {
    if (selectedGoals.contains(id)) {
      selectedGoals.remove(id);
    } else {
      selectedGoals.add(id);
    }
  }
}
