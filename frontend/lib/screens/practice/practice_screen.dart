import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/brief/brief_player_controller.dart';
import '../../controllers/conversation/conversation_controller.dart';
import '../../theme/app_tokens.dart';
import '../../utils/utils.dart';
import '../../widgets/ui/dorna_action_row.dart';
import '../../widgets/ui/toast.dart';
import '../conversation/conversation_screen.dart';
import '../phrase/phrase_library_screen.dart';

/// The **Practice** tab — a hub of conversation/phrase features. The deep
/// features (live AI conversation, decks, event prep) are F4/F5; for now this
/// is a presentable shell whose cards flag "coming soon".
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  static const _items = [
    (
      Icons.forum_outlined,
      'Talk with Dorna',
      'Practice real conversations out loud',
    ),
    (
      Icons.style_outlined,
      'Phrase decks',
      'Bite-size phrases for everyday situations',
    ),
    (
      Icons.groups_2_outlined,
      'Event prep',
      'Get ready for meetings and networking',
    ),
    (
      Icons.record_voice_over_outlined,
      'Ice-breakers',
      'Openers that start a friendly chat',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    Utils.appContext = context;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final brief = Get.find<BriefPlayerController>();
    return SafeArea(
      bottom: false,
      child: Obx(
        () => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(DornaSpacing.screenMargin, 16,
              DornaSpacing.screenMargin, brief.started.value ? 170 : 110),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Practice',
                style: tt.headlineLarge?.copyWith(
                    color: cs.onSurface, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Build confidence for real conversations.',
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: DornaSpacing.xl),
            for (final item in _items) ...[
              DornaActionRow(
                icon: item.$1,
                title: item.$2,
                subtitle: item.$3,
                onTap: () {
                  switch (item.$2) {
                    case 'Phrase decks':
                      Get.toNamed(PhraseLibraryScreen.routeName);
                    case 'Talk with Dorna':
                      Get.toNamed(ConversationScreen.routeName,
                          arguments: {'scene': ConversationScenes.smallTalk});
                    default:
                      showCustomToast('${item.$2} is coming soon', context);
                  }
                },
              ),
              const SizedBox(height: DornaSpacing.md),
            ],
          ],
          ),
        ),
      ),
    );
  }
}
