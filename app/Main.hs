module Main (main) where

import qualified Data.IntSet as IS
import           Data.List (sort)
import           Solver
import           Syntax
import           Testing   (allClauses, deleteAt, predictedModel, satisfies)

-- Measuring how large n can get
import Control.Exception (AsyncException (HeapOverflow), evaluate, throwIO, try)
import System.CPUTime    (getCPUTime)
import System.IO         (hSetBuffering, stdout, BufferMode(LineBuffering))
import Text.Printf       (printf)

main :: IO ()
main = do
  hSetBuffering stdout LineBuffering     -- print each row as soon as it is measured
  checkN3
  putStrLn ""
  scaling

-- Part 1: all 8 clauses over 3 atoms is UNSAT, and deleting any one
-- clause makes it SAT.
checkN3 :: IO ()
checkN3 = do
  let s3 = allClauses 3

  putStrLn "All 8 clauses over 3 atoms:"
  putStrLn ("  " ++ showCNF s3)
  putStrLn ("  " ++ showResult (solve s3) ++ "   (expected UNSAT)")
  putStrLn ""

  putStrLn "With one clause deleted:"
  mapM_ (deletionCase s3) [0 .. length s3 - 1]

-- Remove a clause and test the solver's response.
deletionCase :: CNF -> Int -> IO ()
deletionCase cnf i = do
  let removed  = cnf !! i
      smaller  = deleteAt i cnf
      expected = predictedModel removed
      result   = solve smaller
  putStrLn ("  without " ++ showClause removed ++ ":")
  putStrLn ("    " ++ showResult result)

  -- Check the solver's result against the expected model.
  case result of
    Unsatisfiable -> putStrLn "    WRONG: expected SAT"
    Satisfiable m -> putStrLn
      (  "    expected  " ++ showModel expected
      ++ "   match: "     ++ show (sort m == sort expected)
      ++ "   verified: "  ++ show (satisfies m smaller) )

-- "UNSAT", or "SAT"
showResult :: Result -> String
showResult Unsatisfiable   = "UNSAT"
showResult (Satisfiable m) = "SAT  " ++ showModel m

-- Part 2: how large can n get?
-- Solve the 2ⁿ clauses over n atoms for n = 3, 4, 5, … and stop after the
-- first n that takes longer than timeLimit seconds, or that runs out of memory.
--
-- The memory cap is the RTS option -M, set to 8 GB (default) in sat-solver.cabal.
-- Override default: cabal run sat-solver -- +RTS -M12g
-- Going over it makes GHC throw HeapOverflow, which is caught below, so the
timeLimit :: Double
timeLimit = 60

scaling :: IO ()
scaling = do
  printf "How large can n get? (stops after the first n over %.0f s, or out of memory)\n" timeLimit
  putStrLn "   n     clauses     seconds   result"
  go 3
  where
    go :: Int -> IO ()
    go n = do
      outcome <- try (row n)
      case outcome of
        Left HeapOverflow ->
          printf "%4d  stopped: out of memory (over the -M heap cap)\n" n
        Left other -> throwIO other
        Right seconds
          | seconds > timeLimit -> printf "Stopped: n = %d took %.1f s.\n" n seconds
          | otherwise           -> go (n + 1)

-- Solve the 2ⁿ clauses over n atoms, print one table row, return the time.
row :: Int -> IO Double
row n = do
  let cnf = allClauses n
  _ <- evaluate (sum (map IS.size cnf))  -- build the clauses first, so only solving is timed
  t0 <- getCPUTime
  result <- evaluate (solve cnf)
  t1 <- getCPUTime
  let seconds = fromIntegral (t1 - t0) / 1e12 :: Double
  printf "%4d  %10d  %10.3f   %s\n" n (length cnf) seconds (showResult result)
  pure seconds
