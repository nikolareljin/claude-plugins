# nikolareljin/claude-plugins

Claude Code plugin marketplace registry for plugins by [Nikola Reljin](https://github.com/nikolareljin).

## Plugins

| Plugin | Category | Command | Description |
|--------|----------|---------|-------------|
| [claude-reposec](https://github.com/nikolareljin/claude-reposec) | Security | `/nr-scan` | Deep security scanning for git repos: secrets, PII, vulnerabilities, git history, and dependency CVEs. |
| [claude-docsmith](https://github.com/nikolareljin/claude-docsmith) | Developer Tools | `/nr-update-docs` | Generate user and developer documentation from a repository using Claude Code, with optional local Ollama fallback. |
| [claude-reelsmith](https://github.com/nikolareljin/claude-reelsmith) | Media | `/nr-reelsmith` | Batch-finish a folder of video with Claude: enhance audio, stabilize, brand with a logo, and add news-style titles and captions. |

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

---

## Clone traffic

![Clone traffic](https://raw.githubusercontent.com/nikolareljin/stats/main/charts/claude-plugins.svg)

_Updated daily. Total and unique cloners over the last 14 days._
