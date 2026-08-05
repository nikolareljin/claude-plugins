# Plugin site style guide

Every product owns a dependency-free static site under `site/` and deploys that directory
with GitHub Pages. Keep local CSS in the product repository so one unavailable site cannot
break the rest of the suite.

## Required page structure

1. A compact suite-style header with product name, page anchors, and repository link.
2. A product-specific hero that states the outcome before implementation details.
3. Capability and workflow sections tailored to the product.
4. An installation section using the shared marketplace sequence.
5. A quick-start example using the canonical namespaced command.
6. An ecosystem section linking the marketplace hub and sibling product pages.
7. Repository, documentation, issue, privacy, and license links as applicable.

## Shared installation sequence

```text
/plugin marketplace add nikolareljin/claude-plugins
/plugin install <plugin>@nikolareljin-plugins
/plugin
/reload-plugins
/<plugin>:<command>
```

Document required companion software before invocation. Clearly label optional CLIs and
standalone alternatives rather than mixing them into the plugin installation steps.

## Design and accessibility

- Use the dark neutral surfaces and spacing scale established by the marketplace site.
- Select one accessible accent color and one supporting color for each product.
- Use semantic headings and landmarks, keyboard-visible focus, and descriptive link text.
- Keep the site readable at 320px width and disable nonessential motion when requested.
- Do not require JavaScript, remote fonts, analytics, or a build system.
- Keep the plugin manifest `homepage` pointed at Pages and `repository` at the source.
