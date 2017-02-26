module Web.Facebook.Messenger.Types.Requests.Message
    ( RequestMessage (..)
    , RequestQuickReply (..)
    , module Web.Facebook.Messenger.Types.Requests.Attachment
    ) where

import           Control.Applicative  ((<|>))
import           Data.Text
import           Data.Aeson
import qualified Data.HashMap.Strict  as HM

import           Web.Facebook.Messenger.Types.Requests.Attachment
import           Web.Facebook.Messenger.Types.Static


-- ----------------- --
--  MESSAGE REQUEST  --
-- ----------------- --

data RequestMessage =
  RequestMessageText
    { req_message_text        :: Text                -- Message text (UTF8 - 320 character limit)
    , req_message_quick_reply :: [RequestQuickReply] -- Array of quick_reply to be sent with messages (max 10)
    , req_message_metadata    :: Maybe Text          -- Has a 1000 character limit
    }
  | RequestMessageAttachment
    { req_message_attachment  :: RequestAttachment   -- Attachment object
    , req_message_quick_reply :: [RequestQuickReply] -- Array of quick_reply to be sent with messages (max 10)
    , req_message_metadata    :: Maybe Text          -- Has a 1000 character limit
    }
  deriving (Eq, Show)

data RequestQuickReply =
  RequestQuickReply
    { req_quick_reply_title     :: Text -- Caption of button (20 char limit)
    , req_quick_reply_payload   :: Text -- Custom data that will be sent back to you via webhook (1000 char limit)
    , req_quick_reply_image_url :: Maybe Text -- URL of image for text quick replies (Image for image_url should be at least 24x24 and will be cropped and resized)
    }
  | LocationQuickReply
    { req_quick_reply_image_url :: Maybe Text }
  deriving (Eq, Show)


-- ------------------- --
--  MESSAGE INSTANCES  --
-- ------------------- --

instance ToJSON RequestMessage where
  toJSON (RequestMessageText text qreplies metadata) =
    object' [ "text"     .=! text
            , "metadata" .=!! metadata
            , mEmptyList "quick_replies" $ Prelude.take 10 qreplies
            ]
  toJSON (RequestMessageAttachment attach qreplies metadata) =
    object' [ "attachment" .=! attach
            , "metadata"   .=!! metadata
            , mEmptyList "quick_replies" $ Prelude.take 10 qreplies
            ]

instance ToJSON RequestQuickReply where
  toJSON (RequestQuickReply title payload imageurl) =
    object' [ "content_type" .=! String "text"
            , "title"        .=! title
            , "payload"      .=! payload
            , "image_url"    .=!! imageurl
            ]
  toJSON (LocationQuickReply imageurl) =
    object' [ "content_type" .=! String "location"
            , "image_url"    .=!! imageurl
            ]


instance FromJSON RequestMessage where
  parseJSON = withObject "RequestMessage" $ \o ->
    RequestMessageText <$> o .: "text"
                       <*> o .:? "quick_replies" .!= []
                       <*> o .:? "metadata"
    <|> RequestMessageAttachment <$> o .: "attachment"
                                 <*> o .:? "quick_replies" .!= []
                                 <*> o .:? "metadata"

instance FromJSON RequestQuickReply where
  parseJSON = withObject "RequestQuickReply" $ \o ->
    case HM.lookup "content_type" o of
      Just "text" -> RequestQuickReply <$> o .: "title"
                                       <*> o .: "payload"
                                       <*> o .:? "image_url"
      Just "location" -> LocationQuickReply <$> o .:? "image_url"
      _ -> fail "QuickReply object expected \"text\" or \"location\" in [content_type] argument"
