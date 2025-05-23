module Arkham.Asset.Assets.ArchiveOfConduitsGatewayToTindalos4 (
  archiveOfConduitsGatewayToTindalos4,
  ArchiveOfConduitsGatewayToTindalos4 (..),
)
where

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Import.Lifted
import Arkham.Asset.Uses
import Arkham.DamageEffect
import Arkham.Matcher
import Arkham.Message qualified as Msg
import Arkham.Movement
import Arkham.Token qualified as Token

newtype ArchiveOfConduitsGatewayToTindalos4 = ArchiveOfConduitsGatewayToTindalos4 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

archiveOfConduitsGatewayToTindalos4 :: AssetCard ArchiveOfConduitsGatewayToTindalos4
archiveOfConduitsGatewayToTindalos4 = asset ArchiveOfConduitsGatewayToTindalos4 Cards.archiveOfConduitsGatewayToTindalos4

instance HasAbilities ArchiveOfConduitsGatewayToTindalos4 where
  getAbilities (ArchiveOfConduitsGatewayToTindalos4 attrs) =
    [ controlledAbility attrs 1 (exists NonEliteEnemy <> exists (be attrs <> AssetWithUses Leyline))
        $ FastAbility Free
    , controlledAbility
        attrs
        2
        ( exists $ LocationWithEnemy (EnemyWithToken Token.Leyline) <> CanEnterLocation (affectsOthers Anyone)
        )
        actionAbility
    ]

instance RunMessage ArchiveOfConduitsGatewayToTindalos4 where
  runMessage msg a@(ArchiveOfConduitsGatewayToTindalos4 attrs) = runQueueT $ case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      enemies <- select NonEliteEnemy
      chooseOne
        iid
        [ targetLabel enemy [MoveTokens (attrs.ability 1) (toSource attrs) (toTarget enemy) Leyline 1]
        | enemy <- enemies
        ]
      pure a
    UseThisAbility iid (isSource attrs -> True) 2 -> do
      iids <-
        select
          $ affectsOthers
          $ InvestigatorCanMoveTo (attrs.ability 2) (LocationWithEnemy $ EnemyWithToken Token.Leyline)
      chooseOrRunOne
        iid
        [targetLabel iid' [HandleTargetChoice iid (attrs.ability 2) (toTarget iid')] | iid' <- iids]
      pure a
    HandleTargetChoice iid (isAbilitySource attrs 2 -> True) (InvestigatorTarget iid') -> do
      locations <-
        select
          $ LocationWithEnemy (EnemyWithToken Token.Leyline)
          <> CanEnterLocation (InvestigatorWithId iid')
      player <- getPlayer iid
      choices <- concatForM locations \location -> do
        enemies <- select $ enemyAt location <> EnemyWithToken Token.Leyline
        pure
          [ targetLabel
            enemy
            [ toMessage $ move (attrs.ability 2) iid' location
            , Msg.chooseOne
                player
                [ Label "Do not remove Leyline" []
                , Label
                    "Remove Leyline"
                    [ RemoveTokens (attrs.ability 2) (toTarget enemy) Token.Leyline 1
                    , EnemyDamage enemy $ nonAttack (Just iid) (attrs.ability 2) 1
                    ]
                ]
            ]
          | enemy <- enemies
          ]

      chooseOrRunOne iid choices
      pure a
    _ -> ArchiveOfConduitsGatewayToTindalos4 <$> liftRunMessage msg attrs
