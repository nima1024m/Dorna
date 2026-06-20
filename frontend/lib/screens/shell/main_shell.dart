import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/today/today_controller.dart';
import '../../widgets/home/brief_mini_player.dart';
import '../../widgets/ui/dorna_bottom_nav.dart';
import '../brief/brief_player_screen.dart';
import '../home/today_screen.dart';

/// The redesign's 3-tab app shell (Today / Practice / Profile).
///
/// Today (Phase 6) is live; Practice and Profile are placeholders filled in by
/// their phases (Practice → practice hub, Profile → Phase 9). The brief
/// mini-player docks just above the nav once a brief has started.
class MainShell extends StatefulWidget {
  static const String routeName = '/main';

  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final TodayController _today = Get.put(TodayController());

  late final List<Widget> _tabs = const [
    TodayScreen(),
    _TabPlaceholder(title: 'Practice', icon: Icons.forum_outlined),
    _TabPlaceholder(title: 'Profile', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(
            () => _today.briefStarted.value
                ? BriefMiniPlayer(
                    playing: _today.briefPlaying.value,
                    onToggle: _today.toggleMiniPlayer,
                    onClose: _today.dismissMiniPlayer,
                    onTap: () => Get.toNamed(BriefPlayerScreen.routeName),
                  )
                : const SizedBox.shrink(),
          ),
          DornaBottomNav(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: const [
              DornaNavItem(icon: Icons.graphic_eq, label: 'Today'),
              DornaNavItem(icon: Icons.forum, label: 'Practice'),
              DornaNavItem(icon: Icons.person, label: 'Profile'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Temporary placeholder for an unbuilt tab. Replaced by the real screen in the
/// tab's phase.
class _TabPlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;

  const _TabPlaceholder({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: cs.primary),
            const SizedBox(height: 12),
            Text(
              '$title — coming soon',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
