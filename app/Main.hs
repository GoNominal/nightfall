module Main where

import Nightfall.MASM
import Control.Monad.State
import Nightfall.Targets.Miden
import Examples.Simple
import Examples.Cond
import Data.Map as Map
import System.Environment (getArgs, getProgName)

main :: IO ()
main = do
    let allProgs = Map.fromList [ ("trivial1", trivial1Prog)
                                , ("trivial2", trivial2Prog)
                                , ("trivial3", trivial3Prog)
                                , ("trivial4", trivial4Prog)
                                , ("simpleVar1", simpleVar1Prog)
                                , ("simpleVar2", simpleVar2Prog)
                                , ("simpleVar3", simpleVar3Prog)
                                , ("simpleIf", simpleIfProg)
                                , ("ifVar", ifVarProg)
                                , ("simpleInf", simpleInfProg)
                                ]
    
    args <- getArgs

    -- For now, trivial: argument is the name of the example to run
    when (length args < 1) $ do
        progName <- getProgName
        let str = "Usage: " ++ progName ++ " <example> [filepath] where <example> is one of:\n"
            examples = unlines . Prelude.map ("    "++) . Map.keys $ allProgs
        error $ str ++ examples ++ "\n and [filepath] (optional) is path to write the MASM, otherwise stdout"
    
    (masm, ctx) <- case Map.lookup (head args) allProgs of
        Nothing -> do
            let str = "Example program \"" ++ head args ++ "\" not found. Available ones are:\n"
                examples = unlines . Prelude.map ("    "++) . Map.keys $ allProgs
            error $ str ++ examples
        Just prog -> do
            let cfg = defaultConfig { cgfTraceVariablesDecl = True
                                    , cfgTraceVariablesUsage = True
                                    }
                context = defaultContext { config = cfg }
            let (midenProg, ctx) = runState (transpile prog) context
            return (midenProg, ctx)
    
    putStrLn $ "\n| Transpilation of program \"" ++ progName ctx ++ "\" finished!"
    putStrLn $ "|   - Program is estimated to take " ++ show (nbCycles ctx) ++ " execution cycles"
    putStrLn ""

    -- Check if the user provided a path to write the program
    let io = if (length args >= 2)
        then do
            let fp = args !! 1
            writeFile fp (ppMASM masm)
            putStrLn $ "Miden program written in \"" ++ fp ++ "\""
        else do
            putStrLn . ppMASM $ masm
    
    io