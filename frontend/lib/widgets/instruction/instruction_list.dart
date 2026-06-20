import 'package:dorna/utils/utils.dart';
import 'package:flutter/material.dart';

class InstructionList extends StatelessWidget {
  final List<String> instructions;
  final bool isCompleted;
  final int activeStep;
  final int startIndex;
  final List<Widget?>? customWidgets;

  const InstructionList({
    super.key,
    required this.instructions,
    required this.isCompleted,
    this.activeStep = 0,
    this.startIndex = 0,
    this.customWidgets,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final isStepCompleted = isCompleted || index < activeStep;
        final isCurrentStep = index == activeStep;
        final isFilled = isStepCompleted || index == activeStep;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Number circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? cs.primary : cs.surfaceContainerLowest,
                border: Border.all(color: cs.primary, width: 1),
              ),
              child: isStepCompleted
                  ? Icon(Icons.done, color: cs.onPrimary, size: 12)
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${index + 1 + startIndex}',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: isFilled ? cs.onPrimary : cs.primary,
                                  fontSize: 12.sp,
                                ),
                      ),
                    ),
            ),
            const SizedBox(width: 20),
            // Connecting line and text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  customWidgets != null &&
                          index < customWidgets!.length &&
                          customWidgets![index] != null
                      ? customWidgets![index]!
                      : Text(
                          instructions[index],
                          style: (isCurrentStep && !isStepCompleted
                                  ? Theme.of(context).textTheme.displayLarge
                                  : Theme.of(context).textTheme.bodyMedium)
                              ?.copyWith(
                            color: isStepCompleted
                                ? cs.onSurfaceVariant
                                : cs.onSurface,
                            fontSize: 13.sp,
                          ),
                        ),
                ],
              ),
            ),
          ],
        );
      },
      separatorBuilder: (context, index) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 2,
          height: 30,
          margin: const EdgeInsets.only(top: 8, bottom: 8, left: 10),
          color: cs.outlineVariant,
        ),
      ),
      itemCount: instructions.length,
    );
  }
}
