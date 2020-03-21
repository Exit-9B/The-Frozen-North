Scriptname _CNM_PlayerColdScript extends ReferenceAlias

int myVersion = 100
int Property Version = 152  AutoReadOnly

Actor Property PlayerRef  Auto

Keyword Property ActorTypeUndead  Auto
Keyword Property MagicFlameCloak  Auto
Keyword Property Survival_ArmorCold  Auto
Keyword Property Survival_ArmorWarm  Auto

GlobalVariable Property Enabled  Auto
{True if temperature is checked, false otherwise}
GlobalVariable Property PollingInterval  Auto
{The number of real-time seconds temperature is checked}
GlobalVariable Property Sunrise  Auto
{The time of day when the sun begins radiating additional warmth}
GlobalVariable Property Sunset  Auto
{The time of day when the sun stops radiating additional warmth}
GlobalVariable Property TemperatureLevel Auto
{Controls temperature UI}
GlobalVariable Property ClothingWarmthScale Auto
{Amount of warmth per point of warmth rating}
GlobalVariable Property FrostResistScale Auto
{Amount of warmth per point of frost resist}
GlobalVariable Property VisualFeedback  Auto
{Visual effects for player temperature}
GlobalVariable Property VerboseFeedback  Auto
{Notifications for player temperature}
GlobalVariable Property LowBodyTempThreshold  Auto
{Threshold at which body temp penalty and fast travel restriction may apply}

FormList Property InteriorColdZones  Auto
{Interior areas with a location that present as cold (deprecated)}
FormList Property InteriorColdCells  Auto
{Non-location interior areas that present as cold (deprecated)}
FormList Property ColdStatics  Auto
{Statics that indicate an area being cold}
FormList Property BeastRaces  Auto
{Beast forms that the player might transform into}

Spell Property DebuffAbilityChilly  Auto
Spell Property DebuffAbilityCold  Auto
Spell Property DebuffAbilityFreezing  Auto
Spell Property DebuffAbilityLowBodyTemp  Auto
Spell Property BuffAbilityWarm  Auto

ImageSpaceModifier Property IMODChilly  Auto
ImageSpaceModifier Property IMODCold  Auto
ImageSpaceModifier Property IMODFreezing  Auto

Message Property ChillyMsg  Auto
Message Property ColdMsg  Auto
Message Property FreezingMsg  Auto
Message Property WarmMsg  Auto

int Property TEMP_WARM = 2  AutoReadOnly
int Property TEMP_COMFORTABLE = 1  AutoReadOnly
int Property TEMP_NONE = 0  AutoReadOnly
int Property TEMP_COOL = -1  AutoReadOnly
int Property TEMP_COLD = -2  AutoReadOnly
int Property TEMP_FREEZING = -3  AutoReadOnly

int Property WeatherNone = -1  AutoReadOnly
int Property WeatherPleasant = 0  AutoReadOnly
int Property WeatherCloudy = 1  AutoReadOnly
int Property WeatherRainy = 2  AutoReadOnly
int Property WeatherSnow = 3  AutoReadOnly

Int Property TemperatureLevelNeutral = 0  AutoReadOnly
Int Property TemperatureLevelNearHeat = 1  AutoReadOnly
Int Property TemperatureLevelWarmArea = 2  AutoReadOnly
Int Property TemperatureLevelColdArea = 3  AutoReadOnly
Int Property TemperatureLevelFreezingArea = 4  AutoReadOnly

int Property CurrentEnvironmentTemp = 0  Auto
float Property CurrentClothingWarmth = 0.0  Auto
float Property CurrentHeatSourceWarmth = 0.0  Auto
float Property CurrentFrostResist = 0.0  Auto
bool Property HasFlameCloak = false  Auto

int previousTemp = 0
int currentTemp = 0

_CNM_PlayerHeatSourceScript Property HeatSourceScript  Auto

event OnInit()
{Ensure everything is sorted when starting for the first time}
	RegisterForSingleUpdateGameTime(PollingInterval.GetValue())
	
	myVersion = Version
endEvent

event OnPlayerLoadGame()
	EnsureLatestVersion()
endEvent

event OnUpdateGameTime()
{Run polling interval updates}
	Update()
	RegisterForSingleUpdateGameTime(PollingInterval.GetValue())
endEvent

event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
{Handle item usage and consumption}
	if (akBaseObject as Armor == None)
		return
	endIf
	
	float fWarmthRating = PlayerRef.GetWarmthRating()
	float fFrostResist = PlayerRef.GetActorValue("FrostResist")
	
	if (fWarmthRating == CurrentClothingWarmth && fFrostResist == CurrentFrostResist)
		return
	endIf
	
	QuickUpdate()
endEvent

event OnObjectUnequipped(Form akBaseObject, ObjectReference akReference)
{Handle removed enchantments}
	if (akBaseObject as Armor == None)
		return
	endIf

	float fWarmthRating = PlayerRef.GetWarmthRating()
	float fFrostResist = PlayerRef.GetActorValue("FrostResist")
	
	if (fWarmthRating == CurrentClothingWarmth && fFrostResist == CurrentFrostResist)
		return
	endIf
	
	QuickUpdate()
endEvent

event OnMagicEffectApply(ObjectReference akCaster, MagicEffect akEffect)
{Handle potions or other magic}
	float fFrostResist = PlayerRef.GetActorValue("FrostResist")
	bool bFlameCloak = PlayerRef.HasMagicEffectWithKeyword(MagicFlameCloak)
	
	if (fFrostResist == CurrentFrostResist && bFlameCloak == HasFlameCloak)
		return
	endIf
	
	QuickUpdate()
endEvent

event OnLocationChange(Location akOldLoc, Location akNewLoc)
{Handle location changes}
	int iEnvironmentTemp = GetEnvironmentTemperature()
	float fHeatSourceWarmth = HeatSourceScript.FindHeatSources()
	
	if (iEnvironmentTemp == CurrentEnvironmentTemp && fHeatSourceWarmth == CurrentHeatSourceWarmth)
		return
	endIf
	
	CurrentEnvironmentTemp = iEnvironmentTemp
	CurrentHeatSourceWarmth = fHeatSourceWarmth
	
	QuickUpdate()
endEvent

function EnsureLatestVersion()
	if (myVersion < 140)
		ClothingWarmthScale.SetValue(0.03125)
		FrostResistScale.SetValue(0.015625)
		QuickUpdate()
	endIf
	if (myVersion < 150)
		BuffAbilityWarm = Game.GetFormFromFile(0x832, "TheFrozenNorth.esp") as Spell
	endIf
	
	myVersion = Version
endFunction

function QuickUpdate()
{Update current temperature without checking environment}
	Update(true)
endFunction

function Update(bool abSkipEnvironment = false)
{Update current temperature}
	if (!Enabled.GetValueInt() || !Game.IsMenuControlsEnabled())
		Disable()
		return
	endIf
	
	if (!abSkipEnvironment)
		CurrentEnvironmentTemp = GetEnvironmentTemperature()
	endIf
	
	CurrentClothingWarmth = PlayerRef.GetWarmthRating()
	HasFlameCloak = PlayerRef.HasMagicEffectWithKeyword(MagicFlameCloak)
	CurrentFrostResist = PlayerRef.GetActorValue("FrostResist")
	
	int iNewTemp = Math.Floor(GetCurrentTemperature())
	UpdateTemperature(iNewTemp)
	UpdateTemperatureUI()
endFunction

function Disable()
{Disable cold survival}
	if (currentTemp < TEMP_NONE)
		ImageSpaceModifier.RemoveCrossFade(1.0)
		
		PlayerRef.RemoveSpell(DebuffAbilityLowBodyTemp)
		
		if (currentTemp == TEMP_WARM)
			PlayerRef.RemoveSpell(BuffAbilityWarm)
		elseIf (currentTemp == TEMP_COOL)
			PlayerRef.RemoveSpell(DebuffAbilityChilly)
		elseIf (currentTemp == TEMP_COLD)
			PlayerRef.RemoveSpell(DebuffAbilityCold)
		elseIf (currentTemp == TEMP_FREEZING)
			PlayerRef.RemoveSpell(DebuffAbilityFreezing)
		endIf
	endIf
	
	if (TemperatureLevel.GetValueInt() != 0)
		TemperatureLevel.SetValueInt(0)
	endIf
	
	previousTemp = TEMP_NONE
	currentTemp = TEMP_NONE
endFunction

int function GetEnvironmentTemperature()
{Get environment temperature based on weather and time of day}
	int iTemp = 0
	
	if (!PlayerRef.IsInInterior())
		Weather kCurrentWeather = Weather.GetCurrentWeather()
		int iWeatherClass = WeatherNone
	
		if (kCurrentWeather == none)
			iTemp = TEMP_COOL
		else
			iWeatherClass = kCurrentWeather.GetClassification()
			
			if (iWeatherClass == WeatherNone)
				iTemp = TEMP_NONE
			elseIf (iWeatherClass == WeatherPleasant)
				iTemp = TEMP_COMFORTABLE
			elseIf (iWeatherClass == WeatherCloudy)
				iTemp = TEMP_NONE
			elseIf (iWeatherClass == WeatherRainy)
				iTemp = TEMP_COLD
			elseIf (iWeatherClass == WeatherSnow)
				iTemp = TEMP_COLD
			endIf
		endIf
		
		float fHour = GetCurrentHourOfDay()
		bool bIsSunUp = fHour >= Sunrise.GetValue() && fHour <= Sunset.GetValue()
		
		if (!bIsSunUp)
			; Reduce warmth when the sun is below a viewing angle
			iTemp -= 1
		endIf
	endif
	
	if (Game.FindClosestReferenceOfAnyTypeInListFromRef(ColdStatics, PlayerRef, 2000) != None)
		iTemp -= 2
	endIf
	
	return iTemp
endFunction

float function GetCurrentTemperature()
{Get the current ambient temperature based on all tracked information}
	float fTemp = CurrentEnvironmentTemp + CurrentHeatSourceWarmth
	fTemp += CurrentClothingWarmth * ClothingWarmthScale.GetValue()
	
	if (fTemp < 0)
		fTemp += CurrentFrostResist * FrostResistScale.GetValue()
	endIf
	
	; Check for warming magic effects
	if (HasFlameCloak)
		fTemp = TEMP_WARM
	endIf
	
	if (fTemp > TEMP_WARM && CurrentHeatSourceWarmth <= 0)
		fTemp = TEMP_COMFORTABLE
	endIf
	
	; Undead do not feel cold or warmth
	if (PlayerRef.GetRace().HasKeyword(ActorTypeUndead))
		fTemp = TEMP_NONE
	endIf
	
	; Werebeasts are immune to the cold
	if (fTemp < TEMP_NONE && BeastRaces.HasForm(PlayerRef.GetRace()))
		fTemp = TEMP_NONE
	endIf
	
	; Clamp the final temperature
	if (fTemp < TEMP_FREEZING)
		fTemp = TEMP_FREEZING
	elseIf (fTemp > TEMP_WARM)
		fTemp = TEMP_WARM
	endIf
	
	if (fTemp < TEMP_COLD && !Game.IsFightingControlsEnabled())
		fTemp = TEMP_COLD
	endIf
	
	return fTemp
endFunction

float function GetCurrentHourOfDay()
{Identify the current 24 hour time of day}
	float fNow = Utility.GetCurrentGameTime()
	
	fNow -= Math.Floor(fNow)
	fNow *= 24
	
	return fNow
endFunction

function UpdateTemperature(int aiNewTemperature)
{Apply or remove buffs/debuffs according to body temp and settings}
	if (aiNewTemperature == currentTemp)
		previousTemp = currentTemp
		return
	endIf
	;Debug.Notification("Temperature: " + aiNewTemperature)
	
	Spell kPreviousAbility = GetTemperatureAbility(currentTemp)
	if kPreviousAbility
		PlayerRef.RemoveSpell(kPreviousAbility)
	endIf
	
	previousTemp = currentTemp
	currentTemp = aiNewTemperature
	
	Spell kNextAbility = GetTemperatureAbility(currentTemp)
	if kNextAbility
		PlayerRef.AddSpell(kNextAbility, false)
		if (currentTemp == TEMP_COOL)
			RunVerboseFeedback(ChillyMsg, IMODChilly)
		elseIf (currentTemp == TEMP_COLD)
			RunVerboseFeedback(ColdMsg, IMODCold)
		elseIf (currentTemp == TEMP_FREEZING)
			RunVerboseFeedback(FreezingMsg, IMODFreezing)
		endIf
	endIf
	
	int iTempThreshold = LowBodyTempThreshold.GetValueInt()
	if (previousTemp > iTempThreshold && currentTemp <= iTempThreshold)
		PlayerRef.AddSpell(DebuffAbilityLowBodyTemp, false)
	elseIf (previousTemp <= iTempThreshold && currentTemp > iTempThreshold)
		PlayerRef.RemoveSpell(DebuffAbilityLowBodyTemp)
	endIf

	if (previousTemp < TEMP_NONE && currentTemp >= TEMP_NONE)
		RunVerboseFeedback(WarmMsg)
	endIf
endFunction

function UpdateTemperatureUI()
	float fTemp = CurrentEnvironmentTemp + CurrentHeatSourceWarmth
	if (fTemp >= TEMP_WARM)
		TemperatureLevel.SetValueInt(TemperatureLevelNearHeat)
	elseIf (fTemp == TEMP_COMFORTABLE)
		TemperatureLevel.SetValueInt(TemperatureLevelWarmArea)
	elseIf (fTemp == TEMP_NONE)
		TemperatureLevel.SetValueInt(TemperatureLevelNeutral)
	elseIf (fTemp > TEMP_FREEZING)
		TemperatureLevel.SetValueInt(TemperatureLevelColdArea)
	elseIf (fTemp <= TEMP_FREEZING)
		TemperatureLevel.SetValueInt(TemperatureLevelFreezingArea)
	endIf
endFunction

Spell function GetTemperatureAbility(int aiTemp)
	if (aiTemp == TEMP_WARM)
		return BuffAbilityWarm
	elseIf (aiTemp == TEMP_COOL)
		return DebuffAbilityChilly
	elseIf (aiTemp == TEMP_COLD)
		return DebuffAbilityCold
	elseIf (aiTemp == TEMP_FREEZING)
		return DebuffAbilityFreezing
	endIf
	
	return None
endFunction

function RunVerboseFeedback(Message akMsg, ImageSpaceModifier akImodEffect = None)
{Apply verbose feedback effects}
	if (VisualFeedback.GetValueInt())
		if (akImodEffect)
			akImodEffect.ApplyCrossFade()
		else
			ImageSpaceModifier.RemoveCrossFade()
		endIf
	endIf
	
	if (VerboseFeedback.GetValueInt())
		akMsg.Show()
	endIf
endFunction

