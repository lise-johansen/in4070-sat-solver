# SAT Solver — Work Plan

IN4070 Oblig 3, Exercise O3.1. The rules and definitions are in
[dpll-rules-reference.md](dpll-rules-reference.md).

## The assignment, in short

- Write a program that checks whether a **clause set** is satisfiable. If it is, print a
  **satisfying interpretation**.
- IN4070: the calculus must use **unit propagation** (the DPLL lecture).
- **Test:** all 8 clauses over 3 atoms is unsatisfiable. Deleting any one clause makes it
  satisfiable.
- **Scale:** run the `2ⁿ` clauses over `n` atoms for `n > 3`. How large can `n` get?
- **Deliver:** the program, plus a PDF explaining the code and the results.

---

## Status

| Part | State |
|---|---|
| Types and printing | **done** — `src/Syntax.hs` |
| Simplification, unit propagation, atomic cut, DPLL | **done** — `src/Solver.hs` |
| Test family, predicted model, verifier, brute force | **done** — `src/Testing.hs` |
| The assignment's `n = 3` check, self-verifying | **done** — `app/Main.hs` |
| Test suite | **partly done** — `tests/Main.hs` |
| Decision counting | todo — §6 |
| Scaling runs for `n > 3` | todo — §7 |
| The report PDF | todo — §8 |
| Trace of the proof steps | optional — §9 |
| Parser for typed-in clause sets | **decided against** — §10 |

---

## Design decisions

| Thing | Decision | Why |
|---|---|---|
| Atom | `Int`, `1, 2, 3, …` | The assignment's suggestion; never `0` |
| Literal | `Int`: `n` is the atom, `¬n` its negation | Complement is just `negate` |
| Clause | `IntSet` of literals | Fast membership and delete; duplicates disappear for free |
| Clause set | `[Clause]` | Rebuilt at every step anyway; order doesn't matter |
| Partial interpretation `M` | `[Literal]`, newest first | The literals assumed true on the current branch |
| Result | `Unsatisfiable \| Satisfiable Model` | `src/Solver.hs` |
| Sequent | the pair `(S, M)`, passed as two arguments | Keeps literals and clauses separate |
| Proof tree | never stored; one branch at a time, by recursion | Memory; `<\|>`on`Maybe` does the backtracking |
| Printed names | `1, 2, 3` → `p, q, r`; from `4`: `p4, p5, …` | Matches the assignment text for `n = 3` |
| Printed negation | `-p`, not `¬p` | Easier to type and read in a terminal; only `showLiteral` differs |
| Input | generated or hardcoded | The assignment needs no parser|

What the two answers look like when printed:

```haskell 
UNSAT                                   -- every branch closed
SAT  p = false, q = true, r = false     -- every atom 1..n gets a value
```

The satisfying interpretation gives a value to **every** atom of the input. On an open branch
some atoms may never have been assigned; `completeModel` sets those `false`.

**The two empty objects.** `{{}}` is a valid clause set and is unsatisfiable — the empty
clause is the closing condition. The empty clause **set** `{}` is satisfiable. Both are
covered in `tests/Main.hs`.

---

## Modules

```haskell
src/Syntax.hs     --types, literal/clause helpers, pretty-printing
src/Solver.hs     -- simplify, propagate, chooseAtom, dpll, solve      ← the calculus
src/Testing.hs    -- allClauses, predictedModel, satisfies,          bruteForce ← never imports Solver
app/Main.hs     -- the assignment's n = 3 run, self-checking
tests/Main.hs   -- tasty suite
```

`Testing.hs` imports only `Syntax`, so that it can act as an "independent check" true


```haskell
Syntax  ←  Solver   ←┐
   ↑                 ├─  tests/Main.hs,  app/Main.hs
   └──  Testing   ←──┘
```

---

## 1. Types and printing 
`src/Syntax.hs`.

- `Atom`, `Literal`, `Clause`, `CNF`, `Model`, `Sequent`
- `complement`, `atom`, `isPositive`
- `isEmptyClause`, `hasEmptyClause` (□ ∈ S), `isSatisfied` (S = ∅)
- `isUnit`, `unitLit`, `findUnit`
- `atomsOf`, `completeModel`
- `atomName`, `showLiteral`, `showClause`, `showCNF`, `showSequent`, `showModel`, `braced`


Printed notation:

- literal: `p`, `¬q`
- clause: `{p, q, ¬r}`, the empty clause as `□`
- clause set: `{{p, q, ¬r}, {¬p}}`
- interpretation: `p = false, q = true, r = false`

`showClause` sorts by atom, because `IntSet` orders numerically and would otherwise print
`{¬r, p, q}`.

---

## 2. The solver 

`src/Solver.hs`. Four functions, each mapped to a rule in the reference:

| Function | Rule |
|---|---|
| `simplify` | simplification for clauses |
| `propagate` | unit propagation, to a fixpoint |
| `chooseAtom` | the heuristic for the cut |
| `dpll` | with `<\|>` as the atomic cut |
| `solve` | entry point; `completeModel` on the **original** atom set |

Heuristic: the smallest atom of the first clause. Any choice is correct; a better one (e.g.
an atom from a shortest clause) as a TODO for the futhere.

---

## 3. Test family and verifier 

`src/Testing.hs`.

```haskell
allClauses     :: Int -> CNF          -- Sₙ, all 2ⁿ clauses over atoms 1..n
deleteAt       :: Int -> [a] -> [a]
predictedModel :: Clause -> Model     -- the unique model of Sₙ minus that clause
satisfies      :: Model -> CNF -> Bool
allModels      :: Int -> [Model]      -- all 2ⁿ interpretations
bruteForce     :: Int -> CNF -> Bool  -- ground truth by exhaustive search
clausesOver    :: Int -> [Clause]     -- all 3ⁿ non-tautological clauses
clauseSetsOver :: Int -> [CNF]        -- every clause set built from those
```

`clausesOver`/`clauseSetsOver` generate exhaustive small inputs — 512 clause sets over two
atoms, which is what validates the UNSAT answers.

---

## 4. The assignment's run 

`app/Main.hs` prints, for `n = 3`:

1. the full clause set and its result (expected UNSAT)
2. for each of the 8 deletions: the result, the predicted model, whether they match, and
   whether the verifier accepts

All eight report `match: True   verified: True`.

---

## 5. Test suite — in progress

`tests/Main.hs`, tasty + HUnit. Groups:

- **simplify** — drops clauses containing `L`, shortens those containing `L̄`, and shortening
  to nothing gives `□`
- **propagate** — one unit creates the next; contradictory units close; stops when no unit
  is left
- **solve** — the two empty objects; slide 19's example; unassigned atoms still get a value
- **assignment** — `allClauses 3` and `allClauses 4` are UNSAT
- **deletions** — all 8, each matching `predictedModel` and passing `satisfies`
- **brute force** — `agrees` on all 512 clause sets over 2 atoms, and on `S₃` with its
  deletions
---

## 6. Decision counting — todo

For the report. Decisions (cuts) are machine-independent; seconds are not.

A second version of `dpll` that threads a counter.

Haskell pitfalls:

- Thread the counter explicitly (return `(Maybe Model, Int)`), or use `State Int (Maybe a)`.
  **Not** `StateT Int Maybe`: when a branch fails, `Maybe` throws the state away, so the
  count resets on every backtrack.
- Make the counter strict (`let !n' = n + 1` with `BangPatterns`, or `$!`). Otherwise
  millions of unevaluated `+1`s pile up and overflow the stack on large `n`.

---

## 7. Measurements — todo

For the "how large can `n` get" part.

- Compile with `-O2` and run the compiled binary. Timings from `ghci` or `runghc` are
  meaningless — interpreted code is far slower.
- Measure for `n = 3, 4, 5, …` until it gets too slow: clauses (`2ⁿ`), decisions, time.
- Compare with unit propagation turned off. Expected: on `Sₙ` no unit clause appears until
  `n − 1` atoms are assigned, so propagation only saves the last level. **Measure it rather
  than assuming.**
- Possibly compare with random 3-SAT at the same `n`, where propagation should help much more.
- For memory and GC numbers: compile with `-rtsopts`, run with `+RTS -s`.

Rough expectation: work per level ≈ `2ⁿ(n−k)`, summed ≈ `2ⁿ·n²/2`. So `n` in the mid-teens
should be reachable; check where it actually breaks and why (time or memory).

**Done when:** a table of `n`, clauses, decisions and time, up to the `n` where it breaks
down, and the reason.

---

## 8. The report (PDF) — todo

1. **The calculus:** one-sided sequents, atomic cut (slide 18), simplification for clauses
   and unit propagation (slide 14). This is DPLL without pure literal elimination (slide 21).
   State explicitly that this meets the IN4070 requirement.
2. **Correctness:** Theorem 2.1 (slide 11) and the argument in §6 of the rule reference.
3. **The code:** the types, then `simplify` as a direct transcription of slide 14,
   `propagate`, and `dpll` with `<|>` as the atomic cut.
4. **Testing:** the test family, the 8 deletions against `predictedModel`, the independent
   verifier, and brute-force agreement on all clause sets over 2 atoms.
5. **Results:** the table from §7, how far `n` gets, and why it stops.
6. **Discussion:** propagation on `Sₙ` versus random input; pure literal elimination never
   fires on `Sₙ` (every literal occurs both ways), so leaving it out costs nothing here;
   what CDCL would add (slide 21's closing remarks).

---

## Checklist

- [x] `□ ∈ S` means closed, `S = ∅` means SAT. Not swapped.
- [x] Unit propagation runs to a fixpoint, not one pass.
- [x] The interpretation gives a value to every atom of the input.
- [x] Every SAT answer is checked by `satisfies`.
- [x] `allClauses 3` is UNSAT; all 8 deletions are SAT with the predicted model.
- [ ] UNSAT answers agree with brute force (`agrees` wired into the test suite).
- [ ] Timings come from a `-O2` build of the compiled binary.
- [ ] A table of `n`, clauses, decisions, time.
- [ ] The report names the rules with their slides: atomic cut (18), simplification for
      clauses and unit propagation (14), Theorem 2.1 (11).
- [ ] Code has comments and readable names; loose ends above resolved.