import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/app_colors.dart';
import 'package:dorna/widgets/ui/back_header.dart';
import 'package:dorna/widgets/ui/custom_list_tile.dart';
import 'package:flutter/material.dart';

class LanguagesScreen extends StatefulWidget {
  static const String routeName = '/languages';

  const LanguagesScreen({Key? key}) : super(key: key);

  @override
  State<LanguagesScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends State<LanguagesScreen> {
  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    var style = Theme.of(context).textTheme.displayLarge?.copyWith(
          fontSize: 14.sp,
          color: isDarkMode ? AppColors.textMain() : const Color(0xFF222222),
        );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const BackHeader(
                title: 'Keyboard Languages',
              ),
              const SizedBox(height: 24),
              CustomListTile(
                leading: _buildCanadaFlag(),
                title: 'English (Canada)',
                onTap: null,
                showArrow: false,
                style: style,
              ),
              const SizedBox(height: 24),
              CustomListTile(
                leading: _buildPersianFlag(),
                title: 'Persian (Farsi)',
                onTap: null,
                showArrow: false,
                style: style,
              ),
              const SizedBox(height: 24),
              CustomListTile(
                leading: _buildAddLanguageIcon(),
                title: 'Add Language',
                onTap: null,
                showArrow: false,
                isEnabled: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanadaFlag() {
    return Image.asset(
      'assets/images/ca_flag.png',
      width: 32,
      height: 32,
      fit: BoxFit.cover,
    );
  }

  Widget _buildPersianFlag() {
    return Image.asset(
      'assets/images/ir_flag.png',
      width: 32,
      height: 32,
      fit: BoxFit.cover,
    );
  }

  Widget _buildAddLanguageIcon() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1)),
      ),
      child: Icon(
        Icons.add,
        color: isDarkMode
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.1),
        size: 20,
      ),
    );
  }
}
