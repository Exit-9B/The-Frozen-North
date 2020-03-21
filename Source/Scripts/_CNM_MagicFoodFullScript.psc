Scriptname _CNM_MagicFoodFullScript extends ActiveMagicEffect

Actor Property PlayerRef  Auto
_CNM_PlayerHungerScript Property HungerScript  Auto

event OnEffectStart(Actor akTarget, Actor akCaster)
	if akTarget == PlayerRef
		HungerScript.SetToFull()
	endIf
endEvent
