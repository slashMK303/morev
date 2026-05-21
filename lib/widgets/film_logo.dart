import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

class FilmLogo extends StatelessWidget {
  final double iconSize;
  final bool showText;

  const FilmLogo({super.key, this.iconSize = 72, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Kontainer logo dengan efek glow
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(iconSize * 0.28),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFE043),
                Color(0xFFD97706),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGold.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/images/icon.svg',
              width: iconSize * 0.55,
              height: iconSize * 0.55,
              colorFilter: const ColorFilter.mode(
                Color(0xFF18191E),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          const Text(
            'Morev',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Movie Review',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF9E9E9E),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
