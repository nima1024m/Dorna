import 'package:dorna/services/keyboard_service.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/back_header.dart';
import 'package:dorna/widgets/ui/custom_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../widgets/tones/tone_detail_card.dart';
import '../../widgets/ui/app_colors.dart';

class TonesScreen extends StatefulWidget {
  static const String routeName = '/tones';

  const TonesScreen({Key? key}) : super(key: key);

  @override
  State<TonesScreen> createState() => _TonesScreenState();
}

class _TonesScreenState extends State<TonesScreen> {
  final KeyboardService _keyboardService = KeyboardService();
  late List<String> _favoriteTones = [];
  bool _isFormalExpanded = true;
  bool _isFriendlyExpanded = false;
  bool _isAcademicExpanded = false;

  void _toggleFormal() {
    setState(() {
      _isFormalExpanded = !_isFormalExpanded;
    });
  }

  void _toggleFriendly() {
    setState(() {
      _isFriendlyExpanded = !_isFriendlyExpanded;
    });
  }

  void _toggleAcademic() {
    setState(() {
      _isAcademicExpanded = !_isAcademicExpanded;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadFavoriteTones();
  }

  Future<void> _loadFavoriteTones() async {
    try {
      final favorites = await _keyboardService.getFavoriteTones();
      setState(() {
        _favoriteTones = favorites.toList();
      });
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> _toggleFavorite(String toneName) async {
    try {
      bool isCurrentlyFavorite = _favoriteTones.contains(toneName);

      if (isCurrentlyFavorite) {
        // Remove from favorites
        _keyboardService.removeFavoriteTone(toneName);
        setState(() {
          _favoriteTones.remove(toneName);
        });
      } else {
        // Add to favorites (with max 2 limit)
        if (_favoriteTones.length >= 2) {
          // Remove the first favorite
          String firstFavorite = _favoriteTones.first;
          _keyboardService.removeFavoriteTone(firstFavorite);
          setState(() {
            _favoriteTones.removeAt(0);
          });
        }

        // Add the new favorite
        _keyboardService.addFavoriteTone(toneName);
        setState(() {
          _favoriteTones.add(toneName);
        });
      }
    } catch (e) {
      debugPrint('mylog err _toggleFavorite=${e.toString()}');
    }
  }

  bool _isFavorite(String toneName) {
    return _favoriteTones.contains(toneName);
  }

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
                title: 'Writing Tones',
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      CustomListTile(
                        leading: _buildIcon(
                            icon: 'assets/images/formal.png',
                            toneName: 'Formal'),
                        title: 'Formal',
                        padding: const EdgeInsets.only(
                            right: 20, bottom: 20, top: 20),
                        onTap: _toggleFormal,
                        showArrow: true,
                        style: style,
                        initExpanded: _isFormalExpanded,
                        expandedBackgroundColor:
                            const Color(0xff1E3A8A).withOpacity(0.15),
                        expandedWidget: _buildFormalDetailsCard(),
                      ),
                      const SizedBox(height: 24),
                      CustomListTile(
                        leading: _buildIcon(
                            icon: 'assets/images/friendly.png',
                            toneName: 'Friendly'),
                        title: 'Friendly',
                        padding: const EdgeInsets.only(
                            right: 20, bottom: 20, top: 20),
                        onTap: _toggleFriendly,
                        showArrow: true,
                        style: style,
                        initExpanded: _isFriendlyExpanded,
                        expandedBackgroundColor:
                            const Color(0xffFF7818).withOpacity(0.15),
                        expandedWidget: _buildFriendlyDetailsCard(),
                      ),
                      const SizedBox(height: 24),
                      CustomListTile(
                        leading: _buildIcon(
                          icon: 'assets/images/concise.png',
                          toneName: 'Concise',
                        ),
                        title: 'Concise',
                        padding: const EdgeInsets.only(
                            right: 20, bottom: 20, top: 20),
                        onTap: _toggleAcademic,
                        showArrow: true,
                        style: style,
                        initExpanded: _isAcademicExpanded,
                        expandedBackgroundColor:
                            const Color(0xffF0525C).withOpacity(0.15),
                        expandedWidget: _buildConciseDetailsCard(),
                      ),
                      const SizedBox(height: 24),
                      CustomListTile(
                        leading: _buildAddLanguageIcon(),
                        title: 'Add New Tone',
                        onTap: null,
                        showArrow: false,
                        isEnabled: false,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon({
    required String icon,
    required String toneName,
  }) {
    return Center(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildFavoriteIcon(toneName),
          Image.asset(
            icon,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        ],
      ),
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

  Widget _buildFavoriteIcon(String toneName) {
    bool isFavorite = _isFavorite(toneName);
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _toggleFavorite(toneName),
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Container(
        width: 62,
        height: 32,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SvgPicture.asset(
            isFavorite
                ? 'assets/icons/ic_star_filled.svg'
                : 'assets/icons/ic_star.svg',
            width: 28,
            height: 28,
            color: isDarkMode && !isFavorite
                ? Colors.white.withOpacity(0.4)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildFormalDetailsCard() {
    return const ToneDetailsCard(
      useCases: [
        'Job applications',
        'Official emails',
        'Business reports',
        'Customer service communication',
      ],
      traits: [
        'Polite and respectful',
        'Clear and concise',
        'No slang or contractions',
        'Passive or neutral phrasing',
      ],
      beforeExample: 'Can you send me the file?',
      afterExample:
          'Could you kindly provide the requested file at your earliest convenience?',
      afterLabel: 'After (Formal)',
    );
  }

  Widget _buildFriendlyDetailsCard() {
    return const ToneDetailsCard(
      useCases: [
        'Chatting with classmates or colleagues',
        'Networking messages (LinkedIn, Meetup)',
        'Asking for help or recommendations',
        'Follow-up messages with a light touch',
      ],
      traits: [
        'Warm and approachable',
        'Conversational language',
        'Uses first-person often ("I", "we")',
        'Light contractions and softening phrases',
      ],
      beforeExample: 'I need help with my resume',
      afterExample:
          'Hey! I’m working on my resume and would love your input if you have a few minutes',
      afterLabel: 'After (Friendly)',
    );
  }

  Widget _buildConciseDetailsCard() {
    return const ToneDetailsCard(
      useCases: [
        'Job Applications',
        'Texting New Friends',
        'Assignments & Reports',
        'Support Requests',
      ],
      traits: [
        'Short, direct sentences',
        'Focuses on the main message',
        'Still polite, but efficient',
        'Reads smoothly, no clutter',
      ],
      beforeExample:
          'Hey, I just wanted to quickly reach out and ask if you maybe had some time this week to help me review my resume, if that’s okay?',
      afterExample: 'Could you help me review my resume this week?',
      afterLabel: 'After (Concise)',
    );
  }
}
