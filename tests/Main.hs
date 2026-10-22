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
  [ simplifyTests, propagateTests, solveTests, assignmentTests, deletionTests
  , bruteForceTests, inputTests ]

-- {{p, q}, {¬p, q}, {p, ¬q}, {¬p, ¬q}} — lecture 9, slide 19
slide19 :: CNF
slide19 = map IS.fromList [[1, 2], [-1, 2], [1, -2], [-1, -2]]

-- Unit subsumption drops, unit resolution shortens
simplifyTests :: TestTree
simplifyTests = testGroup "simplify"
  [ testCase "drops clauses containing L, shortens those containing ¬L" $
      map IS.toList (simplify 1 slide19) @?= [[2], [-2]]
  , testCase "leaves untouched clauses alone" $
      map IS.toList (simplify 3 slide19) @?= map IS.toList slide19
  , testCase "shortening to nothing gives the empty clause" $
      map IS.toList (simplify 1 [IS.fromList [-1]]) @?= [[]]
  ]

-- Runs to a fixpoint, reports conflicts
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

-- The two empty objects, and the cut 
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

-- Check if the expected assignment is returned by the solver
assignmentTests :: TestTree
assignmentTests = testGroup "assignment"
  [ testCase "all 8 clauses over 3 atoms is unsatisfiable" $
      solve (allClauses 3) @?= Unsatisfiable
  , testCase "all 16 clauses over 4 atoms is unsatisfiable" $
      solve (allClauses 4) @?= Unsatisfiable
  ]

-- Deleting one clause leaves exactly one model 
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

  -- Does the solver agree with exhaustive search?
agrees :: Int -> CNF -> Bool
agrees n cnf = case solve cnf of
  Satisfiable m -> satisfies m cnf && bruteForce n cnf
  Unsatisfiable -> not (bruteForce n cnf)

bruteForceTests :: TestTree
bruteForceTests = testGroup "agreement with brute force"
  [ testCase "all 512 clause sets over 2 atoms" $
      assertBool "disagreement" (all (agrees 2) (clauseSetsOver 2))
  , testCase "S3 and all its deletions" $
      assertBool "disagreement" $
        agrees 3 (allClauses 3)
          && all (\i -> agrees 3 (deleteAt i (allClauses 3))) [0 .. 7]
  ]

-- Reading clauses typed by the user (parseCNF in src/Syntax.hs)
inputTests :: TestTree
inputTests = testGroup "user input"
  [ testCase "one clause per line, any number of literals" $
      parseCNF "1 -2\n2 3 4 5\n-1\n" @?= Just (map IS.fromList [[1, -2], [2, 3, 4, 5], [-1]])
  , testCase "blank lines are skipped" $
      parseCNF "1\n\n   \n2\n" @?= Just (map IS.fromList [[1], [2]])
  , testCase "DIMACS: comments, header and trailing 0" $
      parseCNF "c a comment\np cnf 2 2\n1 -2 0\n2 0\n" @?= Just (map IS.fromList [[1, -2], [2]])
  , testCase "empty input is the empty clause set" $
      parseCNF "" @?= Just []
  , testCase "a lone 0 is the empty clause" $
      parseCNF "0\n" @?= Just [IS.empty]
  , testCase "a literal that is not an integer is rejected" $
      parseCNF "1 x\n" @?= Nothing
  , testCase "parsed input is solved: slide 19 is UNSAT" $
      fmap solve (parseCNF "1 2\n-1 2\n1 -2\n-1 -2\n") @?= Just Unsatisfiable
  ]
