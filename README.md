# SAT Solver — IN4070 Oblig 3
See more in [documents/notes.md](documents/notes.md).

## Project layout

| Path | Contents |
|---|---|
| `src/Syntax.hs` | Types (`Literal`, `Clause`, `CNF`, `Model`), helpers, and printing |
| `src/Solver.hs` | `simplify`, `propagate`, `chooseAtom`, `dpll`, `solve` |
| `src/Testing.hs` | Test clause sets, brute force, and the independent verifier |
| `app/Main.hs` | The program: part 1 (n = 3) and part 2 (how large can n get) |
| `tests/Main.hs` | The test suite |
| `documents/` | Assignment text, Lecture 9, and work plan |

---

# Run project

Everything comes from the flake. With [direnv](https://direnv.net), `cd` into the
project folder loads it automatically (`.envrc` contains `use flake`). 

The first time, run `direnv allow` in the project folder. Without direnv, run `nix develop` instead.

To run SAT-solver (part 1 and part 2), from `./sat-solver`

```
cmd `cabal run`


`nix run` can also work.
```


## The test suite (`tests/Main.hs`)

Checks the solver's answers against known correct results. Run it from: `sat-solver/`

```
cmd `cabal test`
```



## Helpers in `src/Testing.hs`

Helper functions for testing (test clause sets, brute force, and the verifier). `cabal run` use it automatically. 

To try the functions by hand, start GHCi from the project folder (`sat-solver/`), inside `nix develop`:

```
cabal repl lib:sat-solver
```

Then, inside GHCi:

```
ghci> :m + Testing Solver Syntax
ghci> solve (allClauses 3)
Unsatisfiable
ghci> bruteForce 3 (allClauses 3)
False
```

# Results

## Part 1: all 8 clauses over 3 atoms

From `cabal run`.

```haskell
{
  {p, q, r},
  {p, q, ¬r},
  {p, ¬q, r},
  {p, ¬q, ¬r},
  {¬p, q, r},
  {¬p, q, ¬r},
  {¬p, ¬q, r},
  {¬p, ¬q, ¬r}
}
```

**Result:** `UNSAT` (expected: `UNSAT`)

### With one clause removed

Each clause is removed in turn, and the remaining 7 clauses are solved.

- **Match:** the model is the predicted one, every literal of the removed clause made false.
- **Verified:** the independent verifier confirms that the model makes all 7 clauses true.

| Removed clause | Result | p | q | r | Match | Verified |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| `{p, q, r}` | SAT | false | false | false | ✓ | ✓ |
| `{p, q, ¬r}` | SAT | false | false | true | ✓ | ✓ |
| `{p, ¬q, r}` | SAT | false | true | false | ✓ | ✓ |
| `{p, ¬q, ¬r}` | SAT | false | true | true | ✓ | ✓ |
| `{¬p, q, r}` | SAT | true | false | false | ✓ | ✓ |
| `{¬p, q, ¬r}` | SAT | true | false | true | ✓ | ✓ |
| `{¬p, ¬q, r}` | SAT | true | true | false | ✓ | ✓ |
| `{¬p, ¬q, ¬r}` | SAT | true | true | true | ✓ | ✓ |

**Result:** all 8 clause sets with one clause removed are `SAT`, each with exactly the
predicted model.

---

## Part 2: how large can `n` get?

Sₙ, all 2ⁿ clauses over `n` atoms, for `n = 3, 4, 5, …`

**Setup**

| | |
|---|---|
| Command | `cabal run sat-solver` (part 2 of the output) |
| Machine | AMD Ryzen 7 4700U (8 cores), 14 GB RAM |
| Compiler | GHC 9.10.3, `-O2` |
| Memory cap | 8 GB (`+RTS -M8g`) |
| Stops after | the first `n` over 60 s, or out of memory |
| Time | CPU time for `solve` only; building the clause set is not timed |

Three runs. The **mean** column is the one used in the report.

| n | Clauses | Run 1 (s) | Run 2 (s) | Run 3 (s) | **Mean (s)** | Result |
|---:|---:|---:|---:|---:|---:|:---:|
| 3 | 8 | 0.000 | 0.000 | 0.000 | **0.000** | UNSAT |
| 4 | 16 | 0.000 | 0.000 | 0.000 | **0.000** | UNSAT |
| 5 | 32 | 0.000 | 0.000 | 0.000 | **0.000** | UNSAT |
| 6 | 64 | 0.000 | 0.000 | 0.000 | **0.000** | UNSAT |
| 7 | 128 | 0.000 | 0.000 | 0.000 | **0.000** | UNSAT |
| 8 | 256 | 0.000 | 0.000 | 0.000 | **0.000** | UNSAT |
| 9 | 512 | 0.001 | 0.000 | 0.001 | **0.001** | UNSAT |
| 10 | 1,024 | 0.001 | 0.001 | 0.002 | **0.001** | UNSAT |
| 11 | 2,048 | 0.003 | 0.002 | 0.003 | **0.003** | UNSAT |
| 12 | 4,096 | 0.005 | 0.004 | 0.006 | **0.005** | UNSAT |
| 13 | 8,192 | 0.011 | 0.007 | 0.011 | **0.010** | UNSAT |
| 14 | 16,384 | 0.026 | 0.018 | 0.030 | **0.025** | UNSAT |
| 15 | 32,768 | 0.062 | 0.044 | 0.072 | **0.059** | UNSAT |
| 16 | 65,536 | 0.143 | 0.100 | 0.157 | **0.133** | UNSAT |
| 17 | 131,072 | 0.343 | 0.249 | 0.367 | **0.320** | UNSAT |
| 18 | 262,144 | 0.730 | 0.535 | 0.763 | **0.676** | UNSAT |
| 19 | 524,288 | 1.390 | 1.121 | 1.670 | **1.394** | UNSAT |
| 20 | 1,048,576 | 2.491 | 2.598 | 3.026 | **2.705** | UNSAT |
| 21 | 2,097,152 | 5.300 | 5.343 | 5.505 | **5.383** | UNSAT |
| 22 | 4,194,304 | 11.333 | 11.197 | 11.869 | **11.466** | UNSAT |
| 23 | 8,388,608 | 25.089 | 23.922 | 25.147 | **24.719** | UNSAT |
| 24 | 16,777,216 | 66.825 | 69.422 | 67.410 | **67.886** | UNSAT |

**Result:** all three runs stopped at `n = 24`, the first `n` over the 60-second limit
(mean 67.9 s). Every Sₙ up to `n = 24` was correctly found `UNSAT`. The largest `n`
solved within the limit is `n = 23` (mean 24.7 s).

**Observations**

- From `n = 15` to `n = 23`, each step multiplies the mean time by 1.9–2.4, so the
  time roughly doubles with each `n`. That matches the input: the number of clauses
  doubles with each `n`.
- The step from `n = 23` to `n = 24` is larger, ×2.7. At `n = 24` the heap gets close
  to the 8 GB cap, which may make garbage collection more expensive. Not measured yet;
  `+RTS -s` would show it.
- Without a memory cap (an earlier version of the program), the process was killed by
  the operating system's out-of-memory killer during `n = 24`. With the cap, GHC
  manages the same problem within 8 GB.
- The small times (under 0.01 s) vary a lot between runs, so they say little; the means
  for `n ≥ 18` are the meaningful ones.
