module Main (main) where

import           Data.List (sort)
import           Solver
import           Syntax
import           Testing   (allClauses, deleteAt, predictedModel, satisfies)

main :: IO ()
main = do
  let s3 = allClauses 3

  putStrLn "All 8 clauses over 3 atoms:"
  putStrLn ("  " ++ showCNF s3)
  putStrLn ("  " ++ showResult (solve s3) ++ "   (expected UNSAT)")
  putStrLn ""

  putStrLn "With one clause deleted:"
  mapM_ (deletionCase s3) [0 .. length s3 - 1]

-- Solve the clause set with clause number i removed, and check the answer
-- against the model the deleted clause predicts (§5).
deletionCase :: CNF -> Int -> IO ()
deletionCase cnf i = do
  let removed  = cnf !! i
      smaller  = deleteAt i cnf
      expected = predictedModel removed
      result   = solve smaller
  putStrLn ("  without " ++ showClause removed ++ ":")
  putStrLn ("    " ++ showResult result)
  case result of
    Unsatisfiable -> putStrLn "    WRONG: expected SAT"
    Satisfiable m -> putStrLn
      (  "    expected  " ++ showModel expected
      ++ "   match: "     ++ show (sort m == sort expected)
      ++ "   verified: "  ++ show (satisfies m smaller) )

-- "UNSAT", or "SAT  p = false, q = true"
showResult :: Result -> String
showResult Unsatisfiable   = "UNSAT"
showResult (Satisfiable m) = "SAT  " ++ showModel m