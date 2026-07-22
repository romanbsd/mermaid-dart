import 'dart:convert';
import 'dart:io';

import 'package:mermaid_dart/mermaid_dart.dart';

import 'mermaid_parity/parity.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    _printUsage();
    return;
  }

  final updateReference = arguments.contains('--update-reference');
  final reportOnly = arguments.contains('--report-only');
  final fixtureId = _optionValue(arguments, '--fixture');
  if (arguments.contains('--fixture') && fixtureId == null) {
    stderr.writeln('--fixture requires an ID');
    exitCode = 64;
    return;
  }
  final unknown = arguments.where(
    (argument) =>
        !{'--update-reference', '--report-only'}.contains(argument) &&
        !argument.startsWith('--fixture=') &&
        argument != '--fixture' &&
        argument != fixtureId,
  );
  if (unknown.isNotEmpty) {
    stderr.writeln('Unknown argument: ${unknown.first}');
    _printUsage();
    exitCode = 64;
    return;
  }

  final root = Directory.current;
  final parityDirectory = Directory('${root.path}/tool/mermaid_parity');
  final manifest = ParityManifest.load(File('${parityDirectory.path}/fixtures.json'));
  final fixtures = fixtureId == null
      ? manifest.fixtures
      : manifest.fixtures.where((fixture) => fixture.id == fixtureId).toList();
  if (fixtures.isEmpty) {
    stderr.writeln('Unknown fixture: $fixtureId');
    exitCode = 64;
    return;
  }

  final references = Directory('${parityDirectory.path}/references')..createSync(recursive: true);
  final output = Directory('${parityDirectory.path}/out')..createSync(recursive: true);
  final sources = Directory('${output.path}/sources')..createSync(recursive: true);
  final referenceRenderer = File('${parityDirectory.path}/reference/node_modules/.bin/mmdc');
  if (updateReference && !referenceRenderer.existsSync()) {
    stderr.writeln(
      'Pinned Mermaid CLI is not installed. Run:\n'
      '  npm install --prefix tool/mermaid_parity/reference',
    );
    exitCode = 69;
    return;
  }
  final puppeteerConfig = updateReference ? _writePuppeteerConfig(output) : null;

  stdout.writeln(
    'Mermaid.js ${manifest.mermaidVersion} parity (${fixtures.length} fixture${fixtures.length == 1 ? '' : 's'})',
  );
  var exact = 0;
  var visual = 0;
  var differences = 0;
  var errors = 0;

  for (final fixture in fixtures) {
    final reference = File('${references.path}/${fixture.id}.svg');
    if (updateReference) {
      final source = File('${sources.path}/${fixture.id}.mmd')..writeAsStringSync(fixture.source);
      final mermaidConfig = _writeMermaidConfig(output, fixture);
      final process = await Process.run(referenceRenderer.path, [
        '--input',
        source.path,
        '--output',
        reference.path,
        '--backgroundColor',
        'transparent',
        if (mermaidConfig != null) ...['--configFile', mermaidConfig.path],
        if (puppeteerConfig != null) ...['--puppeteerConfigFile', puppeteerConfig.path],
        '--quiet',
      ]);
      if (process.exitCode != 0) {
        errors++;
        stdout.writeln('ERROR ${fixture.id}: Mermaid.js render failed');
        final message = '${process.stderr}'.trim();
        if (message.isNotEmpty) stderr.writeln(message);
        continue;
      }
    }

    if (!reference.existsSync()) {
      errors++;
      stdout.writeln('MISSING ${fixture.id}: rerun with --update-reference');
      continue;
    }

    try {
      final dartSvg = renderDiagramSvg(
        fixture.type,
        fixture.source,
        options: fixture.renderOptions,
        textMeasurer: fixture.textMeasurer,
      );
      File('${output.path}/${fixture.id}.dart.svg').writeAsStringSync(dartSvg);
      final dartSnapshot = SvgSnapshot.fromSvg(dartSvg);
      final mermaidSnapshot = SvgSnapshot.fromSvg(reference.readAsStringSync());
      File('${output.path}/${fixture.id}.dart.canonical.svg').writeAsStringSync(dartSnapshot.canonicalSvg);
      File('${output.path}/${fixture.id}.mermaid.canonical.svg').writeAsStringSync(mermaidSnapshot.canonicalSvg);

      final comparison = SvgComparison.compare(dartSnapshot, mermaidSnapshot);
      if (comparison.exact) {
        exact++;
        stdout.writeln('EXACT ${fixture.id}');
      } else if (comparison.visualParity) {
        visual++;
        stdout.writeln('PASS  ${fixture.id}: visual parity');
      } else {
        differences++;
        stdout.writeln('DIFF  ${fixture.id}: ${comparison.summary}');
      }
    } on Object catch (error) {
      errors++;
      stdout.writeln('ERROR ${fixture.id}: $error');
    }
  }

  stdout.writeln('Result: $exact exact, $visual visual, $differences different, $errors errors');
  stdout.writeln('Artifacts: ${output.path}');
  if (!reportOnly && (differences > 0 || errors > 0)) exitCode = 1;
}

File? _writeMermaidConfig(Directory output, ParityFixture fixture) {
  if (fixture.mermaidConfig.isEmpty) return null;
  return File('${output.path}/${fixture.id}.config.json')
    ..writeAsStringSync(const JsonEncoder.withIndent(' ').convert(fixture.mermaidConfig));
}

File? _writePuppeteerConfig(Directory output) {
  final configured = Platform.environment['PUPPETEER_EXECUTABLE_PATH'];
  final candidates = [
    ?configured,
    if (Platform.isMacOS) ...[
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
      '/Applications/Chromium.app/Contents/MacOS/Chromium',
    ],
    if (Platform.isLinux) ...[
      '/usr/bin/google-chrome',
      '/usr/bin/google-chrome-stable',
      '/usr/bin/chromium',
      '/usr/bin/chromium-browser',
    ],
  ];
  final executable = candidates.where((path) => File(path).existsSync()).firstOrNull;
  if (executable == null) return null;
  return File('${output.path}/puppeteer.json')..writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'executablePath': executable,
      'args': ['--no-sandbox'],
    }),
  );
}

String? _optionValue(List<String> arguments, String name) {
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument.startsWith('$name=')) return argument.substring(name.length + 1);
    if (argument == name && index + 1 < arguments.length) return arguments[index + 1];
  }
  return null;
}

void _printUsage() {
  stdout.writeln('''
Compare mermaid_dart SVG output with pinned Mermaid.js reference SVGs.

Usage: dart run tool/mermaid_parity.dart [options]

Options:
  --update-reference  Render references with Mermaid CLI 11.16.0 first.
  --report-only       Report differences without returning a failing exit code.
  --fixture ID        Run one fixture only.
  -h, --help          Show this help.
''');
}
