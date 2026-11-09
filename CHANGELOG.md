# Changelog

All notable changes to the nikolareljin-plugins marketplace are documented here.
The repository has no release tags; versions are `metadata.version` in
`.claude-plugin/marketplace.json`, and entries before 1.3.0 are rebuilt from
git history.

## [1.3.0] - 2026-11-09

### Changed

- Every plugin entry is pinned to a release: `ref` is the tag and `sha` is the
  40-character commit it points to. claude-reposec 0.2.1, claude-docsmith 1.4.0,
  claude-reelsmith 0.1.0.

### Added

- `scripts/check_marketplace_pins.sh` checks that each `sha` matches its tag and
  that `plugin.json` at that commit has the same version. Exit 1 is a pin failure,
  exit 2 a network or tooling error.
- The check runs on pull requests, on pushes to main and weekly.

## [1.2.1] - 2026-08-04

### Added

- GitHub Pages site for the marketplace (`site/`, `.github/workflows/pages.yml`)
  and a site style guide.

### Changed

- claude-reposec, claude-docsmith and claude-reelsmith homepages point at each
  plugin's GitHub Pages site.

## [1.2.0] - 2026-08-01

### Added

- claude-reelsmith.

## [1.1.0] - 2026-05-26

### Changed

- Version bump after the plugin repositories were renamed; the manifest was
  reformatted with no change to the entries.

## [1.0.0] - 2026-05-26

### Added

- Marketplace registry with claude-reposec and claude-docsmith.
