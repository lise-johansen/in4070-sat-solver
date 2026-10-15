module Main (main) where

import Solver
import Test.Tasty
import Test.Tasty.HUnit

main :: IO ()
main = defaultMain $ testGroup "Solver"
  [ testCase "empty clause is unsatisfiable" $
      solve [[]] @?= Unsatisfiable
  ]
