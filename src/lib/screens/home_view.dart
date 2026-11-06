import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            stretch: true,
            centerTitle: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: AppSpacing.lg),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Origin Lens',
                    style: AppTypography.titleLarge.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(context),

                      const SizedBox(height: AppSpacing.xxxl),

                      _buildStatsRow(context),

                      const SizedBox(height: AppSpacing.xxxl),

                      Text(
                        'Quick Actions',
                        style: AppTypography.headlineMedium.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildQuickActions(context),

                      const SizedBox(height: AppSpacing.huge),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.verified,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Active',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Verify Media\nAuthenticity',
            style: AppTypography.displayMedium.copyWith(
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Detect AI-generated content and verify C2PA credentials to combat misinformation.',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: _buildHeroStat('C2PA', 'Verified')),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(child: _buildHeroStat('AI', 'Detection')),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(child: _buildHeroStat('Context', 'Search')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.analytics_rounded,
            value: '12',
            label: 'Analyzed',
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.verified_rounded,
            value: '8',
            label: 'Verified',
            color: AppColors.verified,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.warning_rounded,
            value: '3',
            label: 'Flagged',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: AppTypography.headlineLarge.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        FeatureCard(
          icon: Icons.folder_open_rounded,
          title: 'Analyze from Files',
          subtitle: 'Best for C2PA verification',
          iconColor: AppColors.primaryBlue,
          isHighlighted: true,
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.md),
        FeatureCard(
          icon: Icons.link_rounded,
          title: 'Analyze from URL',
          subtitle: 'Perfect for web images',
          iconColor: AppColors.aiGenerated,
          onTap: () {},
        ),
      ],
    );
  }
}
