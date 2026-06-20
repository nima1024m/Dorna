import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/brief/brief_player_controller.dart';
import '../../theme/app_tokens.dart';
import '../../utils/utils.dart';
import '../../widgets/ui/dorna_card.dart';
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
              DornaCard(
                onTap: () {
                  switch (item.$2) {
                    case 'Phrase decks':
                      Get.toNamed(PhraseLibraryScreen.routeName);
                    case 'Talk with Dorna':
                      Get.toNamed(ConversationScreen.routeName,
                          arguments: {'scene': 'small_talk'});
                    default:
                      showCustomToast('${item.$2} is coming soon', context);
                  }
                },
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainer,
                        borderRadius: BorderRadius.circular(DornaRadii.md),
                      ),
                      child: Icon(item.$1, color: cs.primary, size: 26),
                    ),
                    const SizedBox(width: DornaSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$2,
                              style: tt.bodyLarge?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(item.$3,
                              style: tt.bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: cs.outlineVariant),
                  ],
                ),
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
