module Arkham.Asset.Assets.ArcaneInsight4 (arcaneInsight4) where

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Helpers.Modifiers
import Arkham.Investigator.Types (Field (..))
import Arkham.Matcher hiding (DuringTurn)
import Arkham.Prelude
import Arkham.Projection

newtype ArcaneInsight4 = ArcaneInsight4 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

arcaneInsight4 :: AssetCard ArcaneInsight4
arcaneInsight4 = asset ArcaneInsight4 Cards.arcaneInsight4

instance HasAbilities ArcaneInsight4 where
  getAbilities (ArcaneInsight4 a) =
    [ limited (PlayerLimit PerTurn 1)
        $ controlled a 1 (DuringTurn Anyone)
        $ FastAbility
        $ assetUseCost a Charge 1
    ]

instance RunMessage ArcaneInsight4 where
  runMessage msg a@(ArcaneInsight4 attrs) = case msg of
    UseCardAbility iid (isSource attrs -> True) 1 _ _ -> do
      mlid <- field InvestigatorLocation iid
      for_ mlid $ \lid -> do
        iid' <- selectJust TurnInvestigator
        ems <- effectModifiers attrs [ShroudModifier (-2)]
        push $ CreateWindowModifierEffect (EffectTurnWindow iid') ems (toSource attrs) (LocationTarget lid)
      pure a
    _ -> ArcaneInsight4 <$> runMessage msg attrs
