import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Non-dismissible dialog that guides the user through a two-step
/// PIN creation flow (enter → confirm).
///
/// Call [showPinSetupDialog] to display it.
Future<void> showPinSetupDialog(
  BuildContext context, {
  required Future<void> Function(String pin) onPinConfirmed,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PinSetupDialog(onPinConfirmed: onPinConfirmed),
  );
}

class PinSetupDialog extends StatefulWidget {
  final Future<void> Function(String pin) onPinConfirmed;

  const PinSetupDialog({required this.onPinConfirmed, super.key});

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog>
    with SingleTickerProviderStateMixin {
  int _step = 1; // 1 = enter, 2 = confirm
  String _firstPin = '';
  String _pin = '';
  bool _error = false;
  bool _saving = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_pin.length >= 4 || _saving) return;
    setState(() {
      _pin += digit;
      _error = false;
    });
    if (_pin.length == 4) _onComplete();
  }

  void _onDelete() {
    if (_pin.isEmpty || _saving) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onComplete() async {
    if (_step == 1) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _step = 2;
      });
    } else {
      if (_pin == _firstPin) {
        setState(() => _saving = true);
        await widget.onPinConfirmed(_pin);
        if (mounted) Navigator.of(context).pop();
      } else {
        await _shakeCtrl.forward(from: 0);
        setState(() {
          _pin = '';
          _error = true;
        });
      }
    }
  }

  void _goBack() {
    setState(() {
      _step = 1;
      _firstPin = '';
      _pin = '';
      _error = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                AnimatedOpacity(
                  opacity: _step == 2 ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    onPressed: _step == 2 ? _goBack : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 32), // balance the back button
              ],
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _step == 1 ? 'Crea tu PIN' : 'Confirma tu PIN',
                key: ValueKey(_step),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _step == 1
                    ? 'Elige un PIN de 4 dígitos para desbloquear tu vault'
                    : 'Ingresa el mismo PIN para confirmar',
                key: ValueKey('sub$_step'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // PIN dots
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(_shakeAnim.value, 0),
                child: child,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _error
                          ? AppColors.error
                          : filled
                              ? AppColors.primary
                              : Colors.transparent,
                      border: Border.all(
                        color: _error
                            ? AppColors.error
                            : filled
                                ? AppColors.primary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (_error) ...[
              const SizedBox(height: 10),
              const Text(
                'Los PINs no coinciden, intenta de nuevo',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 28),
            // Numpad
            _buildNumpad(theme, isDark),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad(ThemeData theme, bool isDark) {
    return Column(
      children: [
        _buildRow(['1', '2', '3'], theme, isDark),
        const SizedBox(height: 12),
        _buildRow(['4', '5', '6'], theme, isDark),
        const SizedBox(height: 12),
        _buildRow(['7', '8', '9'], theme, isDark),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 64, height: 64),
            _buildDigitButton('0', theme, isDark),
            _buildDeleteButton(theme),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> digits, ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildDigitButton(d, theme, isDark)).toList(),
    );
  }

  Widget _buildDigitButton(String digit, ThemeData theme, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _saving ? null : () => _onDigit(digit),
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.darkCard : AppColors.inputBg,
          ),
          child: Center(
            child: Text(
              digit,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _saving ? null : _onDelete,
        borderRadius: BorderRadius.circular(32),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(
            Icons.backspace_outlined,
            size: 22,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}
