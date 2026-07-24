# Mermaid.js golden sources

These `.mmd` files are rendered with the Mermaid CLI pinned by
`tool/mermaid_parity/reference/package-lock.json`. Regenerate a reference with:

```sh
tool/mermaid_parity/reference/node_modules/.bin/mmdc \
  --input test/rendering/goldens/sources/<name>.mmd \
  --output test/rendering/goldens/<name>_mermaid.svg \
  --backgroundColor transparent \
  --puppeteerConfigFile tool/mermaid_parity/out/puppeteer.json
```

The Mindmap reference intentionally preserves Mermaid.js's force-layout
coordinates. It is a visual reference, not an assertion that a different
force-layout engine will choose identical coordinates.
