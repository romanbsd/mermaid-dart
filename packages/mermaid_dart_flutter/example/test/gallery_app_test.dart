import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mermaid_dart_flutter_example/main.dart';

void main() {
  testWidgets('shows the renderer gallery and opens a sample', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MermaidGalleryApp());
    await tester.pumpAndSettle();

    expect(find.text('Mermaid Dart Gallery'), findsOneWidget);
    expect(find.textContaining('26 supported grammars'), findsOneWidget);
    expect(find.byKey(const ValueKey('sample-architecture')), findsOneWidget);
    expect(find.byKey(const ValueKey('sample-flowchart')), findsOneWidget);

    await tester.enterText(find.byType(SearchBar), 'State Diagram');
    await tester.pumpAndSettle();
    final stateSample = find.byKey(const ValueKey('sample-stateDiagram'));
    expect(stateSample, findsOneWidget);
    await tester.tap(stateSample);
    await tester.pumpAndSettle();

    expect(find.text('State Diagram'), findsWidgets);
    expect(find.text('Mermaid source'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out without overflow on a phone-sized viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MermaidGalleryApp());
    await tester.pumpAndSettle();

    expect(find.byType(SearchBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
