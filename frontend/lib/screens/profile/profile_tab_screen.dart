import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/brief/brief_player_controller.dart';
import '../../controllers/phrase/phrase_controller.dart';
import '../../controllers/profile/profile_progress_controller.dart';
import '../../theme/app_tokens.dart';
import '../../utils/utils.dart';
import '../../widgets/ui/dorna_card.dart';
import '../../widgets/ui/dorna_pill.dart';
import '../../widgets/ui/user_avatar.dart';
import '../onboarding/interests_screen.dart';
import '../phrase/saved_phrases_screen.dart';
import '../settings/settings_screen.dart';

/// The redesigned **Profile** tab — identity, streak, progress stats, weak
/// areas, interests and saved phrases.
class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Utils.appContext = context;
    final c = Get.put(ProfileProgressController());
    final brief = Get.find<BriefPlayerController>();
    final phraseC = Get.find<PhraseController>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Obx(
        () => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(DornaSpacing.screenMargin, 12,
            DornaSpacing.screenMargin, brief.started.value ? 170 : 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dorna',
                    style: tt.headlineMedium?.copyWith(
                        color: cs.primary, fontWeight: FontWeight.w800)),
                IconButton(
                  onPressed: () => Get.toNamed(SettingsScreen.routeName),
                  icon: Icon(Icons.settings_outlined,
                      color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: DornaSpacing.gutter),
            // Identity
            Center(
              child: Column(
                children: [
                  const _AvatarWithBadge(),
                  const SizedBox(height: DornaSpacing.gutter),
                  Obx(() => Text(c.name,
                      style: tt.headlineLarge?.copyWith(
                          color: cs.onSurface, fontWeight: FontWeight.w800))),
                  const SizedBox(height: DornaSpacing.sm),
                  Obx(() => DornaPill(
                        label: '${c.streakDays.value}-day streak',
                        icon: Icons.local_fire_department,
                        iconColor: DornaColors.accentCyan,
                        textColor: cs.primary,
                        backgroundColor: cs.surfaceContainerHighest,
                      )),
                ],
              ),
            ),
            const SizedBox(height: DornaSpacing.xl),
            // Stat tiles
            Obx(() => Row(
                  children: [
                    Expanded(
                        child: _StatTile(
                            value: '${c.phrasesLearned.value}',
                            label: 'Phrases learned')),
                    const SizedBox(width: 11),
                    Expanded(
                        child: _StatTile(
                            value: '${c.conversations.value}',
                            label: 'Conversations')),
                    const SizedBox(width: 11),
                    Expanded(
                        child: _StatTile(
                            value: '${c.briefsHeard.value}',
                            label: 'Briefs heard')),
                  ],
                )),
            const SizedBox(height: DornaSpacing.gutter),
            // Improving card
            Obx(() => _ImprovingCard(weakAreas: c.weakAreas.toList())),
            const SizedBox(height: DornaSpacing.xl),
            // Interests
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Interests',
                    style: tt.titleLarge?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w800)),
                TextButton(
                  onPressed: () => Get.toNamed(InterestsScreen.routeName),
                  child: Text('Edit',
                      style: tt.labelLarge?.copyWith(
                          color: cs.primary, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: DornaSpacing.sm),
            Obx(() => Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final i in c.interests)
                      DornaPill(label: i, variant: DornaPillVariant.outlined),
                  ],
                )),
            const SizedBox(height: DornaSpacing.xl),
            // Saved phrases
            Obx(() => DornaCard(
                  onTap: () => Get.toNamed(SavedPhrasesScreen.routeName),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainer,
                          borderRadius: BorderRadius.circular(DornaRadii.md),
                        ),
                        child: Icon(Icons.bookmark, color: cs.primary),
                      ),
                      const SizedBox(width: DornaSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Saved phrases',
                                style: tt.bodyLarge?.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('${phraseC.saved.length} phrases collected',
                                style: tt.bodyMedium
                                    ?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: cs.outlineVariant),
                    ],
                  ),
                )),
          ],
        ),
      ),
        ),
    );
  }
}

class _AvatarWithBadge extends StatelessWidget {
  const _AvatarWithBadge();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        children: [
          const Center(child: UserAvatar(size: 104)),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 3),
              ),
              child: Icon(Icons.military_tech, color: cs.onPrimary, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return DornaCard(
      soft: true,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        children: [
          Text(value,
              style: tt.headlineMedium?.copyWith(
                  color: cs.primary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: tt.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _ImprovingCard extends StatelessWidget {
  final List<String> weakAreas;
  const _ImprovingCard({required this.weakAreas});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return DornaCard(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(18),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Icon(Icons.trending_up,
                size: 92, color: cs.surfaceContainerHigh),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("You're improving",
                  style: tt.titleLarge?.copyWith(
                      color: cs.onSurface, fontWeight: FontWeight.w800)),
              const SizedBox(height: DornaSpacing.sm),
              Text('Keep practicing these areas to sound more natural:',
                  style: tt.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant, height: 1.45)),
              const SizedBox(height: DornaSpacing.gutter),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (final w in weakAreas)
                    DornaPill(label: w, leadingDot: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
