{-# LANGUAGE OverloadedStrings #-}

module Template ( mkDefaultTemplate
                , tocTemplate
                , Schema
                , NavigationLink(..)
                ) where

import Data.List (intersperse)
import Control.Monad                (forM_)
import Text.Blaze.Html5             as H
import Text.Blaze.Html5.Attributes  as A

import Text.Blaze                    (toValue, toMarkup)

fontAwesomeURL = "https://use.fontawesome.com/releases/v5.2.0/css/all.css" 
bulmaURL = "/css/mgaps-style.css"

type Icon = String
type Link = String

type SocialLink = (Icon, Link, String)

data NavigationLink = NavLink            Link String                  -- ^ Regular link to a page
                    | NavLinkWithSublink Link String [NavigationLink] -- ^ Link to a page, as well as sublinks
                    | Waypoint                String [NavigationLink] -- ^ Waypoint to other links

type Schema = [NavigationLink]

socialLinks :: [SocialLink]
socialLinks = [ ("fab fa-facebook", "https://www.facebook.com/OfficialMGAPS",    "Follow us on Facebook") ]

styleSheets :: [AttributeValue]
styleSheets = 
    [ bulmaURL
    , fontAwesomeURL
    ]

-- Wrap the content of a page with a table of content
tocTemplate :: H.Html
tocTemplate = do 
    H.div ! class_ "message is-link" $ do
        H.div ! class_ "message-header" $
            H.p $ "On this page:"
        
        H.div ! class_ "message-body" $
            H.p $ "$toc$"

    "$body$"

defaultHead :: H.Html
defaultHead = H.head $ do
    H.meta ! charset "utf-8"
    H.meta ! name "viewport" ! content "width=device-width, initial-scale=1"
    H.title "$title$ - MGAPS"
    -- Tab icon
    -- Note : won't show up for Edge while on localhost
    H.link ! rel "icon" ! type_ "image/x-icon" ! href "/images/icon.png"
    -- Style sheets
    forM_ styleSheets (\link -> H.link ! rel "stylesheet" ! type_ "text/css" ! href link)
    -- Bulma helpers
    H.script ! type_ "text/javascript" ! src "/js/navbar-onclick.js" $ mempty


navigationBar :: Schema -> H.Html
navigationBar links = H.section ! class_ "hero is-primary" $ do
    --------------------------------------------------------------------------
    H.div ! class_ "hero-head" $
        H.nav ! class_ "navbar is-primary" $ 
            H.div ! class_ "container" $ do
                H.div ! class_ "navbar-brand" $ do
                    H.a ! class_ "navbar-item" ! href "/index.html" $ H.strong $ "MGAPS"
                    
                    -- toggleBurger function defined in js/navbar-onclick.js
                    H.span ! class_ "navbar-burger burger" ! A.id "burger" ! A.onclick "toggleBurger()"$ do
                        H.span $ mempty
                        H.span $ mempty
                        H.span $ mempty
                    
                H.div ! class_ "navbar-menu" ! A.id "navbarMenu" $ 
                    H.div ! class_ "navbar-start" $
                        forM_ links renderLink
    --------------------------------------------------------------------------
    H.div ! class_ "hero-body" $
        H.div ! class_ "container has-text-centered" $ do
            H.h1 ! class_ "title" $
                "$title$"
            "$if(contact)$"
            H.p . (H.a ! href "/people.html#$contact$") $ "For help, contact the $contact$."
            "$endif$"
    --------------------------------------------------------------------------
    H.div ! class_ "hero-foot" $ mempty

    where
        renderLink :: NavigationLink -> H.Html
        renderLink (NavLink link title) = H.a ! class_ "navbar-item" ! href (toValue link) $ toMarkup title
        renderLink (Waypoint title sublinks) = do
                H.div ! class_"navbar-item has-dropdown is-hoverable" $ do
                    -- A Waypoint does not have a liink of its own
                    -- But an anchor <a class="navbar-link">...</a> is still required
                    H.a ! class_ "navbar-link" $ toMarkup title
                    H.div ! class_ "navbar-dropdown is-boxed" $ -- is-boxed makes it easier to see hovering if navbar is transparent
                        forM_ sublinks renderLink
        

defaultFooter :: String -> H.Html
defaultFooter s = H.footer ! class_ "footer" $
    H.div ! class_ "content has-text-centered" $ do
        H.p $ (mconcat . intersperse " | ") $ renderLink <$> socialLinks
        H.p $ mconcat [
              "For questions and comments regarding this website, contact "
            , H.a ! href "/people.html#VP Communications" $ "VP Communications"
            , "." 
            ]
        H.p $ mconcat [
            "To know more about this how this site was created, click "
            , H.a ! href "/about-this-website.html" $ "here"
            , "."
            ]

    where
        renderLink (icon, link, name) = do 
            H.span ! class_ "icon" $ H.i ! class_ (toValue icon) $ mempty
            H.a ! target "_blank" ! href (toValue link) $ toMarkup name

-- | Full default template
-- The schema is used to render the navigation bar
-- The templateFooter will be adorned with the message @s@
mkDefaultTemplate :: Schema -> String -> H.Html
mkDefaultTemplate schema s = H.docTypeHtml $ do
    defaultHead
    H.body $ do
        navigationBar schema
        H.div ! class_ "section " $
            -- Test : for mobile, we make the regular text a little smaller (25% smaller)
            -- This is the "is-size-7-mobile" class
            --      https://bulma.io/documentation/modifiers/typography-helpers/#text-transformation
            H.div ! class_ "container is-size-7-mobile" $
            -- Note : the "content" class handles all barebones HTML tags
            --      https://bulma.io/documentation/elements/content/
                H.div ! class_ "content" $ "$body$"

        defaultFooter s