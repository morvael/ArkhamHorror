module Arkham.Asset.Assets.DrWilliamTMaleson2 (drWilliamTMaleson2) where

import Arkham.Ability
import Arkham.Message.Lifted.Choose
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Import.Lifted
import Arkham.Card
import Arkham.Deck qualified as Deck
import Arkham.Draw.Types
import Arkham.Helpers.Window (cardDrawnBy)
import Arkham.Matcher

newtype Meta = Meta {drawnCard :: Maybe EncounterCard}
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)

newtype DrWilliamTMaleson2 = DrWilliamTMaleson2 (AssetAttrs `With` Meta)
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

drWilliamTMaleson2 :: AssetCard DrWilliamTMaleson2
drWilliamTMaleson2 = ally (DrWilliamTMaleson2 . (`with` Meta Nothing)) Cards.drWilliamTMaleson2 (2, 2)

instance HasAbilities DrWilliamTMaleson2 where
  getAbilities (DrWilliamTMaleson2 (With attrs _)) =
    [ restricted attrs 1 ControlsThis
        $ ReactionAbility
          (DrawCard #when (affectsOthers Anyone) (basic IsEncounterCard) EncounterDeck)
          (exhaust attrs <> PlaceClueOnLocationCost 1)
    ]

instance RunMessage DrWilliamTMaleson2 where
  runMessage msg a@(DrWilliamTMaleson2 (With attrs meta)) = runQueueT $ case msg of
    UseCardAbility _iid (isSource attrs -> True) 1 (cardDrawnBy -> (iid, EncounterCard card)) _ -> do
      quietCancelCardDraw (EncounterCard card)
      push $ DrawCards iid $ setTarget attrs $ newCardDraw (attrs.ability 1) Deck.EncounterDeck 1
      pure . DrWilliamTMaleson2 $ attrs `with` Meta (Just card)
    DrewCards iid drewCards | maybe False (isTarget attrs) drewCards.target -> do
      case (drawnCard meta, drewCards.cards) of
        (Just e1, [c2@(EncounterCard e2)]) -> focusCards [EncounterCard e1, c2] do
          chooseOneM iid do
            questionLabeled "Choose card to resolve"
            targeting e1 do
              unfocusCards
              push $ AddToEncounterDiscard e2
              drawCard iid e1
            targeting c2 do
              unfocusCards
              push $ AddToEncounterDiscard e1
              drawCard iid e2
        _ -> error "Unhandled william t maleson"
      cancelledOrIgnoredCardOrGameEffect $ attrs.ability 1
      pure a
    _ -> DrWilliamTMaleson2 . (`with` meta) <$> liftRunMessage msg attrs
