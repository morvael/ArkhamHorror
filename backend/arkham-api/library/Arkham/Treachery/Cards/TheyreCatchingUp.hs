module Arkham.Treachery.Cards.TheyreCatchingUp (theyreCatchingUp) where

import Arkham.Card
import Arkham.Deck qualified as Deck
import Arkham.Matcher
import Arkham.Name
import Arkham.Trait (Trait (Vehicle))
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Import.Lifted

newtype TheyreCatchingUp = TheyreCatchingUp TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theyreCatchingUp :: TreacheryCard TheyreCatchingUp
theyreCatchingUp = treachery TheyreCatchingUp Cards.theyreCatchingUp

instance RunMessage TheyreCatchingUp where
  runMessage msg t@(TheyreCatchingUp attrs) = runQueueT $ case msg of
    Revelation _iid (isSource attrs -> True) -> do
      push HuntersMove
      doStep 1 msg
      pure t
    EnemyMove {} -> do
      pure . TheyreCatchingUp $ setMeta True attrs
    DoStep 1 (Revelation iid (isSource attrs -> True)) -> do
      unless (toResultDefault False attrs.meta) do
        discardUntilFirst iid attrs Deck.EncounterDeck (basic $ #enemy <> withTrait Vehicle)
      pure t
    RequestedEncounterCard (isSource attrs -> True) _ (Just card) -> do
      sendEnemy ("They're Catching Up finds " <> toTitle card.name) (toJSON $ toCard card)
      createEnemyAtLocationMatching_ card RearmostLocation
      pure t
    _ -> TheyreCatchingUp <$> liftRunMessage msg attrs
