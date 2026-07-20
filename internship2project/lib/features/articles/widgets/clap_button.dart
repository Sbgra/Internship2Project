import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Medium tarzı animasyonlu alkış butonu.
/// Herkes kullanabilir — kalan hak göstergesi ile.
class ClapButton extends StatefulWidget {
  final int totalClaps;
  final int remainingClaps;
  final bool isLoading;
  final ValueChanged<int> onClap;

  const ClapButton({
    super.key,
    required this.totalClaps,
    required this.remainingClaps,
    this.isLoading = false,
    required this.onClap,
  });

  @override
  State<ClapButton> createState() => _ClapButtonState();
}

class _ClapButtonState extends State<ClapButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.remainingClaps <= 0 || widget.isLoading) return;
    _controller.forward().then((_) => _controller.reverse());
    widget.onClap(1);
  }

  @override
  Widget build(BuildContext context) {
    final canClap = widget.remainingClaps > 0 && !widget.isLoading;

    return Column(
      children: [
        ScaleTransition(
          scale: _scaleAnim,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canClap ? _handleTap : null,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: canClap
                        ? AppTheme.primary
                        : AppTheme.textSecondary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.favorite,
                        color: canClap
                            ? AppTheme.primary
                            : AppTheme.textSecondary.withOpacity(0.3),
                        size: 24,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.totalClaps}',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        if (widget.remainingClaps > 0)
          Text(
            '${widget.remainingClaps} hak kaldı',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          )
        else
          const Text(
            'Limit doldu',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
      ],
    );
  }
}
