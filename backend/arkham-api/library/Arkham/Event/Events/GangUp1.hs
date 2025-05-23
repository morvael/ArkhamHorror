module Arkham.Event.Events.GangUp1 (gangUp1, GangUp1 (..)) where

import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Import.Lifted
import Arkham.Matcher
import Arkham.Modifier

newtype GangUp1 = GangUp1 EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

gangUp1 :: EventCard GangUp1
gangUp1 = event GangUp1 Cards.gangUp1

instance RunMessage GangUp1 where
  runMessage msg e@(GangUp1 attrs) = runQueueT $ case msg of
    PlayThisEvent iid eid | eid == toId attrs -> do
      sid <- getRandom
      skillTestModifier sid attrs iid
        $ ForEach
          (DifferentClassAmong (InvestigatorWithId iid) $ ControlledBy (InvestigatorWithId iid))
          [SkillModifier #combat 1, DamageDealt 1]
      chooseFightEnemy sid iid attrs
      pure e
    _ -> GangUp1 <$> liftRunMessage msg attrs
