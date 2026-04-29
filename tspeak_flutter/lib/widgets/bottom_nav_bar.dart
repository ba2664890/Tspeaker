import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 90,
      color: Colors.white,
      elevation: 0,
      padding: EdgeInsets.zero,
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, Icons.home_rounded, 'HOME', 0),
          _buildNavItem(context, Icons.auto_stories_rounded, 'PRACTICE', 1),
          const SizedBox(width: 60), // Space for FAB
          _buildNavItem(context, Icons.emoji_events_rounded, 'RANKS', 3),
          _buildNavItem(context, Icons.account_circle_rounded, 'PROFILE', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.onSurface.withOpacity(0.3),
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isSelected ? AppColors.primary : AppColors.onSurface.withOpacity(0.3),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingMicButton extends StatelessWidget {
  final VoidCallback onTap;

  const FloatingMicButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      margin: const EdgeInsets.only(top: 32), // Raise it slightly
      child: FloatingActionButton(
        onPressed: onTap,
        backgroundColor: AppColors.onSurface,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.mic_rounded,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}
