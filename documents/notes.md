# SAT Solver 
IN4070 Oblig 3, Exercise O3.1. The rules and definitions are in
[assigemnt-text.pdf](assigemnt-text.pdf).

## The assignment, in short

- Write a program that checks whether a **clause set** is satisfiable. If it is, print a
  **satisfying interpretation**.
- IN4070: the calculus must use **unit propagation** (the DPLL lecture).
- **Test:** all 8 clauses over 3 atoms is unsatisfiable. Deleting any one clause makes it
  satisfiable.
- **Scale:** run the `2ⁿ` clauses over `n` atoms for `n > 3`. How large can `n` get?
- **Deliverables:** the program + PDF explaining the code and the results.

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
| Input | generated  | n=3, or n ++|

*notes* 
1. The satisfying interpretation gives a value to **every** atom of the input. On an open branch. Atoms not assigned is set to `false`; `completeModel`. 
2. **The two empty objects.** `{{}}` is a valid clause set and is unsatisfiable 
3. the empty clause is the closing condition. The empty clause **set** `{}` is satisfiable. 

Both 2 and 3 are covered in `tests/Main.hs`.

---

## Modules

```haskell
src/Syntax.hs --> types, literal/clause helpers, pretty-printing

src/Solver.hs --> simplify, propagate, chooseAtom, dpll, solve ← the calculus

src/Testing.hs  --> allClauses, predictedModel, satisfies, bruteForce ← never imports Solver

app/Main.hs  --> the assignment's n = 3 run, self-checking

tests/Main.hs  --> test suit 
```

```haskell
Syntax  ←  Solver   ←┐
   ↑                 ├─  tests/Main.hs,  app/Main.hs
   └──  Testing   ←──┘
```

---

## Types and printing 
`src/Syntax.hs`.

Printed notation:

- literal: `p`, `¬q`
- clause: `{p, q, ¬r}`, the empty clause as `□`
- clause set: `{{p, q, ¬r}, {¬p}}`
- interpretation: `p = false, q = true, r = false`

`showClause` sorts by atom, because `IntSet` orders numerically and would otherwise print `{¬r, p, q}`.

---

## TLDR;

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
      