import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/brief/brief_player_controller.dart';
import '../../controllers/phrase/phrase_controller.dart';
import '../../controllers/today/today_controller.dart';
import '../../services/push_service.dart';
import '../../widgets/home/brief_mini_player.dart';
import '../../widgets/ui/dorna_bottom_nav.dart';
import '../brief/brief_player_screen.dart';
import '../home/today_screen.dart';
import '../practice/practice_screen.dart';
import '../profile/profile_tab_screen.dart';

/// The redesign's 3-tab app shell (Today / Practice / Profile), all live. The
/// brief mini-player docks just above the nav once a brief has started.
class MainShell extends StatefulWidget {
  static const String routeName = '/main';

  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const List<Widget> _tabs = [
    TodayScreen(),
    PracticeScreen(),
    ProfileTabScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Shell-scoped controllers shared by the tabs and the mini-player.
    Get.put(TodayController());
    Get.put(BriefPlayerController());
    Get.put(PhraseController());
    // Register for push now that the user is authenticated (F7).
    PushService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    final brief = Get.find<BriefPlayerController>();
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(
            () => brief.started.value
                ? BriefMiniPlayer(
                    playing: brief.isPlaying.value,
                    onToggle: brief.togglePlay,
                    onClose: brief.stop,
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
