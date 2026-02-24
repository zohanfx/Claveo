import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/password_generator.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;

  const PasswordStrengthIndicator({super.key, required this.strength});

  Color get _color {
    switch (strength) {
      case PasswordStrength.weak:
        return AppColors.strengthWeak;
      case PasswordStrength.fair:
        return AppColors.strengthFair;
      case PasswordStrength.good:
        return AppColors.strengthGood;
      case PasswordStrength.strong:
        return AppColors.strengthStrong;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (strength == PasswordStrength.none) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strength.progress,
            backgroundColor: _color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(_color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Seguridad: ${strength.label}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
