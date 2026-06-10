import 'package:dorna/utils/utils.dart';
import 'package:flutter/material.dart';

import '../ui/app_colors.dart';

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
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final isStepCompleted = isCompleted || index < activeStep;
        final isCurrentStep = index == activeStep;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Number circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isStepCompleted || index == activeStep
                    ? AppColors.primaryColor()
                    : isDarkMode
                        ? Colors.transparent
                        : Colors.white,
                border: Border.all(
                  color: AppColors.primaryColor(),
                  width: 1,
                ),
              ),
              child: isStepCompleted
                  ? const Icon(
                      Icons.done,
                      color: Colors.white,
                      size: 12,
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${index + 1 + startIndex}',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: isCurrentStep || isStepCompleted
                            ? (isDarkMode ? Colors.black : Colors.white)
                                  : AppColors.primaryColor(),
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
                          style: isCurrentStep && !isStepCompleted
                              ? Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    color: isStepCompleted
                                        ? Colors.grey
                                        : AppColors.textMain(),
                                    fontSize: 13.sp,
                                  )
                              : Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: isStepCompleted
                                        ? Colors.grey
                                        : AppColors.textMain(),
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
          color: isDarkMode ? const Color(0xff2E373F) : const Color(0xffCFD6DC),
        ),
      ),
      itemCount: instructions.length,
    );
  }
}
