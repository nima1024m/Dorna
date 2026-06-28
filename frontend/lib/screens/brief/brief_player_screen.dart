import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/brief/brief_player_controller.dart';
import '../../theme/app_tokens.dart';
import '../../utils/utils.dart';
import '../../widgets/brief/animated_waveform.dart';
import '../../widgets/brief/brief_segment_chip.dart';
import '../../widgets/brief/dot_indicator.dart';
import '../../widgets/brief/highlighted_transcript.dart';
import '../../widgets/ui/toast.dart';

/// The redesigned Daily Brief player (light theme; segmented; live transcript).
class BriefPlayerScreen extends StatelessWidget {
  static const String routeName = '/brief_player';

  const BriefPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Utils.appContext = context;
    final c = Get.isRegistered<BriefPlayerController>()
        ? Get.find<BriefPlayerController>()
        : Get.put(BriefPlayerController());
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              DornaSpacing.screenMargin, 8, DornaSpacing.screenMargin, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(c: c),
              const SizedBox(height: DornaSpacing.gutter),
              _PlayerCard(c: c),
              const SizedBox(height: DornaSpacing.xl),
              Text(
                'SEGMENTS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: DornaSpacing.md),
              _SegmentRow(c: c),
              const SizedBox(height: DornaSpacing.xl),
              _TranscriptCard(c: c),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final BriefPlayerController c;
  const _TopBar({required this.c});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        IconButton(
          onPressed: Get.back,
          icon: Icon(Icons.arrow_back, color: cs.primary),
        ),
        Expanded(
          child: Column(
            children: [
              Text('Daily Brief',
                  style: tt.headlineMedium
                      ?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
              Obx(() => Text(c.dateLabel.value,
                  style: tt.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant, fontSize: 12.5))),
            ],
          ),
        ),
        IconButton(
          onPressed: () =>
              showCustomToast('Picking another day is coming soon', context),
          icon: Icon(Icons.calendar_today_outlined, color: cs.primary),
        ),
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final BriefPlayerController c;
  const _PlayerCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DornaRadii.xl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: DornaColors.brandGradient,
          boxShadow: [
            BoxShadow(
              color: DornaColors.primary.withValues(alpha: 0.28),
              blurRadius: 34,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -40,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Obx(() => _StatusPill(
                      label: c.currentSegment.label.toUpperCase())),
                  const SizedBox(height: DornaSpacing.gutter),
                  Obx(() => AnimatedWaveform(
                        playing: c.isPlaying.value,
                        color: Colors.white.withValues(alpha: 0.85),
                        accentColor: DornaColors.accentCyan,
                        seed: c.currentIndex,
                      )),
                  const SizedBox(height: DornaSpacing.gutter),
                  _Scrubber(c: c),
                  const SizedBox(height: DornaSpacing.md),
                  _Transport(c: c),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DornaRadii.full),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(DornaRadii.full),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 10.5,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
  }
}

class _Scrubber extends StatelessWidget {
  final BriefPlayerController c;
  const _Scrubber({required this.c});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final whiteLabel = tt.labelLarge?.copyWith(
      color: Colors.white.withValues(alpha: 0.85),
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
    );
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 5,
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.22),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.15),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Obx(() => Slider(
                value: c.position.value
                    .clamp(0, BriefPlayerController.totalSeconds)
                    .toDouble(),
                max: BriefPlayerController.totalSeconds.toDouble(),
                onChangeStart: (_) => c.beginSeek(),
                onChanged: (v) => c.position.value = v.round(),
                onChangeEnd: (_) => c.endSeek(),
              )),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => Text(BriefPlayerController.fmt(c.position.value),
                  style: whiteLabel)),
              Text(BriefPlayerController.fmt(BriefPlayerController.totalSeconds),
                  style: whiteLabel),
            ],
          ),
        ),
      ],
    );
  }
}

class _Transport extends StatelessWidget {
  final BriefPlayerController c;
  const _Transport({required this.c});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Speed pill
        Obx(() => GestureDetector(
              onTap: c.cycleSpeed,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DornaRadii.full),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                child: Text(
                  '${c.speed % 1 == 0 ? c.speed.toInt() : c.speed}x',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                ),
              ),
            )),
        Row(
          children: [
            IconButton(
              onPressed: () => c.nudge(-15),
              icon: const Icon(Icons.replay, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 6),
            Obx(() => Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: c.togglePlay,
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Icon(
                        c.isPlaying.value
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 36,
                        color: cs.primary,
                      ),
                    ),
                  ),
                )),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => c.nudge(15),
              icon: const Icon(Icons.fast_forward,
                  color: Colors.white, size: 28),
            ),
          ],
        ),
        IconButton(
          onPressed: () =>
              showCustomToast('Read-aloud is coming soon', context),
          icon: const Icon(Icons.campaign_outlined, color: Colors.white),
        ),
      ],
    );
  }
}

class _SegmentRow extends StatelessWidget {
  final BriefPlayerController c;
  const _SegmentRow({required this.c});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Obx(() {
        final active = c.currentIndex;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: c.segments.length,
          separatorBuilder: (_, _) => const SizedBox(width: DornaSpacing.sm),
          itemBuilder: (context, i) {
            final s = c.segments[i];
            return BriefSegmentChip(
              icon: s.icon,
              label: s.label,
              selected: i == active,
              onTap: () => c.selectSegment(i),
            );
          },
        );
      }),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  final BriefPlayerController c;
  const _TranscriptCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DornaRadii.lg),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.notes, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('LIVE TRANSCRIPT',
                    style: tt.labelLarge?.copyWith(
                      color: cs.primary,
                      fontSize: 12,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w800,
                    )),
                const Spacer(),
                Obx(() => IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: c.toggleFa,
                      icon: Icon(
                        Icons.translate,
                        size: 20,
                        color: c.showFa.value
                            ? cs.primary
                            : cs.onSurfaceVariant,
                      ),
                    )),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 14),
          Obx(() => HighlightedTranscript(
                text: c.currentSegment.transcript,
                highlight: c.currentSegment.highlight,
              )),
          // Persian gloss
          Obx(() => c.showFa.value
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 13),
                      decoration: BoxDecoration(
                        color: DornaColors.accentCyan.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(DornaRadii.md),
                        border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        c.currentSegment.fa,
                        style: tt.bodyLarge?.copyWith(
                            color: cs.onSurface, height: 1.8, fontSize: 15),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink()),
          const SizedBox(height: DornaSpacing.gutter),
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => _SaveButton(
                    saved: c.isSaved,
                    onTap: () {
                      c.toggleSave();
                      showCustomToast(
                          c.isSaved ? 'Phrase saved' : 'Removed from saved',
                          context,
                          isSuccess: c.isSaved);
                    },
                  )),
              Obx(() => DotIndicator(
                    count: c.segments.length,
                    activeIndex: c.currentIndex,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saved;
  final VoidCallback onTap;
  const _SaveButton({required this.saved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(DornaRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DornaRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(saved ? Icons.bookmark : Icons.bookmark_border,
                  size: 18, color: cs.primary),
              const SizedBox(width: 7),
              Text(saved ? 'Saved' : 'Save phrase',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      )),
            ],
          ),
        ),
      ),
    );
  }
}
