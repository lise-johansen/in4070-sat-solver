module Testing where

import qualified Data.IntSet as IS
import           Syntax

-- | Sₙ: all 2ⁿ clauses over atoms 1..n.  sequence is the cartesian product.
allClauses :: Int -> CNF
allClauses n = map IS.fromList (sequence [[i, -i] | i <- [1 .. n]])

-- | Drop the element at index i.
deleteAt :: Int -> [a] -> [a]
deleteAt i xs = take i xs ++ drop (i + 1) xs

-- | The only model of Sₙ without clause c: every literal of c made false.
predictedModel :: Clause -> Model
predictedModel = map complement . IS.toList

-- | Independent check of a SAT answer: every clause has a true literal.
satisfies :: Model -> CNF -> Bool
satisfies m = all (\c -> not (IS.null (IS.intersection c model)))
  where model = IS.fromList m
