import 'dart:io';

import 'mermaid_parity/parity.dart';

// sysexits-compatible codes make command-line failures distinguishable.
const _usageExitCode = 64;
const _missingInputExitCode = 66;

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln('Usage: dart run tool/debug_geometry.dart FIXTURE_ID');
    exitCode = _usageExitCode;
    return;
  }

  final id = arguments.single;
  final dartFile = File('tool/mermaid_parity/out/$id.dart.svg');
  final mermaidFile = File('tool/mermaid_parity/references/$id.svg');
  if (!dartFile.existsSync() || !mermaidFile.existsSync()) {
    stderr.writeln('Missing parity artifacts for "$id". Run tool/mermaid_parity.dart first.');
    exitCode = _missingInputExitCode;
    return;
  }

  final dart = SvgSnapshot.fromSvg(dartFile.readAsStringSync());
  final mermaid = SvgSnapshot.fromSvg(mermaidFile.readAsStringSync());
  _printDifferences('geometry', dart.geometry, mermaid.geometry);
  _printDifferences('paint', dart.paint, mermaid.paint);
}

void _printDifferences(String label, List<String> dart, List<String> mermaid) {
  stdout
    ..writeln('Dart-only $label:')
    ..writeln(_difference(dart, mermaid).join('\n'))
    ..writeln('Mermaid-only $label:')
    ..writeln(_difference(mermaid, dart).join('\n'));
}

Iterable<String> _difference(List<String> values, List<String> other) sync* {
  final remaining = [...other];
  for (final value in values) {
    if (!remaining.remove(value)) yield value;
  }
}
