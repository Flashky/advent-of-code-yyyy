# 🎄 Advent of Code yyyy


- [Day 1](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day01)
- [Day 2](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day02)
- [Day 3](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day03)
- [Day 4](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day04)
- [Day 5](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day05)
- [Day 6](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day06)
- [Day 7](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day07)
- [Day 8](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day08)
- [Day 9](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day09)
- [Day 10](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day10)
- [Day 11](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day11)
- [Day 12](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day12)
- [Day 13](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day13)
- [Day 14](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day14)
- [Day 15](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day15)
- [Day 16](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day16)
- [Day 17](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day17)
- [Day 18](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day18)
- [Day 19](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day19)
- [Day 20](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day20)
- [Day 21](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day21)
- [Day 22](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day22)
- [Day 23](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day23)
- [Day 24](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day24)
- [Day 25](https://github.com/Flashky/advent-of-code-yyyy/tree/master/src/main/java/com/adventofcode/flashk/day25)

## Required secrets

The repository must have the following secrets declared under both **Actions** and **Dependabot** secrets:

| Secret | Purpose |
|---|---|
| `AOC_CI_APP_CLIENT_ID` | Client ID of the GitHub App to be used by CI build workflows |
| `AOC_CI_APP_PRIVATE_KEY` | Private key of the GitHub App CI to be used by CI build workflows |
| `CODACY_PROJECT_TOKEN` | *(Optional)* Needed for sending reports to Codacy. No reports will be sent if it is not present |

The only **required permission** the GitHub App must have is **Repository Contents** (`read`). 
The GitHub App must be installed in both the solutions and data repository so the build can successfully complete.
  
These secrets will be **provisioned automatically** if the repo has been created using the template repository [repository creation workflow](https://github.com/Flashky/advent-of-code-yyyy/actions/workflows/create-repo.yml).

## Cloning this repository

Clone with data repository:

```bash
git clone https://github.com/Flashky/advent-of-code-yyyy.git --recurse-submodules
```

The data repository is private, so use the following command if you are not the repository owner:

```bash
git clone https://github.com/Flashky/advent-of-code-yyyy.git
```

## Update data submodule

Use the following command to update the data submodule if there are any remote changes:

```bash
git submodule update --recursive --remote
```

## Re-attach local repository

If the local repo becomes detached, execute:

```bash
git checkout master
```

## About

- [Advent of Code](https://adventofcode.com/about)
