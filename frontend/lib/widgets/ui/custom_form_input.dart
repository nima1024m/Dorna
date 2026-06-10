import 'dart:io';
import 'dart:math';

import 'package:dorna/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_colors.dart';

// Custom Input
class CustomFormInput extends StatefulWidget {
  final bool isSecureText;
  final FormFieldValidator? validator;
  final String? hintText;
  final TextInputType keyboardType;
  final int? maxLength;
  final String? title;
  bool isEnabled;
  final bool useFormatter;
  IconData? suffixIcon;
  Widget? suffix;
  Widget? prefix;
  final TextDirection? textDirection;
  final TextAlign? inputTextAlign;
  final TextEditingController? controller;
  final FocusNode? nextFocusNode;
  FocusNode? inputFocusNode;

  final Function(String)? onFieldSubmitted;
  final Function(String)? onChanged;

  final VoidCallback? onIconPressed;
  final TextInputAction? textInputAction;
  final bool? filled;
  final Color? fillColor;
  final int? minLines;
  final int maxLines;
  final InputBorder? border;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final TextStyle? style;
  final String? initialValue;
  final String? prefixSvg;
  final String? prefixSvgFocused;
  final Alignment? alignment;
  final VoidCallback? onTap;
  final bool useDropDownMode;
  final bool useDropDownIcon;
  final EdgeInsets? contentPadding;
  final Color? unFocusedLabelColor;
  Color? borderColor;
  final BorderRadius? borderRadius;
  final ScrollController? scrollController;
  final GlobalKey<FormState>? formKey;

  CustomFormInput({
    super.key,
    this.title,
    this.isSecureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.validator,
    this.textDirection,
    this.hintText,
    this.alignment,
    this.isEnabled = true,
    this.suffixIcon,
    this.prefixSvg,
    this.prefixSvgFocused,
    this.inputTextAlign,
    this.controller,
    this.inputFocusNode,
    this.onFieldSubmitted,
    this.onIconPressed,
    this.useFormatter = true,
    this.textInputAction,
    this.fillColor,
    this.filled,
    this.suffix,
    this.nextFocusNode,
    this.onChanged,
    this.minLines,
    this.maxLines = 1,
    this.border,
    this.hintStyle,
    this.initialValue,
    this.labelStyle,
    this.onTap,
    this.style,
    this.contentPadding,
    this.unFocusedLabelColor,
    this.borderRadius,
    this.prefix,
    this.scrollController,
    this.borderColor,
    this.formKey,
    this.useDropDownMode = false,
    this.useDropDownIcon = false,
  });

  @override
  State<CustomFormInput> createState() => _CustomFormInputState();
}

class _CustomFormInputState extends State<CustomFormInput>
    with SingleTickerProviderStateMixin {
  bool hasError = false;
  bool removeErrors = false;
  bool isFocused = false;
  bool _obscureText = false;
  double _thumbHeight = 0;
  double _thumbTop = 0;
  double _trackHeight = 0;
  bool _isDraggingThumb = false;
  double _dragStartThumbTop = 0;
  double _dragStartLocalY = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticIn,
      ),
    );

    _obscureText = widget.isSecureText;
    widget.inputFocusNode ??= FocusNode();
    widget.inputFocusNode?.addListener(() {
      if (widget.inputFocusNode!.hasFocus && !isFocused && mounted) {
        setState(() {
          isFocused = true;
        });
        removeErrors = true;
        widget.formKey?.currentState?.validate();
        removeErrors = false;
      }
      if (!widget.inputFocusNode!.hasFocus && isFocused && mounted) {
        setState(() {
          isFocused = false;
        });
      }
    });

    if (widget.useDropDownMode) {
      widget.isEnabled = false;
    }

    if (widget.maxLines > 1) {
      widget.scrollController?.addListener(_updateThumbPosition);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateThumbPosition();
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.maxLines > 1) {
      widget.scrollController?.removeListener(_updateThumbPosition);
      widget.scrollController?.dispose();
    }
    super.dispose();
  }

  void _updateThumbPosition() {
    if (mounted &&
        widget.maxLines > 1 &&
        widget.scrollController?.hasClients == true) {
      double maxScroll = widget.scrollController!.position.maxScrollExtent;
      double currentScroll = widget.scrollController!.position.pixels;
      double viewportHeight =
          widget.scrollController!.position.viewportDimension;
      setState(() {
        if (maxScroll > 0) {
          _thumbHeight =
              (viewportHeight / (maxScroll + viewportHeight)) * viewportHeight;
          _thumbTop =
              (currentScroll / maxScroll) * (viewportHeight - _thumbHeight);
          if (_thumbTop < 0) _thumbTop = 0;
          if (_thumbHeight < 0) _thumbHeight = 0;
          if (_thumbHeight > viewportHeight) _thumbHeight = viewportHeight;
        } else {
          _thumbTop = 0;
          _thumbHeight = 0;
        }
      });
    }
  }

  void _jumpToScrollByThumbTop(double thumbTop) {
    if (!mounted ||
        widget.scrollController?.hasClients != true ||
        _trackHeight <= 0) {
      return;
    }
    final double maxScroll = widget.scrollController!.position.maxScrollExtent;
    final double maxThumbTravel =
        (_trackHeight - _thumbHeight).clamp(0, double.infinity);
    if (maxScroll <= 0 || maxThumbTravel <= 0) return;
    final double clampedThumbTop = thumbTop.clamp(0, maxThumbTravel);
    final double scrollPixels = (clampedThumbTop / maxThumbTravel) * maxScroll;
    widget.scrollController?.jumpTo(scrollPixels);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useDropDownIcon) {
      widget.suffix = SvgPicture.asset(
        isFocused
            ? 'assets/icons/ic_arrow_blue.svg'
            : 'assets/icons/ic_arrow_grey.svg',
        width: 10,
        height: 10,
      );
    }
    var borderRadius = widget.borderRadius ?? BorderRadius.circular(12);
    widget.borderColor = isFocused
        ? Theme.of(context).colorScheme.primary
        : hasError
            ? AppColors.errorText
            : AppColors.greySubtext();
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (hasError &&
        widget.validator != null &&
        widget.validator!(widget.controller?.text) == null) {
      removeErrors = true;
      widget.formKey?.currentState?.validate();
      removeErrors = false;
      hasError = false;
    }

    double borderWidth = 1.3;
    return GestureDetector(
      onTap: widget.useDropDownMode ? widget.onTap : null,
      child: AbsorbPointer(
        absorbing: widget.useDropDownMode,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(sin(_animation.value * 2 * 3.1415926535) * 10, 0),
              child: child,
            );
          },
          child: Stack(
            alignment: widget.alignment ?? Alignment.center,
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                // height: 50,
                child: Form(
                  key: widget.formKey,
                  child: TextFormField(
                    initialValue: widget.initialValue,
                    maxLength: widget.maxLength,
                    onTap: widget.onTap,
                    autocorrect: !(widget.isSecureText ||
                        widget.keyboardType == TextInputType.emailAddress),
                    enableSuggestions: !(widget.isSecureText ||
                        widget.keyboardType == TextInputType.emailAddress),
                    textCapitalization: (widget.isSecureText ||
                            widget.keyboardType == TextInputType.emailAddress)
                        ? TextCapitalization.none
                        : TextCapitalization.sentences,
                    contextMenuBuilder: (BuildContext context,
                        EditableTextState editableTextState) {
                      final List<ContextMenuButtonItem> buttonItems =
                          editableTextState.contextMenuButtonItems;

                      // Add the "Select" option if it's not already present.
                      if (!buttonItems.any((ContextMenuButtonItem button) =>
                              button.type == ContextMenuButtonType.custom) &&
                          Platform.isIOS &&
                          editableTextState.textEditingValue.text.isNotEmpty) {
                        // Add "Select Last Word" option
                        buttonItems.insert(
                          0,
                          ContextMenuButtonItem(
                            label: 'Select',
                            onPressed: () {
                              final text =
                                  editableTextState.textEditingValue.text;
                              final cursorPosition = editableTextState
                                  .textEditingValue.selection.baseOffset;

                              if (cursorPosition >= 0 &&
                                  cursorPosition <= text.length) {
                                int wordStart, wordEnd;

                                // Check if cursor is in the middle of a word
                                if (cursorPosition > 0 &&
                                    cursorPosition < text.length &&
                                    text[cursorPosition - 1]
                                        .trim()
                                        .isNotEmpty &&
                                    text[cursorPosition].trim().isNotEmpty) {
                                  // Cursor is in the middle of a word, select that word
                                  wordStart = cursorPosition - 1;
                                  while (wordStart > 0 &&
                                      text[wordStart - 1].trim().isNotEmpty) {
                                    wordStart--;
                                  }
                                  wordEnd = cursorPosition;
                                  while (wordEnd < text.length &&
                                      text[wordEnd].trim().isNotEmpty) {
                                    wordEnd++;
                                  }
                                } else if (cursorPosition < text.length &&
                                    text[cursorPosition].trim().isNotEmpty) {
                                  // Cursor is before a word, select the next word
                                  wordStart = cursorPosition;
                                  wordEnd = cursorPosition;
                                  while (wordEnd < text.length &&
                                      text[wordEnd].trim().isNotEmpty) {
                                    wordEnd++;
                                  }
                                } else if (cursorPosition > 0 &&
                                    text[cursorPosition - 1]
                                        .trim()
                                        .isNotEmpty) {
                                  // Cursor is after a word, select the previous word
                                  wordStart = cursorPosition - 1;
                                  while (wordStart > 0 &&
                                      text[wordStart - 1].trim().isNotEmpty) {
                                    wordStart--;
                                  }
                                  wordEnd = cursorPosition;
                                } else {
                                  // No word found, return
                                  return;
                                }

                                editableTextState.userUpdateTextEditingValue(
                                  editableTextState.textEditingValue.copyWith(
                                    selection: TextSelection(
                                      baseOffset: wordStart,
                                      extentOffset: wordEnd,
                                    ),
                                  ),
                                  SelectionChangedCause.toolbar,
                                );
                              }
                            },
                          ),
                        );
                      }
                      return AdaptiveTextSelectionToolbar.buttonItems(
                        anchors: editableTextState.contextMenuAnchors,
                        buttonItems: buttonItems,
                      );
                    },
                    onTapOutside: (d) {
                      widget.inputFocusNode?.unfocus();
                    },
                    validator: (s) {
                      if (removeErrors) {
                        setState(() {
                          hasError = false;
                        });

                        return null;
                      }
                      if (widget.validator != null) {
                        var res = widget.validator!(s);
                        if (res == null) {
                          setState(() {
                            hasError = false;
                          });
                        } else {
                          _controller.forward(from: 0.0);
                          setState(() {
                            hasError = true;
                          });
                        }
                        return res;
                      }
                      return null;
                    },
                    keyboardType: widget.keyboardType,
                    focusNode: widget.inputFocusNode,
                    textInputAction: widget.textInputAction,
                    textDirection: widget.textDirection ?? TextDirection.ltr,
                    minLines: widget.minLines,
                    maxLines: widget.maxLines,
                    onFieldSubmitted: (s) {
                      widget.formKey?.currentState?.validate();
                      if (widget.onFieldSubmitted != null) {
                        FocusScope.of(context).unfocus();

                        widget.onFieldSubmitted!(s);
                        return;
                      }
                      FocusScope.of(context).requestFocus(widget.nextFocusNode);
                    },
                    onChanged: (s) {
                      widget.onChanged?.call(s);
                      if (widget.maxLines > 1) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _updateThumbPosition();
                          }
                        });
                      }
                      if (widget.controller?.text.isEmpty == true) {
                        removeErrors = true;
                        widget.formKey?.currentState?.validate();
                        removeErrors = false;
                      }
                    },
                    scrollController:
                        widget.maxLines > 1 ? widget.scrollController : null,
                    controller: widget.controller,
                    obscureText: _obscureText,
                    obscuringCharacter: '*',
                    onTapUpOutside: (d) {
                      widget.formKey?.currentState?.validate();
                      widget.inputFocusNode?.unfocus();
                    },
                    textAlign: widget.inputTextAlign ?? TextAlign.start,
                    style: widget.style ??
                        Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 13.sp,
                              color: AppColors.textMain(),
                            ),
                    cursorColor: Theme.of(context).colorScheme.primary,
                    decoration: InputDecoration(
                      isDense: true,
                      counterText: '',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: widget.contentPadding ??
                          const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                      border: widget.border ??
                          OutlineInputBorder(
                            borderSide: BorderSide(
                              width: borderWidth,
                              color: widget.borderColor!,
                            ),
                            borderRadius: borderRadius,
                          ),
                      focusedBorder: widget.border ??
                          OutlineInputBorder(
                            borderSide: BorderSide(
                              width: borderWidth,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            borderRadius: borderRadius,
                          ),
                      labelText: widget.title,
                      alignLabelWithHint: false,
                      disabledBorder: widget.border ??
                          OutlineInputBorder(
                            borderSide: BorderSide(
                              color: widget.borderColor!,
                              width: borderWidth,
                            ),
                            borderRadius: borderRadius,
                          ),
                      enabledBorder: widget.border ??
                          OutlineInputBorder(
                            borderSide: BorderSide(
                              color: widget.borderColor!,
                              width: borderWidth,
                            ),
                            borderRadius: borderRadius,
                          ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: widget.borderColor!,
                          width: borderWidth,
                        ),
                        borderRadius: borderRadius,
                      ),
                      hintText: widget.hintText,
                      enabled: widget.isEnabled,
                      prefixIcon: widget.prefix ??
                          (widget.prefixSvg != null
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: SvgPicture.asset(
                                    isFocused
                                        ? widget.prefixSvgFocused.toString()
                                        : widget.prefixSvg.toString(),
                                    width: 25,
                                    height: 25,
                                  ),
                                )
                              : null),
                      prefixIconConstraints:
                          const BoxConstraints(maxHeight: 35, maxWidth: 55),
                      hintStyle: widget.hintStyle ??
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 13.sp,
                                color: isDarkMode
                                    ? const Color(0xffFFFFFF).withOpacity(0.25)
                                    : const Color(0xff2E3633).withOpacity(0.25),
                              ),
                      errorStyle: const TextStyle(fontSize: 0),
                      labelStyle: widget.labelStyle?.copyWith(
                            color: hasError
                                ? AppColors.errorText
                                : isFocused
                                    ? Theme.of(context).colorScheme.primary
                                    : (widget.unFocusedLabelColor),
                          ) ??
                          Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: hasError
                                    ? AppColors.errorText
                                    : isFocused
                                        ? Theme.of(context).colorScheme.primary
                                        : (widget.unFocusedLabelColor ??
                                            AppColors.greySubtext()),
                                fontSize: 14.sp,
                              ),
                      fillColor: widget.fillColor ?? Colors.transparent,
                      filled: widget.filled ?? true,
                      suffixIcon: widget.isSecureText
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.greySubtext().withOpacity(0.5),
                                size: 23,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              if (hasError)
                Positioned(
                  left: 16,
                  bottom: -20,
                  child: Text(
                    '${widget.validator != null ? widget.validator!(widget.controller?.text) : ''}',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: hasError &&
                                widget.validator != null &&
                                widget.validator!(widget.controller?.text)
                                        ?.isEmpty ==
                                    true
                            ? 0
                            : 11.sp,
                        color: AppColors.errorText),
                  ),
                ),
              if (widget.maxLines > 1 && _thumbHeight > 0)
                Positioned(
                  right: 8,
                  top: 15,
                  bottom: 15,
                  child: LayoutBuilder(builder: (context, constraints) {
                    _trackHeight = constraints.maxHeight;
                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onVerticalDragStart: (details) {
                        _isDraggingThumb = true;
                        _dragStartLocalY = details.localPosition.dy;
                        _dragStartThumbTop = _thumbTop;
                      },
                      onVerticalDragUpdate: (details) {
                        if (!_isDraggingThumb) return;
                        final double deltaY =
                            details.localPosition.dy - _dragStartLocalY;
                        final double newThumbTop = _dragStartThumbTop + deltaY;
                        _jumpToScrollByThumbTop(newThumbTop);
                      },
                      onVerticalDragEnd: (_) {
                        _isDraggingThumb = false;
                      },
                      onTapDown: (details) {
                        // Jump to the position where user taps on the track
                        final double desiredCenterTop =
                            details.localPosition.dy - (_thumbHeight / 2);
                        _jumpToScrollByThumbTop(desiredCenterTop);
                      },
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: <Widget>[
                          // Track
                          Container(
                            width: 16,
                            height: constraints.maxHeight,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          // Thumb
                          Positioned(
                            top: _thumbTop,
                            right: 4,
                            child: Container(
                              width: 4,
                              height: _thumbHeight,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              if (widget.suffix != null || widget.suffixIcon != null)
                Positioned(
                  left: 16,
                  top: hasError ? 16.sp : null,
                  child: Center(
                    child: GestureDetector(
                        onTap: widget.onIconPressed,
                        child: widget.suffixIcon != null
                            ? Icon(
                                widget.suffixIcon,
                                color: AppColors.grey4,
                              )
                            : widget.suffix!),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
