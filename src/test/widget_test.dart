import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:origin_lens/main.dart';

void main() {
  group('App navigation and buttons', () {
    testWidgets('MainScreen starts on Home and shows welcome card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const OriginLensApp());
      await tester.pumpAndSettle();

      // Home view should show the welcome card
      expect(find.text('Verify Authenticity'), findsOneWidget);
      expect(find.text('Recent Analyses'), findsOneWidget);
    });

    testWidgets('Tapping nav to Analyze shows Analyze screen with buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const OriginLensApp());
      await tester.pumpAndSettle();

      // Tap Analyze in the bottom navigation
      final Finder analyzeIcon = find.byIcon(Icons.image_search_outlined);
      expect(analyzeIcon, findsOneWidget);
      await tester.tap(analyzeIcon);
      await tester.pumpAndSettle();

      // Verify Analyze view content
      expect(find.text('Select an image to analyze'), findsOneWidget);
      expect(find.text('Open from Gallery'), findsOneWidget);
      expect(find.text('Browse Files'), findsOneWidget);

      // Ensure the buttons are tappable and don't throw
      await tester.tap(find.text('Open from Gallery'));
      await tester.pump();

      await tester.tap(find.text('Browse Files'));
      await tester.pump();
    });

    testWidgets('Tapping nav to FAQ shows FAQ and expands item', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const OriginLensApp());
      await tester.pumpAndSettle();

      // Tap FAQ in the bottom navigation
      final Finder faqIcon = find.byIcon(Icons.help_outline);
      expect(faqIcon, findsOneWidget);
      await tester.tap(faqIcon);
      await tester.pumpAndSettle();

      // Verify FAQ view content
      expect(find.text('How it Works'), findsOneWidget);
      expect(find.text('What is Origin Lens?'), findsOneWidget);

      // Expand the first FAQ and verify the answer becomes visible
      final Finder question = find.text('What is Origin Lens?');
      expect(question, findsOneWidget);
      await tester.tap(question);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Origin Lens is a tool designed to help'),
        findsOneWidget,
      );
    });
  });
}
