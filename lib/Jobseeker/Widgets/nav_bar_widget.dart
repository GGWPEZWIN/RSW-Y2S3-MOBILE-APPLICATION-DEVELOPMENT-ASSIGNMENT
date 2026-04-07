import 'package:flutter/material.dart';

// Reusable nav bar, prevent maintenance nightmare
class NavBarWidget extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const NavBarWidget({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  State<NavBarWidget> createState() => _NavBarWidgetState();
}

class _NavBarWidgetState extends State<NavBarWidget> {
  // Constants for styling to match your JobBuddy theme
  static const Color kBlue = Color(0xFF2F6FED);
  static const Color kTextSecondary = Color(0xFF6B7280);
  static const Color kBorder = Color(0xFFE4E9F0);

  // Your defined labels and icons
  final List<String> _labels = ['Home', 'Saved', 'Applied', 'Profile'];

  final List<IconData> _icons = [
    Icons.home_outlined,
    Icons.bookmark_border_rounded,
    Icons.work_outline_rounded,
    Icons.person_outline_rounded,
  ];

  final List<IconData> _activeIcons = [
    Icons.home_rounded,
    Icons.bookmark_rounded,
    Icons.work_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kBorder, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SafeArea(
        top: false, // Ensures padding for iPhones with "Home bars"
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_labels.length, (index) {
            final bool isActive = widget.currentIndex == index;

            return GestureDetector(
              behavior: HitTestBehavior.opaque, // Makes the empty space clickable
              onTap: () => widget.onTabSelected(index),
              child: _buildNavItem(
                isActive ? _activeIcons[index] : _icons[index],
                _labels[index],
                isActive: isActive,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false}) {
    final color = isActive ? kBlue : kTextSecondary;
    return SizedBox(
      width: 70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: color,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}