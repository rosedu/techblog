{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE OverloadedStrings #-}

import Hakyll

import Data.Char (toLower)
import Data.Monoid (mappend)
import GHC.IO.Encoding (setLocaleEncoding, setForeignEncoding, utf8,
  setFileSystemEncoding)
import System.Console.CmdArgs (cmdArgs, cmdArgsMode, help, program, ignore,
  (&=), helpArg, modes, auto, Data, Typeable, versionArg)
import System.Environment (withArgs)

import qualified System.Console.CmdArgs.Explicit as CA

main :: IO ()
main = do
  args' <- cmdArgs techblogArgs
  case args' of
    Help -> showHelp
    x -> withArgs [map toLower $ show x] buildTechblog

buildTechblog :: IO ()
buildTechblog = do
  setLocaleEncoding utf8
  setFileSystemEncoding utf8
  setForeignEncoding utf8
  hakyllWith techblogConfiguration $ do
    match "images/**" $ do
      route   idRoute
      compile copyFileCompiler

    match "font/**" $ do
      route   idRoute
      compile copyFileCompiler

    match "css/*" $ do
      route   idRoute
      compile compressCssCompiler

    match (fromList ["about.md", "people.md", "404.md"]) $ do
      route   $ setExtension "html"
      compile $ pandocCompiler
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

    match "posts/**" $ do
      route $ gsubRoute "posts/[0-9]{4}/[0-9]{2}/[0-9]{2}/" (const "")
        `composeRoutes`
        setExtension "html"
      compile $ pandocCompiler
        >>= loadAndApplyTemplate "templates/post.html"    postCtx
        -- >>= (externalizeUrls $ feedRoot feedConfiguration)
        >>= saveSnapshot "postContent"
        -- >>= (unExternalizeUrls $ feedRoot feedConfiguration)
        >>= loadAndApplyTemplate "templates/disqus.html" postCtx
        >>= loadAndApplyTemplate "templates/default.html" postCtx
        >>= relativizeUrls

    create ["archive.html"] $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll "posts/**"
        let archiveCtx =
              listField "posts" postCtx (return posts) `mappend`
              constField "title" "Archives"            `mappend`
              defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
          >>= loadAndApplyTemplate "templates/default.html" archiveCtx
          >>= relativizeUrls

    match "index.html" $ do
      route idRoute
      compile $ do
        -- TODO: limit number of posts and add nav buttons
        posts <- recentFirst =<< loadAllSnapshots "posts/**" "postContent"
        let indexCtx =
              listField "posts" postCtx (return posts) `mappend`
              defaultContext

        getResourceBody
          >>= applyAsTemplate indexCtx
          >>= loadAndApplyTemplate "templates/default.html" indexCtx
          >>= relativizeUrls

    match "templates/*" $ compile templateCompiler

postCtx :: Context String
postCtx =
  dateField "date" "%B %e, %Y" `mappend`
  defaultContext

techblogConfiguration :: Configuration
techblogConfiguration = defaultConfiguration { deployCommand = commStr }
  where
    commStr = "rsync -rtv _site/ techblog@rosedu.org:techblog/content/_site"

data TechblogArgs
  = Clean
  | Deploy
  | Help
  | Validate
  | Watch
  deriving (Data, Typeable, Show)

techblogArgs :: TechblogArgs
techblogArgs = modes
  [ Clean &= help "Cleanup and remove caches. Needed after compiling."
  , Deploy &= help "Deploy the site."
  , Help &= help "Show this message"
  , Validate &= help "Check for broken links, validate site."
  , Watch &= help "Build the site and open a preview server." &= auto
  ]
  &= help "Hakyll powered Techblog site compiler"
  &= program "techblog"
  &= versionArg [ignore]
  &= helpArg [ignore]

showHelp :: IO ()
showHelp = print $ CA.helpText [] CA.HelpFormatOne $ cmdArgsMode techblogArgs
