# cpbrew Usage Guide

## 1) Setup

```zsh
source ~/.zshrc
cpbrew init /Users/coffee/00-personal/cp_solutions
```

## 2) Workflow (Sandbox first)

### New problem in sandbox

```zsh
cpbrew sb new Counting_Divisors
```

This creates/uses:
- Work file: `.sandbox/Counting_Divisors.cpp`
- Internal metadata: `.sandbox/.cpbrew/Counting_Divisors/meta.txt`
- Retry snapshots: `.sandbox/.cpbrew/Counting_Divisors/retries/`

### Mark as done (normal solve)

Direct mode:

```zsh
cpbrew done Counting_Divisors.cpp math
```

Interactive mode:

```zsh
cpbrew done
```

Normal done copies the solution to the destination folder and also stores a snapshot in retries.

## 3) Retry mode (spaced repetition)

```zsh
cpbrew retry Counting_Divisors
```

Behavior:
- Clears `.sandbox/Counting_Divisors.cpp` (blank code file)
- Keeps test cases in `.sandbox` (e.g. `.in/.out`)
- Marks problem as retry-active

When retry is active, `cpbrew done`:
- **Does not copy** to original destination folder
- Stores solve in retry history/log only

## 4) Compare retries

```zsh
cpbrew sb diff Counting_Divisors
```

Choose any two snapshots from:
- `.sandbox/.cpbrew/Counting_Divisors/retries/`

## 5) Useful commands

```zsh
cpbrew sb ls
cpbrew log
cpbrew stats
cpbrew stop
```

## 6) Connect repository by URL

```zsh
cpbrew repo https://github.com/your-user/your-repo.git
```

What it does:
- Initializes git if needed
- Adds `origin` if missing
- Updates `origin` URL if it already exists
