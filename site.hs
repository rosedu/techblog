{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import GHC.IO.Encoding (setLocaleEncoding, setForeignEncoding)
import GHC.IO.Encoding (utf8, setFileSystemEncoding)
import           Hakyll

main :: IO ()
main = do
  setLocaleEncoding utf8
  setFileSystemEncoding utf8
  setForeignEncoding utf8
  hakyll $ do
    match "images/**" $ do
      route   idRoute
      compile copyFileCompiler

    match "font/**" $ do
      route   idRoute
      compile copyFileCompiler

    match "css/*" $ do
      route   idRoute
      compile compressCssCompiler

    match (fromList ["about.rst", "contact.markdown"]) $ do
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
        >>= saveSnapshot "postContent"
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
