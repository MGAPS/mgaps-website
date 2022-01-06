{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TupleSections     #-}

import           BulmaFilter                     (bulmaTransform)
import qualified Data.ByteString.Lazy            as B
import           Data.List                       (sortBy)
import           Data.Maybe                      (fromMaybe)
import           Data.Ord                        (comparing)
import qualified Data.Text                       as T
import qualified Data.Text.Lazy                  as TL
import           Data.Text.Lazy.Encoding         (encodeUtf8, decodeUtf8)
import qualified GHC.IO.Encoding                 as E
import           Hakyll
import           Hakyll.Images                   (compressJpgCompiler, loadImage)
import           System.Process.Typed            (ExitCode(..), readProcess, shell)
import           Template                        (NavigationLink (..), Schema, mkDefaultTemplate, tocTemplate)
import qualified Text.Blaze.Html.Renderer.String as St
import qualified Text.Blaze.Html.Renderer.Pretty as Pretty
import           Text.Pandoc.Extensions          (enableExtension, Extension(..))
import           Text.Pandoc.Options             (WriterOptions(..))
import qualified Text.Pandoc.Templates           as Template


schema :: Schema
schema = [
    -- Navigation link to home (/index.html) is done over the logo
    -- So no need to include it in the schema
      Waypoint "About"  [
          NavLink "/people.html"                "Executive Council and Officers"
        , NavLink "/announcements.html"         "All Announcements"
      ]
    , Waypoint "Academic" [
          NavLink "/academic/prelim.html"       "Preliminary Examination"
        , NavLink "/academic/mentorship.html"   "Mentorship Program"
        , NavLink "/academic/colloquium.html"   "Physics Colloquium"
      ]
    , Waypoint "Community" [
          NavLink "/community/events.html"      "Events"
        , NavLink "/community/sports.html"      "Sports"
        , NavLink "/community/workspace.html"   "Workspace"
        , NavLink "/community/amenities.html"   "Amenities"
    ]
    , NavLink "/rtech.html"                     "RTech"
    , Waypoint "Teaching" [
          NavLink "/teaching/teaching.html"     "Teaching Assistantship"
        , NavLink "/teaching/outreach.html"     "Outreach"
    ]
    , Waypoint "Graduate Program" [
          NavLink "/program/program.html"       "Program Information"
        , NavLink "/program/finances.html"      "Finances"
        , NavLink "/program/new_students.html"  "New Students"
    ]
    , NavLink "/resources.html"       "Resources" 
    ]

-- We match images down to two levels
-- Images/* and images/*/**
jpgImages, nonJpgImages, quickLinks :: Pattern
jpgImages    = "images/*.jpg" .||. "images/*/**.jpg" .||. "images/*.jpeg" .||. "images/*/**.jpeg"
nonJpgImages = ( "images/*/**" .||. "images/*" ) .&&. complement jpgImages
quickLinks   = "static/quick-links/*.md"


config :: Configuration
config = defaultConfiguration { destinationDirectory = "_rendered" }


main :: IO ()
main = do
    -- Hakyll can trip on characters like apostrophes
    -- https://github.com/jaspervdj/hakyll/issues/109
    E.setLocaleEncoding E.utf8

    -- We generate the default template
    -- TODO: do this using `create`
    B.writeFile "templates/default.html" $ encodeUtf8 . TL.pack . Pretty.renderHtml $ mkDefaultTemplate schema

    hakyllWith config $ do
        -- It is important that CNAME be in docs
        -- This allows for redirecting the Github Pages to
        -- a McGill domain
        match "CNAME" $ do
            route   idRoute
            compile copyFileCompiler

        match "css/*" $ do
            route   idRoute
            compile compressCssCompiler

        -- JPG images are special: they can be compressed
        match jpgImages $ do
            route   idRoute
            compile $ loadImage >>= compressJpgCompiler 50

        -- Most other things can be copied directly
        match (nonJpgImages .||. "js/*" .||. "files/**") $ do
            route   idRoute
            compile copyFileCompiler

        -- These are static pages, like the "sports" page
        -- Note that /static/index.html is a special case and is handled below
        match ("static/**.md" .&&. complement quickLinks) $ do
            route $ setExtension "html" `composeRoutes` staticRoute
            compile $ pandocCompiler_
                >>= loadAndApplyTemplate "templates/default.html" (defaultContext <> lastUpdatedField)
                >>= relativizeUrls

        --------------------------------------------------------------------------------
        -- Compile announcements
        -- This will create a new page per announcement
        match "announcements/*.md" $ do
            route $ setExtension "html"
            compile $ pandocCompiler_
                >>= loadAndApplyTemplate "templates/ann.html"     annCtx
                >>= loadAndApplyTemplate "templates/default.html" annCtx
                >>= relativizeUrls


        --------------------------------------------------------------------------------
        -- Compile all profiles
        -- If this is not done, we cannot use the metadata in HTML templates
        match "people/**" $ compile $ pandocCompiler_ >>= relativizeUrls

        --------------------------------------------------------------------------------
        -- Create a page for all MGAPS executives and officers
        create ["people.html"] $ do
            route idRoute
            compile $ do
                -- Special case: if there is a position called "president",
                -- it should be first!
                executives <- presidentFirst =<< loadAll (fromGlob "people/council/*.md")
                officers <- loadAll (fromGlob "people/officers/*.md")

                let profileListCtx = mconcat [
                          listField "executives" defaultContext (return executives)
                        , listField "officers"   defaultContext (return officers)
                        , constField "title" "MGAPS Executives and Officers"
                        , defaultContext
                        ]

                makeItem ""
                    >>= loadAndApplyTemplate "templates/people-list.html" profileListCtx
                    >>= loadAndApplyTemplate "templates/default.html" profileListCtx
                    >>= relativizeUrls

        --------------------------------------------------------------------------------
        -- Create a page containing all announcements
        create ["announcements.html"] $ do
            route idRoute
            compile $ do
                announcements <- recentFirst =<< loadAll "announcements/*"
                -- Context for announcement list (annList)
                let annListCtx = mconcat [
                          listField "announcements" annCtx (return announcements)
                        , constField "title" "All announcements"
                        , defaultContext
                        ]

                makeItem ""
                    >>= loadAndApplyTemplate "templates/ann-list.html" annListCtx
                    >>= loadAndApplyTemplate "templates/default.html" annListCtx
                    >>= relativizeUrls


        --------------------------------------------------------------------------------
        -- Compile all quick links before inserting them on the home page
        match quickLinks $ compile $ pandocCompiler_ >>= relativizeUrls

        --------------------------------------------------------------------------------
        -- Generate the home page, including recent announcements (i.e. last 5)
        match "static/index.html" $ do
            route staticRoute
            compile $ do
                quickLinks' <- loadAll quickLinks
                announcements <- fmap (take 5) . recentFirst =<< loadAll "announcements/*"
                let indexCtx = mconcat [
                          listField "announcements" annCtx (return announcements)
                        , listField "quick-links" defaultContext (return quickLinks')
                        , defaultContext
                        ]

                getResourceBody
                    >>= applyAsTemplate indexCtx
                    >>= loadAndApplyTemplate "templates/default.html" indexCtx
                    >>= relativizeUrls

        --------------------------------------------------------------------------------
        -- Create a sitemap for easier search engine integration
        -- Courtesy of Robert Pearce <https://robertwpearce.com/hakyll-pt-2-generating-a-sitemap-xml-file.html>
        create ["sitemap.xml"] $ do
            route   idRoute
            compile $ do
                -- Gather all announcements
                anns <- recentFirst =<< loadAll "announcements/*"
                -- Gather all other pages
                pages <- loadAll (fromGlob "static/**.md")
                let allPages = pages <> anns
                    sitemapCtx = listField "pages" annCtx (return allPages)

                makeItem (""::String)
                    >>= loadAndApplyTemplate "templates/sitemap.xml" sitemapCtx

        --------------------------------------------------------------------------------
        match "templates/*" $ compile templateCompiler


-- | Context for announcements
annCtx :: Context String
annCtx = mconcat [ dateField "date" "%Y-%m-%d"
                 , defaultContext
                 ]


-- Sort lists of profiles by position
-- most importantly, president should be first
-- The rest is alphabetical.
-- This is guaranteed by the Position newtype
presidentFirst :: MonadMetadata m => [Item a] -> m [Item a]
presidentFirst = sortByM (getPosition . itemIdentifier)
    where
        sortByM :: (Monad m, Ord k) => (a -> m k) -> [a] -> m [a]
        sortByM f xs = map fst . sortBy (comparing snd) <$> mapM (\x -> fmap (x,) (f x)) xs

        -- Extract the "position: " string from the item
        getPosition :: MonadMetadata m => Identifier -> m Position
        getPosition id' = do
            metadata <- getMetadata id'
            return $ (Position . fromMaybe "") $ lookupString "position" metadata

-- We create a special string type to describe a council position
-- This is only so that when sorting, the president always comes first ;)
newtype Position = Position String deriving Eq

instance Ord Position where
    compare _ (Position "President")  = LT
    compare (Position "President") _  = GT
    compare (Position a) (Position b) = compare a b


-- | Allow math display, code highlighting, and Pandoc filters
-- Note that the Bulma pandoc filter is always applied last
pandocCompiler_ :: Compiler (Item String)
pandocCompiler_ = do
    ident <- getUnderlying
    toc <- getMetadataField ident "withtoc"
    tocDepth <- getMetadataField ident "tocdepth"
    template <- unsafeCompiler $ either error id <$>
                        Template.compileTemplate mempty (T.pack . St.renderHtml $ tocTemplate)

    let extensions = [
            -- Pandoc Extensions: http://pandoc.org/MANUAL.html#extensions
            Ext_implicit_header_references    -- We also allow implicit header references (instead of inserting <a> tags)
            , Ext_definition_lists              -- Definition lists based on PHP Markdown
            , Ext_yaml_metadata_block           -- Allow metadata to be speficied by YAML syntax
            , Ext_superscript                   -- Superscripts (2^10^ is 1024)
            , Ext_subscript                     -- Subscripts (H~2~O is water)
            , Ext_footnotes                     -- Footnotes ([^1]: Here is a footnote)
            ]
        newExtensions = foldr enableExtension defaultExtensions extensions
        defaultExtensions = writerExtensions defaultHakyllWriterOptions
    -- Conditional writer options dependind on if a table of content (TOC) is required
    -- From Julie Moronuki
    --      https://argumatronic.com/posts/2018-01-16-pandoc-toc.html
        writerOptions = case toc of
            Just _ -> defaultHakyllWriterOptions {
                writerExtensions = newExtensions
                , writerTableOfContents = True
                , writerTOCDepth = read (fromMaybe "3" tocDepth) :: Int
                , writerTemplate = Just template
                }
            Nothing -> defaultHakyllWriterOptions { writerExtensions = newExtensions }
    -- Pandoc filters could be composed, instead of simply `bulmaTransform`
    pandocCompilerWithTransform defaultHakyllReaderOptions writerOptions bulmaTransform


-- Move content from static/ folder to base folder
staticRoute :: Routes
staticRoute = gsubRoute "static/" (const mempty)


-- | Check when a file was last updated, based on the git history
lastUpdatedViaGit :: FilePath -> IO (Maybe String)
lastUpdatedViaGit fp = do
    (ec, out, _) <- readProcess (shell $ "git log -1 --date=format:\"%Y-%m-%d\" --format=\"%ad\" " <> fp )
    case ec of
        ExitFailure _ -> return Nothing
        ExitSuccess   -> return . Just . TL.unpack . decodeUtf8 $ out

-- | Field which provides the "last-updated" variable for items, which 
-- provides the date of the most recent git commit which modifies a file.
-- Note that this context will be unavailable for generated pages
lastUpdatedField :: Context String
lastUpdatedField = field "last-updated" $ \(Item ident _) -> unsafeCompiler $ do
    lastUpdated <- lastUpdatedViaGit (toFilePath ident)
    case lastUpdated of
        Nothing -> return "<unknown>"
        Just dt -> return dt