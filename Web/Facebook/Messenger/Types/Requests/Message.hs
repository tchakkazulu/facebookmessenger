{-|
Module      : Web.Facebook.Messenger.Types.Requests.Message
Copyright   : (c) Felix Paulusma, 2016
License     : MIT
Maintainer  : felix.paulusma@gmail.com
Stability   : semi-experimental

All the types that are used when sending regular messages to users. Text\/attachments\/templates

https://developers.facebook.com/docs/messenger-platform/send-api-reference/contenttypes
-}
module Web.Facebook.Messenger.Types.Requests.Message (
  -- * Send API Message
  --
  -- | Used when sending a `SendRequest`
  RequestMessage (..)
  -- ** Text Message
  , textRequest
  , textRequest_
  , RequestMessageText (..)
  -- ** Attachment Message
  , attachmentRequest
  , attachmentRequest_
  , RequestMessageAttachment (..)
  -- ** Quick Replies
  , qr
  , locQR
  , RequestQuickReply (..)
  , RQuickReply (..)
  , LocationQuickReply (..)
  -- * Exported modules
  , module Web.Facebook.Messenger.Types.Requests.Attachment
  )
where

import Control.Applicative ((<|>))
import Control.Monad (unless)
import Data.Aeson
import Data.Aeson.Types (Parser)
import qualified Data.HashMap.Strict as HM
import Data.Text (Text)

import Web.Facebook.Messenger.Types.Requests.Attachment
import Web.Facebook.Messenger.Types.Static



-- ----------------- --
--  MESSAGE REQUEST  --
-- ----------------- --

-- | Text, attachments or templates sent using the Send API
data RequestMessage = RMText RequestMessageText
                    | RMAttachment RequestMessageAttachment
  deriving (Eq, Show)

-- | Constructor for a text message; maybe including Quick Replies and/or meta data
textRequest :: [RequestQuickReply] -> Maybe Text -> Text -> RequestMessage
textRequest qrs metadata txt = RMText $ RequestMessageText txt qrs metadata

-- | Constructor to make a plain text message (no QRs or meta data)
textRequest_ :: Text -> RequestMessage
textRequest_ = textRequest [] Nothing

-- | A standard text message with optional Quick Replies and/or meta data
data RequestMessageText = RequestMessageText
    { rmtText :: Text
    -- ^ Message text. Previews will not be shown for the URLs in this field.
    -- Use attachment instead. (UTF-8; 640 character limit)
    , rmtQuickReply :: [RequestQuickReply] -- ^ List of `RequestQuickReply` to be sent with messages (max 11)
    , rmtMetadata :: Maybe Text -- ^ Custom string that is delivered with a message echo (1000 character limit)
    } deriving (Eq, Show)

-- | Constructor for an attachment message; maybe including Quick Replies and/or meta data
attachmentRequest :: [RequestQuickReply] -> Maybe Text -> RequestAttachment -> RequestMessage
attachmentRequest qrs metadata reqAtt = RMAttachment $ RequestMessageAttachment reqAtt qrs metadata

-- | Constructor to make a plain attachment message (no QRs or meta data)
attachmentRequest_ :: RequestAttachment -> RequestMessage
attachmentRequest_ = attachmentRequest [] Nothing

-- | An attachment (multimedia or template) message
data RequestMessageAttachment = RequestMessageAttachment
    { rmaAttachment :: RequestAttachment -- Attachment object
    , rmaQuickReply :: [RequestQuickReply] -- Array of quick_reply to be sent with messages (max 11)
    , rmaMetadata :: Maybe Text -- Has a 1000 character limit
    } deriving (Eq, Show)

-- | Constructor to make a regular `RequestQuickReply`
qr :: Text -> Text -> Maybe Text -> RequestQuickReply
qr title payload = RQR . RQuickReply title payload

-- | Constructor to make a location `RequestQuickReply`
locQR :: RequestQuickReply
locQR = RLQR $ LocationQuickReply

-- |  Quick Replies can be added to Text, Image and Template message types
data RequestQuickReply = RQR RQuickReply
                       | RLQR LocationQuickReply
  deriving (Eq, Show)

-- | A regular Quick Reply
data RQuickReply = RQuickReply
    { rqrTitle :: Text -- ^ Caption of button (20 char limit)
    , rqrPayload :: Text -- ^ Custom data that will be sent back to you via webhook (1000 char limit)
    , rqrImageUrl :: Maybe Text
    -- ^ URL of image for text quick replies
    -- (Image for `rqrImageUrl` should be at least 24x24 and will be cropped and resized)
    } deriving (Eq, Show)

-- | A Quick Reply that requests a geolocation from the user
data LocationQuickReply = LocationQuickReply
  deriving (Eq, Show)


-- ------------------- --
--  MESSAGE INSTANCES  --
-- ------------------- --

instance ToJSON RequestMessage where
  toJSON (RMText x) = toJSON x
  toJSON (RMAttachment x) = toJSON x

instance ToJSON RequestMessageText where
  toJSON (RequestMessageText text qrs metadata) =
      object' [ "text" .=! text
              , mEmptyList "quick_replies" $ Prelude.take 10 qrs
              , "metadata" .=!! metadata
              ]

instance ToJSON RequestMessageAttachment where
  toJSON (RequestMessageAttachment attach qrs metadata) =
      object' [ "attachment" .=! attach
              , mEmptyList "quick_replies" $ Prelude.take 10 qrs
              , "metadata" .=!! metadata
              ]

instance ToJSON RequestQuickReply where
  toJSON (RQR x) = toJSON x
  toJSON (RLQR x) = toJSON x

instance ToJSON RQuickReply where
  toJSON (RQuickReply title payload imageurl) =
      object' [ "content_type" .=! String "text"
              , "title" .=! title
              , "payload" .=! payload
              , "image_url" .=!! imageurl
              ]

instance ToJSON LocationQuickReply where
  toJSON LocationQuickReply =
      object' ["content_type" .=! String "location"]


instance FromJSON RequestMessage where
  parseJSON = withObject "RequestMessage" $ \o ->
        RMText <$> parseJSON (Object o)
    <|> RMAttachment <$> parseJSON (Object o)

instance FromJSON RequestMessageText where
  parseJSON = withObject "RequestMessageText" $ \o ->
      RequestMessageText <$> o .: "text"
                         <*> o .:? "quick_replies" .!= []
                         <*> o .:? "metadata"

instance FromJSON RequestMessageAttachment where
  parseJSON = withObject "RequestMessageAttachment" $ \o ->
      RequestMessageAttachment <$> o .: "attachment"
                               <*> o .:? "quick_replies" .!= []
                               <*> o .:? "metadata"

instance FromJSON RequestQuickReply where
  parseJSON = withObject "RequestQuickReply" $ \o ->
        RQR <$> parseJSON (Object o)
    <|> RLQR <$> parseJSON (Object o)

instance FromJSON RQuickReply where
  parseJSON = withObject "RQuickReply" $ \o -> do
      typ <- o .: "content_type" :: Parser Text
      unless (typ == "text") $
        fail "RQuickReply: expected \"text\" in \"content_type\" field"
      RQuickReply <$> o .: "title"
                  <*> o .: "payload"
                  <*> o .:? "image_url"

instance FromJSON LocationQuickReply where
  parseJSON = withObject "LocationQuickReply" $ \o -> do
      typ <- o .: "content_type" :: Parser Text
      unless (typ == "location") $
        fail "LocationQuickReply: expected \"location\" in \"content_type\" field"
      pure LocationQuickReply
