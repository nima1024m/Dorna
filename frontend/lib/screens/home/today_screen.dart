import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/brief/brief_player_controller.dart';
import '../../controllers/calendar/calendar_controller.dart';
import '../../controllers/today/today_controller.dart';
import '../../theme/app_tokens.dart';
import '../../utils/utils.dart';
import '../../widgets/home/around_you_teaser.dart';
import '../../widgets/home/brief_hero_card.dart';
import '../../widgets/home/empty_plan_card.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/plan_event_tile.dart';
import '../../widgets/ui/toast.dart';
import '../brief/brief_player_screen.dart';

/// The **Today** tab — the redesign's daily home hub. Switches between the
/// populated layout and the "welcome / no events yet" empty state.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  void _comingSoon(BuildContext context, String what) =>
      showCustomToast('$what is coming soon', context);

  Future<void> _showEventPrep(
      BuildContext context, CalendarController cal, String id) async {
    final prep = await cal.eventPrep(id);
    if (!context.mounted) return;
    final summary = prep?['summary']?.toString();
    showCustomToast(
      summary?.isNotEmpty == true ? summary! : 'Event prep is coming soon',
      context,
      isSuccess: summary?.isNotEmpty == true,
    );
  }

  @override
  Widget build(BuildContext context) {
    Utils.appContext = context;
    final c = Get.find<TodayController>();
    final brief = Get.find<BriefPlayerController>();
    final cal = Get.find<CalendarController>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Obx(() {
        // Real calendar events take precedence over the placeholder plan.
        final realEvents =
            cal.events.where((e) => (e.title ?? '').isNotEmpty).toList();
        final empty = realEvents.isEmpty;
        final bottomClear = brief.started.value ? 150.0 : 96.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(DornaSpacing.screenMargin, 24,
              DornaSpacing.screenMargin, bottomClear),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(
                title: empty ? 'Welcome, ${c.firstName}' : c.greeting,
                welcome: empty,
                subtitle: 'Your English companion',
                dateLabel: c.dateLabel,
                weatherTemp: TodayController.weatherTemp,
                weatherLabel: TodayController.weatherLabel,
                weatherIcon: TodayController.weatherIcon,
              ),
              const SizedBox(height: DornaSpacing.xl),
              BriefHeroCard(
                title: TodayController.briefTitle,
                subtitle: empty
                    ? 'Daily English insights for your life in Canada.'
                    : TodayController.briefSubtitle,
                durationLabel: empty ? '5 MIN' : TodayController.briefDuration,
                durationIcon: empty ? Icons.timer_outlined : null,
                playOnLeft: !empty,
                onPlay: () {
                  brief.play();
                  Get.toNamed(BriefPlayerScreen.routeName);
                },
              ),
              const SizedBox(height: DornaSpacing.xl),
              // Plan section header
              if (empty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Plan",
                        style: tt.titleLarge?.copyWith(
                            color: cs.onSurface, fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: () => _comingSoon(context, 'Calendar'),
                      child: Text('Connect',
                          style: tt.labelLarge?.copyWith(color: cs.primary)),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("TODAY'S PLAN",
                        style: tt.labelLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                        )),
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: cs.onSurfaceVariant),
                  ],
                ),
              const SizedBox(height: DornaSpacing.md),
              if (empty)
                EmptyPlanCard(
                  icon: Icons.edit_calendar_outlined,
                  title: 'No events yet',
                  body:
                      'Connect your calendar to get prep before meetings and events',
                  ctaLabel: 'Connect calendar',
                  onCta: () => _comingSoon(context, 'Calendar connection'),
                )
              else
                Column(
                  children: [
                    for (final e in realEvents) ...[
                      PlanEventTile(
                        time: e.timeLabel,
                        title: e.title ?? 'Event',
                        dotAccent: e != realEvents.first,
                        onTap: () => _showEventPrep(context, cal, e.id),
                      ),
                      if (e != realEvents.last)
                        const SizedBox(height: DornaSpacing.sm),
                    ],
                  ],
                ),
              const SizedBox(height: DornaSpacing.gutter),
              AroundYouTeaser(
                place: empty ? null : c.aroundPlace.value,
                tip: TodayController.aroundTip,
                onTap: () => _comingSoon(
                    context, empty ? 'Location tips' : 'Around You'),
              ),
            ],
          ),
        );
      }),
    );
  }
}
