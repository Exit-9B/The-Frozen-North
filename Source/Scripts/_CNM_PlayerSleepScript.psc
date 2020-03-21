Scriptname _CNM_PlayerSleepScript extends ReferenceAlias

Spell Property FoodAbilityWellFed  Auto
Spell Property FoodAbilityBuzzed  Auto

Spell Property SleepAbilityFoodBonus  Auto
Spell Property SleepAbilityDrinkBonus  Auto

GlobalVariable Property MinSleepTime  Auto

_CNM_PlayerHungerScript Property HungerScript  Auto

bool foodBonus = false
bool drinkBonus = false

event OnInit()
	RegisterForSleep()
endEvent

event OnSleepStart(float afSleepStartTime, float afDesiredSleepEndTime)
	foodBonus = false
	drinkBonus = false
	
	Actor PlayerRef = GetActorRef()
	if (afDesiredSleepEndTime - afSleepStartTime >= MinSleepTime.GetValue())
		foodBonus = PlayerRef.HasSpell(FoodAbilityWellFed)
		drinkBonus = PlayerRef.HasSpell(FoodAbilityBuzzed)
	endIf
endEvent

event OnSleepStop(bool abInterrupted)
	if (abInterrupted)
		return
	endIf
	
	Actor PlayerRef = GetActorRef()
	
	if (foodBonus)
		HungerScript.SetToHungry()
		PlayerRef.AddSpell(SleepAbilityFoodBonus, false)
	endIf
	
	if (drinkBonus)
		PlayerRef.AddSpell(SleepAbilityDrinkBonus, false)
	endIf
endEvent

