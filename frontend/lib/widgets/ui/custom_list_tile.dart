import 'dart:io';

import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/app_colors.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomListTile extends StatefulWidget {
  final String title;
  final VoidCallback? onTap;
  final bool showArrow;
  final bool isEnabled;
  final bool initExpanded;
  final Widget? expandedWidget;
  final Widget? leading;
  final Widget? trailing;
  final Color? expandedBackgroundColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final TextStyle? style;
  final String? subtitle;

  const CustomListTile({
    Key? key,
    required this.title,
    required this.onTap,
    this.padding,
    this.margin,
    this.leading,
    this.trailing,
    this.expandedWidget,
    this.expandedBackgroundColor,
    this.style,
    this.subtitle,
    this.initExpanded = false,
    this.showArrow = true,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  State<CustomListTile> createState() => _CustomListTileState();
}

class _CustomListTileState extends State<CustomListTile>
    with AutomaticKeepAliveClientMixin {
  late bool isExpanded = widget.initExpanded;
  ExpandableController? expandedController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    if (widget.expandedWidget != null) {
      expandedController = ExpandableController(initialExpanded: isExpanded);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: widget.margin ?? const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: isDarkMode ? Colors.transparent : Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              radius: Platform.isIOS ? 500 : null,
              borderRadius: BorderRadius.circular(12),
              onTap: widget.isEnabled
                  ? widget.expandedWidget != null
                      ? () {
                          setState(() {
                            expandedController?.expanded =
                                !expandedController!.expanded;
                            isExpanded = expandedController!.expanded;
                          });
                        }
                      : widget.onTap
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: widget.padding ??
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(12),
                  color: isExpanded
                      ? widget.expandedBackgroundColor
                      : Colors.transparent,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (widget.leading != null) widget.leading!,
                        if (widget.leading != null) const SizedBox(width: 8),
                        Text(
                          widget.title,
                          style: widget.style ??
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 14.sp,
                                    color: widget.isEnabled
                                        ? AppColors.textMain()
                                        : (isDarkMode
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.black.withOpacity(0.25)),
                                  ),
                        ),
                        const Spacer(),
                        if (widget.trailing != null) widget.trailing!,
                        if (widget.trailing == null && widget.showArrow)
                          RotatedBox(
                            quarterTurns: isExpanded ? 1 : 0,
                            child: SvgPicture.asset(
                              'assets/icons/ic_arrow.svg',
                              width: 16,
                              height: 16,
                              color: AppColors.textMain(),
                            ),
                          ),
                      ],
                    ),
                    buildExpansionView(context),
                  ],
                ),
              ),
            ),
          ),
          if (widget.subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 20, right: 20),
              child: Text(
                widget.subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.greySubtext().withOpacity(0.5),
                      fontSize: 13.sp,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildExpansionView(BuildContext context) {
    return ExpandablePanel(
      controller: expandedController,
      collapsed: Container(),
      expanded: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: widget.expandedWidget,
      ),
    );
  }
}
