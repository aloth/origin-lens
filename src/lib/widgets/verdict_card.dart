import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../verdict.dart';
import 'common_widgets.dart';

/// The status card at the top of the analysis results.
///
/// A solid color band carries the icon and title in high contrast; the
/// description and any secondary lines sit below it on the card surface. The
/// band is announced as one unit to screen readers.
class VerdictCard extends StatelessWidget {
  final Verdict verdict;

  const VerdictCard({super.key, required this.verdict});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final band = verdict.level.bandColor;
    final onBand = verdict.level.onBandColor;

    return GlassCard(
      padding: EdgeInsets.zero,
      borderColor: band.withOpacity(0.6),
      borderWidth: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: verdict.semanticsLabel,
            excludeSemantics: true,
            child: Container(
              color: band,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(verdict.icon, size: 28, color: onBand),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      verdict.title,
                      style: AppTypography.titleLarge.copyWith(
                        color: onBand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verdict.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
                for (final line in verdict.secondary) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          line,
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
