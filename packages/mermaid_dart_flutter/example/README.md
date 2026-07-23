# Mermaid Dart Flutter gallery

A responsive gallery that parses, lays out, and paints one representative
example for every `DiagramType` supported by `mermaid_dart`.

From this directory:

```shell
flutter run -d chrome
```

The gallery renders every preview directly with Flutter Canvas. Select a card
to inspect the diagram with pan and zoom alongside its Mermaid source.

The sample catalog is exhaustive: its test compares the catalog with
`DiagramType.values`, then parses, lays out, and paints every entry. Adding a
new diagram type requires adding a demo before the test can pass.

