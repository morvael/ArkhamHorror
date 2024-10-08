import { JsonDecoder } from 'ts.data.json';

export type ModifierType
  = ActionSkillModifier
  | AddKeyword
  | AddSkillValue
  | AnySkillValue
  | BaseSkill
  | BaseSkillOf
  | CannotEnter
  | DamageDealt
  | DiscoveredClues
  | GainVictory
  | OtherModifier
  | SkillModifier
  | UseEncounterDeck

export type BaseSkillOf = {
  tag: "BaseSkillOf"
  skillType: string
  value: number
}

export type BaseSkill = {
  tag: "BaseSkill"
  contents: number
}

export type DiscoveredClues = {
  tag: "DiscoveredClues"
  contents: number
}

export type DamageDealt = {
  tag: "DamageDealt"
  contents: number
}

export type AddSkillValue = {
  tag: "AddSkillValue"
  contents: string
}

export type ActionSkillModifier = {
  tag: "ActionSkillModifier"
  action: string
  skillType: string
  value: number
}

export type SkillModifier = {
  tag: "SkillModifier"
  skillType: string
  value: number
}

export type AnySkillValue = {
  tag: "AnySkillValue"
  contents: number
}

export type GainVictory = {
  tag: "GainVictory"
  contents: number
}

export type AddKeyword = {
  tag: "AddKeyword"
  contents: string
}

export type UseEncounterDeck = {
  tag: "UseEncounterDeck"
  contents: string
}

export type CannotEnter = {
  tag: "CannotEnter"
  contents: string
}

export type OtherModifier = {
  tag: "OtherModifier"
  contents: string
}


export type Modifier = {
  type: ModifierType;
}

const modifierTypeDecoder = JsonDecoder.oneOf<ModifierType>([
  JsonDecoder.object<BaseSkillOf>(
    {
      tag: JsonDecoder.isExactly('BaseSkillOf'),
      skillType: JsonDecoder.string,
      value: JsonDecoder.number
    }, 'BaseSkillOf'),
  JsonDecoder.object<BaseSkill>(
    {
      tag: JsonDecoder.isExactly('BaseSkill'),
      contents: JsonDecoder.number
    }, 'BaseSkill'),
  JsonDecoder.object<DiscoveredClues>(
    {
      tag: JsonDecoder.isExactly('DiscoveredClues'),
      contents: JsonDecoder.number
    }, 'DiscoveredClues'),
  JsonDecoder.object<DamageDealt>(
    {
      tag: JsonDecoder.isExactly('DamageDealt'),
      contents: JsonDecoder.number
    }, 'DamageDealt'),
  JsonDecoder.object<AddSkillValue>(
    {
      tag: JsonDecoder.isExactly('AddSkillValue'),
      contents: JsonDecoder.string
    }, 'AddSkillValue'),
  JsonDecoder.object<UseEncounterDeck>(
    {
      tag: JsonDecoder.isExactly('UseEncounterDeck'),
      contents: JsonDecoder.string
    }, 'UseEncounterDeck'),
  JsonDecoder.object<CannotEnter>(
    {
      tag: JsonDecoder.isExactly('CannotEnter'),
      contents: JsonDecoder.string
    }, 'UseEncounterDeck'),
  JsonDecoder.object<SkillModifier>(
    {
      tag: JsonDecoder.isExactly('SkillModifier'),
      skillType: JsonDecoder.string,
      value: JsonDecoder.number
    }, 'SkillModifier'),
  JsonDecoder.object<AnySkillValue>(
    {
      tag: JsonDecoder.isExactly('AnySkillValue'),
      contents: JsonDecoder.number
    }, 'AnySkillValue'),
  JsonDecoder.object<GainVictory>(
    {
      tag: JsonDecoder.isExactly('GainVictory'),
      contents: JsonDecoder.number
    }, 'GainVictory'),
  JsonDecoder.object<AddKeyword>(
    {
      tag: JsonDecoder.isExactly('AddKeyword'),
      contents: JsonDecoder.object({ tag: JsonDecoder.string }, "Keyword").map(s => s.tag)
    }, 'AddKeyword'),
  JsonDecoder.object<ActionSkillModifier>(
    {
      tag: JsonDecoder.isExactly('ActionSkillModifier'),
      action: JsonDecoder.string,
      skillType: JsonDecoder.string,
      value: JsonDecoder.number
    }, 'ActionSkillModifier'),
  JsonDecoder.object<OtherModifier>({
    tag: JsonDecoder.constant('OtherModifier'),
    contents: JsonDecoder.string
  }, 'OtherModifier', { contents: 'tag'}),
], 'ModifierType');

export const modifierDecoder = JsonDecoder.object<Modifier>({
  type: modifierTypeDecoder
}, 'Modifier')
