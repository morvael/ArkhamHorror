module Arkham.Location.Cards.TheGeistTrap (
  theGeistTrap,
  TheGeistTrap (..),
)
where

import Arkham.Prelude

import Arkham.Action qualified as Action
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.GameValue
import Arkham.Helpers.Modifiers
import Arkham.Keyword qualified as Keyword
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Scenarios.UnionAndDisillusion.Helpers

newtype TheGeistTrap = TheGeistTrap LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theGeistTrap :: LocationCard TheGeistTrap
theGeistTrap = location TheGeistTrap Cards.theGeistTrap 4 (PerPlayer 1)

instance HasModifiersFor TheGeistTrap where
  getModifiersFor target (TheGeistTrap attrs)
    | attrs `isTarget` target
    , not (locationRevealed attrs) = do
        toModifiers attrs [Blocked]
  getModifiersFor (EnemyTarget eid) (TheGeistTrap attrs) | locationRevealed attrs = do
    gainsRetaliate <-
      selectAny (EnemyWithId eid <> enemyIs Enemies.theSpectralWatcher <> enemyAt (toId attrs))
    toModifiers attrs [AddKeyword Keyword.Retaliate | gainsRetaliate]
  getModifiersFor _ _ = pure []

instance HasAbilities TheGeistTrap where
  getAbilities (TheGeistTrap attrs) =
    withRevealedAbilities
      attrs
      [ restrictedAbility attrs 1 Here $ ActionAbility ([Action.Circle]) $ ActionCost 1
      , haunted "Take 1 damage and 1 horror" attrs 2
      ]

instance RunMessage TheGeistTrap where
  runMessage msg l@(TheGeistTrap attrs) = case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      sid <- getRandom
      circleTest sid iid (attrs.ability 1) attrs [#willpower, #intellect, #combat, #agility] (Fixed 20)
      pure l
    UseThisAbility iid (isSource attrs -> True) 2 -> do
      push $ InvestigatorAssignDamage iid (toSource attrs) DamageAny 1 1
      pure l
    PassedThisSkillTest iid (isSource attrs -> True) -> do
      passedCircleTest iid attrs
      pure l
    _ -> TheGeistTrap <$> runMessage msg attrs
