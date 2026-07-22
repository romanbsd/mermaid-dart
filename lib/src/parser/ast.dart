/// Base type for syntax trees produced by Mermaid parsers.
sealed class DiagramAst {
  const DiagramAst();
}

/// Syntax tree for an `info` diagram.
final class InfoAst extends DiagramAst {
  const InfoAst({this.title, this.accessibilityTitle, this.accessibilityDescription});

  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InfoAst &&
          title == other.title &&
          accessibilityTitle == other.accessibilityTitle &&
          accessibilityDescription == other.accessibilityDescription;

  @override
  int get hashCode => Object.hash(title, accessibilityTitle, accessibilityDescription);

  @override
  String toString() =>
      'InfoAst(title: $title, accessibilityTitle: $accessibilityTitle, '
      'accessibilityDescription: $accessibilityDescription)';
}

/// Syntax tree for a `pie` diagram.
final class PieAst extends DiagramAst {
  const PieAst({
    this.showData = false,
    this.sections = const [],
    this.title,
    this.accessibilityTitle,
    this.accessibilityDescription,
  });

  final bool showData;
  final List<PieSectionAst> sections;
  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;
}

/// A labeled numeric section in a [PieAst].
final class PieSectionAst {
  const PieSectionAst({required this.label, required this.value});

  final String label;
  final num value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PieSectionAst && label == other.label && value == other.value;

  @override
  int get hashCode => Object.hash(label, value);

  @override
  String toString() => 'PieSectionAst(label: $label, value: $value)';
}

/// Syntax tree for a `packet` diagram.
final class PacketAst extends DiagramAst {
  const PacketAst({this.blocks = const [], this.title, this.accessibilityTitle, this.accessibilityDescription});

  final List<PacketBlockAst> blocks;
  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;
}

/// A bit range or relative-width block in a [PacketAst].
final class PacketBlockAst {
  const PacketBlockAst({this.start, this.end, this.bits, required this.label});

  final int? start;
  final int? end;
  final int? bits;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PacketBlockAst && start == other.start && end == other.end && bits == other.bits && label == other.label;

  @override
  int get hashCode => Object.hash(start, end, bits, label);

  @override
  String toString() => 'PacketBlockAst(start: $start, end: $end, bits: $bits, label: $label)';
}

/// Syntax tree for a `radar` diagram.
final class RadarAst extends DiagramAst {
  const RadarAst({
    this.axes = const [],
    this.curves = const [],
    this.options = const [],
    this.title,
    this.accessibilityTitle,
    this.accessibilityDescription,
  });

  final List<RadarAxisAst> axes;
  final List<RadarCurveAst> curves;
  final List<RadarOptionAst> options;
  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;
}

final class RadarAxisAst {
  const RadarAxisAst({required this.name, this.label});

  final String name;
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RadarAxisAst && name == other.name && label == other.label;

  @override
  int get hashCode => Object.hash(name, label);
}

final class RadarCurveAst {
  const RadarCurveAst({required this.name, this.label, required this.entries});

  final String name;
  final String? label;
  final List<RadarEntryAst> entries;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadarCurveAst && name == other.name && label == other.label && _listEquals(entries, other.entries);

  @override
  int get hashCode => Object.hash(name, label, Object.hashAll(entries));
}

final class RadarEntryAst {
  const RadarEntryAst({this.axis, required this.value});

  final String? axis;
  final num value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RadarEntryAst && axis == other.axis && value == other.value;

  @override
  int get hashCode => Object.hash(axis, value);
}

final class RadarOptionAst {
  const RadarOptionAst({required this.name, required this.value});

  final RadarOptionName name;
  final Object value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RadarOptionAst && name == other.name && value == other.value;

  @override
  int get hashCode => Object.hash(name, value);
}

enum RadarOptionName { showLegend, ticks, max, min, graticule }

enum RadarGraticule { circle, polygon }

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
