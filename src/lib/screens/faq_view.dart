import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class FaqView extends StatefulWidget {
  const FaqView({super.key});

  @override
  State<FaqView> createState() => _FaqViewState();
}

class _FaqViewState extends State<FaqView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _expandedIndex = -1;

  final List<_FaqItem> _faqItems = [
    _FaqItem(
      icon: Icons.shield_outlined,
      question: 'What is Origin Lens?',
      answer:
          'Origin Lens is a powerful tool designed to help you verify the authenticity of digital images. It analyzes C2PA metadata and uses reverse image search to identify if an image has been manipulated, is AI-generated, or taken out of context.',
    ),
    _FaqItem(
      icon: Icons.verified_outlined,
      question: 'What is C2PA?',
      answer:
          'C2PA (Coalition for Content Provenance and Authenticity) is an open technical standard that allows publishers to embed tamper-evident information about who created a piece of content and how it was altered. Origin Lens reads this data to show you the complete history of an image.',
    ),
    _FaqItem(
      icon: Icons.auto_awesome_outlined,
      question: 'How does AI Detection work?',
      answer:
          'Origin Lens uses multiple methods to detect AI-generated content:\n\n'
          '• C2PA Metadata: Cryptographically signed data embedded by AI tools like Adobe Firefly and Microsoft Designer\n\n'
          '• Digital Source Type: IPTC standards like "trainedAlgorithmicMedia" that indicate AI generation\n\n'
          '• Claim Generator Analysis: We analyze the software that created the C2PA manifest to identify AI tools',
    ),
    _FaqItem(
      icon: Icons.travel_explore_outlined,
      question: 'What is Context Verification?',
      answer:
          'Context Verification uses reverse image search to find where an image has appeared online. This helps detect:\n\n'
          '• Out-of-context images: Old photos shared as current events\n'
          '• Misattributed sources: Images falsely claimed to be from specific locations\n'
          '• Viral misinformation: Images reused across different fake stories',
    ),
    _FaqItem(
      icon: Icons.check_circle_outlined,
      question: 'Which AI tools support C2PA?',
      answer:
          'Currently supported AI tools:\n\n'
          '✅ Adobe Firefly (firefly.adobe.com)\n'
          '✅ Microsoft Designer (designer.microsoft.com)\n'
          '✅ Bing Image Creator (bing.com/create)\n'
          '✅ Shutterstock AI\n'
          '✅ Getty Images AI\n\n'
          'Not yet supported:\n'
          '❌ ChatGPT / DALL-E\n'
          '❌ Google Gemini / Imagen\n'
          '❌ Midjourney\n'
          '❌ Stable Diffusion',
    ),
    _FaqItem(
      icon: Icons.help_outline_rounded,
      question: 'Why might an AI image not be detected?',
      answer:
          'Several reasons an AI image might not be detected:\n\n'
          '1. Tool doesn\'t support C2PA: Most AI tools don\'t embed metadata yet\n\n'
          '2. Screenshot instead of download: Taking a screenshot removes all metadata\n\n'
          '3. Social media re-upload: Platforms like Instagram, Twitter strip C2PA\n\n'
          '4. Image editing: Many editors remove C2PA metadata',
    ),
    _FaqItem(
      icon: Icons.photo_library_outlined,
      question: 'Why does "Select from Gallery" sometimes fail?',
      answer:
          'Mobile operating systems often optimize images when sharing from the Photo Library, which can strip sensitive metadata like C2PA.\n\n'
          'For best results:\n'
          '• Use "Select from Files" whenever possible\n'
          '• Save photos to the Files app first\n'
          '• Avoid taking screenshots (this removes all metadata)',
    ),
    _FaqItem(
      icon: Icons.science_outlined,
      question: 'How do I test C2PA detection?',
      answer:
          'To verify C2PA detection works:\n\n'
          '1. Go to firefly.adobe.com (free account)\n'
          '2. Generate any image\n'
          '3. Click the "Download" button (not screenshot!)\n'
          '4. Choose PNG or JPG format\n'
          '5. Save to Files app (not Photos)\n'
          '6. Open Origin Lens and use "Select from Files"\n\n'
          'The image should show "Verified" with Adobe Firefly as the creator.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
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
              title: Text(
                'Learn',
                style: AppTypography.titleLarge.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // _buildHeroCard(context), // Removed for cleaner look
                    const SizedBox(height: AppSpacing.lg),

                    Text(
                      'Frequently Asked Questions',
                      style: AppTypography.headlineMedium.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    ...List.generate(_faqItems.length, (index) {
                      return _buildFaqCard(context, index, _faqItems[index]);
                    }),

                    const SizedBox(height: AppSpacing.xxxl),

                    Text(
                      'Helpful Resources',
                      style: AppTypography.headlineMedium.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    _buildResourcesCard(context),

                    const SizedBox(height: AppSpacing.xxxl),

                    Text(
                      'About',
                      style: AppTypography.headlineMedium.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    _buildAboutCard(context),

                    const SizedBox(height: AppSpacing.huge),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Why This Matters',
                style: AppTypography.titleMedium.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'In the age of deepfakes and misinformation, knowing the origin of media is crucial. This tool empowers you to fact-check visual content before sharing it.',
            style: AppTypography.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqCard(BuildContext context, int index, _FaqItem item) {
    final theme = Theme.of(context);
    final isExpanded = _expandedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: Key('faq_$index'),
            initiallyExpanded: isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedIndex = expanded ? index : -1;
              });
            },
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 8,
            ),
            childrenPadding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
            ),
            leading: Icon(
              item.icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            title: Text(
              item.question,
              style: AppTypography.titleMedium.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            children: [
              Text(
                item.answer,
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourcesCard(BuildContext context) {
    final theme = Theme.of(context);

    final resources = [
      _ResourceLink(
        icon: Icons.security_rounded,
        title: 'Content Authenticity Initiative',
        subtitle: 'Learn about CAI',
        url: 'https://contentauthenticity.org/',
      ),
      _ResourceLink(
        icon: Icons.verified_rounded,
        title: 'C2PA.org',
        subtitle: 'Official C2PA Standard',
        url: 'https://c2pa.org/',
      ),
      _ResourceLink(
        icon: Icons.code_rounded,
        title: 'Project JudgeGPT',
        subtitle: 'Related Research Project',
        url: 'https://github.com/aloth/JudgeGPT',
      ),
    ];

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: resources.asMap().entries.map((entry) {
          final index = entry.key;
          final resource = entry.value;
          final isLast = index == resources.length - 1;

          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _launchUrl(resource.url),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Icon(
                          resource.icon,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resource.title,
                                style: AppTypography.titleMedium.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                resource.subtitle,
                                style: AppTypography.bodySmall.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.5,
                          ),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: AppSpacing.xxl + 40,
                  endIndent: AppSpacing.lg,
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Origin Lens',
                      style: AppTypography.titleLarge.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Version 1.0.0',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildAboutRow(
            context,
            icon: Icons.copyright_rounded,
            text: '2026 Alexander Loth and\nDominique Conceicao Rosario',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildAboutLink(
            context,
            icon: Icons.description_outlined,
            text: 'Terms of Use',
            url:
                'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildAboutLink(
            context,
            icon: Icons.privacy_tip_outlined,
            text: 'Privacy Policy',
            url:
                'https://raw.githubusercontent.com/aloth/origin-lens/refs/heads/main/privacy_policy.md',
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutLink(
    BuildContext context, {
    required IconData icon,
    required String text,
    required String url,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final IconData icon;
  final String question;
  final String answer;

  const _FaqItem({
    required this.icon,
    required this.question,
    required this.answer,
  });
}

class _ResourceLink {
  final IconData icon;
  final String title;
  final String subtitle;
  final String url;

  const _ResourceLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.url,
  });
}
