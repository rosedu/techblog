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

import System.Exit
import System.Process

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
    tags <- buildTags ("posts/**" .&&. hasNoVersion) $ fromCapture "tags/*.html"
    tagsRules tags $ \tag pattern -> do
      let title = "Posts tagged '" ++ tag ++ "'"
      route idRoute
      compile $ do
        posts <- loadAll pattern >>= recentFirst
        recent <- (fmap (take 3) . recentFirst) =<< loadAll ("posts/**" .&&. hasVersion "raw")
        let tagCtx =
              listField "recent" postCtx (return recent) `mappend`
              constField "title" title                 `mappend`
              listField "posts" postCtx (return posts) `mappend`
              tagsCtx tags

        makeItem ""
          >>= loadAndApplyTemplate "templates/post-list.html" tagCtx
          >>= loadAndApplyTemplate "templates/default.html" tagCtx
          >>= relativizeUrls

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
      compile $ do
        recent <- (fmap (take 3) . recentFirst) =<< loadAll ("posts/**" .&&. hasVersion "raw")
        let ctx =
              listField "recent" postCtx (return recent) `mappend`
              defaultContext

        pandocCompiler
          >>= loadAndApplyTemplate "templates/default.html" ctx
          >>= relativizeUrls

    match "posts/**" $ do
      route $ gsubRoute "posts/[0-9]{4}/[0-9]{2}/[0-9]{2}/" (const "")
        `composeRoutes`
        setExtension "html"
      compile $ do
        recent <- (fmap (take 3) . recentFirst) =<< loadAll ("posts/**" .&&. hasVersion "raw")
        let ctx =
              listField "recent" postCtx (return recent) `mappend`
              tagsCtx tags

        pandocCompiler
          >>= loadAndApplyTemplate "templates/post.html" ctx
          -- >>= (externalizeUrls $ feedRoot feedConfiguration)
          >>= saveSnapshot "postContent"
          -- >>= (unExternalizeUrls $ feedRoot feedConfiguration)
          >>= loadAndApplyTemplate "templates/disqus.html" ctx
          >>= loadAndApplyTemplate "templates/default.html" ctx
          >>= relativizeUrls

    -- attempt at providing recent posts
    match "posts/**" $ version "raw" $ compile getResourceBody

    create ["archive.html"] $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll ("posts/**" .&&. hasNoVersion)
        recent <- (fmap (take 3) . recentFirst) =<< loadAll ("posts/**" .&&. hasVersion "raw")
        let archiveCtx =
              listField "recent" postCtx (return recent) `mappend`
              listField "posts" postCtx (return posts) `mappend`
              constField "title" "Archives"            `mappend`
              defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
          >>= loadAndApplyTemplate "templates/default.html" archiveCtx
          >>= relativizeUrls

    create ["tags.html"] $ do
      route idRoute
      compile $ do
        renderedTags <- renderTagList $ sortTagsBy caseInsensitiveTags tags
        let nicerTags = replaceAll ", " (const "</li><li>") renderedTags
        recent <- (fmap (take 3) . recentFirst) =<< loadAll ("posts/**" .&&. hasVersion "raw")
        let ctx =
              listField "recent" postCtx (return recent) `mappend`
              constField "alltags" nicerTags     `mappend`
              constField "title" "Techblog tags" `mappend`
              defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/tags.html" ctx
          >>= loadAndApplyTemplate "templates/default.html" ctx
          >>= relativizeUrls

    match "index.html" $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAllSnapshots ("posts/**" .&&. hasNoVersion) "postContent"
        recent <- (fmap (take 3) . recentFirst) =<< loadAll ("posts/**" .&&. hasVersion "raw")
        let indexCtx =
              listField "recent" postCtx (return recent) `mappend`
              listField "posts" postCtx (return posts) `mappend`
              defaultContext

        getResourceBody
          >>= applyAsTemplate indexCtx
          >>= loadAndApplyTemplate "templates/default.html" indexCtx
          >>= relativizeUrls

    match "templates/*" $ compile templateCompiler
    --create rss feed
    create ["rss.xml"] rssFeed
techblogFeed :: FeedConfiguration
techblogFeed = FeedConfiguration
  { feedTitle       ="ROSEdu Techblog"
  , feedAuthorName  ="ROSEdu"
  , feedDescription ="ROSEdu Techblog"
  , feedAuthorEmail = "techblog@rosedu.org"
  , feedRoot        ="http://techblog.rosedu.org"
  }
-- Finally created the feed thanks to http://thetarpit.org/

rssFeed :: Rules()
rssFeed = do
    route idRoute
    compile $ do
        let feedCtx = postCtx `mappend` bodyField "description"
        posts <- fmap (take 10) . recentFirst =<<
            loadAllSnapshots ("posts/**" .&&. hasNoVersion) "postContent"
        renderRss techblogFeed feedCtx posts
tagsCtx :: Tags -> Context String
tagsCtx tags = tagsField "tags" tags `mappend` postCtx

postCtx :: Context String
postCtx =
  urlField "shareUrl" `mappend`
  dateField "date" "%B %e, %Y" `mappend`
  defaultContext

techblogConfiguration :: Configuration
techblogConfiguration = defaultConfiguration { deploySite = doDeploy }

doDeploy :: Configuration -> IO ExitCode
doDeploy _ = do
  -- return a nasty user error/pattern match failure if any command fails
  -- TODO: find a better way to do this
  ExitSuccess <- system "git stash"
  ExitSuccess <- system "git checkout gh-pages"
  ExitSuccess <- system "cp -r _site/* ."
  ExitSuccess <- system "git add ."
  ExitSuccess <- system "git commit -m \"`git log master --pretty=oneline -n1`\""
  ExitSuccess <- system "git push origin gh-pages"
  ExitSuccess <- system "git checkout master"
  system "git stash apply"

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
