import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/stats_model.dart';

/// Makale istatistik göstergesi — görüntülenme ve alkış sayısı.
/// Herkes tarafından görüntülenebilir.
class StatsWidget extends StatelessWidget {
  final ArticleStatsModel stats;
  const StatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(
          icon: Icons.visibility_outlined,
          value: _formatCount(stats.viewCount),
          label: 'görüntülenme',
        ),
        const SizedBox(width: 20),
        _StatItem(
          icon: Icons.favorite_border,
          value: _formatCount(stats.clapCount),
          label: 'alkış',
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
