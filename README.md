# nikolareljin/claude-plugins

[![Website](https://img.shields.io/badge/docs-GitHub%20Pages-F97316)](https://nikolareljin.github.io/claude-plugins/)

Claude Code plugin marketplace registry for plugins by [Nikola Reljin](https://github.com/nikolareljin).

## Plugins

| Plugin | Category | Command | Description |
|--------|----------|---------|-------------|
| [claude-reposec](https://nikolareljin.github.io/claude-reposec/) | Security | `/claude-reposec:nr-scan` | Deep security scanning for git repos: secrets, PII, vulnerabilities, git history, and dependency CVEs. |
| [claude-docsmith](https://nikolareljin.github.io/claude-docsmith/) | Developer Tools | `/claude-docsmith:nr-update-docs` | Generate user and developer documentation from a repository using Claude Code, with optional local Ollama fallback. |
| [claude-reelsmith](https://nikolareljin.github.io/claude-reelsmith/) | Media | `/claude-reelsmith:nr-reelsmith` | Batch-finish a folder of video with Claude: enhance audio, stabilize, brand with a logo, and add news-style titles and captions. |

## Add this marketplace

```
/plugin marketplace add nikolareljin/claude-plugins
```

Then install a plugin:

```
/plugin install claude-reposec@nikolareljin-plugins
/plugin install claude-docsmith@nikolareljin-plugins
/plugin install claude-reelsmith@nikolareljin-plugins
```

Restart Claude Code or run `/reload-plugins`, then verify installation with `/plugin`.
Each plugin website documents its companion CLI prerequisites and namespaced command.

## Related tool

[Docforge](https://nikolareljin.github.io/docforge/) is standalone GitHub Actions automation for developer, end-user, and NotebookLM-ready documentation. It is not installed through this marketplace.

## Website conventions

New plugin sites follow [`docs/site-style-guide.md`](docs/site-style-guide.md) so navigation, installation, accessibility, and ecosystem discovery remain predictable.

---

## Clone traffic

![Clone traffic](https://raw.githubusercontent.com/nikolareljin/stats/main/charts/claude-plugins.svg)

_Updated daily. Total and unique cloners over the last 14 days._
