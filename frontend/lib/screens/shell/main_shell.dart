import 'package:flutter/material.dart';

import '../../widgets/ui/dorna_bottom_nav.dart';

/// The redesign's 3-tab app shell (Today / Practice / Profile).
///
/// Tab bodies are placeholders for now; each is filled in by its own phase:
/// Today → Phase 6 (home hub), Practice → F5 (practice hub), Profile → Phase 9.
/// Splash/onboarding will route here once the Today hub lands (Phase 6).
class MainShell extends StatefulWidget {
  static const String routeName = '/main';

  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const List<Widget> _tabs = <Widget>[
    _TabPlaceholder(title: 'Today', icon: Icons.graphic_eq),
    _TabPlaceholder(title: 'Practice', icon: Icons.forum_outlined),
    _TabPlaceholder(title: 'Profile', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: DornaBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          DornaNavItem(icon: Icons.graphic_eq, label: 'Today'),
          DornaNavItem(icon: Icons.forum, label: 'Practice'),
          DornaNavItem(icon: Icons.person, label: 'Profile'),
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
