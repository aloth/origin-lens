import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'src/rust/api/c2pa_reader.dart';

/// The four headline levels of the analysis verdict.
///
/// The levels are ordered by precedence: a red state always wins over purple,
/// purple over green, and green over yellow. Only a validated signature can
/// produce green or purple.
enum VerdictLevel { red, purple, green, yellow }

/// Colors of the solid verdict band and the text drawn on it.
///
/// Every pair reaches at least 4.5:1 WCAG contrast, which a unit test checks.
extension VerdictLevelColors on VerdictLevel {
  Color get bandColor {
    switch (this) {
      case VerdictLevel.green:
        return const Color(0xFF15803D);
      case VerdictLevel.red:
        return const Color(0xFFB91C1C);
      case VerdictLevel.yellow:
        return const Color(0xFFFACC15);
      case VerdictLevel.purple:
        return const Color(0xFF6D28D9);
    }
  }

  Color get onBandColor {
    switch (this) {
      case VerdictLevel.yellow:
        return const Color(0xFF422006);
      case VerdictLevel.green:
      case VerdictLevel.red:
      case VerdictLevel.purple:
        return const Color(0xFFFFFFFF);
    }
  }
}

/// The headline of an analysis, decided from the Rust result alone.
class Verdict {
  final VerdictLevel level;
  final String title;
  final String description;
  final IconData icon;

  /// Supporting facts shown under the description. They never change the
  /// headline: unsigned metadata, AI names inside failed credentials and raw
  /// status codes all end up here.
  final List<String> secondary;

  const Verdict({
    required this.level,
    required this.title,
    required this.description,
    required this.icon,
    this.secondary = const [],
  });

  /// Red verdicts mean the credentials failed validation. Anything read from
  /// them is a claim, not a fact, and is labeled as such.
  bool get credentialsFailed => level == VerdictLevel.red;

  /// The text a screen reader announces for the verdict band.
  String get semanticsLabel => 'Verdict: $title. $description';
}

/// Secondary line for AI keywords found in EXIF or other unsigned metadata.
const String kUnsignedAiLine = 'AI tool named in unsigned metadata';

/// Secondary line for an AI declaration inside credentials that did not
/// validate.
const String kFailedCredentialsAiLine = 'Failed credentials name an AI tool';

/// Decide the verdict for [result].
///
/// [fromUrl] is true when the image was loaded from a web address, which adds
/// a hint to the "no credentials" text.
///
/// Precedence: red (signature invalid, content changed) > purple (Verified and
/// the signed manifest declares AI generation) > green (Verified) > yellow
/// (everything else).
Verdict computeVerdict(C2paAnalysisResult result, {bool fromUrl = false}) {
  final status = result.status;
  final ai = result.aiInfo;
  final exif = result.exifInfo;

  final manifestDeclaresAi =
      (ai?.isAiGenerated ?? false) &&
      (ai?.detectionSource == 'c2pa' || ai?.detectionSource == 'both');
  final unsignedAi = exif?.aiDetected ?? false;

  final secondary = <String>[];

  if (status is VerificationStatus_SignatureInvalid) {
    if (manifestDeclaresAi) secondary.add(kFailedCredentialsAiLine);
    if (unsignedAi) secondary.add(kUnsignedAiLine);
    return Verdict(
      level: VerdictLevel.red,
      title: 'Credentials Invalid',
      description:
          'These credentials fail validation. Do not rely on the claims below.',
      icon: Icons.dangerous_rounded,
      secondary: secondary,
    );
  }

  if (status is VerificationStatus_ContentChanged) {
    if (manifestDeclaresAi) secondary.add(kFailedCredentialsAiLine);
    if (unsignedAi) secondary.add(kUnsignedAiLine);
    if (status.codes.isNotEmpty) {
      secondary.add('Status: ${status.codes.join(', ')}');
    }
    return Verdict(
      level: VerdictLevel.red,
      title: "Credentials Don't Match This Image",
      description: 'The image was changed after it was signed.',
      icon: Icons.broken_image_rounded,
      secondary: secondary,
    );
  }

  if (status is VerificationStatus_Verified) {
    final issuer = _issuer(result.signer);
    if (manifestDeclaresAi) {
      final from = issuer == null ? '' : ' from $issuer';
      return Verdict(
        level: VerdictLevel.purple,
        title: 'AI-Generated (Signed)',
        description:
            'Signed Content Credentials$from declare this image as AI-generated.',
        icon: Icons.auto_awesome_rounded,
      );
    }
    if (unsignedAi) secondary.add(kUnsignedAiLine);
    // An issuer such as "Adobe Inc." already ends the sentence.
    final signedBy = issuer == null
        ? ''
        : issuer.endsWith('.')
        ? 'Signed by $issuer '
        : 'Signed by $issuer. ';
    return Verdict(
      level: VerdictLevel.green,
      title: 'Content Credentials Valid',
      description:
          '${signedBy}The signature is valid and the image is unchanged since signing. The signer was not checked against a trust list.',
      icon: Icons.verified_rounded,
      secondary: secondary,
    );
  }

  // Everything below is yellow. AI names from the manifest are reported as a
  // secondary line only, because these credentials did not fully validate.
  if (manifestDeclaresAi) secondary.add(kFailedCredentialsAiLine);
  if (unsignedAi) secondary.add(kUnsignedAiLine);

  if (status is VerificationStatus_CertificateExpired) {
    return Verdict(
      level: VerdictLevel.yellow,
      title: 'Certificate Expired',
      description:
          'The signing certificate has expired, so the signature could not be checked.',
      icon: Icons.schedule_rounded,
      secondary: secondary,
    );
  }

  if (status is VerificationStatus_CertificateUntrusted) {
    return Verdict(
      level: VerdictLevel.yellow,
      title: 'Signer Not Verified',
      description: 'The signing certificate could not be validated.',
      icon: Icons.gpp_maybe_rounded,
      secondary: secondary,
    );
  }

  if (status is VerificationStatus_NoManifest) {
    if (exif?.isScreenshot ?? false) {
      return Verdict(
        level: VerdictLevel.yellow,
        title: 'Screenshot',
        description:
            "This is a screenshot. A screenshot is a new image and never carries the original's Content Credentials, so where it came from cannot be checked here. Look for the original file.",
        icon: Icons.screenshot_rounded,
        secondary: secondary,
      );
    }
    return Verdict(
      level: VerdictLevel.yellow,
      title: 'No Content Credentials',
      description:
          'Most images carry none. This alone is not a sign of manipulation.${fromUrl ? ' The website may have removed them.' : ''}',
      icon: Icons.help_outline_rounded,
      secondary: secondary,
    );
  }

  if (status is VerificationStatus_RemoteManifestPending) {
    // Something exists to check, held elsewhere, and not yet fetched. Distinct
    // from "no credentials": nothing has been ruled out here.
    final host = Uri.tryParse(status.url)?.host ?? '';
    return Verdict(
      level: VerdictLevel.yellow,
      title: 'Credentials Held Elsewhere',
      description: host.isEmpty
          ? 'This image points to credentials stored on another server, which have not been fetched'
          : 'This image points to credentials stored at $host, which have not been fetched',
      icon: Icons.cloud_download_outlined,
      secondary: secondary,
    );
  }

  if (status is VerificationStatus_Error) {
    final message = status.message;
    final lower = message.toLowerCase();
    if (message.isNotEmpty) secondary.add('Details: $message');

    if (lower.contains('c2pa data') ||
        lower.contains('could not be parsed') ||
        lower.contains('unsupported format') ||
        lower.contains('corrupted')) {
      return Verdict(
        level: VerdictLevel.yellow,
        title: 'Parsing Issue',
        description:
            'This image contains Content Credentials that could not be read.',
        icon: Icons.warning_amber_rounded,
        secondary: secondary,
      );
    }
    if (lower.contains('remote') ||
        lower.contains('fetch') ||
        lower.contains('manifest host')) {
      return Verdict(
        level: VerdictLevel.yellow,
        title: 'Connection Issue',
        description: 'Could not retrieve remote credentials',
        icon: Icons.cloud_off_rounded,
        secondary: secondary,
      );
    }
    return Verdict(
      level: VerdictLevel.yellow,
      title: 'Analysis Issue',
      description: 'Origin Lens could not analyze this image.',
      icon: Icons.error_outline_rounded,
      secondary: secondary,
    );
  }

  return Verdict(
    level: VerdictLevel.yellow,
    title: 'Analysis Issue',
    description: 'Origin Lens could not analyze this image.',
    icon: Icons.error_outline_rounded,
    secondary: secondary,
  );
}

String? _issuer(SignerInfo? signer) {
  final org = signer?.organization?.trim();
  if (org != null && org.isNotEmpty) return org;
  final name = signer?.name?.trim();
  if (name != null && name.isNotEmpty) return name;
  return null;
}

/// Relative luminance of [c] per WCAG 2.x.
double relativeLuminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG contrast ratio between two opaque colors, from 1 to 21.
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Title of the remote AI assessment card. It is an opinion from a remote
/// model, never a verdict, and is styled neutrally.
const String kAiOpinionTitle = 'AI Opinion (Gemini, experimental)';

/// The three outcomes the AI opinion card can show once the user consented.
enum AiOpinionOutcome { watermarkReported, noneReported, noAnswer }

AiOpinionOutcome aiOpinionOutcome({
  required bool success,
  required bool hasSynthId,
}) {
  if (!success) return AiOpinionOutcome.noAnswer;
  return hasSynthId
      ? AiOpinionOutcome.watermarkReported
      : AiOpinionOutcome.noneReported;
}

extension AiOpinionOutcomeText on AiOpinionOutcome {
  String get headline {
    switch (this) {
      case AiOpinionOutcome.watermarkReported:
        return 'Gemini reports a SynthID watermark.';
      case AiOpinionOutcome.noneReported:
        return 'Gemini reports no SynthID watermark.';
      case AiOpinionOutcome.noAnswer:
        return 'Could not get an answer from Gemini.';
    }
  }
}

/// Shown under every AI opinion so it is not read as a verification result.
const String kAiOpinionCaveat =
    'This is the opinion of a remote AI model, not a cryptographic check. It can be wrong in both directions.';
