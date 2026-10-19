# SAT Solver — Work Plan

IN4070 Oblig 3, Exercise O3.1. The rules and definitions are in
[dpll-rules-reference.md](dpll-rules-reference.md); 

## The assignment, in short

- Write a program that checks whether a **clause set** is satisfiable. If it is, print a
  **satisfying interpretation**.
- IN4070: the calculus must use **unit propagation** (the DPLL lecture).
- **Test:** all 8 clauses over 3 atoms is unsatisfiable. Deleting any one clause makes it
  satisfiable.
- **Scale:** run the `2ⁿ` clauses over `n` atoms for `n > 3`. How large can `n` get?
- **Deliver:** the program, plus a PDF explaining the code and the results.

## Design decisions

| Thing | Decision | Why |
|---|---|---|
| Atom | `Int`, `1, 2, 3, …` | The assignment's suggestion; never `0` |
| Literal | `Int`: `n` is the atom, `-n` its negation | Complement is just `negate` |
| Clause | `IntSet` of literals | Fast membership and delete; duplicates disappear for free |
| Clause set | `[Clause]` | Rebuilt at every step anyway; order doesn't matter |
| Partial interpretation `M` | `[Literal]`, newest first | The literals assumed true on the current branch |
| Result | `Unsatisfiable \| Satisfiable [Literal]` | Already in `src/Solver.hs` |
| Sequent | the pair `(S, M)` | The assignment's hint: keep literals and clauses separate (§2) |
| Proof tree | never stored; one branch at a time, by recursion | The assignment's hint; memory |
| Printed names | `1, 2, 3` → `p, q, r`; from `4`: `p4, p5, …` | Matches the assignment text for `n = 3` |

What the two answers look like when printed:

```
UNSAT                                   -- every branch closed
SAT   p = false, q = true, r = false    -- every atom 1..n gets a value
```

The satisfying interpretation must give a value to **every** atom `1..n`. On an open
branch some atoms may never have been assigned. Give those any value, e.g. `false` 

**Empty clauses in the input are allowed.** `{{}}` is a valid clause set, and it is
unsatisfiable: the empty clause is the closing condition. The existing
test `solve [[]] @?= Unsatisfiable` checks this. The empty clause **set** `{}` is satisfiable.

## Modules

-- TODO: fill in when done


## 1. Types and printing
--TODO: fill in rest when done

- Printing, in the assignment's notation:
  - literal: `p`, `¬q`
  - clause: `{p, q, ¬r}`, the empty clause as `□` (or `{}`)
  - clause set: `{{p, q, ¬r}, {¬p}}`
  - interpretation: `p = false, q = true, r = false`



### 2. Parser
Grammar for input like `{{p, q, r}, {p, q, ¬r}}`:

```
clauseSet ::= "{" [ clause { "," clause } ] "}"
clause    ::= "{" [ literal { "," literal } ] "}"
literal   ::= [ "¬" | "~" | "-" ] atom
atom      ::= letter { letter | digit }        -- p, q, r, p4, …
```

- Whitespace allowed anywhere between tokens.
- Accept `~` and `-` as well as `¬`, since `¬` is awkward to type in a terminal.
- Map atom names to numbers in order of first appearance, and keep the names for printing.


## 3. Test family and verifier

```haskell
-- | Sₙ: all 2ⁿ clauses over atoms 1..n. sequence is the cartesian product.
allClauses :: Int -> [Clause]
allClauses n = map IS.fromList (sequence [[i, -i] | i <- [1 .. n]])

-- | The only model of Sₙ without clause c: every literal of c made false.
predictedModel :: Clause -> [Literal]
predictedModel = map negate . IS.toList

-- | Independent check of a SAT answer: every clause has a true literal.
satisfies :: [Literal] -> [Clause] -> Bool
satisfies m = all (\c -> not (IS.null (IS.intersection c model)))
  where model = IS.fromList m
```

## Rules
### 5. Unit propagation 

```haskell
-- | Nothing: the branch closed.  Just: the simplified set and the extended M.
propagate :: [Clause] -> [Literal] -> Maybe ([Clause], [Literal])
propagate s m
  | any IS.null s = Nothing                          -- □ ∈ S: closed (§3.6)
  | otherwise = case find ((== 1) . IS.size) s of
      Nothing   -> Just (s, m)                       -- no unit clause left
      Just unit -> let l = IS.findMin unit
                   in  propagate (simplify l s) (l : m)
```

(`find` comes from `Data.List`. `IS.findMin` avoids `head`, which `-Wall` warns about in
recent GHC versions.)

**Done when:** tests pass for:
- a chain where one unit creates the next: `{{p}, {¬p, q}, {¬q, r}}` gives `M = r, q, p`
  and `S = ∅`
- a conflict: `{{p}, {¬p}}` gives `Nothing`

### 6. DPLL (§3.5, §4)

```haskell
-- | One branch at a time. <|> on Maybe: try the first branch; only if it
--   closes (Nothing), try the second. Laziness means the second branch is
--   never computed when the first one succeeds.
dpll :: [Clause] -> [Literal] -> Maybe [Literal]
dpll s m = do
  (s', m') <- propagate s m                    -- Nothing here = closed branch
  case s' of
    []      -> Just m'                         -- S = ∅: open branch, SAT
    (c : _) ->
      let a = abs (IS.findMin c)               -- the atom to cut on (heuristic)
      in      dpll (simplify a s')          (a : m')
          <|> dpll (simplify (negate a) s') (negate a : m')
```

- `solve` calls `dpll s []`, turns `Nothing` into `Unsatisfiable`, and fills in unassigned
  atoms before returning `Satisfiable`.
- Start with the simplest heuristic (an atom from the first clause). A better one, such as
  an atom from a shortest clause, can be compared later in the report.

**Done when:** all of these pass:
- slide 19's example `{{p, q}, {¬p, q}, {p, ¬q}, {¬p, ¬q}}` is UNSAT
- `{}` is SAT and `{{}}` is UNSAT
- `allClauses 3` is UNSAT
- each of the 8 single deletions is SAT, and the answer equals `predictedModel`
- every SAT answer passes `satisfies`
- for `n ≤ 4`, the result agrees with brute force over all `2ⁿ` interpretations (in the
  tests only, never in the solver)

### 7. Showing the steps (the trace)

The original goal: see the start point, each rule application and its result, and whether
it ends in SAT or UNSAT.

- Make a second version of `dpll` that also returns the steps, e.g.

  ```haskell
  data Step
    = Propagate Literal [Clause]       -- unit L used, and the resulting S
    | Cut Literal                      -- start of a branch: atom assumed true or false
    | Closed                           -- □ derived
    | Open [Literal]                   -- S = ∅, with the interpretation
  ```

- Print it as an indented tree, top-down (the slides draw it bottom-up):

  ```
  {{p, q}, {¬p, q}, {p, ¬q}, {¬p, ¬q}}
  ├─ cut q
  │   S[q] = {{p}, {¬p}}
  │   unit p: S[p] = {□}   closed
  └─ cut ¬q
      S[¬q] = {{p}, {¬p}}
      unit p: S[p] = {□}   closed
  UNSAT
  ```

- Keep the plain `dpll` for measuring. The trace for `n = 15` has thousands of
  lines and slows everything down, so only use the trace for small inputs.

**Done when:** the trace for slide 19's example has the same shape as the tree on the slide:
one cut, two branches, each closed after one propagation. (The slide cuts on `q`; the simple
heuristic from step 6 cuts on `p` first, which gives the mirror image.)

### 8. The command-line program

The flow from the original notes:

```
1. Choose the input:
     a) type a clause set, e.g. {{p, q}, {¬p}}
     b) the test family Sₙ for a chosen n (from assigment text)
     c) Sₙ with one clause deleted (choose which one)
2. Print the start clause set.
3. Run the solver; with --trace, print each step (step 7).
4. Print the result: UNSAT, or SAT with the interpretation.
5. For SAT: print whether the verifier accepts it.
```

Command-line arguments are easier to script for the measurements than an interactive menu,
e.g. `sat-solver family 3 --delete 5 --trace`.

**Done when:** all three input kinds work from the terminal.

### 9. Measurements

For the "how large can `n` get" part.

- Compile with `-O2` and run the compiled binary. Timings from `ghci` or `runghc` are
  meaningless, since interpreted code is far slower.
- Measure for `n = 3, 4, 5, …` until it gets too slow: number of clauses (`2ⁿ`), number of
  decisions (cuts), and time.
- Count decisions, not just seconds: they don't depend on the machine.
- Compare with unit propagation turned off. Expected: on `Sₙ` no unit clause appears until
  `n − 1` atoms are assigned, so propagation only saves the last level. Measure it to check.
- Possibly compare with random 3-SAT at the same `n`, where propagation should help much more.

Haskell pitfalls when counting:

- Thread the counter explicitly (return `(Maybe [Literal], Int)`), or use
  `State Int (Maybe a)`. **Not** `StateT Int Maybe`: when a branch fails, `Maybe` throws
  the state away, so the count resets on every backtrack.
- Make the counter strict (`let !n' = n + 1` with `BangPatterns`, or `$!`). Otherwise
  millions of unevaluated `+1`s pile up and overflow the stack on large `n`.
- For memory and GC numbers: compile with `-rtsopts`, run with `+RTS -s`.
- Avoid `nub` and `Data.List` set operations on large clause lists (quadratic).

**Done when:** a table of `n`, clauses, decisions and time, up to the `n` where it breaks
down, and the reason (time or memory).

### 10. The report (PDF)

1. **The calculus:** one-sided sequents with atomic cut (slide 18) specialised to clauses (slide 14). 
    This is DPLL without pure literal elimination (slide 21).
2. **Correctness:** Theorem 2.1 (slide 11) and the argument in §6 of the rule reference.
3. **The code:** the types, then `simplify` as a transcription of slide 14, `propagate`, and
   `dpll` with `<|>` as the atomic cut.
4. **Testing:** the test family, the 8 deletions against `predictedModel`, the verifier, and
   brute force for small `n`.
5. **Results:** the table from step 9, how far `n` gets, and why it stops.
6. **Discussion:** propagation on `Sₙ` versus random input; pure literal elimination never
   fires on `Sₙ` (every literal occurs both ways), so leaving it out costs nothing here.

## Summery

- [ ] `□ ∈ S` means closed, `S = ∅` means SAT. Not swapped.
- [ ] Unit propagation runs to a fixpoint, not one pass.
- [ ] The interpretation gives a value to every atom `1..n`.
- [ ] Every SAT answer is checked by `satisfies`.
- [ ] `allClauses 3` is UNSAT; all 8 deletions are SAT with the predicted model.
- [ ] UNSAT answers agree with brute force for small `n`.
- [ ] Timings come from a `-O2` build.
- [ ] The report names the rules with their slides: atomic cut (18), simplification for
      clauses and unit propagation (14), Theorem 2.1 (11).
- [ ] Code has comments and readable names.
