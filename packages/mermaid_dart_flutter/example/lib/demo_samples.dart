import 'package:flutter/material.dart' show Icons;
import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:mermaid_dart_flutter/mermaid_dart_flutter.dart';

/// A representative source document for one supported Mermaid grammar.
final class DemoSample {
  /// Creates a gallery sample.
  const DemoSample({
    required this.type,
    required this.title,
    required this.description,
    required this.source,
    this.iconResolver = const EmptyIconResolver(),
  });

  /// The parser and renderer family exercised by this sample.
  final DiagramType type;

  /// The human-readable gallery title.
  final String title;

  /// A short description of the demonstrated behavior.
  final String description;

  /// Valid Mermaid source for [type].
  final String source;

  /// Resolves icons used by this sample during layout.
  final IconResolver iconResolver;

  /// The Flutter glyph resolver, when this sample demonstrates `IconData`.
  FlutterIconDataResolver? get iconDataResolver => switch (iconResolver) {
    FlutterIconDataResolver resolver => resolver,
    _ => null,
  };
}

/// One non-trivial demo for every public [DiagramType].
const demoSamples = <DemoSample>[
  DemoSample(
    type: DiagramType.architecture,
    title: 'Architecture · Flutter icons',
    description:
        'Compound groups and services rendered with Material IconData glyphs.',
    iconResolver: FlutterIconDataResolver({
      'gallery:cloud': Icons.cloud,
      'gallery:gateway': Icons.router,
      'gallery:api': Icons.api,
      'gallery:database': Icons.storage,
    }),
    source: '''
architecture-beta
title Service platform
group cloud(gallery:cloud)[Cloud]
service gateway(gallery:gateway)[Gateway] in cloud
service api(gallery:api)[API] in cloud
service db(gallery:database)[Database] in cloud
gateway:R --> L:api
api:R --> L:db
''',
  ),
  DemoSample(
    type: DiagramType.classDiagram,
    title: 'Class Diagram',
    description: 'Classes, members, inheritance, cardinality, and notes.',
    source: '''
classDiagram
direction LR
class Animal {
  +String name
  +move()
}
class Duck {
  +swim()
}
Animal "1" <|-- "*" Duck : extends
note for Duck "Can fly and swim"
''',
  ),
  DemoSample(
    type: DiagramType.cynefin,
    title: 'Cynefin',
    description: 'All five decision-making domains and their practices.',
    source: '''
cynefin-beta
complex "Probe"
complicated "Analyze"
clear "Sense"
chaotic "Act"
confusion "Collect"
''',
  ),
  DemoSample(
    type: DiagramType.eventModeling,
    title: 'Event Modeling',
    description: 'Commands, events, read models, frames, and dependencies.',
    source: '''
eventmodeling
timeframe 01 command Cart.Update
tf 02 evt Cart.Updated ->> 01 `jsobj`{ status: accepted }
resetframe 03 readmodel Cart.Items ->> 02
''',
  ),
  DemoSample(
    type: DiagramType.entityRelationship,
    title: 'Entity Relationship',
    description: 'Entity attributes, keys, cardinalities, and relationships.',
    source: '''
erDiagram
CUSTOMER {
  int id PK
  string name
}
ORDER {
  int id PK
  int customer_id FK
}
CUSTOMER ||--o{ ORDER : places
''',
  ),
  DemoSample(
    type: DiagramType.flowchart,
    title: 'Flowchart',
    description:
        'Directions, subgraphs, node shapes, edge labels, and custom classes.',
    source: '''
---
title: Request lifecycle
---
flowchart LR
accTitle: Request lifecycle flowchart
accDescr: A request passes through authorization and application services
Client([Client]) -->|request| Gateway{Authorized?}
subgraph services [Services]
  direction TB
  Gateway --> API[API]
  API ==> Database[(Database)]
end
Gateway -. denied .-> Error((Denied))
classDef success fill:#d5f5e3,stroke:#1e8449,color:#145a32
class API,Database success
''',
  ),
  DemoSample(
    type: DiagramType.gantt,
    title: 'Gantt',
    description:
        'Sections, task states, dependencies, milestones, and date axes.',
    source: '''
gantt
title Release plan
dateFormat YYYY-MM-DD
axisFormat %b %d
tickInterval 1day
todayMarker off
section Design
Research :done, crit, research, 2025-01-01, 2d
Review :active, review, after research, 1d
section Delivery
Implementation :implementation, after review, 3d
Release :milestone, release, after implementation, 0d
Deadline :vert, deadline, 2025-01-06, 1d
''',
  ),
  DemoSample(
    type: DiagramType.gitGraph,
    title: 'Git Graph',
    description: 'Branches, highlighted commits, tags, merges, and history.',
    source: '''
gitGraph
title Release history
commit id: "base" type: HIGHLIGHT tag: "v1"
branch feature
checkout feature
commit id: "work"
checkout main
commit id: "trunk"
merge feature id: "merge" tag: "v2"
''',
  ),
  DemoSample(
    type: DiagramType.info,
    title: 'Info',
    description: 'A compact runtime and version-information diagram.',
    source: '''
info showInfo
title Renderer information
accTitle: Mermaid Dart renderer
accDescr: Flutter Canvas renderer information
''',
  ),
  DemoSample(
    type: DiagramType.kanban,
    title: 'Kanban',
    description: 'Columns, cards, tickets, assignees, and priorities.',
    source: '''
kanban
  backlog[Backlog]
    parser[Implement parser]@{ ticket: M-1, assigned: Roman, priority: High }
  doing[In progress]
    painter[Canvas renderer]@{ ticket: M-2, priority: Very High }
  done[Done]
    tests[Parity tests]
''',
  ),
  DemoSample(
    type: DiagramType.packet,
    title: 'Packet',
    description: 'Bit ranges, single-bit flags, and multi-row packet fields.',
    source: '''
packet-beta
title Transport header
0-7: "Source"
8-15: "Destination"
16: "ACK"
17: "SYN"
18-31: "Payload length"
''',
  ),
  DemoSample(
    type: DiagramType.mindmap,
    title: 'Mindmap',
    description:
        'Indented hierarchy, node shapes, classes, and curved branches.',
    source: '''
mindmap
  root((Product))
    research[Research]
      interviews(Interviews)
      prototype(Prototype)
    launch{{Launch}}
      rollout)Rollout(
''',
  ),
  DemoSample(
    type: DiagramType.pie,
    title: 'Pie',
    description: 'Slices, labels, values, title, and legend.',
    source: '''
pie showData
title Storage allocation
"Applications": 45
"Documents": 30
"Media": 18
"Free": 7
''',
  ),
  DemoSample(
    type: DiagramType.quadrantChart,
    title: 'Quadrant Chart',
    description:
        'Normalized campaign points, quadrant labels, axes, and point styles.',
    source: '''
quadrantChart
title Campaign reach and engagement
x-axis Low Reach --> High Reach
y-axis Low Engagement --> High Engagement
quadrant-1 Expand
quadrant-2 Promote
quadrant-3 Re-evaluate
quadrant-4 Improve
Campaign A: [0.30, 0.60]
Campaign B: [0.78, 0.34] color: #ff3300, radius: 9
Campaign C:::priority: [0.57, 0.69]
classDef priority color: #109060, stroke-color: #310085, stroke-width: 3px
''',
  ),
  DemoSample(
    type: DiagramType.radar,
    title: 'Radar',
    description: 'Named axes and multiple comparative data curves.',
    source: '''
radar-beta
title Platform comparison
axis speed["Speed"], quality["Quality"], cost["Cost"], reach["Reach"]
curve current["Current"] { 3, 4, 2, 3 }
curve target["Target"] { 5, 5, 4, 5 }
''',
  ),
  DemoSample(
    type: DiagramType.railroad,
    title: 'Railroad',
    description: 'Native railroad grammar with sequences and optional nodes.',
    source: '''
railroad-beta
rule = sequence(terminal("SELECT"), nonterminal("column"), optional(terminal("WHERE"))) ;
''',
  ),
  DemoSample(
    type: DiagramType.railroadAbnf,
    title: 'Railroad · ABNF',
    description: 'ABNF alternatives, optional nodes, and bounded repetition.',
    source: '''
railroad-abnf-beta
rule = "GET" [path] 1*3header ;
''',
  ),
  DemoSample(
    type: DiagramType.railroadEbnf,
    title: 'Railroad · EBNF',
    description: 'EBNF choices, grouping, and one-or-more repetition.',
    source: '''
railroad-ebnf-beta
rule = ("read" | "write") identifier+ ;
''',
  ),
  DemoSample(
    type: DiagramType.railroadPeg,
    title: 'Railroad · PEG',
    description: 'PEG ordered choice and optional expressions.',
    source: '''
railroad-peg-beta
rule <- ("yes" / "no") value? ;
''',
  ),
  DemoSample(
    type: DiagramType.sequence,
    title: 'Sequence',
    description:
        'Participants, messages, activations, alternatives, notes, and automatic numbering.',
    source: '''
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
''',
  ),
  DemoSample(
    type: DiagramType.stateDiagram,
    title: 'State Diagram',
    description: 'States, transitions, choices, notes, and terminal markers.',
    source: '''
stateDiagram-v2
[*] --> Idle
Idle --> Processing : submit
state Processing {
  [*] --> Validating
  Validating --> Complete
}
Processing --> Done : success
Processing --> Failed : error
Done --> [*]
note right of Failed : Retry is available
''',
  ),
  DemoSample(
    type: DiagramType.treeView,
    title: 'Tree View',
    description: 'Nested directories, files, descriptions, and Unicode.',
    source: '''
treeView-beta
src/ ## Application sources
    lib/
        main.dart
        renderer.dart
    test/
        renderer_test.dart
README.md
''',
  ),
  DemoSample(
    type: DiagramType.timeline,
    title: 'Timeline',
    description: 'Sections, periods, events, and top-down orientation.',
    source: '''
timeline TD
title Product history
section Discovery
  Research : Interviews : Prototype
section Delivery
  Beta : Customer feedback
  Launch : General availability
''',
  ),
  DemoSample(
    type: DiagramType.treemap,
    title: 'Treemap',
    description: 'Nested weighted sections and bounded labels.',
    source: '''
treemap-beta
title Product portfolio
"Products"
  "Applications"
    "Mobile": 50
    "Web": 30
  "Services"
    "Consulting": 15
    "Support": 5
''',
  ),
  DemoSample(
    type: DiagramType.wardley,
    title: 'Wardley Map',
    description: 'Anchors, components, evolution, dependencies, and notes.',
    source: '''
wardley-beta
title Platform strategy
anchor User [0.9, 0.1]
component API [0.65, 0.45] (build)
component Database [0.35, 0.75] (buy)
User -> API
API +<> Database; data
evolve API 0.85
note "Reduce coupling" [0.2, 0.8]
''',
  ),
  DemoSample(
    type: DiagramType.xyChart,
    title: 'XY Chart',
    description: 'Categorical axes with bar and line series.',
    source: '''
xychart
title "Quarterly sales"
x-axis "Quarter" [Q1, Q2, Q3, Q4]
y-axis "Revenue" 0 --> 100
bar "Actual" [20, 45, 70, 85]
line "Forecast" [25, 50, 75, 95]
''',
  ),
];
