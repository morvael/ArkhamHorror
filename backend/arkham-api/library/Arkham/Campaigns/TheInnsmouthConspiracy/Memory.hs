module Arkham.Campaigns.TheInnsmouthConspiracy.Memory where

import Arkham.Prelude

data Memory
  = AMeetingWithThomasDawson
  | ABattleWithAHorrifyingDevil
  | ADecisionToStickTogether
  | AnEncounterWithASecretCult
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)
