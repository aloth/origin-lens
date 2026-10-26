/// App facts shown in the interface that must match the repository.
///
/// Tests compare these against `pubspec.yaml` and `../CITATION.cff`, so a
/// release that bumps one without the other fails before it ships.
library;

/// Fallback for the About card while the platform version is loading.
const String kAppVersion = '1.4.1';

/// Text copied by the "Cite Origin Lens" row: both papers, blank line between.
const String kCiteOriginLensText =
    'Alexander Loth, Dominique Conceicao Rosario, Peter Ebinger, Martin Kappes, and Marc-Oliver Pahl. 2026. Origin Lens: Reclaiming Trust on the AI-Mediated Web Through On-Device Image Provenance Verification. In Companion Publication of the 18th ACM Web Science Conference (WebSci Companion \'26), Braunschweig, Germany. ACM. https://doi.org/10.1145/3795513.3806658'
    '\n\n'
    'Alexander Loth, Dominique Conceicao Rosario, Peter Ebinger, Martin Kappes, and Marc-Oliver Pahl. 2026. Origin Lens: A Privacy-First Mobile Framework for Cryptographic Image Provenance and AI Detection. arXiv:2602.03423. https://arxiv.org/abs/2602.03423';
