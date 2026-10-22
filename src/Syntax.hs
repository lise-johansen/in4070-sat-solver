module Syntax where

import           Data.IntSet (IntSet)
import qualified Data.IntSet as IS
import           Data.List   (find, intercalate, sortOn)
import           Text.Read   (readMaybe)

-- Data types
type Atom    = Int          -- 1, 2, 3, …  never 0
type Literal = Int          -- n is the atom, -n its negation
type Clause  = IntSet       -- disjunction
type CNF     = [Clause]     -- conjunction
type Model   = [Literal]    -- literals assumed true, newest first

-- A sequent consists of an assumed model and a set of clauses
data Sequent = Sequent { assumed :: Model, clauses :: CNF }
  deriving (Eq, Show)

-- Literals
complement :: Literal -> Literal
complement = negate

atom :: Literal -> Atom
atom = abs

isPositive :: Literal -> Bool
isPositive = (> 0)

-- Two empty objects
isEmptyClause :: Clause -> Bool             -- □
isEmptyClause = IS.null

hasEmptyClause :: CNF -> Bool               -- □ ∈ S, the closing condition 
hasEmptyClause = any isEmptyClause

isSatisfied :: CNF -> Bool                  -- S = ∅, the open branch
isSatisfied = null

-- Find a unit clause if there is one
isUnit :: Clause -> Bool
isUnit c = IS.size c == 1

findUnit :: CNF -> Maybe Literal
findUnit cs = IS.findMin <$> find isUnit cs

-- The candidates for the cut
atomsOf :: CNF -> [Atom]
atomsOf = IS.toList . IS.map abs . IS.unions

-- Decision counting 

-- For printing
completeModel :: [Atom] -> Model -> Model
completeModel as m = m ++ [negate a | a <- as, not (a `IS.member` assigned)]
  where assigned = IS.fromList (map abs m)

-- A pretty-printer
atomName :: Atom -> String                  -- 1,2,3 -> p,q,r;  from 4 -> p4, p5, …
atomName 1 = "p"
atomName 2 = "q"
atomName 3 = "r"
atomName a = "p" ++ show a

showLiteral :: Literal -> String            -- "p"  / "¬p"
showLiteral l
  | isPositive l = atomName l
  | otherwise    = "¬" ++ atomName (atom l)

showClause :: Clause -> String              -- "{p, q, ¬r}",  "□" when empty
showClause c
  | isEmptyClause c = "□"
  | otherwise       = braced (map showLiteral (sortOn atom (IS.toList c)))

showCNF :: CNF -> String                    -- "{{p, q, ¬r}, {¬p}}"
showCNF = braced . map showClause

showSequent :: Sequent -> String            -- "p, ¬q, {r, s} ⟹"
showSequent (Sequent m s) =
  intercalate ", " (map showLiteral (reverse m) ++ map showClause s) ++ " ⟹"

showModel :: Model -> String                -- show the interpretation of the satisfied model
showModel m = intercalate ", "
  [ atomName (atom l) ++ " = " ++ (if isPositive l then "true" else "false")
  | l <- sortOn atom m ]


braced :: [String] -> String
braced xs = "{" ++ intercalate ", " xs ++ "}"

-- Reading user input (used by app/Main.hs).
-- One clause per line, literals as non-zero integers: "1 -2 3" is {p, ¬q, r}.
-- Blank lines, comment lines ("c ...") and the "p cnf" header are skipped, and
-- a trailing 0 is ignored.
-- Nothing happens if the literal is not an (non-zero) integer.
parseCNF :: String -> Maybe CNF
parseCNF text = mapM parseClause [ws | ws@(w : _) <- map words (lines text), w `notElem` ["c", "p"]]
  where
    parseClause ws = IS.fromList . filter (/= 0) <$> mapM readMaybe ws
