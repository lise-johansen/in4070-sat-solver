-- | DPLL SAT solver. Literals are non-zero Ints: n is a variable, -n its negation.
module Solver where

import Control.Applicative ((<|>)) -- <-- needed, not in Prelude
import qualified Data.IntSet as IS
import Syntax

data Result = Unsatisfiable | Satisfiable Model
  deriving (Eq, Show)

-- S[L] : unit subsumption + unit resolution
simplify :: Literal -> CNF -> CNF
simplify literal cnf =
  [ IS.delete (complement literal) clause   -- unit resolution: remove L̄
  | clause <- cnf
  , not (IS.member literal clause)          -- unit subsumption: drop clauses containing L
  ]

-- Apply to fixpoint.  Nothing = branch closed.
propagate :: CNF -> Model -> Maybe (CNF, Model)
propagate cnf model
  | hasEmptyClause cnf = Nothing
  | otherwise = case findUnit cnf of
      Nothing      -> Just (cnf, model)
      Just literal -> propagate (simplify literal cnf) (literal : model)

-- The atom to cut on: the smallest atom in the first clause.
-- Only called when no clause is empty and the clause set is not empty.
chooseAtom :: CNF -> Atom
chooseAtom (clause : _) | not (isEmptyClause clause) = atom (IS.findMin clause)
chooseAtom _ = error "chooseAtom: no atom left to cut on"

-- One branch at a time
dpll :: CNF -> Model -> Maybe Model
dpll cnf model = case propagate cnf model of
  Nothing -> Nothing
  Just (cnf', model') ->
    if isSatisfied cnf'
      then Just model'
      else let cutAtom = chooseAtom cnf'
           in dpll (simplify cutAtom cnf') (cutAtom : model')
              <|> dpll (simplify (complement cutAtom) cnf') (complement cutAtom : model')


-- the entry point
solve :: CNF -> Result
solve cnf = maybe Unsatisfiable (Satisfiable . completeModel (atomsOf cnf)) (dpll cnf [])

