module Arkham.Investigator.Cards.DaisyWalkerParallel (daisyWalkerParallel) where

import Arkham.Ability
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Helpers.Ability
import Arkham.Helpers.Modifiers
import Arkham.Investigator.Cards qualified as Cards
import Arkham.Investigator.Import.Lifted
import Arkham.Matcher
import Arkham.Message.Lifted.Choose
import Arkham.Strategy

newtype DaisyWalkerParallel = DaisyWalkerParallel InvestigatorAttrs
  deriving anyclass IsInvestigator
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)
  deriving stock Data

daisyWalkerParallel :: InvestigatorCard DaisyWalkerParallel
daisyWalkerParallel =
  investigator DaisyWalkerParallel Cards.daisyWalkerParallel
    $ Stats {health = 5, sanity = 7, willpower = 1, intellect = 5, combat = 2, agility = 2}

instance HasModifiersFor DaisyWalkerParallel where
  getModifiersFor (DaisyWalkerParallel a) = do
    tomeCount <- selectCount $ assetControlledBy a.id <> #tome
    modifySelf a
      $ guard (tomeCount > 0)
      *> [SkillModifier #willpower tomeCount, SanityModifier tomeCount]

instance HasChaosTokenValue DaisyWalkerParallel where
  getChaosTokenValue iid ElderSign (DaisyWalkerParallel attrs) | attrs `is` iid = do
    pure $ ChaosTokenValue ElderSign (PositiveModifier 1)
  getChaosTokenValue _ token _ = pure $ ChaosTokenValue token mempty

instance HasAbilities DaisyWalkerParallel where
  getAbilities (DaisyWalkerParallel attrs) =
    [ playerLimit PerGame
        $ restrictedAbility attrs 1 (Self <> exists (AssetControlledBy You <> #tome))
        $ FastAbility Free
    ]

instance RunMessage DaisyWalkerParallel where
  runMessage msg i@(DaisyWalkerParallel attrs) = runQueueT $ case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      tomeAssets <- select $ assetControlledBy iid <> #tome
      forTargets tomeAssets msg
      pure i
    ForTargets [] (UseThisAbility _iid (isSource attrs -> True) 1) -> pure i
    ForTargets ts msg'@(UseCardAbility iid (isSource attrs -> True) 1 windows' _) -> do
      allAbilities <- getAllAbilities
      let nullifyActionCost = (`applyAbilityModifiers` [ActionCostSetToModifier 0])
      let abilitiesForAsset aid = map nullifyActionCost $ filter (isSource aid . abilitySource) allAbilities
      let tomeAssets = mapMaybe (preview _AssetTarget) ts

      canTrigger <-
        filter (notNull . snd)
          <$> traverse
            (traverseToSnd (filterM (getCanPerformAbility iid windows') . abilitiesForAsset))
            tomeAssets

      unless (null canTrigger) do
        let toLabel a = AbilityLabel iid a windows' [] []
        chooseOneM iid do
          for_ (eachWithRest canTrigger) \((tome, actions), rest) -> do
            targeting tome do
              chooseOne iid $ map toLabel actions
              forTargets (map fst rest) msg'
      pure i
    ElderSignEffect iid | attrs `is` iid -> do
      chooseOneM iid do
        targeting iid $ search iid attrs attrs [fromDiscard] (basic $ #asset <> #tome) $ DrawFound iid 1
        labeled "Do not use Daisy's ability" nothing
      pure i
    _ -> DaisyWalkerParallel <$> liftRunMessage msg attrs
