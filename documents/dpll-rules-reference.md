# DPLL — Rule Reference

The definitions and rules this SAT solver uses, 
Source: IN3070/IN4070 Lecture 9, *DPLL* (Martin Giese, 13 October 2025).

The solver only needed from lecture: **simplification for clauses**,
**unit propagation**, **atomic cut**, and the **closing condition**. 

---

## 1. Definitions

### Formulas in clause form

| Term | Definition | Read as |
|---|---|---|
| **Atom** (propositional variable) | `p`, `q`, `r`, … In the program: a positive integer `1, 2, 3, …` | — |
| **Literal** `L` | An atom `p` or a negated atom `¬p`. In the program: `n` or `-n` (never `0`) | — |
| **Complement** `L̄` | The opposite literal: `p̄ = ¬p` and `¬p̄ = p`. In the program: `negate` | — |
| **Clause** `C` | A finite set of literals | disjunction `L₁ ∨ … ∨ Lₖ` |
| **Unit clause** | A clause with exactly one literal, `{L}` | `L` |
| **Clause set** `S` | A finite set of clauses | conjunction `C₁ ∧ … ∧ Cₙ` |

Because clauses and clause sets are *sets*, order and duplicates do not matter.

### Truth

| Term | Definition |
|---|---|
| **Interpretation** `I` | Assigns `true` or `false` to every atom |
| `I ⊨ L` | `L = p` and `I(p) = true`, or `L = ¬p` and `I(p) = false` |
| `I ⊨ C` | `I ⊨ L` for **at least one** `L ∈ C` |
| `I ⊨ S` | `I ⊨ C` for **every** `C ∈ S` |
| **Satisfiable** | There is an `I` with `I ⊨ S`. Such an `I` is a **satisfying interpretation** (model) |
| **Unsatisfiable** | No interpretation satisfies `S` |

A **partial interpretation** is written as a set of literals `M`, the literals assumed
true so far. It must never contain both `L` and `L̄`. Atoms not mentioned in `M` can
be given any value when the final answer is printed.

### The two empty objects

Different types of empty

| | Is | Truth value | Meaning for the solver |
|---|---|---|---|
| **Empty clause** `□` (`∅ ∈ S`) | a disjunction of nothing | `false` | the branch is **closed** (conflict) |
| **Empty clause set** `S = ∅` | a conjunction of nothing | `true` | the branch is **open**: satisfiable |

### Notation

- `C[L]`: the clause `C` simplified with literal `L`, i.e. assuming `L` is true (§3.3).
- `S[L]`: every clause in `S` simplified with `L`.

---

## 2. The setting: one-sided sequents

The solver does proof search in a **one-sided** sequent calculus: all clauses are on the
left, the right side is empty.

```
C₁, C₂, …, Cₙ ⇒
```

- A **closed** proof tree (every branch closed) proves that the clause set is
  **unsatisfiable**.
- An **open** branch, where no more rules apply and nothing is closed, gives a
  **satisfying interpretation**: the literals on that branch.
---

## 3. The rules

### 3.1 Simplification — general form (Definition 2.1)

> Given two formulas `A` and `B`, where `B` does not have `¬` as top-symbol, the
> **simplification of `A` with `B`**, written `A[B]`, is the result of
> - replacing all occurrences of `B` in `A` by `true`, and
> - simplifying subformulae as long as possible using the rewritings
>
> ```
> A ∨ true  ↦ true        A ∨ false ↦ A
> A ∧ true  ↦ A           A ∧ false ↦ false
> A → true  ↦ true        A → false ↦ ¬A
> true → A  ↦ A           false → A ↦ true
> ¬true     ↦ false       ¬false    ↦ true
> ```
>
> The simplification of `A` with `¬B`, written `A[¬B]`, is the result of replacing all
> occurrences of `B` in `A` by `false`, and applying the same rewritings.


The solver never implements this general form. On clause form it reduces to §3.3. It is
included because the correctness results (§6) are stated for it.

### 3.2 The simplification rule (slide 12)

We have four simplification rules to LK. With an empty right side, only this one
is needed:

```
  B, A[B], Γ ⇒
  ─────────────
   B, A, Γ ⇒
```

Read bottom-up: if `B` is on the left, any other formula `A` on the left may be replaced by
`A[B]`. This is the step the solver performs every time it propagates a unit literal.

### 3.3 Simplification for clauses (slide 14) — *implemented*

Simplify a clause `C` with a literal `L`, i.e. assume `L` is true:

| Case | Condition | `C[L]` | What happens to `C` | Name |
|---|---|---|---|---|
| 1 | `L ∈ C` | `true` | **removed** from the clause set | unit subsumption |
| 2 | `L̄ ∈ C`, `C = A₁ ∨ … ∨ Aₖ ∨ L̄` | `A₁ ∨ … ∨ Aₖ` | **shortened** by removing `L̄` | unit resolution |
| 3 | neither | `C` | unchanged | — |


### 3.4 Unit propagation (slide 14) — *implemented*

> Unit subsumption and unit resolution together: **unit propagation**. Given a literal
> `L`, every clause can be either removed completely, or shortened by removing `L̄`.

The solver applies it **exhaustively**: as long as `S` contains a unit clause `{L}`, the
literal `L` must be true in every model, so

```
while S contains a unit clause {L}:
    add L to M                  -- L is now assumed true
    S := S[L]                   -- §3.3 applied to every clause
    if □ ∈ S: the branch is closed
```

- **Run to a fixpoint, not one pass.** Shortening a clause can create a *new* unit clause.
- **Terminates:** each round removes the unit clause `{L}` itself (case 1), so the
  number of clauses strictly decreases.

### 3.5 Atomic cut (slide 18) — *implemented*

> The atomic cut rule is just the cut rule
>
> ```
>  Γ ⇒ A, ∆      A, Γ ⇒ ∆
>  ──────────────────────
>          Γ ⇒ ∆
> ```
>
> where `A` is restricted to be an **atomic** formula.

The form for one-sided calculi, which is the one the solver uses (slide 18):

```
  A, Γ ⇒      ¬A, Γ ⇒
  ───────────────────
         Γ ⇒
```

Assume `A` true in one branch and `A` false in the other. In the program: pick an atom
`a` that still occurs in `S`, and continue with `S[a]` and, if that branch closes,
with `S[¬a]`. Each premise starts with a new unit literal, so unit propagation (§3.4) does
the simplifying.

What slide 18 says about it:

- *"No nonelementary speedup :-("*
- *"But we don't need more atomic cuts than we have prop. variables :-)"*. Each cut
  removes one atom from `S`, so a branch has at most `n` cuts (§6).
- *"We can replace β rules in LK by atomic cut… if we add the simplification rules to deal
  with β formulas."* This is why the solver needs no other branching rule.

**Which atom?** Slide 21: atomic cut *"with a heuristic for choosing the atom"*. Any choice
is correct; the choice only changes how fast the solver is.

### 3.6 Closing a branch

A branch is **closed** when the empty clause has been derived:

```
□ ∈ S
```

`□` is `false`, and a sequent with `false` on the left is valid, so the branch needs no
more work. Deriving `□` is the same as having both `L` and `L̄`: simplifying the unit
`{L̄}` with `L` gives `□`. That is the axiom `L, ¬L ⇒` (see the closed leaves on slide 19,
e.g. `q, p, ¬p ⇒`).

**All branches closed ⟹ the clause set is unsatisfiable.**

### 3.7 An open branch

A branch is **open** when `S = ∅`: every clause has been removed by unit subsumption, so
every clause is satisfied by `M`. The satisfying interpretation is `M`, with every atom
not in `M` set to an arbitrary value (e.g. `false`).

### 3.8 Pure literal elimination — *optional, not implemented*

Slide 21 lists it as the third part of DPLL, marked *"(exercise!)"*.

- A literal `L` is **pure** in `S` if `L̄` does not occur in any clause of `S`.
- If `L` is pure, remove every clause containing `L`. `S` is satisfiable if and only if the
  result is, since setting `L` true satisfies those clauses and falsifies nothing.
- If implemented, `L` must be added to `M`, or the printed interpretation is wrong.
- It never fires on the assignment's test family (§5): every literal occurs both positively
  and negatively there.

---

## 4. The DPLL algorithm (slide 21)

> DPLL works on a set of propositional clauses. DPLL consists of
> - Atomic Cut (with a heuristic for choosing the atom)
> - Unit Propagation
> - Pure Literal Elimination (exercise!)

Put together, on one branch at a time (the assignment's `prove(Sequent s)`):

```
dpll(S, M):
    unit propagation on (S, M)          -- §3.4
    if □ ∈ S:  return UNSAT             -- §3.6  (the sequent is an axiom)
    if S = ∅:  return SAT with M        -- §3.7  (no more rules apply)
    choose an atom a occurring in S     -- §3.5  (the heuristic)
    result := dpll(S[a], M ∪ {a})
    if result is SAT: return it
    return dpll(S[¬a], M ∪ {¬a})        -- both UNSAT ⟹ UNSAT
```

Only the current branch is kept in memory; backtracking happens through the recursion.

### Worked example (slides 13 and 19)

`S = {p ∨ q, ¬p ∨ q, p ∨ ¬q, ¬p ∨ ¬q}`, no unit clauses, so cut on `q`:

```
Branch q:   S[q]  = {p, ¬p}     (p∨q and ¬p∨q removed, p∨¬q → p, ¬p∨¬q → ¬p)
            unit p: S[p] = {□}  closed
Branch ¬q:  S[¬q] = {p, ¬p}     (p∨¬q and ¬p∨¬q removed, p∨q → p, ¬p∨q → ¬p)
            unit p: S[p] = {□}  closed
```

Both branches close after one cut, so `S` is unsatisfiable. Without simplification, the
naive β-rule proof on slide 6 needs 9 branches for the same clause set.

---

## 5. The test family

`Sₙ` is the set of **all `2ⁿ` clauses over `n` atoms**: each clause contains, for every atom,
either the atom or its negation. For `n = 3`: `{{p, q, r}, {p, q, ¬r}, {p, ¬q, r}, …}`.

- **`Sₙ` is unsatisfiable.** Any interpretation `I` falsifies exactly one clause: the one
  whose literals are all false under `I`, i.e. the complement of `I`.
- **`Sₙ` minus one clause `C` is satisfiable, with exactly one model:** the interpretation
  that makes every literal of `C` false. Every other interpretation falsifies a clause that
  is still in the set.

This gives an exact expected answer for each of the `2ⁿ` single deletions.

---

**An UNSAT answer is correct.** By induction over the recursion:

- *Closed branch:* `□ ∈ S`, and `□` is `false`, so `S` has no model.
- *Unit propagation:* a unit clause `{L}` forces `L` true in every model of `S`, so by
  Theorem 2.1, `S` has a model if and only if `S[L]` has one.
- *Atomic cut:* every interpretation makes `a` either true or false. If neither `S[a]` nor
  `S[¬a]` has a model, `S` has none.

**It terminates.** Unit propagation removes at least one clause per round. Each cut removes
an atom from `S`, and no rule adds one, so a branch has at most `n` cuts and the search tree
has at most `2ⁿ` leaves.

---

## 7. Glossary

| Term | Meaning |
|---|---|
| **Unit subsumption** | Removing a clause because it contains the true literal `L` |
| **Unit resolution** | Shortening a clause by removing `L̄` |
| **Unit propagation** | Repeating both, for every unit clause, until no unit clause is left |
| **Atomic cut** | Branching on an atom: one branch assumes it true, the other false |
| **Decision** | One application of atomic cut (useful to count when measuring) |
| **Conflict** | Deriving the empty clause `□`: the branch closes |
| **Closed branch** | A branch ending in a conflict |
| **Open branch** | A branch ending with `S = ∅`: gives a satisfying interpretation |
