Scriptname _CNM_PlayerHungerScript extends ReferenceAlias

Actor Property PlayerRef  Auto

Spell Property AbilityWellFed  Auto

GlobalVariable Property VerboseFeedback  Auto
Message Property HungryMsg  Auto
Message Property SatedMsg  Auto

string Property FoodAV  Auto
{Actor value tracking food}
float Property SatedThreshold  Auto
{Threshold to get buff}
float Property HungerTimer  Auto
{Time in hours to gain 1 point of hunger}

float lastUpdate
float lastValue

event OnInit()
	PlayerRef.SetAV(FoodAV, SatedThreshold)
	if (PlayerRef.GetAV(FoodAV) > 0.0)
		PlayerRef.DamageAV(FoodAV, PlayerRef.GetAV(FoodAV))
	endIf
	
	lastValue = PlayerRef.GetAV(FoodAV)
endEvent

event OnUpdateGameTime()
	float now = Utility.GetCurrentGameTime()
	float mag = (now - lastUpdate) * 24.0 / HungerTimer
	PlayerRef.DamageAV(FoodAV, mag)
	
	lastUpdate = now
	
	if (PlayerRef.GetAV(FoodAV) > 0.0)
		float nextUpdateHours = (Math.Ceiling(mag) - mag) * HungerTimer
		if (nextUpdateHours == 0)
			nextUpdateHours = HungerTimer
		endIf
	
		RegisterForSingleUpdateGameTime(nextUpdateHours)
	else
		; Clamp to 0
		if (PlayerRef.GetAV(FoodAV) < 0.0)
			PlayerRef.RestoreAV(FoodAV, -1.0 * PlayerRef.GetAV(FoodAV))
		endIf
		
		PlayerRef.RemoveSpell(AbilityWellFed)
		
		if (VerboseFeedback.GetValueInt())
			HungryMsg.Show()
		endIf
	endIf
	
	lastValue = PlayerRef.GetAV(FoodAV)
endEvent

event OnVampireFeed(Actor akTarget)
	SetToFull()
endEvent

function SetToHungry()
	if (PlayerRef.GetAV(FoodAV) > 0.0)
		UnregisterForUpdateGameTime()
		PlayerRef.DamageAV(FoodAV, PlayerRef.GetAV(FoodAV))
		
		PlayerRef.RemoveSpell(AbilityWellFed)
	endIf
endFunction

function SetToFull()
	PlayerRef.RestoreAV(FoodAV, SatedThreshold)
	AteFood()
endFunction

function AteFood()
	float currentAmount = PlayerRef.GetAV(FoodAV)
	
	if (currentAmount > SatedThreshold)
		; Something went wrong, try to correct
		PlayerRef.SetAV(FoodAV, SatedThreshold)
		currentAmount = SatedThreshold
	endIf
	
	if (lastValue == 0.0 || currentAmount == SatedThreshold)
		; Started eating -> Start update timer
		lastUpdate = Utility.GetCurrentGameTime()
		RegisterForSingleUpdateGameTime(HungerTimer)
	endIf
	
	if (currentAmount == SatedThreshold)
		; Reached threshold -> Add buff and give feedback
		if (!PlayerRef.HasSpell(AbilityWellFed))
			PlayerRef.AddSpell(AbilityWellFed, false)
		endIf
		
		if (lastValue < SatedThreshold && VerboseFeedback.GetValueInt())
			SatedMsg.Show()
		endIf
	endIf
	
	lastValue = PlayerRef.GetAV(FoodAV)
endFunction

