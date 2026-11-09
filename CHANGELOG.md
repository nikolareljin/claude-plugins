# Changelog

All notable changes to the nikolareljin-plugins marketplace are documented here.
Earlier versions are recorded only in git history.

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
