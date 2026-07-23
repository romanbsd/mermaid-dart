import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

import 'support/svg_golden.dart';

const _demoSource = '''
sequenceDiagram
autonumber
actor Client
participant API
participant Database
Client->>+API: Request
alt cached
  API-->>Client: Cached response
else query
  API->>Database: Read
  Database-->>API: Result
  API-->>-Client: Response
end
Note right of API: Validates access
''';

const _demoMeasurements = <String, Size>{
  'Client': Size(42.672, 19),
  'API': Size(22.813, 19),
  'Database': Size(65.5, 19),
  'Request': Size(56.594, 19),
  'Cached response': Size(119.969, 19),
  'Read': Size(34.719, 19),
  'Result': Size(43.672, 19),
  'Response': Size(65.313, 19),
  'alt': Size(19.469, 19),
  '[cached]': Size(62.391, 19),
  '[query]': Size(52.25, 19),
  'Validates access': Size(115.453, 19),
};

final class _DemoTextMeasurer implements TextMeasurer {
  const _DemoTextMeasurer();

  @override
  Size measure(String text, SceneTextStyle style) =>
      _demoMeasurements[text] ?? const DeterministicTextMeasurer().measure(text, style);
}

void main() {
  test('matches the demo sequence diagram golden', () {
    final scene = layoutDiagram(
      parse(DiagramType.sequence, _demoSource),
      textMeasurer: const _DemoTextMeasurer(),
      options: const RenderOptions(padding: 0),
    );

    expectSvgGolden('sequence_demo', renderSvg(scene));
  });
}
