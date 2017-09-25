module Web.Facebook.Messenger.Types 
    ( CallbackHandlers (..)
    , module Web.Facebook.Messenger.Types.Responses
    , module Web.Facebook.Messenger.Types.Callbacks
    , module Web.Facebook.Messenger.Types.Requests
    , module Web.Facebook.Messenger.Types.Static
    , SenderID
    , RecipientID
    , RecipientPhone
    , RecipientRef
    , Timestamp
    , MID
    , Sequence
    , Url
    , Msg
    , QuickReply        (..)
    ) where

import Data.Text

import Web.Facebook.Messenger.Types.Callbacks
import Web.Facebook.Messenger.Types.Requests
import Web.Facebook.Messenger.Types.Responses
import Web.Facebook.Messenger.Types.Static

type SenderID       = Text
type RecipientID    = Text
type RecipientPhone = Text
type RecipientRef   = Text
type MID            = Text
type Url            = Text
type Msg            = Text

type Timestamp      = Integer
type Sequence       = Integer
type StickerID      = Integer

data QuickReply = QR Text Text (Maybe Text)
                | LocQR (Maybe Text)
  deriving (Eq, Show)

data CallbackHandlers a = CallbackHandlers
  { messageHandler        :: SenderID -> RecipientID ->       Timestamp -> MID -> Msg -> Maybe CallbackQuickReply     -> Maybe Sequence -> a
  , attachmentHandler     :: SenderID -> RecipientID ->       Timestamp -> MID -> [CallbackAttachment]                -> Maybe Sequence -> a
  , stickerHandler        :: SenderID -> RecipientID ->       Timestamp -> MID -> [CallbackAttachment] -> StickerID   -> Maybe Sequence -> a
  , locationHandler       :: SenderID -> RecipientID ->       Timestamp -> MID -> [CallbackLocation]                  -> Maybe Sequence -> a
  , postbackHandler       :: SenderID -> RecipientID ->       Timestamp -> Postback       -> a
  , optinHandler          :: SenderID -> RecipientID ->       Timestamp -> Text           -> a
  , optinRefHandler       ::             RecipientID ->       Timestamp -> Text ->   Text -> a
  , referralHandler       :: SenderID -> RecipientID ->       Timestamp -> Referral       -> a
  , deliveryHandler       :: SenderID -> RecipientID -> Maybe Timestamp -> Delivery       -> a
  , accountLinkHandler    :: SenderID -> RecipientID ->       Timestamp -> AccountLink    -> a
  , readHandler           :: SenderID -> RecipientID ->       Timestamp -> ReadCallback   -> a
  , echoHandler           :: SenderID -> RecipientID ->       Timestamp -> Echo           -> a
  , paymentHandler        :: SenderID -> RecipientID ->       Timestamp -> Payment        -> a
  , checkoutUpdateHandler :: SenderID -> RecipientID ->       Timestamp -> CheckoutUpdate -> a
  }
