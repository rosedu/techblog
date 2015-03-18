{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE OverloadedStrings #-}

import Hakyll

import Control.Applicative (empty)
import Control.Monad (liftM)
import Data.Char (isAlphaNum, isAscii, toLower)
import Data.List (intersperse)
import Data.Maybe (maybeToList)
import Data.Monoid (mappend, mconcat)
import GHC.IO.Encoding (setLocaleEncoding, setForeignEncoding, utf8,
  setFileSystemEncoding)
import System.Console.CmdArgs (cmdArgs, cmdArgsMode, help, program, ignore,
  (&=), helpArg, modes, auto, Data, Typeable, versionArg)
import System.Environment (withArgs)
import System.Exit (ExitCode(..))
import System.Process (system)
import Text.Pandoc (ReaderOptions(..), WriterOptions(..), HTMLMathMethod(..))

import qualified Data.Map as M
import qualified System.Console.CmdArgs.Explicit as CA
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A

type People = Tags

main :: IO ()
main = do
  args' <- cmdArgs techblogArgs
  case args' of
    Help -> showHelp
    Validate -> withArgs ["check"] buildTechblog
    x -> withArgs [map toLower $ show x] buildTechblog

buildTechblog :: IO ()
buildTechblog = do
  setLocaleEncoding utf8
  setFileSystemEncoding utf8
  setForeignEncoding utf8
  hakyllWith techblogConfiguration techblogRules

techblogRules :: Rules ()
techblogRules = do
  tags <- extractTags
  people <- extractPeople
  let fullCtx = mconcat
                  [ tagsField "tags" tags
                  , tagsFieldWith getPeople simpleRenderLink
                    (mconcat . intersperse ", ") "author" people
                  , postCtx]
  tagsRules tags $ makeTagPage postCtx
  tagsRules people $ makePeoplePage postCtx
  match "res/**" idRouteAndCopy
  match "images/**" idRouteAndCopy
  match "font/**" idRouteAndCopy
  match "css/*" cssRules
  match "templates/*" $ compile templateCompiler
  match "index.html" $ makeIndexArchive compileIndex
  match "posts/**" $ makePosts fullCtx
  match "posts/**" . version "raw" $ makeRawPosts
  match (fromList ["about.md", "404.md"]) markdownRules
  create ["archive.html"] $ makeIndexArchive compileArchive
  create ["rss.xml"] rssFeed
  create ["tags.html"] $ makeTags tags
  create ["people.html"] $ makePeople people

{-
 - Index and Archive pages.
 -}

makeIndexArchive :: Compiler (Item String) -> Rules ()
makeIndexArchive compiler = do
  route idRoute
  compile compiler

compileIndex :: Compiler (Item String)
compileIndex = getResourceBody
  >>= applyAsTemplate ctx
  >>= loadAndApplyTemplate "templates/default.html" ctx
  >>= relativizeUrls
  where
    ctx = recentPostCtx `mappend`
      listField "posts" postCtx loadTeaserSnapshots `mappend`
      constField "index" "" `mappend`
      defaultContext

compileArchive :: Compiler (Item String)
compileArchive = makeItem ""
  >>= loadAndApplyTemplate "templates/archive.html" ctx
  >>= loadAndApplyTemplate "templates/default.html" ctx
  >>= relativizeUrls
  where
    ctx = recentPostCtx `mappend`
      listField "posts" postCtx loadAllPosts `mappend`
      constField "title" "Archives" `mappend`
      defaultContext

{-
 - Resource rules (images, CSS, fonts, special files).
 -}

cssRules :: Rules ()
cssRules = do
  route idRoute
  compile compressCssCompiler

idRouteAndCopy :: Rules ()
idRouteAndCopy = do
  route idRoute
  compile copyFileCompiler

markdownRules :: Rules ()
markdownRules = do
  route $ setExtension "html"
  compile markdownCompiler

markdownCompiler :: Compiler (Item String)
markdownCompiler = techblogCompiler
  >>= loadAndApplyTemplate "templates/default.html" ctx
  where
    ctx = recentPostCtx `mappend` defaultContext

{-
 - Posts: rules, routing, snapshot creation and loading, versioning.
 -
 - We need snapshots to implements post visibility on home page and we need
 - versions to implement recent posts.
 -}

loadTeaserSnapshots :: Compiler [Item String]
loadTeaserSnapshots =
  loadAllSnapshots ("posts/**" .&&. hasNoVersion) "postTeaser"
  >>= fmap (take 25) . recentFirst

loadSnapshots :: Compiler [Item String]
loadSnapshots = loadAllSnapshots ("posts/**" .&&. hasNoVersion) "postContent"
  >>= recentFirst

loadAllPosts :: Compiler [Item String]
loadAllPosts = loadAll ("posts/**" .&&. hasNoVersion)
  >>= recentFirst

loadRecentPosts :: Compiler [Item String]
loadRecentPosts = liftM (take 3) $
  loadAll ("posts/**" .&&. hasVersion "raw")
  >>= recentFirst

postRouting :: Routes
postRouting =
  gsubRoute "posts/[0-9]{4}/[0-9]{2}/[0-9]{2}/" (const "") `composeRoutes`
  setExtension "html"

makePosts :: Context String -> Rules ()
makePosts tagCtx = do
  route postRouting
  compile $ postCompiler tagCtx

makeRawPosts :: Rules ()
makeRawPosts = do
  route postRouting
  compile getResourceBody

postCompiler :: Context String -> Compiler (Item String)
postCompiler tagCtx = do
  compiled <- techblogCompiler
  full <- loadAndApplyTemplate "templates/post.html" ctx compiled
  teaser <- loadAndApplyTemplate "templates/post-teaser.html" ctx $ f compiled
  _ <- saveSnapshot "postContent" full
  _ <- saveSnapshot "postTeaser" teaser
  loadAndApplyTemplate "templates/share.html" ctx full
  >>= loadAndApplyTemplate "templates/disqus.html" ctx
  >>= loadAndApplyTemplate "templates/default.html" ctx
  >>= relativizeUrls
  where
    ctx = recentPostCtx `mappend` tagCtx
    f = fmap (unlines . takeWhile (/= "<!--more-->") . lines)

{-
 - RSS feed configuration and building rules.
 -}

techblogFeed :: FeedConfiguration
techblogFeed = FeedConfiguration
  { feedTitle       ="ROSEdu Techblog"
  , feedAuthorName  ="ROSEdu"
  , feedDescription ="ROSEdu Techblog"
  , feedAuthorEmail = "techblog@rosedu.org"
  , feedRoot        ="http://techblog.rosedu.org"
  }

rssFeed :: Rules()
rssFeed = do
  route idRoute
  compile feedCompiler

feedCompiler :: Compiler (Item String)
feedCompiler = do
  let feedCtx = bodyField "description" `mappend` postCtx
  posts <- fmap (take 10) loadSnapshots
  renderRss techblogFeed feedCtx posts

{-
 - Tag creation and display in `tags.html`.
 -}

extractTags :: Rules Tags
extractTags = do
  tags <- buildTags ("posts/**" .&&. hasNoVersion) $ fromCapture "tags/*.html"
  return $ sortTagsBy caseInsensitiveTags tags

makeTagPage :: Context String -> String -> Pattern -> Rules ()
makeTagPage tagCtx tag pattern = do
  route sanitizeRoute
  compile $ tagPageCompiler tagCtx tag pattern

tagPageCompiler :: Context String -> String -> Pattern -> Compiler (Item String)
tagPageCompiler tagCtx tag pattern = makeItem ""
  >>= loadAndApplyTemplate "templates/post-list.html" ctx
  >>= loadAndApplyTemplate "templates/default.html" ctx
  >>= relativizeUrls
  where
    ctx = recentPostCtx `mappend`
      constField "title" ("Posts tagged '" ++ tag ++ "'") `mappend`
      listField "posts" postCtx (loadAll pattern >>= recentFirst) `mappend`
      tagCtx

makeTags :: Tags -> Rules ()
makeTags tags = do
  route idRoute
  compile $ renderTagList tags >>= tagCompiler

tagCompiler :: String -> Compiler (Item String)
tagCompiler tags = makeItem ""
  >>= loadAndApplyTemplate "templates/tags.html" ctx
  >>= loadAndApplyTemplate "templates/default.html" ctx
  >>= relativizeUrls
  where
    nicerTags = replaceAll ", " (const "</li><li>") tags
    ctx = recentPostCtx `mappend`
      constField "alltags" nicerTags `mappend`
      constField "title" "Techblog tags" `mappend`
      defaultContext

{-
 - People page creation and display in `people.html`.
 -}

extractPeople :: Rules People
extractPeople = do
  people <- buildTagsWith getPeople ("posts/**" .&&. hasNoVersion) $ fromCapture "people/*.html"
  return $ sortTagsBy caseInsensitiveTags people

getPeople :: MonadMetadata m => Identifier -> m [String]
getPeople identifier = do
  metadata <- getMetadata identifier
  return $ maybe [] (map trim . splitAll ",") $ M.lookup "author" metadata

makePeoplePage :: Context String -> String -> Pattern -> Rules ()
makePeoplePage contribCtx contrib pattern = do
  route sanitizeRoute
  compile $ contribPageCompiler contribCtx contrib pattern

contribPageCompiler :: Context String -> String -> Pattern -> Compiler (Item String)
contribPageCompiler contribCtx contrib pattern = makeItem ""
  >>= loadAndApplyTemplate "templates/post-list.html" ctx
  >>= loadAndApplyTemplate "templates/default.html" ctx
  >>= relativizeUrls
  where
    ctx = recentPostCtx `mappend`
      constField "title" ("Posts by '" ++ contrib ++ "'") `mappend`
      listField "posts" postCtx (loadAll pattern >>= recentFirst) `mappend`
      contribCtx

makePeople :: People -> Rules ()
makePeople people = do
  route idRoute
  compile $ renderTagList people >>= peopleCompiler

peopleCompiler :: String -> Compiler (Item String)
peopleCompiler people = makeItem ""
  >>= loadAndApplyTemplate "templates/people.html" ctx
  >>= loadAndApplyTemplate "templates/default.html" ctx
  >>= relativizeUrls
  where
    nicerPeople = replaceAll ", " (const "</li><li>") people
    ctx = recentPostCtx `mappend`
      constField "allcontribs" nicerPeople `mappend`
      constField "title" "Techblog Authors" `mappend`
      defaultContext

{-
 - Contexts for items.
 -
 - Only those contexts which are repeated in more than one rule.
 -}

postCtx :: Context String
postCtx =
  postTitleField `mappend`
  urlField "shareUrl" `mappend`
  dateField "date" "%B %e, %Y" `mappend`
  defaultContext

recentPostCtx :: Context String
recentPostCtx = listField "recent" postCtx loadRecentPosts

postTitleField :: Context a
postTitleField = Context $ \k _ i -> if k /= "postTitle" then empty else do
    val <- getMetadataField (itemIdentifier i) "postTitle"
    case val of
      Just x -> return . StringField $ x
      _ -> do
            value <- getMetadataField (itemIdentifier i) "title"
            maybe empty (return . StringField . (++ "...") . take 15) value

{-
 - Route sanitization.
 -}

replacements :: M.Map Char Char
replacements = M.fromList [('ă', 'a'), ('â', 'a'), ('î', 'i'), ('Î', 'I'),
  ('ș', 's'), ('Ș', 'S'), ('ț', 't'), ('Ț', 'ț'), ('.', '.'), ('/', '/'),
  ('-', '-'), (' ', '-'), ('+', '+')]

sanitizeRoute :: Routes
sanitizeRoute = customRoute $ sanitizePath . toFilePath

sanitizePath :: FilePath -> FilePath
sanitizePath = map toLower . concatMap replaceChars
  where
    replaceChars x
      | isAscii x && isAlphaNum x = [x]
      | otherwise = maybeToList $ M.lookup x replacements

{-
 - Utility functions.
 -}

{-
 - Copied from
 - http://hackage.haskell.org/package/hakyll-4.4.3.2/docs/src/Hakyll-Web-Tags.html
 - because it was not exported directly.
 -}
simpleRenderLink :: String -> (Maybe FilePath) -> Maybe H.Html
simpleRenderLink _  Nothing         = Nothing
simpleRenderLink tag (Just filePath) =
  Just $ H.a H.! A.href (H.toValue $ toUrl filePath) $ H.toHtml tag

{-
 - Special Markdown compiler. Needed to ensure proper extensions are in place.
 -}

techblogCompiler :: Compiler (Item String)
techblogCompiler = pandocCompilerWith techblogROptions techblogWOptions

techblogROptions :: ReaderOptions
techblogROptions = defaultHakyllReaderOptions

techblogWOptions :: WriterOptions
techblogWOptions = defaultHakyllWriterOptions
  { writerHTMLMathMethod = MathJax ""
  , writerSectionDivs = True
  , writerHtml5 = True
  }

{-
 - Deployment configuration.
 -
 - We use GitHub Pages for deployment thus we have to push to `gh-pages`
 - branch. But before switching to that branch all local changes which are not
 - committed need to be stashed (if any) and reapplied in the end.
 -
 - The `gh-pages` branch keeps only the contents of `_site`.
 -
 - The commit message on `gh-pages` contains the commit message of the `HEAD`
 - of the `master` branch. This way reverts are easier to do.
 -}

techblogConfiguration :: Configuration
techblogConfiguration = defaultConfiguration { deploySite = doDeploy }

doDeploy :: Configuration -> IO ExitCode
doDeploy _ = do
  -- return a nasty user error/pattern match failure if any command fails
  ExitSuccess <- system "git stash"
  ExitSuccess <- system "git checkout gh-pages"
  ExitSuccess <- system "git pull --rebase"
  _ <- system "git rm *.html &> /dev/null"
  _ <- system "git rm -rf css/ &> /dev/null"
  _ <- system "git rm -rf font/ &> /dev/null"
  _ <- system "git rm -rf images/ &> /dev/null"
  _ <- system "git rm -rf res/ &> /dev/null"
  _ <- system "git rm -rf tags/ &> /dev/null"
  _ <- system "git rm -rf people/ &> /dev/null"
  ExitSuccess <- system "cp -r _site/* ."
  ExitSuccess <- system "git add ."
  _ <- system "git commit -m \"`git log master --pretty=format:'%h %s%n' -n1`\""
  ExitSuccess <- system "git push origin gh-pages"
  ExitSuccess <- system "git checkout master"
  system "git stash apply"

{-
 - Command line arguments.
 -
 - We need this part to ensure that only the needed commands are in use
 - and hide all of the others.
 -}

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
