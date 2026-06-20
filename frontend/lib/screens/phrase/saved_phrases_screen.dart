import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/phrase/phrase_controller.dart';
import '../../theme/app_tokens.dart';
import '../../utils/utils.dart';
import '../../widgets/phrase/phrase_card.dart';
import '../../widgets/ui/back_header.dart';

/// The user's saved phrases (backend F1). Reached from Profile → Saved phrases.
class SavedPhrasesScreen extends StatefulWidget {
  static const String routeName = '/saved_phrases';

  const SavedPhrasesScreen({super.key});

  @override
  State<SavedPhrasesScreen> createState() => _SavedPhrasesScreenState();
}

class _SavedPhrasesScreenState extends State<SavedPhrasesScreen> {
  final PhraseController _c = Get.isRegistered<PhraseController>()
      ? Get.find<PhraseController>()
      : Get.put(PhraseController());

  @override
  void initState() {
    super.initState();
    _c.fetchSaved();
  }

  @override
  Widget build(BuildContext context) {
    Utils.appContext = context;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(title: 'Saved phrases'),
            Expanded(
              child: Obx(() {
                if (_c.isLoadingSaved.value && _c.saved.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_c.saved.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_border,
                              size: 56, color: cs.outlineVariant),
                          const SizedBox(height: 14),
                          Text('No saved phrases yet',
                              style: tt.titleLarge?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text('Tap the bookmark on a phrase to save it here.',
                              textAlign: TextAlign.center,
                              style: tt.bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _c.saved.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: DornaSpacing.md),
                  itemBuilder: (context, i) {
                    final p = _c.saved[i];
                    return PhraseCard(
                      phrase: p.copyWith(saved: true),
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
