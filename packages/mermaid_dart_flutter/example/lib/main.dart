import 'package:flutter/material.dart';
import 'package:mermaid_dart/mermaid_dart.dart' as mermaid;
import 'package:mermaid_dart_flutter/mermaid_dart_flutter.dart';

import 'demo_samples.dart';

void main() => runApp(const MermaidGalleryApp());

/// A responsive gallery of every Mermaid diagram supported by this repository.
final class MermaidGalleryApp extends StatelessWidget {
  /// Creates the demo application.
  const MermaidGalleryApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Mermaid Dart Gallery',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff6750a4),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xfff8f7fb),
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xffd0bcff),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    home: const _GalleryPage(),
  );
}

final class _GalleryPage extends StatefulWidget {
  const _GalleryPage();

  @override
  State<_GalleryPage> createState() => _GalleryPageState();
}

final class _GalleryPageState extends State<_GalleryPage> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final samples = query.isEmpty
        ? demoSamples
        : demoSamples
              .where(
                (sample) =>
                    sample.title.toLowerCase().contains(query) ||
                    sample.description.toLowerCase().contains(query) ||
                    sample.type.wireName.toLowerCase().contains(query),
              )
              .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mermaid Dart Gallery'),
        actions: MediaQuery.sizeOf(context).width >= 600
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      '${mermaid.DiagramType.values.length} supported grammars',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          _GalleryHeader(
            sampleCount: samples.length,
            onQueryChanged: (value) => setState(() => _query = value),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = switch (constraints.maxWidth) {
                  < 700 => 1,
                  < 1120 => 2,
                  _ => 3,
                };
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: columns == 1 ? 1.35 : 1.15,
                  ),
                  itemCount: samples.length,
                  itemBuilder: (context, index) {
                    final sample = samples[index];
                    return _SampleCard(
                      key: ValueKey('sample-${sample.type.name}'),
                      sample: sample,
                      onTap: () => _openSample(context, sample),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSample(BuildContext context, DemoSample sample) =>
      showDialog<void>(
        context: context,
        builder: (context) =>
            Dialog.fullscreen(child: _SampleDetails(sample: sample)),
      );
}

final class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({
    required this.sampleCount,
    required this.onQueryChanged,
  });

  final int sampleCount;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Direct Flutter Canvas rendering',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          '$sampleCount examples · no SVG intermediary',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    final search = SearchBar(
      leading: const Icon(Icons.search),
      hintText: 'Filter diagrams',
      onChanged: onQueryChanged,
    );
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: constraints.maxWidth < 680
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [summary, const SizedBox(height: 16), search],
              )
            : Row(
                children: [
                  Expanded(child: summary),
                  const SizedBox(width: 20),
                  SizedBox(width: 280, child: search),
                ],
              ),
      ),
    );
  }
}

final class _SampleCard extends StatelessWidget {
  const _SampleCard({required this.sample, required this.onTap, super.key});

  final DemoSample sample;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sample.title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  _TypeBadge(type: sample.type),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                sample.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: RepaintBoundary(
                          child: MermaidDiagram(
                            diagramType: sample.type,
                            source: sample.source,
                            iconResolver: sample.iconResolver,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Open',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.open_in_full,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SampleDetails extends StatelessWidget {
  const _SampleDetails({required this.sample});

  final DemoSample sample;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
      title: Text(sample.title),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(child: _TypeBadge(type: sample.type)),
        ),
      ],
    ),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final diagram = _InteractiveDiagram(sample: sample);
        final source = _SourcePanel(sample: sample);
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              Expanded(flex: 3, child: diagram),
              const VerticalDivider(width: 1),
              SizedBox(width: 420, child: source),
            ],
          );
        }
        return Column(
          children: [
            Expanded(flex: 3, child: diagram),
            const Divider(height: 1),
            Expanded(flex: 2, child: source),
          ],
        );
      },
    ),
  );
}

final class _InteractiveDiagram extends StatelessWidget {
  const _InteractiveDiagram({required this.sample});

  final DemoSample sample;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xfff4f2f8),
    child: InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(240),
      minScale: .25,
      maxScale: 6,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: MermaidDiagram(
            diagramType: sample.type,
            source: sample.source,
            iconResolver: sample.iconResolver,
          ),
        ),
      ),
    ),
  );
}

final class _SourcePanel extends StatelessWidget {
  const _SourcePanel({required this.sample});

  final DemoSample sample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mermaid source', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: SelectionArea(
                  child: Text(
                    sample.source.trim(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final mermaid.DiagramType type;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          type.wireName,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSecondaryContainer,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
