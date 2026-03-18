# cpbrew Usage Guide

## Naming rules

- New problem work file in sandbox:
  - `.sandbox/<name>.cpp`
  - `<name>` is what you provide (or filename basename from CPH).
- Retry snapshots:
  - `.sandbox/.cpbrew/<name>/retries/<name>_attempt_<attempt_name>.cpp`

## Setup

```zsh
source ~/.zshrc
cpbrew init /Users/coffee/00-personal/cp_solutions
```

## New problem (sandbox-first)

```zsh
cpbrew sb new Counting_Divisors
```

Creates/uses:
- `.sandbox/Counting_Divisors.cpp`
- `.sandbox/.cpbrew/Counting_Divisors/meta.txt`
- `.sandbox/.cpbrew/Counting_Divisors/retries/`

## Done

Direct mode:

```zsh
cpbrew done Counting_Divisors.cpp math
```

Interactive mode:

```zsh
cpbrew done
```

Normal done:
- copies solve to destination folder
- stores a snapshot in retries history

## Retry (spaced repetition)

```zsh
cpbrew retry Counting_Divisors
```

Behavior:
- clears `.sandbox/Counting_Divisors.cpp` (blank)
- keeps testcases in `.sandbox`
- sets retry mode

Then when you run `cpbrew done`, it stores automatically as:

`Counting_Divisors_attempt_<n>.cpp`

in `.sandbox/.cpbrew/Counting_Divisors/retries/`.

In retry mode, `done` does **not** copy to original destination folder.

## Compare retries

```zsh
cpbrew sb diff Counting_Divisors
```

## Connect repo by URL

```zsh
cpbrew repo https://github.com/your-user/your-repo.git
```

- init git if needed
- add or update `origin`
