module Main (main) where

import qualified Data.IntSet as IS
import           Data.List (sort)
import           Solver
import           Syntax
import           Testing
import           Test.Tasty
import           Test.Tasty.HUnit

main :: IO ()
main = defaultMain $ testGroup "DPLL"
  [ simplifyTests, propagateTests, solveTests, assignmentTests, deletionTests ]

-- {{p, q}, {¬p, q}, {p, ¬q}, {¬p, ¬q}} — lecture 9, slide 19
slide19 :: CNF
slide19 = map IS.fromList [[1, 2], [-1, 2], [1, -2], [-1, -2]]

-- §3.3: unit subsumption drops, unit resolution shortens
simplifyTests :: TestTree
simplifyTests = testGroup "simplify"
  [ testCase "drops clauses containing L, shortens those containing ¬L" $
      map IS.toList (simplify 1 slide19) @?= [[2], [-2]]
  , testCase "leaves untouched clauses alone" $
      map IS.toList (simplify 3 slide19) @?= map IS.toList slide19
  , testCase "shortening to nothing gives the empty clause" $
      map IS.toList (simplify 1 [IS.fromList [-1]]) @?= [[]]
  ]

-- §3.4: runs to a fixpoint, reports conflicts
propagateTests :: TestTree
propagateTests = testGroup "propagate"
  [ testCase "one unit creates the next" $
      propagate [IS.fromList [1], IS.fromList [-1, 2], IS.fromList [-2, 3]] []
        @?= Just ([], [3, 2, 1])
  , testCase "contradictory units close the branch" $
      propagate [IS.fromList [1], IS.fromList [-1]] [] @?= Nothing
  , testCase "stops when no unit clause is left" $
      propagate slide19 [] @?= Just (slide19, [])
  ]

-- §1: the two empty objects, and §3.5 the cut
solveTests :: TestTree
solveTests = testGroup "solve"
  [ testCase "empty clause SET is satisfiable" $
      solve [] @?= Satisfiable []
  , testCase "empty CLAUSE is unsatisfiable" $
      solve [IS.empty] @?= Unsatisfiable
  , testCase "slide 19's example is unsatisfiable" $
      solve slide19 @?= Unsatisfiable
  , testCase "unassigned atoms still get a value" $
      case solve [IS.fromList [1, 2]] of
        Unsatisfiable -> assertFailure "expected Satisfiable"
        Satisfiable m -> sort (map atom m) @?= [1, 2]
  ]

-- the check the assignment text asks for
assignmentTests :: TestTree
assignmentTests = testGroup "assignment"
  [ testCase "all 8 clauses over 3 atoms is unsatisfiable" $
      solve (allClauses 3) @?= Unsatisfiable
  , testCase "all 16 clauses over 4 atoms is unsatisfiable" $
      solve (allClauses 4) @?= Unsatisfiable
  ]

-- §5: deleting one clause leaves exactly one model
deletionTests :: TestTree
deletionTests = testGroup "S3 minus one clause"
  [ testCase ("without clause " ++ show i) $
      case solve (deleteAt i s3) of
        Unsatisfiable -> assertFailure "expected Satisfiable"
        Satisfiable m -> do
          assertBool "verifier rejects the model" (satisfies m (deleteAt i s3))
          sort m @?= sort (predictedModel (s3 !! i))
  | i <- [0 .. length s3 - 1]
  ]
  where s3 = allClauses 3
  