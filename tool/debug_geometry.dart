import 'dart:io';

import 'mermaid_parity/parity.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln('Usage: dart run tool/debug_geometry.dart FIXTURE_ID');
    exitCode = 64;
    return;
  }

  final id = arguments.single;
  final dartFile = File('tool/mermaid_parity/out/$id.dart.svg');
  final mermaidFile = File('tool/mermaid_parity/references/$id.svg');
  if (!dartFile.existsSync() || !mermaidFile.existsSync()) {
    stderr.writeln('Missing parity artifacts for "$id". Run tool/mermaid_parity.dart first.');
    exitCode = 66;
    return;
  }

  final dart = SvgSnapshot.fromSvg(dartFile.readAsStringSync());
  final mermaid = SvgSnapshot.fromSvg(mermaidFile.readAsStringSync());
  stdout
    ..writeln('Dart only:')
    ..writeln(_difference(dart.geometry, mermaid.geometry).join('\n'))
    ..writeln('Mermaid only:')
    ..writeln(_difference(mermaid.geometry, dart.geometry).join('\n'));
}

Iterable<String> _difference(List<String> values, List<String> other) sync* {
  final remaining = [...other];
  for (final value in values) {
    if (!remaining.remove(value)) yield value;
  }
}
