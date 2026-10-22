# SAT Solver — IN4070 Oblig 3
See more in [documents/notes.md](documents/notes.md).

## Project layout

| Path | Contents |
|---|---|
| `src/Syntax.hs` | Types (`Literal`, `Clause`, `CNF`, `Model`), helpers, and printing |
| `src/Solver.hs` | `simplify`, `propagate`, `chooseAtom`, `dpll`, `solve` |
| `src/Testing.hs` | Test clause sets, brute force, and the independent verifier |
| `app/Main.hs` | The program: part 1 (n = 3), part 2 (how large can n get), and user input from files |
| `examples/` | Example input files, one clause set per file |
| `tests/Main.hs` | The test suite |
| `documents/` | Assignment text, Lecture 9, and work plan |

---

# Run project

Everything comes from the flake. With [direnv](https://direnv.net), `cd` into the
project folder loads it automatically (`.envrc` contains `use flake`). 

The first time, run `direnv allow` in the project folder. Without direnv, run `nix develop` instead.

To run SAT-solver (part 1 and part 2), from `./sat-solver`:

```
cabal run
```
Can also work:
```
nix run 
```

## Solve your own clause set (user input)

Write each clause set in its own file in the
`examples/` folder has five ready examples:


Run all of them, or only one:

```
cabal run exe:sat-solver -- examples/*.txt
```
```
cabal run exe:sat-solver -- examples/2-sat-two-atoms.txt
```

To add your own, make a new file in `examples/` and follow the rules below.

**The rules for the file**

- One clause per line. The literals go on the same line, separated by spaces.
- A literal is an integer: `1` = p, `2` = q, `3` = r, `4` = p4, … A minus sign means
  "not". `0` is not an atom.
- A clause can have any number of literals.
- Lines starting with `c` are comments, and blank lines are skipped. The comment lines
  at the top of a file are printed as its description.


## The test suite (`tests/Main.hs`)

Checks the solver's answers against known correct results. Run it from: `sat-solver/`

```
cabal test
```

Only the user input tests:

```
cabal test --test-options='-p "user input"'
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
--- 
