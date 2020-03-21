Scriptname _CNM_MagicAddAbilityScript extends ActiveMagicEffect

Spell Property AbilityToAdd  Auto
bool Property Verbose  Auto

event OnEffectStart(Actor akTarget, Actor akCaster)
	if akTarget.HasSpell(AbilityToAdd)
		akTarget.RemoveSpell(AbilityToAdd)
		akTarget.AddSpell(AbilityToAdd, false)
	else
		akTarget.AddSpell(AbilityToAdd, Verbose)
	endIf
endEvent
