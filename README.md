# Advent of Code {year}

## How to create a repository from this template repository

### Creation

1. Open the main page of the [template repository](https://github.com/Flashky/advent-of-code-yyyy).
2. Click on **Use this template**.
3. Select **Create a new repository**:
   1. Give a name to the new repository. Example: ``advent-of-code-2022``.
   2. Add a description to the new repository. Example: ``Advent of Code 2022``.

### Personal Access Token Setup

In order to the GitHub Actions to be able to perform certain actions, a **Personal Access Token** is needed:
1. Open **Account / Settings / Developer Settings**.
2. Click on **Generate New Token**.
3. Select ``repo`` checkbox.
4. Copy the token.
5. Open the created repository.
6. Open **Settings / Secrets and variables / Actions** and click on **New repository secret**:
   1. **Name:** ``PAT_TOKEN``
   2. **Secret:** The previously copied token.

### Update repository information

1. Go to **Settings / Actions / General**.
2. Under **Workflow permissions**:
   1. Enable **Read and write permissions**.
   2. Enable **Allow GitHub Actions to create and approve pull requests**.
4. Go to **Actions** and open the **Update year** workflow:
   1. Click on **Run workflow**.
   2. Type the year in ``yyyy`` format and click on **Run workflow**.

After the workflow has ended, the repository will have its topics assigned and all ``README.md`` and ``pom.xml`` will be updated with current year value.

### Data Repository Setup

1. Create a private data repository using [advent-of-code-yyyy-data](https://github.com/Flashky/advent-of-code-yyyy-data) template repository and set it up.
2. Add the data repository as a [submodule](https://github.blog/2016-02-01-working-with-submodules/) using the command:
```bash
git clone https://github.com/Flashky/advent-of-code-{year}.git &&
git submodule add -b master https://github.com/Flashky/advent-of-code-{year}-data.git advent-of-code-{year}/src/test/resources/inputs && 
git push
```

### Codacy Project Token Setup

1. Go to [Codacy](https://app.codacy.com) and add the repository.
2. Open **Settings / Coverage** and copy the ``CODACY_PROJECT_TOKEN`` value.
3. Go to the created [GitHub repository](https://github.com/Flashky/advent-of-code-{year}).
4. Open **Settings / Secrets and variables / Actions** and click on **New repository secret**:
   1. **Name:** ``CODACY_PROJECT_TOKEN``
   2. **Secret:** The previously copied token.

### Codacy Badges Setup

1. Go to [Codacy](https://app.codacy.com) and open the repository.
2. Open **Settings / General** and copy both the ``code quality`` and ``coverage`` badges.
3. Add them to this ``README.md``.

### Almost done...

1. Push the changes.
2. Remove these instructions from ``README.md`` and...

**Enjoy your new Advent of Code edition!**

---

- [Day 1](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day01)
- [Day 2](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day02)
- [Day 3](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day03)
- [Day 4](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day04)
- [Day 5](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day05)
- [Day 6](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day06)
- [Day 7](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day07)
- [Day 8](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day08)
- [Day 9](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day09)
- [Day 10](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day10)
- [Day 11](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day11)
- [Day 12](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day12)
- [Day 13](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day13)
- [Day 14](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day14)
- [Day 15](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day15)
- [Day 16](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day16)
- [Day 17](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day17)
- [Day 18](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day18)
- [Day 19](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day19)
- [Day 20](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day20)
- [Day 21](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day21)
- [Day 22](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day22)
- [Day 23](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day23)
- [Day 24](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day24)
- [Day 25](https://github.com/Flashky/advent-of-code-{year}/tree/master/src/main/java/com/adventofcode/flashk/day25)

## Cloning this repository

Without data repository:

```bash
git clone https://github.com/Flashky/advent-of-code-{year}.git
```

Including data repository:

```bash
git clone https://github.com/Flashky/advent-of-code-{year}.git --recurse-submodules
```

## About

- [Advent of Code](https://adventofcode.com/{year}/about)
