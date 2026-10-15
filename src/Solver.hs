-- | DPLL SAT solver. Literals are non-zero Ints: n is a variable, -n its negation.
module Solver
  ( Literal
  , Clause
  , Result (..)
  , solve
  ) where

type Literal = Int
type Clause  = [Literal]

data Result = Unsatisfiable | Satisfiable [Literal]
  deriving (Eq, Show)

-- | TODO: implement DPLL with unit propagation.
solve :: [Clause] -> Result
solve _ = Unsatisfiable
