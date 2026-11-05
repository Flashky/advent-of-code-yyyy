# 🎄 Advent of Code - Java template

Template that scaffolds a complete Advent of Code setup generating:

- A public solutions repository
- A private inputs repository (which is wired as a git submodule at the solutions repo)

## Requirements

Configure the following secrets at this repository:

| Secret | Purpose |
|---|---|
| `PAT_TOKEN` | Creates the repositories |
| `CODACY_API_TOKEN` | Registers the projects in Codacy |
| `AOC_APP_CLIENT_ID` | GitHub App used by the generated repository |
| `AOC_APP_PRIVATE_KEY` | GitHub App private key |

## 🚀 Usage

1. Go to **Actions → Create AoC repository → Run workflow**.
2. Enter the year (e.g. `2026`).

**And that's pretty much it!**
Workflows will generate and auto-merge a pull request on each repository to scaffold everything automatically.

This README exists only in the template. Generated repositories get their own.

## About

- [Advent of Code](https://adventofcode.com/2025/about)
