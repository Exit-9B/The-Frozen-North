Scriptname _CNM_MagicNotifyScript extends ActiveMagicEffect

Actor Property PlayerRef  Auto
Message Property NotifyMsg  Auto

event OnEffectStart(Actor akTarget, Actor akCaster)
	if akTarget == PlayerRef
		NotifyMsg.Show()
	endIf
endEvent
