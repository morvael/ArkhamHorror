module Arkham.Asset.Assets.BountyContracts (bountyContracts) where

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner hiding (EnemyDefeated)
import Arkham.Enemy.Types (Field (EnemyTokens, EnemyHealth))
import Arkham.Helpers.Window (getEnemy)
import Arkham.Matcher
import Arkham.Prelude
import Arkham.Projection
import Arkham.Token qualified as Token

newtype BountyContracts = BountyContracts AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

bountyContracts :: AssetCard BountyContracts
bountyContracts = asset BountyContracts Cards.bountyContracts

instance HasAbilities BountyContracts where
  getAbilities (BountyContracts a) =
    [ restricted a 1 (available <> ControlsThis)
        $ freeReaction
        $ EnemyEntersPlay #after EnemyWithHealth
    , restricted a 2 ControlsThis $ forced $ EnemyDefeated #after You ByAny EnemyWithBounty
    ]
   where
    available = if hasUses a then mempty else Never

instance RunMessage BountyContracts where
  runMessage msg a@(BountyContracts attrs) = case msg of
    UseCardAbility iid (isSource attrs -> True) 1 (getEnemy -> enemy) _ -> do
      player <- getPlayer iid
      health <- fieldJust EnemyHealth enemy
      let maxAmount = min health (min 3 (findWithDefault 0 Bounty $ assetUses attrs))
      pushM
        $ chooseAmounts
          player
          "Number of bounties to place"
          (MaxAmountTarget maxAmount)
          [("Bounties", (1, maxAmount))]
          (ProxyTarget (toTarget attrs) (toTarget enemy))
      pure a
    ResolveAmounts _ choices (ProxyTarget (isTarget attrs -> True) (EnemyTarget enemy)) -> do
      let bounties = getChoiceAmount "Bounties" choices
      pushAll
        [ SpendUses (attrs.ability 1) (toTarget attrs) Bounty bounties
        , PlaceTokens (attrs.ability 1) (toTarget enemy) Token.Bounty bounties
        ]
      pure a
    UseCardAbility iid (isSource attrs -> True) 2 (getEnemy -> enemy) _ -> do
      bounties <- fieldMap EnemyTokens (Token.countTokens Token.Bounty) enemy
      push $ TakeResources iid bounties (toAbilitySource attrs 2) False
      pure a
    _ -> BountyContracts <$> runMessage msg attrs
