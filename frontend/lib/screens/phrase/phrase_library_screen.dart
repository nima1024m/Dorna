import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/phrase/phrase_controller.dart';
import '../../theme/app_tokens.dart';
import '../../utils/utils.dart';
import '../../widgets/phrase/phrase_card.dart';
import '../../widgets/ui/back_header.dart';

/// Browse the phrase library (backend F1). Reached from Practice → Phrase decks.
class PhraseLibraryScreen extends StatefulWidget {
  static const String routeName = '/phrase_library';

  const PhraseLibraryScreen({super.key});

  @override
  State<PhraseLibraryScreen> createState() => _PhraseLibraryScreenState();
}

class _PhraseLibraryScreenState extends State<PhraseLibraryScreen> {
  final PhraseController _c = Get.isRegistered<PhraseController>()
      ? Get.find<PhraseController>()
      : Get.put(PhraseController());

  @override
  void initState() {
    super.initState();
    _c.fetchPhrases();
  }

  @override
  Widget build(BuildContext context) {
    Utils.appContext = context;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(title: 'Phrase library'),
            Expanded(
              child: Obx(() {
                if (_c.isLoading.value && _c.phrases.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_c.phrases.isEmpty) {
                  return const _Empty(
                    icon: Icons.menu_book_outlined,
                    title: 'No phrases yet',
                    body:
                        'Your phrase library will appear here once it’s available.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _c.phrases.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: DornaSpacing.md),
                  itemBuilder: (context, i) {
                    final p = _c.phrases[i];
                    return PhraseCard(
                      phrase: p,
                      onToggleSave: () => _c.toggleSave(p),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Empty({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: cs.outlineVariant),
            const SizedBox(height: 14),
            Text(title,
                style: tt.titleLarge
                    ?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
