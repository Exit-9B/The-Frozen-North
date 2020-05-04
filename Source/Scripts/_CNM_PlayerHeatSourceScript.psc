Scriptname _CNM_PlayerHeatSourceScript extends ReferenceAlias

int myVersion = 100
int Property Version = 160  AutoReadOnly

Actor Property PlayerRef  Auto

GlobalVariable Property Enabled  Auto
GlobalVariable Property PollingInterval  Auto
GlobalVariable Property HeatSourceRadius  Auto
{The number of units in which a standard heat source radiates warmth}
GlobalVariable Property HeatSourceRadiusSmall  Auto
{The number of units in which a smaller heat source radiates warmth}

FormList Property StandardHeatSources  Auto
{Objects which radiate heat}
FormList Property SmallHeatSources  Auto
{Objects which less radiate heat}

_CNM_PlayerColdScript Property ColdScript  Auto

string Property EnterWaterEvent = "SoundPlay.FSTSwimSwim"  AutoReadOnly
string Property ExitWaterEvent = "MTState"  AutoReadOnly

float Property HeatDefault =         0.0  AutoReadOnly
float Property HeatSwimming =       -1.0  AutoReadOnly
float Property HeatNearHeatSource =  3.0  AutoReadOnly

bool isSwimming = false

float Property CurrentHeatSourceWarmth
	float function Get()
		return ColdScript.CurrentHeatSourceWarmth
	endFunction
	
	function Set(float afValue)
		ColdScript.CurrentHeatSourceWarmth = afValue
	endFunction
endProperty

event OnInit()
	InitializeCompatibility()
	RegisterForSingleUpdate(PollingInterval.GetValue())
	RegisterForAnimationEvent(PlayerRef, EnterWaterEvent)
	
	myVersion = Version
endEvent

event OnPlayerLoadGame()
	EnsureLatestVersion()
	InitializeCompatibility()
	
	if !isSwimming
		RegisterForAnimationEvent(PlayerRef, EnterWaterEvent)
	else
		RegisterForAnimationEvent(PlayerRef, ExitWaterEvent)
	endIf

	RegisterForSingleUpdate(1.0)
endEvent

event OnUpdate()
	Update()
	RegisterForSingleUpdate(PollingInterval.GetValue())
endEvent

event OnAnimationEvent(ObjectReference akSource, string asEventName)
	if (akSource != PlayerRef)
		return
	endIf
	
	if (!isSwimming && asEventName == EnterWaterEvent)
		;Debug.Notification("Started swimming")
		isSwimming = true
		UnregisterForAnimationEvent(PlayerRef, EnterWaterEvent)
		RegisterForAnimationEvent(PlayerRef, ExitWaterEvent)
	elseIf (isSwimming && asEventName == ExitWaterEvent)
		;Debug.Notification("Stopped swimming")
		isSwimming = false
		UnregisterForAnimationEvent(PlayerRef, ExitWaterEvent)
		RegisterForAnimationEvent(PlayerRef, EnterWaterEvent)
	endIf
endEvent

function EnsureLatestVersion()
	if (myVersion < 150)
		HeatSourceRadius.SetValue(500 as float)
	endIf
	
	myVersion = Version
endFunction

function Update()
	if (!Enabled.GetValueInt() || !Game.IsMenuControlsEnabled())
		return
	endIf
	
	float fHeatSourceWarmth = FindHeatSources()
	if (fHeatSourceWarmth != CurrentHeatSourceWarmth)
		CurrentHeatSourceWarmth = fHeatSourceWarmth
		ColdScript.QuickUpdate()
	endIf
endFunction

float function FindHeatSources()
	float fHeat = HeatDefault
	
	if (isSwimming)
		fHeat += HeatSwimming
	endIf
	
	ObjectReference kHeatSource = Game.FindClosestReferenceOfAnyTypeInListFromRef(\
			SmallHeatSources, PlayerRef, HeatSourceRadiusSmall.GetValue())
	if (kHeatSource == none)
		kHeatSource = Game.FindClosestReferenceOfAnyTypeInListFromRef(\
				StandardHeatSources, PlayerRef, HeatSourceRadius.GetValue())
	endIf
	
	if (kHeatSource != none)
		fHeat += HeatNearHeatSource
	endIf
	
	return fHeat
endFunction

function InitializeCompatibility()
{Check for and apply compatibility patches for third party mods}
	StandardHeatSources.Revert()
	
	if (Game.GetModByName("Campfire.esm") != 255)
		StandardHeatSources.AddForm(Game.GetFormFromFile(0x00040013, "Campfire.esm") as Activator)
		StandardHeatSources.AddForm(Game.GetFormFromFile(0x000328b9, "Campfire.esm") as Activator)
		StandardHeatSources.AddForm(Game.GetFormFromFile(0x00033e67, "Campfire.esm") as Activator)
		StandardHeatSources.AddForm(Game.GetFormFromFile(0x00033e69, "Campfire.esm") as Activator)
		
		if (Game.GetModByName("CampfireCabin.esp") != 255)
			; let stove have a large radius to heat up the rest of the cabin
			StandardHeatSources.AddForm(Game.GetFormFromFile(0x00005E81, "CampfireCabin.esp") as Activator)
		endIf
	endIf
	
	if (Game.GetModByName("Campsite.esp") != 255)
		StandardHeatSources.AddForm(Game.GetFormFromFile(0x00005902, "Campsite.esp") as Activator)
	endIf
	
endFunction

