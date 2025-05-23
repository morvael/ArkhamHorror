module Arkham.Asset.Assets.WendysAmuletAdvanced (wendysAmuletAdvanced) where

import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Helpers.Modifiers
import Arkham.Matcher
import Arkham.Prelude

newtype WendysAmuletAdvanced = WendysAmuletAdvanced AssetAttrs
  deriving anyclass (IsAsset, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

wendysAmuletAdvanced :: AssetCard WendysAmuletAdvanced
wendysAmuletAdvanced = asset WendysAmuletAdvanced Cards.wendysAmuletAdvanced

instance HasModifiersFor WendysAmuletAdvanced where
  getModifiersFor (WendysAmuletAdvanced a) = for_ a.controller \iid -> do
    controllerGets a [CanPlayFromDiscard #event]
    modifySelect a (EventOwnedBy $ InvestigatorWithId iid) [PlaceOnBottomOfDeckInsteadOfDiscard]

instance RunMessage WendysAmuletAdvanced where
  runMessage msg (WendysAmuletAdvanced attrs) = WendysAmuletAdvanced <$> runMessage msg attrs
