#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
//#include <tf2_extras>
#include <tf2attributes>
#include <tf2items>
#tryinclude <freak_fortress_2>
//#include <sourcescramble>
#include <dhooks>

#pragma newdecls required

ConVar cvar_DMG_SCOUT;
ConVar cvar_DMG_SOLDIER;
ConVar cvar_DMG_PYRO;
ConVar cvar_DMG_DEMO;
ConVar cvar_DMG_HEAVY;
ConVar cvar_DMG_ENGINEER;
ConVar cvar_DMG_MEDIC;
ConVar cvar_DMG_SNIPER;
ConVar cvar_DMG_SPY;

ConVar cvar_Ability_OncePerRound;

//#define DMG_SCOUT    600
//#define DMG_SOLDIER  2000
//#define DMG_PYRO     2000
//#define DMG_DEMO     2000
//#define DMG_HEAVY    1500
//#define DMG_ENGINEER 2000
//#define DMG_MEDIC    2500
//#define DMG_SNIPER   300
//#define DMG_SPY      2000


int DMG_SCOUT;
int DMG_SOLDIER;
int DMG_PYRO;
int DMG_DEMO;
int DMG_HEAVY;
int DMG_ENGINEER;
int DMG_MEDIC;
int DMG_SNIPER;
int DMG_SPY;

#if defined _FF2_included
bool FF2 = false;
#endif

#define spirite "spirites/zerogxplode.spr"

char g_strClassName[][] = {"", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
char g_strSoundRobotFallDamage[][] = {"mvm/mvm_fallpain01.wav", "mvm/mvm_fallpain02.wav"};
char g_strSoundRobotFootsteps[][] = 
{
	"mvm/player/footsteps/robostep_01.wav", "mvm/player/footsteps/robostep_02.wav", "mvm/player/footsteps/robostep_03.wav", "mvm/player/footsteps/robostep_04.wav", 
	"mvm/player/footsteps/robostep_05.wav", "mvm/player/footsteps/robostep_06.wav", "mvm/player/footsteps/robostep_07.wav", "mvm/player/footsteps/robostep_08.wav", 
	"mvm/player/footsteps/robostep_09.wav", "mvm/player/footsteps/robostep_10.wav", "mvm/player/footsteps/robostep_11.wav", "mvm/player/footsteps/robostep_12.wav", 
	"mvm/player/footsteps/robostep_13.wav", "mvm/player/footsteps/robostep_14.wav", "mvm/player/footsteps/robostep_15.wav", "mvm/player/footsteps/robostep_16.wav", 
	"mvm/player/footsteps/robostep_17.wav", "mvm/player/footsteps/robostep_18.wav"
};

//General
//int g_iPathLaserModelIndex = -1;

bool g_OncePerRound = false;
bool g_AbilityUsed[MAXPLAYERS+1];

int g_iDamageDone[MAXPLAYERS+1];
bool g_bAbilityActive[MAXPLAYERS+1];
float g_flAbilityTime[MAXPLAYERS+1];
bool g_bIsMvM;
Handle g_hHudInfo;
bool g_bDisabledUlt[MAXPLAYERS + 1];

//Resurrect
float flDeathPos[MAXPLAYERS+1][3];
float flDeathAng[MAXPLAYERS+1][3];

//RollerBomb
bool RB_JumpDown[MAXPLAYERS+1];
int RB_Ref[MAXPLAYERS+1];
bool RB_AttackDown[MAXPLAYERS+1];
bool RB_Attacked[MAXPLAYERS+1];
float NextJumpTime[MAXPLAYERS+1];

//Deadeye
int g_iTarget[MAXPLAYERS+1];
float g_flLockOnTime[MAXPLAYERS+1];
bool g_bLocked[MAXPLAYERS+1];
//int FovPerTick[MAXPLAYERS+1];
//bool FovDecrease[MAXPLAYERS+1];
//float FovTickTime = 0.15;
//float SetFovAt[MAXPLAYERS+1];
//int DesFov[MAXPLAYERS+1];

//Grapple
//bool g_bGrappling[MAXPLAYERS + 1];

//Halerocket
int HR_Moveref[MAXPLAYERS + 1];
int HR_Rocketref[MAXPLAYERS + 1][3];
ArrayList HR_Origin[MAXPLAYERS + 1];
ArrayList HR_Angles[MAXPLAYERS + 1];
float HR_NextTouchTickTime[MAXPLAYERS + 1];
int HR_Count[MAXPLAYERS + 1];

//Rewind
//ArrayList g_hPositions[MAXPLAYERS + 1];
//ArrayList g_hAngles[MAXPLAYERS + 1];
//ArrayList g_hHealthPoints[MAXPLAYERS + 1];

static ArrayList g_dynamicHookIds;

//float g_flLastSwingAt[MAXPLAYERS + 1];
//float g_flSmackAt[MAXPLAYERS + 1];
//Handle hPlaySpecificSequence;
Handle hFindEntityInSphere;
Handle hWorldSpaceCenter;
Handle hGetVelocity;
//static DynamicHook g_DHookSwing;

//Handle hSendWeaponAnim;
//Handle hLookUpActivity;

//Shield
bool g_UpdatingPos[MAXPLAYERS + 1];
int FakeshieldRef[MAXPLAYERS + 1];

//MeltCore
char strPlayerModel[MAXPLAYERS + 1][128];

#define MODEL_ENGINEER	"models/bots/engineer/bot_engineer.mdl"
#define MODEL_GRAVITON	"models/empty.mdl"
#define ENGINE_LOOP		"mvm/giant_heavy/giant_heavy_loop.wav"
#define MODEL_TRAIN		"models/props_vehicles/train_enginecar.mdl"

//mannpower_imbalance_blue
//mannpower_imbalance_red

public Plugin myinfo = 
{
	name = "[TF2] Ultimate Abilities",
	author = "Pelipoika",
	description = "Overwatch style ultimate abilities. They copied us, now we copy them.",
	version = "1.x",
	url = "http://www.sourcemod.net/plugins.php?author=Pelipoika&search=1"
};

public void OnPluginStart()
{

	AutoExecConfig(true, "plugin.ultimateabilities");

	#if defined _FF2_included
	FF2 = LibraryExists("freak_fortress_2");
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	#endif

	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("npc_hurt", Event_NPCHurt);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("player_changeclass", Event_PlayerChangeClass, EventHookMode_Pre);
	
	
	g_hHudInfo = CreateHudSynchronizer();

	AddNormalSoundHook(NormalSoundHook);
	
//	RegConsoleCmd("sm_toggleult", Command_ToggleUlt, "Toggle being able to use ultimate with H");
	RegAdminCmd("sm_toggleult", Command_ToggleUlt, ADMFLAG_ROOT);
	RegAdminCmd("sm_fillult", Command_GiveUlt, ADMFLAG_ROOT);
	
	cvar_DMG_SCOUT = CreateConVar("tf2_Ultimate_dmg_scout", "600", "DMG require for scout ability.");
	cvar_DMG_SOLDIER = CreateConVar("tf2_Ultimate_dmg_soldier", "2000", "DMG require for soldier ability.");
	cvar_DMG_PYRO = CreateConVar("tf2_Ultimate_dmg_pyro", "2000", "DMG require for pyro ability.");
	cvar_DMG_DEMO = CreateConVar("tf2_Ultimate_dmg_demo", "2000", "DMG require for demoman ability.");
	cvar_DMG_HEAVY = CreateConVar("tf2_Ultimate_dmg_heavy", "1500", "DMG require for heavy ability.");
	cvar_DMG_ENGINEER = CreateConVar("tf2_Ultimate_dmg_engineer", "2000", "DMG require for engineer ability.");
	cvar_DMG_MEDIC = CreateConVar("tf2_Ultimate_dmg_medic", "300", "DMG require for medic ability.");
	cvar_DMG_SNIPER = CreateConVar("tf2_Ultimate_dmg_sniper", "300", "DMG require for sniper ability.");
	cvar_DMG_SPY = CreateConVar("tf2_Ultimate_dmg_spy", "2000", "DMG require for spy ability.");
	cvar_Ability_OncePerRound = CreateConVar("tf2_Ultimate_OncePerRound", "1", " 1 - yes/ 0 - no. Ability can only be activated once per round.");
	
	
	cvar_DMG_SCOUT.AddChangeHook(OnSettingsChanged);
	cvar_DMG_SOLDIER.AddChangeHook(OnSettingsChanged);
	cvar_DMG_PYRO.AddChangeHook(OnSettingsChanged);
	cvar_DMG_DEMO.AddChangeHook(OnSettingsChanged);
	cvar_DMG_HEAVY.AddChangeHook(OnSettingsChanged);
	cvar_DMG_ENGINEER.AddChangeHook(OnSettingsChanged);
	cvar_DMG_MEDIC.AddChangeHook(OnSettingsChanged);
	cvar_DMG_SNIPER.AddChangeHook(OnSettingsChanged);
	cvar_DMG_SPY.AddChangeHook(OnSettingsChanged);
	cvar_Ability_OncePerRound.AddChangeHook(OnSettingsChanged);

	DMG_SCOUT = cvar_DMG_SCOUT.IntValue;
	DMG_SOLDIER = cvar_DMG_SOLDIER.IntValue;
	DMG_PYRO = cvar_DMG_PYRO.IntValue;
	DMG_DEMO = cvar_DMG_DEMO.IntValue;
	DMG_HEAVY = cvar_DMG_HEAVY.IntValue;
	DMG_ENGINEER = cvar_DMG_ENGINEER.IntValue;
	DMG_MEDIC = cvar_DMG_MEDIC.IntValue;
	DMG_SNIPER = cvar_DMG_SNIPER.IntValue;
	DMG_SPY = cvar_DMG_SPY.IntValue;
	
	g_OncePerRound = cvar_Ability_OncePerRound.IntValue ? true : false;
	
	AddFileToDownloadsTable("models/shields/heavy_shield.mdl");
	AddFileToDownloadsTable("models/shields/heavy_shield.dx80.vtx");
	AddFileToDownloadsTable("models/shields/heavy_shield.dx90.vtx");
	AddFileToDownloadsTable("models/shields/heavy_shield.sw.vtx");
	AddFileToDownloadsTable("models/shields/heavy_shield.vvd");
	AddFileToDownloadsTable("models/shields/heavy_shield.phy");

	AddFileToDownloadsTable("materials/models/shields/heavy_shield/heavy_shield.vmt");
	AddFileToDownloadsTable("materials/models/shields/heavy_shield/heavy_shield.vtf");
	AddFileToDownloadsTable("materials/models/shields/heavy_shield/heavy_shield_blue.vmt");
	AddFileToDownloadsTable("materials/models/shields/heavy_shield/heavy_shield_blue.vtf");
	AddFileToDownloadsTable("materials/models/shields/heavy_shield/heavy_shield_invis.vmt");
	AddFileToDownloadsTable("materials/models/shields/heavy_shield/heavy_shield_invis.vtf");
	
	
	g_dynamicHookIds = new ArrayList();
	
	GameData Agamedata = LoadGameConfigFile("ultimateabilities");
	if(!Agamedata)
	{
		SetFailState("Failed to load gamedata (ultimateabilities).");
		delete Agamedata;
		return;
	}
/*	Handle dtUpdateShieldPosition = DHookCreateFromConf(Agamedata,"CTFMedigunShield::UpdateShieldPosition()");
	DHookEnableDetour(dtUpdateShieldPosition, false, DHook_UpdateShieldPosition);

	MemoryPatch g_PatchMediShieldNoMotion = MemoryPatch.CreateFromConf(Agamedata, "CTFMedigunShield::UpdateShieldPosition()::Disable");
	if (!g_PatchMediShieldNoMotion.Validate())
	{
		SetFailState("Failed to verify CTFMedigunShield::UpdateShieldPosition()::Disable.");
	}
*/
	DHook_CreateDetour(Agamedata, "CTFMedigunShield::UpdateShieldPosition()", DHook_UpdateShieldPosition);

/*	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(Agamedata, SDKConf_Signature, "CTFPlayer::PlaySpecificSequence");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	hPlaySpecificSequence = EndPrepSDKCall();
	if (!hPlaySpecificSequence)
		LogMessage("Failed to create call: CTFPlayer::PlaySpecificSequence");
*/

	StartPrepSDKCall(SDKCall_EntityList);
	PrepSDKCall_SetFromConf(Agamedata, SDKConf_Signature, "CGlobalEntityList::FindEntityInSphere");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer,
			VDECODE_FLAG_ALLOWNULL | VDECODE_FLAG_ALLOWWORLD);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hFindEntityInSphere = EndPrepSDKCall();
	if (!hFindEntityInSphere)
		LogMessage("Failed to create call: CGlobalEntityList::FindEntityInSphere");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(Agamedata, SDKConf_Virtual, "CBaseEntity::WorldSpaceCenter");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByRef);
	if (!(hWorldSpaceCenter = EndPrepSDKCall()))
		LogError("Could not initialize call to CBaseEntity::WorldSpaceCenter. Falling back to m_vecOrigin.");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(Agamedata, SDKConf_Virtual, "CBaseEntity::GetVelocity");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain, 0, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain, 0, VENCODE_FLAG_COPYBACK);
	if (!(hGetVelocity = EndPrepSDKCall()))
		SetFailState("Could not initialize call to CBaseEntity::GetVelocity");

//	g_DHookSwing = DHooks_AddDynamicHook(Agamedata, "CTFWeaponBaseMelee::Swing");


/*	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(Agamedata, SDKConf_Signature, "CTFWeaponBase::SendWeaponAnim");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hSendWeaponAnim = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(Agamedata, SDKConf_Signature, "LookupActivity");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	//pStudioHdr
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);		//label
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);	//return index
	if((hLookupActivity = EndPrepSDKCall()) == INVALID_HANDLE)
		SetFailState("Failed to create Call for LookupActivity");
*/
	delete Agamedata;
}

public void OnPluginEnd()
{
	for (int i = g_dynamicHookIds.Length - 1; i >= 0; i--)
	{
		int hookid = g_dynamicHookIds.Get(i);
		DynamicHook.RemoveHook(hookid);
	}
}

public void OnSettingsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == cvar_DMG_SCOUT)
		DMG_SCOUT = StringToInt(newValue);
	else if(convar == cvar_DMG_SOLDIER)
		DMG_SOLDIER = StringToInt(newValue);
	else if(convar == cvar_DMG_PYRO)
		DMG_PYRO = StringToInt(newValue);
	else if(convar == cvar_DMG_DEMO)
		DMG_DEMO = StringToInt(newValue);
	else if(convar == cvar_DMG_HEAVY)
		DMG_HEAVY = StringToInt(newValue);
	else if(convar == cvar_DMG_ENGINEER)
		DMG_ENGINEER = StringToInt(newValue);
	else if(convar == cvar_DMG_MEDIC)
		DMG_MEDIC = StringToInt(newValue);
	else if(convar == cvar_DMG_SNIPER)
		DMG_SNIPER = StringToInt(newValue);
	else if(convar == cvar_DMG_SPY)
		DMG_SPY = StringToInt(newValue);
	else if(convar == cvar_Ability_OncePerRound)
		g_OncePerRound = cvar_Ability_OncePerRound.IntValue ? true : false;
}

public void OnLibraryAdded(const char[] name)
{

	#if defined _FF2_included
	if(StrEqual(name, "freak_fortress_2", false))
	{
		FF2 = true;
	}
	#endif
}

public void OnLibraryRemoved(const char[] name)
{
	#if defined _FF2_included
	if(StrEqual(name, "freak_fortress_2", false))
	{
		FF2 = false;
	}
	#endif
}

public void OnClientPutInServer(int client)
{
	g_AbilityUsed[client] = false;
	g_iDamageDone[client] = 0;
	g_bAbilityActive[client] = false;
	g_flAbilityTime[client] = 0.0;
	g_bDisabledUlt[client] = false;
	
	//Deadeye
	g_iTarget[client] = 0;
	g_bLocked[client] = false;
	
	//Grapple
//	g_bGrappling[client] = false;
	
//	FakeshieldRef[client] = INVALID_ENT_REFERENCE;
}

public Action Command_ToggleUlt(int client, int args)
{
	if(g_bDisabledUlt[client])
	{
		g_bDisabledUlt[client] = false;
		PrintToChat(client, "[ULTIMATE] You can now activate your ultimate again by pressing the ultimate key");
	}
	else
	{
		g_bDisabledUlt[client] = true;
		PrintToChat(client, "[ULTIMATE] You will no longer be able to activate your ultimate");
	}
	
	return Plugin_Handled;
}

public Action Command_GiveUlt(int client, int args)
{
	g_iDamageDone[client] += 1000;
	PrintCenterText(client, "Damage Done %i", g_iDamageDone[client]);
	
	return Plugin_Handled;
}

public void OnMapStart()
{
	char strMap[32];
	GetCurrentMap(strMap, sizeof(strMap));
	if (StrContains(strMap, "mvm_") != -1)
	{
		g_bIsMvM = true;
	}

	PrecacheModel(MODEL_GRAVITON);
	PrecacheModel(MODEL_ENGINEER);
	PrecacheSound(ENGINE_LOOP);
	PrecacheModel(MODEL_TRAIN);
	
//	g_iPathLaserModelIndex = PrecacheModel("materials/sprites/laserbeam.vmt");
	
	PrecacheSound("ambient/alarms/razortrain_horn1.wav");
	PrecacheSound("misc/cp_harbor_blue_whistle.wav");
	PrecacheSound("misc/cp_harbor_red_whistle.wav");
	PrecacheSound("misc/halloween/duck_pickup_pos_01.wav");
	PrecacheSound("misc/halloween/duck_pickup_neg_01.wav");
	PrecacheSound("replay/cameracontrolmodeentered.wav");
	PrecacheSound("replay/cameracontrolmodeexited.wav");
	PrecacheSound("replay/rendercomplete.wav");
	PrecacheSound("replay/enterperformancemode.wav");
	PrecacheSound("replay/exitperformancemode.wav");
	PrecacheSound("weapons/medi_shield_deploy.wav");
	PrecacheSound("misc/halloween_eyeball/vortex_eyeball_moved.wav");
	PrecacheSound("weapons/airstrike_fire_01.wav");
	PrecacheSound("weapons/airstrike_fire_02.wav");
	PrecacheSound("weapons/airstrike_fire_03.wav");
	
	PrecacheModel(spirite, true);
	
//	PrecacheModel("models/items/gunvolt_sphere.mdl");
	PrecacheModel("models/shields/heavy_shield.mdl");
	
	PrecacheModel("models/roller.mdl");
	PrecacheModel("models/roller_spikes.mdl");
	
	PrecacheSound("npc/roller/mine/rmine_blades_out1.wav");
	PrecacheSound("npc/roller/mine/rmine_blades_out2.wav");
	PrecacheSound("npc/roller/mine/rmine_blades_out3.wav");
	
	PrecacheSound("npc/roller/mine/rmine_movefast_loop1.wav");
	PrecacheSound("npc/roller/mine/rmine_moveslow_loop1.wav");
	PrecacheSound("npc/roller/mine/rmine_explode_shock1.wav");
	
	PrecacheSound("npc/manhack/mh_engine_loop1.wav");
//	PrecacheSound("weapons/bumper_car_go_loop.wav");

	PrecacheSound("mvm/melee_impacts/bat_baseball_hit_robo01.wav");
	
//	PrecacheModel("models/funnystuff/saxton_rockets.mdl");
	
	for(int i = 0; i < sizeof(g_strSoundRobotFootsteps); i++)	PrecacheSound(g_strSoundRobotFootsteps[i]);
	for(int i = 0; i < sizeof(g_strSoundRobotFallDamage); i++)	PrecacheSound(g_strSoundRobotFallDamage[i]);
}

/*public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrContains(classname, "tf_weapon_bat") != -1)
		SDKHook(entity, SDKHook_SpawnPost, DHook_SpawnPost);
	else if(StrContains(classname, "saxxy") != -1)
		SDKHook(entity, SDKHook_SpawnPost, DHook_SpawnPost);
}

public void DHook_SpawnPost(int iWeapon)
{
	DHooks_HookEntityInternal(g_DHookSwing, Hook_Post, iWeapon, DHook_SwingPost);
}

public MRESReturn DHook_SwingPost(int iWeapon, DHookReturn hReturn)
{

	int iClient = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity");
	if(!IsValidClient)
		return MRES_Ignored;
	if(TF2_GetPlayerClass(iClient) == TFClass_Scout && g_bAbilityActive[iClient])
	{
		g_flLastSwingAt[iClient] = GetGameTime();
//		RequestFrame(Scout_Swing, EntIndexToEntRef(iWeapon));

//		int m_iWeaponMode = FindSendPropInfo("CTFWeaponBase", "m_iReloadMode") - 4; 
//		int m_pWeaponInfo = FindSendPropInfo("CTFWeaponBase", "m_flReloadPriorNextFire") + 4;

//		int weaponMode = LoadFromAddress(GetEntityAddress(iWeapon) + view_as<Address>(m_iWeaponMode), NumberType_Int32);
//		int weaponInfo = LoadFromAddress(GetEntityAddress(iWeapon) + view_as<Address>(m_pWeaponInfo), NumberType_Int32);

//		PrintToChatAll("mode %d, info %d", weaponMode, weaponInfo);

//		int SmackDelay = weaponInfo + 64 * weaponMode + 1840;
//		g_flSmackAt[iClient] = view_as<float>(LoadFromAddress(view_as<Address>(SmackDelay), NumberType_Int32));// 58 = 14*4(float & int) + 2*1(bool)

//		PrintToChatAll("%f,%f", g_flSmackAt, GetGameTime());


		SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+0.38);
		SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime()+0.38);
		SetEntPropFloat(iWeapon, Prop_Send, "m_flTimeWeaponIdle", GetGameTime()+0.38)

	}

	return MRES_Ignored;
}*/

/*public void Scout_Swing(int ref)
{
	int weapon = EntRefToEntIndex(ref);
	if(!IsValidEntity(weapon))
		return;
	int iClient = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if(!IsValidClient)
		return;
	g_flSmackAt[client] = GetEntDataFloat(weapon, FindSendPropInfo("DT_TFWeaponBase", "m_nInspectStage") + 28);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+0.28);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime()+0.28);
}*/


public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	if(g_bIsMvM && TF2_GetClientTeam(client) == TFTeam_Blue || g_bDisabledUlt[client])
		return Plugin_Continue;

	char strCmd[256];
	kv.GetSectionName(strCmd, 256);
	
	int iDmg;
	switch(TF2_GetPlayerClass(client))
	{
		case TFClass_Scout:		iDmg = DMG_SCOUT;
		case TFClass_Soldier:	iDmg = DMG_SOLDIER;
		case TFClass_Pyro:		iDmg = DMG_PYRO;
		case TFClass_DemoMan:	iDmg = DMG_DEMO;
		case TFClass_Heavy:		iDmg = DMG_HEAVY;
		case TFClass_Engineer:	iDmg = DMG_ENGINEER;
		case TFClass_Medic:		iDmg = DMG_MEDIC;
		case TFClass_Sniper:	iDmg = DMG_SNIPER;
		case TFClass_Spy:		iDmg = DMG_SPY;
	}
	
	if(StrEqual(strCmd, "+use_action_slot_item_server") && IsPlayerAlive(client) && g_iDamageDone[client] >= iDmg && !g_bAbilityActive[client] && !(g_AbilityUsed[client] && g_OncePerRound))
	{
		int stunflags = GetEntProp(client, Prop_Send, "m_iStunFlags");
		if( (stunflags & TF_STUNFLAG_THIRDPERSON) || (stunflags & TF_STUNFLAG_BONKSTUCK) )
			return Plugin_Continue;
	
		MeleeDare(client);

		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Scout:
			{
			
/*				g_AbilityUsed[client] = true;
			
				g_iDamageDone[client] = 0;
				g_bAbilityActive[client] = true;
				g_flAbilityTime[client] = GetGameTime() + 10.0;
				
				SetEntityMoveType(client, MOVETYPE_NOCLIP);
				
				TF2_AddCondition(client, TFCond_Bonked);
				
				TF2_SetFOV(client, GetEntProp(client, Prop_Send, "m_iDefaultFOV"), 3.0, 120);			
				
				EmitSoundToAll("replay/exitperformancemode.wav", client);
				EmitSoundToClient(client, "replay/exitperformancemode.wav");
*/

				g_AbilityUsed[client] = true;
				
				g_iDamageDone[client] = 0;
				g_bAbilityActive[client] = true;
				g_flAbilityTime[client] = GetGameTime() + 6.0;
				
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 255, 255, 255, 100);
				SetEntProp(client, Prop_Send, "m_CollisionGroup", 2);
				
				int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
				if(IsValidEntity(melee))
				{
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", melee);
					TF2Attrib_SetByName(melee, "hand scale", 3.0);
					SetEntPropFloat(melee, Prop_Send, "m_flNextPrimaryAttack", g_flAbilityTime[client])
					SetEntPropFloat(melee, Prop_Send, "m_flNextSecondaryAttack", g_flAbilityTime[client]);
				}

//				int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
//				if(IsValidEntity(weapon))
//				{
//					float next = GetGameTime() + 10.0;
//					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", g_flAbilityTime[client]);
//					SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", g_flAbilityTime[client]);
//				}
//				SetVariantInt(0);
//				AcceptEntityInput(client, "SetForcedTauntCam");


				SDKHook(client, SDKHook_WeaponCanSwitchTo, Hook_WeaponCanSwitch);
				SDKHook(client, SDKHook_OnTakeDamage, Scout_Ontakedamage);


//				SendConVarValue(client, FindConVar("sv_client_predict"), "0");
//				SetEntProp(client, Prop_Data, "m_bLagCompensation", false);
//				SetEntProp(client, Prop_Data, "m_bPredictWeapons", false);
				
//				g_flLastSwingAt[client] = GetGameTime();
				
//				SDKCall(hPlaySpecificSequence, client, "ACT_MP_ATTACK_STAND_MELEE_SECONDARY");

			}
			case TFClass_Soldier:
			{
				if(!(GetEntityFlags(client) & FL_ONGROUND))
				{
					g_AbilityUsed[client] = true;
					
					g_iDamageDone[client] = 0;
					g_flAbilityTime[client] = GetGameTime() + 3.0;
					g_bAbilityActive[client] = true;
					
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
					SetEntityMoveType(client, MOVETYPE_NONE);
					FireRocket(client);
					Overlay(client, "effects/combine_binocoverlay");
				}
			}
			case TFClass_Pyro:
			{
				float flStartPos[3], flEyeAng[3], flForw[3];
				GetClientEyePosition(client, flStartPos);
				GetClientEyeAngles(client, flEyeAng);
				
				GetAngleVectors(flEyeAng, flForw, NULL_VECTOR, NULL_VECTOR) 
		
				flStartPos[0] += (flForw[0] * 100.0);
				flStartPos[1] += (flForw[1] * 100.0);
				flStartPos[2] += (flForw[2] * 100.0);
				
				Handle hTrace = TR_TraceRayFilterEx(flStartPos, flEyeAng, MASK_SHOT, RayType_Infinite, AimTargetFilter, client);
				float flHitPos[3];
				TR_GetEndPosition(flHitPos, hTrace);
				CloseHandle(hTrace);
				
				float flResult[3];
				SubtractVectors(flStartPos, flHitPos, flResult);
				NegateVector(flResult);
				NormalizeVector(flResult, flResult);
				ScaleVector(flResult, 1000.0);
			
				g_AbilityUsed[client] = true;
			
				g_iDamageDone[client] = 0;
				g_flAbilityTime[client] = GetGameTime() + 10.0;
				g_bAbilityActive[client] = true;
				
				int bomb = CreateEntityByName("tf_projectile_pipe_remote");	
				DispatchKeyValueVector(bomb, "origin", flStartPos);
				DispatchKeyValueVector(bomb, "basevelocity", flResult);
				DispatchKeyValueVector(bomb, "velocity", flResult);
				DispatchKeyValue(bomb, "ModelScale", "5.0");
				
				if (TF2_GetClientTeam(client) == TFTeam_Red) 
					DispatchKeyValue(bomb, "skin", "0");
				else if (TF2_GetClientTeam(client) == TFTeam_Blue) 
					DispatchKeyValue(bomb, "skin", "1");
			
				SetEntPropEnt(bomb, Prop_Data, "m_hThrower", client);
				SetEntProp(bomb, Prop_Send, "m_iType", 1);
				SetEntPropFloat(bomb, Prop_Data, "m_flDetonateTime", GetGameTime() + 6.0);
				
				DispatchSpawn(bomb);
				
				SetEntityModel(bomb, MODEL_GRAVITON);

				if(TF2_GetClientTeam(client) == TFTeam_Blue)
					Particle_Create(bomb, "spell_fireball_small_blue", _, 1.0, true);
				else
					Particle_Create(bomb, "spell_fireball_small_red", _, 1.0, true);
					
				TeleportEntity(bomb, NULL_VECTOR, NULL_VECTOR, flResult);

				SDKHook(bomb, SDKHook_Think, OnGravitonThink);
			}
			case TFClass_DemoMan:
			{
				float flStartPos[3], flEyeAng[3], flForw[3], endPos[3];
				GetClientEyePosition(client, flStartPos);
				GetClientEyeAngles(client, flEyeAng);
				
				GetAngleVectors(flEyeAng, flForw, NULL_VECTOR, NULL_VECTOR) 

				endPos[0] = flStartPos[0] + (flForw[0] * 75.0);
				endPos[1] = flStartPos[1] + (flForw[1] * 75.0);
				endPos[2] = flStartPos[2] + (flForw[2] * 15.0);
				
				float mins[3];
				float maxs[3];
				GetEntPropVector(client, Prop_Send, "m_vecMins", mins);
				GetEntPropVector(client, Prop_Send, "m_vecMaxs", maxs);
				Handle trace = TR_TraceHullFilterEx(flStartPos, endPos, mins, maxs, MASK_PLAYERSOLID, TraceWallsOnly);
//				float flHitPos[3];
//				TR_GetEndPosition(flHitPos, trace);
				
				if(!TR_DidHit(trace))
				{
					g_AbilityUsed[client] = true;
				
					g_iDamageDone[client] = 0;
					g_bAbilityActive[client] = true;
					g_flAbilityTime[client] = GetGameTime() + 15.0;
					
					RB_Attacked[client] = false;
					RB_Ref[client] = INVALID_ENT_REFERENCE;
					NextJumpTime[client] = 0.0;
					int iEnt = CreateEntityByName("prop_physics_multiplayer");
					if(IsValidEntity(iEnt))
					{
						char strName[64];
						Format(strName, sizeof(strName), "RollerBomb%i", iEnt);
						DispatchKeyValue(iEnt, "targetname", strName);
						
						RB_Ref[client] = EntIndexToEntRef(iEnt);
						
						DispatchKeyValueVector(iEnt, "origin", flStartPos);
						DispatchKeyValue(iEnt, "model", "models/roller.mdl");
						DispatchKeyValue(iEnt, "nodamageforces", "1");
						DispatchSpawn(iEnt);
					
						SDKHook(iEnt, SDKHook_SetTransmit, OnRollerbombThink);
					
						int iMotor = CreateEntityByName("phys_torque");
						DispatchKeyValueVector(iMotor, "origin", flStartPos);
						DispatchKeyValue(iMotor, "attach1", strName);
						DispatchKeyValue(iMotor, "force", "5000"); //angular force
						DispatchKeyValue(iMotor, "speed", "300"); //rotation speed
						DispatchSpawn(iMotor);
						
						SetVariantString("!activator");
						AcceptEntityInput(iMotor, "SetParent", iEnt);
						
						ActivateEntity(iMotor);
						
						SetVariantInt(1);
						AcceptEntityInput(client, "SetForcedTauntCam");
						SetClientViewEntity(client, iEnt); 
						
						SetEntityMoveType(client, MOVETYPE_NONE);

						TF2_AddCondition(client, TFCond_Bonked);
						
						SetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity", client);
						
						StopSound(iEnt, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
						StopSound(iEnt, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
						
						EmitSoundToAll("npc/roller/mine/rmine_moveslow_loop1.wav", iEnt);
						EmitSoundToAll("npc/roller/mine/rmine_movefast_loop1.wav", iEnt);
						
						
						SetEntProp(iEnt, Prop_Data, "m_nBody", 1);
						
						SDKHook(client, SDKHook_OnTakeDamage, RB_Ontakedamage);
					}
				}
				CloseHandle(trace);
			}
			case TFClass_Heavy:
			{
				g_AbilityUsed[client] = true;
			
				g_iDamageDone[client] = 0;
				g_flAbilityTime[client] = GetGameTime() + 10.0;
				g_bAbilityActive[client] = true;
				
				FakeshieldRef[client] = INVALID_ENT_REFERENCE;
				
				int shield = CreateEntityByName("entity_medigun_shield");	
				SetEntPropEnt(shield, Prop_Send, "m_hOwnerEntity", client);  
				SetEntProp(shield, Prop_Send, "m_iTeamNum", GetClientTeam(client));  
				SetEntProp(shield, Prop_Data, "m_iInitialTeamNum", GetClientTeam(client));  
				
//				if (TF2_GetClientTeam(client) == TFTeam_Red) 
//					DispatchKeyValue(shield, "skin", "0");
//				else if (TF2_GetClientTeam(client) == TFTeam_Blue) 
//					DispatchKeyValue(shield, "skin", "1");
				
				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
				SetEntProp(client, Prop_Send, "m_bRageDraining", 1);
				
				DispatchKeyValue(shield, "rendermode", "10");
				SetEntityRenderMode(shield, RENDER_NONE);
				
				DispatchSpawn(shield);
				
				SetEntityRenderMode(shield, RENDER_NONE);
				
				
				g_UpdatingPos[client] = false;
				EmitSoundToClient(client, "weapons/medi_shield_deploy.wav", shield);
//				SetEntityModel(shield, "models/props_mvm/mvm_player_shield2.mdl");
//				SetEntityModel(shield, "models/props_mvm/mvm_player_shield.mdl");
				SetEntityModel(shield, "models/shields/heavy_shield.mdl");

				float pos[3], angle[3], flForward[3], origin[3];
				GetClientEyeAngles(client, angle);
				GetAngleVectors(angle, flForward, NULL_VECTOR, NULL_VECTOR);
				flForward[2] = 0.0;
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", pos);
				ScaleVector(flForward, 145.0);
				AddVectors(pos, flForward, origin);
				
				angle[0] = 0.0; angle[2] = 0.0;
				
				int Fakeshield = CreateEntityByName("prop_dynamic_override");
				if(IsValidEntity(Fakeshield))
				{
					FakeshieldRef[client] = EntIndexToEntRef(Fakeshield);
//					DispatchKeyValue(Fakeshield, "model", "models/props_mvm/mvm_player_shield2.mdl");
					DispatchKeyValue(Fakeshield, "model", "models/shields/heavy_shield.mdl");
					
					DispatchKeyValue(Fakeshield, "disablereceiveshadows", "1");
					DispatchKeyValue(Fakeshield, "disableshadows", "1");
					DispatchKeyValue(Fakeshield, "solid", "0");
					DispatchKeyValueVector(Fakeshield, "origin", origin);
					DispatchKeyValueVector(Fakeshield, "angles", angle);
					DispatchKeyValue(Fakeshield, "CollisionGroup", "0");
		//			DispatchKeyValue(Fakeshield, "renderamt", "50");
		//			DispatchKeyValue(Fakeshield, "rendercolor", "255 0 0");
					DispatchKeyValue(Fakeshield, "rendermode", "1");

					SetEntProp(Fakeshield, Prop_Send, "m_nSkin", (TF2_GetClientTeam(client)==TFTeam_Blue) ? 3 : 2);

					DispatchSpawn(Fakeshield);
					
					SetEntityRenderColor(Fakeshield, 255, 255, 255, 100)
				}


			}
			case TFClass_Medic:
			{
				float flPos[3];
				GetClientAbsOrigin(client, flPos);
				
				int iReviveCount = 0;
				
				for(int i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i) && !IsPlayerAlive(i) && TF2_GetClientTeam(i) == TF2_GetClientTeam(client))
					{
						float flDistance = GetVectorDistance(flPos, flDeathPos[i]);
						if(flDistance <= 400.0 && iReviveCount <= 3)
						{
							iReviveCount++;
						
							TF2_RespawnPlayer(i);
							
							float flTimeImmunity = 3.0;
							
							TF2_AddCondition(i, TFCond_UberchargedCanteen, flTimeImmunity);
							TeleportEntity(i, flDeathPos[i], flDeathAng[i], NULL_VECTOR);
							
							Particle_Create(i, "teleporter_mvm_bot_persist", 0.0, flTimeImmunity);
							
							SetVariantString("randomnum:30");
							AcceptEntityInput(i, "AddContext");
	
							SetVariantString("TLK_RESURRECTED");
							AcceptEntityInput(i, "SpeakResponseConcept");
	
							AcceptEntityInput(i, "ClearContext");
						}
					}
				}
				
				if(iReviveCount > 0)
				{
					g_AbilityUsed[client] = true;

					g_iDamageDone[client] = 0;
				}
			}
			case TFClass_Engineer:
			{
				g_AbilityUsed[client] = true;
			
				g_iDamageDone[client] = 0;
				g_flAbilityTime[client] = GetGameTime() + 20.0;
				g_bAbilityActive[client] = true;
				
				SetEntProp(client, Prop_Send, "m_iHealth", GetEntProp(client, Prop_Send, "m_iHealth") + 300);
				
				GetEntPropString(client, Prop_Data, "m_ModelName", strPlayerModel[client], sizeof(strPlayerModel));
				
				SetVariantString(MODEL_ENGINEER);
				AcceptEntityInput(client, "SetCustomModel");
				SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
				
				EmitSoundToAll(ENGINE_LOOP, client, _, _, _, 0.5);
				
				if(TF2_GetClientTeam(client) == TFTeam_Blue)
					EmitSoundToAll("misc/cp_harbor_blue_whistle.wav", client, _, _, _, 0.25);	//LOUD
				else
					EmitSoundToAll("misc/cp_harbor_red_whistle.wav", client, _, _, _, 0.25);
				
				int iPrimary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				if(IsValidEntity(iPrimary))
				{
					TF2Attrib_SetByName(iPrimary, "fire rate bonus HIDDEN", 0.5);
					TF2Attrib_SetByName(iPrimary, "reload time increased hidden", 0.5);
				}
				
				int iSecondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
				if(IsValidEntity(iSecondary))
				{
					TF2Attrib_SetByName(iSecondary, "fire rate bonus HIDDEN", 0.5);
					TF2Attrib_SetByName(iSecondary, "reload time increased hidden", 0.5);
				}
				
				int iMelee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
				if(IsValidEntity(iMelee))
				{
					TF2Attrib_SetByName(iMelee, "fire rate bonus HIDDEN", 0.5);
					TF2Attrib_SetByName(iMelee, "Construction rate increased", 2.0);
				}

				Particle_Create(client, "ghost_appearation", 20.0, 2.0);
			}
			case TFClass_Sniper:
			{
				g_AbilityUsed[client] = true;
			
				g_iDamageDone[client] = 0;
				g_bAbilityActive[client] = true;
				g_flAbilityTime[client] = GetGameTime() + 12.0;

				HR_Count[client] = 0;
				HR_Moveref[client] = INVALID_ENT_REFERENCE;
				HR_Rocketref[client][0] = INVALID_ENT_REFERENCE;
				HR_Rocketref[client][1] = INVALID_ENT_REFERENCE;
				HR_Rocketref[client][2] = INVALID_ENT_REFERENCE;
				HR_NextTouchTickTime[client] = GetEngineTime();

				HR_Angles[client] = new ArrayList(3);
				HR_Origin[client] = new ArrayList(3);
				
				float angles[3], origin[3];
				GetClientEyeAngles(client, angles);
				HR_Angles[client].PushArray(angles);
				GetClientEyePosition(client, origin);
				HR_Origin[client].PushArray(origin);

				int g_iMoveEnt = CreateEntityByName("func_movelinear");
				if(IsValidEntity(g_iMoveEnt))
				{
					char strName[64];
					Format(strName, sizeof(strName), "halemovelinear%i", g_iMoveEnt);
					DispatchKeyValue(g_iMoveEnt, "targetname", strName);
					DispatchKeyValue(g_iMoveEnt, "rendermode", "10");
					DispatchKeyValue(g_iMoveEnt, "startposition", "0");
					DispatchKeyValue(g_iMoveEnt, "speed", "600");
					DispatchKeyValue(g_iMoveEnt, "spawnflags", "8");
					DispatchKeyValue(g_iMoveEnt, "movedistance", "6200");
					DispatchKeyValueVector(g_iMoveEnt, "movedir", angles);
					DispatchKeyValueVector(g_iMoveEnt, "origin", origin);
					DispatchSpawn(g_iMoveEnt);
					SetEntityModel(g_iMoveEnt, MODEL_GRAVITON);					//This is IMPORTANT!!!
					SetEntityMoveType(g_iMoveEnt, MOVETYPE_NOCLIP);
					SetEntProp(g_iMoveEnt, Prop_Send, "m_nSolidType", 0);
					SetEntProp(g_iMoveEnt, Prop_Send, "m_CollisionGroup", 0);
//					PrintToChatAll("pos %f %f %f\nangles %f %f %f\n", origin[0], origin[1], origin[2], angles[0], angles[1], angles[2]);

//					TeleportEntity(g_iMoveEnt, origin, angles, NULL_VECTOR);


					SetVariantString("OnUser1 !self:KillHierarchy::11.6:1");
					AcceptEntityInput(g_iMoveEnt, "AddOutput");
					AcceptEntityInput(g_iMoveEnt, "FireUser1");
//					SetVariantString("OnFullyOpen !self:KillHierarchy::0.0:1");
//					AcceptEntityInput(g_iMoveEnt, "AddOutput");
					AcceptEntityInput(g_iMoveEnt, "Open");
					
					
					HR_Moveref[client] = EntIndexToEntRef(g_iMoveEnt);
				}
				
				CreateTimer(0.56, Timer_HRCreate, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				
				
/*				int iWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
				if(IsValidEntity(iWeapon))
				{
					g_flAbilityTime[client] = GetGameTime() + 12.0;	
					
					Handle TF2Item = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES);
					TF2Items_SetClassname(TF2Item, "tf_weapon_grapplinghook");
					TF2Items_SetItemIndex(TF2Item, 1152);
					TF2Items_SetLevel(TF2Item, 100);
					
					int ItemEntity = TF2Items_GiveNamedItem(client, TF2Item);
					delete TF2Item;
	
					EquipPlayerWeapon(client, ItemEntity);
	
					FakeClientCommand(client, "use tf_weapon_grapplinghook");
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", ItemEntity);
				}*/
			}
			case TFClass_Spy:
			{
				g_AbilityUsed[client] = true;
			
				g_iDamageDone[client] = (iDmg / 2);
				g_flAbilityTime[client] = GetGameTime() + 20.0;
				g_bAbilityActive[client] = true;
				
				g_flLockOnTime[client] = GetGameTime() + 1.0;
				g_bLocked[client] = false;
				g_iTarget[client] = -1;
				
				EmitSoundToAll("replay/enterperformancemode.wav", client);
				EmitSoundToClient(client, "replay/cameracontrolmodeentered.wav");
				TF2_SetFOV(client, GetEntProp(client, Prop_Send, "m_iDefaultFOV"), 1.3, 120);
				Overlay(client, "effects/combine_binocoverlay");
			}
		}
			
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

//Yes i know, it's not ideal to use SetTransmit in place of think but timers are dumb and physics props don't think
public void OnRollerbombThink(int iEnt, int client)
{
	client = GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity");
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		int iMotor = GetEntPropEnt(iEnt, Prop_Data, "m_hMoveChild");
		
		float flEntPos[3];
		GetEntPropVector(iEnt, Prop_Data, "m_vecAbsOrigin", flEntPos);
		
		float flDirection[3];
		GetClientEyeAngles(client, flDirection);
//		flDirection[2] = 0.0;
//		
//		NormalizeVector(flDirection, flDirection);
//		
		float flRight[3], flForward[3];
//		GetVectorVectors(flDirection, flRight, NULL_VECTOR);
		GetAngleVectors(flDirection, flForward, flRight, NULL_VECTOR);
		
		NegateVector(flRight);
		
		SetEntPropVector(iMotor, Prop_Data, "m_axis", flRight);
		
		AcceptEntityInput(iMotor, "Deactivate");
		AcceptEntityInput(iMotor, "Activate");
		
		bool attackDown = (GetClientButtons(client) & IN_ATTACK) != 0;
		bool shouldAttack = attackDown & !RB_AttackDown[client];
		RB_AttackDown[client] = attackDown;
		
		if(shouldAttack && !RB_Attacked[client])
		{
			RB_Attacked[client] = true;

			SetEntityModel(iEnt, "models/roller_spikes.mdl");
			switch(GetRandomInt(1, 3))
			{
				case 1: EmitSoundToAll("npc/roller/mine/rmine_blades_out1.wav", iEnt, _, _, _, _, GetRandomInt(90, 110));
				case 2: EmitSoundToAll("npc/roller/mine/rmine_blades_out2.wav", iEnt, _, _, _, _, GetRandomInt(90, 110));
				case 3: EmitSoundToAll("npc/roller/mine/rmine_blades_out3.wav", iEnt, _, _, _, _, GetRandomInt(90, 110));
			}

			EmitSoundToAll("npc/roller/mine/rmine_explode_shock1.wav", iEnt, _, _, _, _, GetRandomInt(100, 120));
			float impulse[3];
			impulse[0] = flForward[0];impulse[1] = flForward[1];
			impulse[2] = 0.75;
			NormalizeVector(impulse, impulse);
			ScaleVector(impulse, 600.0);

			TeleportEntity(iEnt, NULL_VECTOR, NULL_VECTOR, impulse);
			
			CreateTimer(0.5, Timer_BombExplode, EntIndexToEntRef(iEnt), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		bool JumpDown = (GetClientButtons(client) & IN_JUMP) != 0;
		bool shouldJump = JumpDown & !RB_JumpDown[client];
		RB_JumpDown[client] = JumpDown;

		if (shouldJump && (GetEngineTime() > NextJumpTime[client]))
		{
			NextJumpTime[client] = GetEngineTime() + 1.0;
			float impulse[3];
//			impulse[0] = flDirection[0]*300.0; impulse[1] = flDirection[1]*300.0;
//			impulse[2] = 467.0;
			impulse[0] = flForward[0];impulse[1] = flForward[1];
			impulse[2] = 1.45;
			ScaleVector(impulse, 300.0);
			TeleportEntity(iEnt, NULL_VECTOR, NULL_VECTOR, impulse);
			
		}

		if(GetClientButtons(client) & IN_ATTACK2)
		{
			TR_TraceRayFilter(flEntPos, flDirection, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, iEnt);

			if(!TR_DidHit(INVALID_HANDLE))
				return;

			int TRIndex = TR_GetEntityIndex(INVALID_HANDLE);
			
			static char classname[64];
			
			GetEdictClassname(TRIndex, classname, sizeof(classname));
			if(!StrEqual(classname, "worldspawn"))
				return;

			float fNormal[3];
			TR_GetPlaneNormal(INVALID_HANDLE, fNormal);
			GetVectorAngles(fNormal, fNormal);

			if(fNormal[0]>=30.0 && fNormal[0]<=330.0)
				return;
			if(fNormal[0] <= -30.0)
				return;

			float pos[3];
			TR_GetEndPosition(pos);
			float distance = GetVectorDistance(flEntPos, pos);

			if(distance >= 100.0)
				return;
			float velocity[3];
			velocity[0] = flForward[0]*4.0; velocity[1] = flForward[0]*4.0;
			velocity[2] = 320.0;
			TeleportEntity(iEnt, NULL_VECTOR, NULL_VECTOR, velocity);
		}
	}
	else
	{
		StopSound(iEnt, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
		StopSound(iEnt, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
		AcceptEntityInput(iEnt, "Kill");
	}
}

public Action Timer_HRCreate(Handle hTimer, int client)
{
	if(HR_Count[client] > 2)
		return Plugin_Stop;
	
	int g_iTouchEnt = CreateEntityByName("prop_dynamic");
	if(IsValidEntity(g_iTouchEnt))
	{
		if(!IsValidHandle(HR_Angles[client]) || !IsValidHandle(HR_Origin[client]))
			return Plugin_Stop;
		if((HR_Angles[client].Length <= 0) || (HR_Origin[client].Length <= 0))
			return Plugin_Stop;
		float angles[3], origin[3];

		HR_Angles[client].GetArray(0, angles);
		HR_Origin[client].GetArray(0, origin);

		HR_Rocketref[client][HR_Count[client]] = EntIndexToEntRef(g_iTouchEnt);
//		DispatchKeyValue(g_iTouchEnt, "targetname", targetname);
//		DispatchKeyValue(g_iTouchEnt, "model", "models/funnystuff/saxton_rockets.mdl");
		DispatchKeyValue(g_iTouchEnt, "model", "models/buildables/sentry3_rockets.mdl");
		DispatchKeyValueVector(g_iTouchEnt, "origin", origin);
		DispatchKeyValueVector(g_iTouchEnt, "angles", angles);
		DispatchKeyValueFloat(g_iTouchEnt, "modelscale", 10.0);
		DispatchKeyValue(g_iTouchEnt, "rendermode", "1");
		SetEntProp(g_iTouchEnt, Prop_Send, "m_usSolidFlags", 0x000C);
		SetEntProp(g_iTouchEnt, Prop_Data, "m_nSolidType", 3);
		SetEntProp(g_iTouchEnt, Prop_Send, "m_CollisionGroup", 1);
		DispatchSpawn(g_iTouchEnt);
		ActivateEntity(g_iTouchEnt);

		SetVariantString("idle");
		AcceptEntityInput(g_iTouchEnt, "SetAnimation");
		char tmp[64];
		Format(tmp, sizeof(tmp), "!caller,SetAnimation,idle,0.01,-1");
		DispatchKeyValue(g_iTouchEnt, "OnAnimationDone", tmp);

//		TeleportEntity(g_iTouchEnt, origin, angles, NULL_VECTOR);
		
		SetVariantString("OnUser1 !self:Kill::11.5:1");
		AcceptEntityInput(g_iTouchEnt, "AddOutput");
		AcceptEntityInput(g_iTouchEnt, "FireUser1");
		
		SetEntPropEnt(g_iTouchEnt, Prop_Send, "m_hOwnerEntity", client);
		
		SetEntityRenderColor(g_iTouchEnt, 255, 255, 255, 125);
		
		StopSound(g_iTouchEnt, SNDCHAN_AUTO, "npc/manhack/mh_engine_loop1.wav");
		EmitSoundToAll("npc/manhack/mh_engine_loop1.wav", g_iTouchEnt);
		
		if(HR_Moveref[client] != INVALID_ENT_REFERENCE)
		{
			SetVariantString("!activator");
			AcceptEntityInput(g_iTouchEnt, "SetParent", EntRefToEntIndex(HR_Moveref[client]));
		}
//		HookSingleEntityOutput(g_iTouchEnt, "OnAnimationDone", Callback_AnimEnd, false);
		SDKHook(g_iTouchEnt, SDKHook_Touch, OnHRStartTouch);
		SDKHook(g_iTouchEnt, SDKHook_EndTouch, OnHREndTouch);
	}
	
	HR_Count[client]++;
	if(HR_Count[client] > 2)
		return Plugin_Stop;

	return Plugin_Continue;
}

//public void Callback_AnimEnd(const char[] output, int caller, int activator, float delay) 
//{
//	SetVariantString("idle");
//	AcceptEntityInput(caller, "SetAnimation");
//}


public Action Timer_BombExplode(Handle hTimer, int entref)
{
	int ent = EntRefToEntIndex(entref);
	if(!IsValidEntity(ent))
		return Plugin_Stop;
	int client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		int explosion=CreateEntityByName("env_explosion");
//		DispatchKeyValueFloat(explosion, "DamageForce", 600.0);
		DispatchKeyValue(explosion, "targetname", "explosion");
		DispatchKeyValue(explosion, "spawnflags", "2048");
		DispatchKeyValue(explosion, "rendermode", "5");
		DispatchKeyValue(explosion, "fireballsprite", spirite);

		SetEntProp(explosion, Prop_Data, "m_iMagnitude", 602);
		SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", 322);

//		SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", 300, 4);
		SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", client);

		DispatchSpawn(explosion);
		
		float EntPos[3];
		GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", EntPos);
		
		TeleportEntity(explosion, EntPos, NULL_VECTOR, NULL_VECTOR);
		
		AcceptEntityInput(explosion, "Explode");
		AcceptEntityInput(explosion, "Kill");
		
		EndAbilities(client);
	}

	StopSound(ent, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
	StopSound(ent, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
	
	AcceptEntityInput(ent, "Kill");
	SetClientViewEntity(client, client);
	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");

	return Plugin_Continue;
}

public Action Hook_WeaponCanSwitch(int client, int weapon)
{
	if(g_bAbilityActive[client])
		return Plugin_Handled;
	return Plugin_Continue;
}
public Action Scout_Ontakedamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(attacker <= 0 && attacker > MaxClients)
		return Plugin_Continue;
	if(client == attacker)
		return Plugin_Continue;
//	if(g_bAbilityActive[client] && ((GetGameTime() - g_flLastSwingAt[client]) <= 0.2))
	if(g_bAbilityActive[client])
	{
		float flAng[3], flForward[3], flFwdScaled[3], vecToTarget[3], flDot, flPos[3];
		GetClientEyeAngles(client, flAng);
		GetAngleVectors(flAng, flForward, NULL_VECTOR, NULL_VECTOR);
		flFwdScaled = flForward; ScaleVector(flFwdScaled, 64.0);
		AddVectors(WorldSpaceCenter(client), flFwdScaled, flPos);
		if((damagetype & DMG_CLUB) && (attacker == inflictor))
		{
			SubtractVectors(WorldSpaceCenter(attacker), WorldSpaceCenter(client), vecToTarget);
			NormalizeVector(vecToTarget, vecToTarget);
			flDot = GetVectorDotProduct(flForward, vecToTarget);
			if(flDot < 0.25)
				return Plugin_Continue;
			float next = GetGameTime() + 2.0;
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", next);
			SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", next);
			EmitSoundToAll("mvm/melee_impacts/bat_baseball_hit_robo01.wav", client);
//			int wep = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon")
//			if(IsValidEntity(wep))
//				SDKCall(hSendWeaponAnim, wep, 1258);
//			SDKCall(hPlaySpecificSequence, client, "stun_swing")

			return Plugin_Handled;
		}
		else if(damagetype & DMG_BULLET)	//2232322 sentry damagetype
		{
			SubtractVectors(WorldSpaceCenter(attacker), WorldSpaceCenter(client), vecToTarget);
			NormalizeVector(vecToTarget, vecToTarget);

			if(inflictor > MaxClients)
			{
				char sInflictor[32];
				GetEdictClassname(inflictor, sInflictor, sizeof(sInflictor));
				if(strcmp(sInflictor, "obj_sentrygun") == 0)
				{
					SubtractVectors(WorldSpaceCenter(inflictor), WorldSpaceCenter(client), vecToTarget);
					NormalizeVector(vecToTarget, vecToTarget);
				}
			}

			flDot = GetVectorDotProduct(flForward, vecToTarget);
			if(flDot < 0.25)
				return Plugin_Continue;
			if(TF2_GetClientTeam(client) == TFTeam_Red)
				FireBullet(client, flPos, flForward, damage, 9000.0, damagetype, "bullet_tracer_raygun_red");
			else
				FireBullet(client, flPos, flForward, damage, 9000.0, damagetype, "bullet_tracer_raygun_blue");
			EmitSoundToAll("mvm/melee_impacts/bat_baseball_hit_robo01.wav", client, _, _, _, 0.25);
//			int wep = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon")
//			if(IsValidEntity(wep))
//				SDKCall(hSendWeaponAnim, wep, 1258);
//			SDKCall(hPlaySpecificSequence, client, "stun_swing");
			return Plugin_Handled;
		}
		
		SubtractVectors(damagePosition, WorldSpaceCenter(client), vecToTarget);
		NormalizeVector(vecToTarget, vecToTarget);
		flDot = GetVectorDotProduct(flForward, vecToTarget);
		if (flDot > 0.25)
			return Plugin_Handled;

	}
	return Plugin_Continue;
}


public Action RB_Ontakedamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(attacker <= 0 && attacker > MaxClients)
		return Plugin_Continue;
	if(client == attacker)
		return Plugin_Continue;
	if(g_bAbilityActive[client])
	{
		EndAbilities(client);
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public void OnHRStartTouch(int entity, int victim)
{
	if(!IsValidClient(victim))
		return;

	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

	if(!IsValidClient(owner))
		return;
	if(owner == victim)
		return;
	if(TF2_GetClientTeam(owner) == TF2_GetClientTeam(victim))
		return;
	if(HR_NextTouchTickTime[owner] > GetEngineTime())
		return;
	HR_NextTouchTickTime[owner] += 0.17;
	SDKHooks_TakeDamage(victim, owner, owner, GetRandomFloat(25.0, 75.0), DMG_ENERGYBEAM | DMG_PREVENT_PHYSICS_FORCE);
	int red, green ,blue;
	red = GetRandomInt(0, 255); green = GetRandomInt(0, 255); blue = GetRandomInt(0, 255);
	SetEntityRenderColor(entity, red, green, blue, 200);
}

public void OnHREndTouch(int entity, int victim)
{
	if(!IsValidClient(victim))
		return;

	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

	if(!IsValidClient(owner))
		return;
	if(owner == victim)
		return;
	if(TF2_GetClientTeam(owner) == TF2_GetClientTeam(victim))
		return;

	SetEntityRenderColor(entity, 255, 255, 255, 125);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(buttons & IN_SCORE || IsFakeClient(client))
		return Plugin_Continue;	
	
	if(g_bIsMvM && TF2_GetClientTeam(client) == TFTeam_Blue)
		return Plugin_Continue;
	
	if(TF2_GetClientTeam(client) != TFTeam_Blue && TF2_GetClientTeam(client) != TFTeam_Red)
		return Plugin_Continue;

	int iDmg;
	TFClassType class = TF2_GetPlayerClass(client);
	switch(class)
	{
		case TFClass_Scout:		iDmg = DMG_SCOUT;
		case TFClass_Soldier:	iDmg = DMG_SOLDIER;
		case TFClass_Pyro:		iDmg = DMG_PYRO;
		case TFClass_DemoMan:	iDmg = DMG_DEMO;
		case TFClass_Heavy:		iDmg = DMG_HEAVY;
		case TFClass_Engineer:	iDmg = DMG_ENGINEER;
		case TFClass_Medic:		iDmg = DMG_MEDIC;
		case TFClass_Sniper:	iDmg = DMG_SNIPER;
		case TFClass_Spy:		iDmg = DMG_SPY;
	}
	
	if(class == TFClass_Scout)
	{
		if(g_bAbilityActive[client])
		{
			
			if(g_flAbilityTime[client] > GetGameTime())	//Ability is active
			{
//				if(g_flLastSwingAt[client] - GetGameTime() >= 0.15)
//					SDKCall(hPlaySpecificSequence, client, "ACT_MP_ATTACK_STAND_MELEE_SECONDARY");
//				g_flLastSwingAt[client] = GetGameTime();
				

				float flPos[3], flAng[3], flForward[3], flFwdScaled[3];
				GetClientEyeAngles(client, flAng);
				GetAngleVectors(flAng, flForward, NULL_VECTOR, NULL_VECTOR);
				flFwdScaled = flForward;
				ScaleVector(flFwdScaled, 64.0);
				AddVectors(WorldSpaceCenter(client), flFwdScaled, flPos);

				int ent = -1;
				while((ent = SDKCall(hFindEntityInSphere, ent, flPos, 80.0, Address_Null)) != -1)
				{
					if(ent <= MaxClients)
						continue;

					if (!HasEntProp(ent, Prop_Send, "m_iDeflected"))
						continue;

					char cls[32];
					GetEntityClassname(ent, cls, sizeof(cls));
					if (strncmp(cls, "tf_proj", 7, false))
						continue;
						
					if(GetEntProp(ent, Prop_Send, "m_nForceBone") == 44)
						continue;

					float vecToTarget[3];
					SubtractVectors(WorldSpaceCenter(ent), WorldSpaceCenter(client), vecToTarget);
					NormalizeVector(vecToTarget, vecToTarget);
					float flDot = GetVectorDotProduct(flForward, vecToTarget);
					if (flDot < 0.25)
						continue;

					TR_TraceRayFilter(WorldSpaceCenter(client), WorldSpaceCenter(ent), MASK_SOLID, RayType_EndPoint, TheTrace, client);
				
					if (!TR_DidHit() || TR_GetEntityIndex() == ent)
					{
//						int wep = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon")
//						if(IsValidEntity(wep))
//							SDKCall(hSendWeaponAnim, wep, 1258);
//						SDKCall(hPlaySpecificSequence, client, "stun_swing");


						float vecVel[3];
						vecVel = GetVelocity(ent);
						float speed = GetVectorLength(vecVel);
						flFwdScaled = flForward;
						ScaleVector(flFwdScaled, speed);
						ScaleVector(flFwdScaled, 1.15);	// To be fair you are SWINGING a bat, so velocity should go up, right?
																	// Or down if you want that

						EmitSoundToAll("mvm/melee_impacts/bat_baseball_hit_robo01.wav", client);

						TeleportEntity(ent, NULL_VECTOR, flAng, flFwdScaled);
						SetEntProp(ent, Prop_Send, "m_nForceBone", 44);

						SetEntProp(ent, Prop_Send, "m_iDeflected", GetEntProp(ent, Prop_Send, "m_iDeflected")+1);
//						char classname[32];
//						GetEntityClassname(ent, classname, sizeof(classname));

//						if (!StrEqual(classname, "tf_projectile_pipe_remote", false))	// Shouldn't own sticky bombs

						int team = GetClientTeam(client);
						if(team != GetEntProp(ent, Prop_Send, "m_iTeamNum"))
						{
							if (HasEntProp(ent, Prop_Send, "m_hDeflectOwner"))
								SetEntPropEnt(ent, Prop_Send, "m_hDeflectOwner", client);
							if (HasEntProp(ent, Prop_Send, "m_hLauncher"))
								SetEntPropEnt(ent, Prop_Send, "m_hLauncher", client);
							if (HasEntProp(ent, Prop_Send, "m_hThrower"))
								SetEntPropEnt(ent, Prop_Send, "m_hThrower", client);		// ONE of these HAS to work
							SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
							SetEntProp(ent, Prop_Send, "m_iTeamNum", team);
							SetEntProp(ent, Prop_Send, "m_nSkin", team-2);
						}
					}
				}

			}
		}
	
/*		if(!g_bAbilityActive[client])
		{
			if(g_hPositions[client] == null)
			{
				g_hPositions[client] = new ArrayList(3);
				g_hAngles[client] = new ArrayList(3);
				g_hHealthPoints[client] = new ArrayList(1);
			}
			else
			{
				float flPos[3], flAng[3], flLastPos[3];
				GetClientAbsOrigin(client, flPos);
				GetClientEyeAngles(client, flAng);
				
				int iLength = g_hPositions[client].Length;
				
				if(iLength > 0)
				{
					g_hPositions[client].GetArray(iLength - 1, flLastPos);
				}
				
				if(g_hPositions[client].Length < 100)
				{
					if(GetVectorDistance(flPos, flLastPos) >= 10.0)
					{
						g_hPositions[client].PushArray(flPos);
						g_hAngles[client].PushArray(flAng);
						g_hHealthPoints[client].Push(GetEntProp(client, Prop_Send, "m_iHealth"));
					}
				}
				else
				{
					g_hPositions[client].Erase(0);
					g_hAngles[client].Erase(0);
					g_hHealthPoints[client].Erase(0);
				}
				
			//	PrintCenterText(client, "Pushed %f %f %f\nLastPos %f %f %f\nSize %i", flPos[0], flPos[1], flPos[2], flLastPos[0], flLastPos[1], flLastPos[2], iLength);
			}
		}
		else
		{
		
			if(g_hPositions[client] != null)
			{
				float flPos[3];
				GetClientAbsOrigin(client, flPos);
			
				for(int i = 0; i < g_hPositions[client].Length; i++)
				{
					float flLastPos[3], flAng[3];
					g_hPositions[client].GetArray(i, flLastPos);
					g_hAngles[client].GetArray(i, flAng);
					
					float flVecTo[3];
					MakeVectorFromPoints(flPos, flLastPos, flVecTo);
					NormalizeVector(flVecTo, flVecTo);
					ScaleVector(flVecTo, 600.0);
					
					TeleportEntity(client, NULL_VECTOR, flAng, flVecTo);
					
					if(GetVectorDistance(flPos, flLastPos) <= 32.0)
					{
					//	TE_SetupBeamPoints(flPos, flLastPos, g_iPathLaserModelIndex, g_iPathLaserModelIndex, 0, 30, 10.0, 2.0, 2.0, 2, 0.0, {255, 0, 255, 255}, 30);
					//	TE_SendToAll();
					
						SetEntProp(client, Prop_Send, "m_iHealth", g_hHealthPoints[client].Get(i));
						
						g_hPositions[client].Erase(i);
						g_hAngles[client].Erase(i);
						g_hHealthPoints[client].Erase(i);
					}
				}
				
				if(g_hPositions[client].Length <= 0)
				{
					EndAbilities(client);
				}
			}
		}*/
	}
	
	
	
	float flPercentage = g_iDamageDone[client] / float(iDmg) * 100;
		
	if(flPercentage > 100.0) 
		flPercentage = 100.0;
							
	if(g_bAbilityActive[client])
	{
		if(g_flAbilityTime[client] >= (GetGameTime() + 1.0))	//Ability is active
		{
			SetHudTextParams(0.55, -1.0, 0.1, 255, 255, 0, 0, 0, 0.0, 0.0, 0.0);
			ShowHudText(client, -1, "[%.0fs]", g_flAbilityTime[client] - GetGameTime());
		
			switch(class)
			{
			
/*				case TFClass_Sniper:
				{
					int iGrapple = GetPlayerWeaponSlot(client, view_as<int>(TFWeaponSlot_PDA));
					if(IsValidEntity(iGrapple))
					{
						char strClass[64];
						GetEntityClassname(iGrapple, strClass, sizeof(strClass));
						if(StrEqual(strClass, "tf_weapon_grapplinghook"))
						{
							int iProjectile = GetEntPropEnt(iGrapple, Prop_Send, "m_hProjectile");
							if(g_bGrappling[client] && !IsValidEntity(iProjectile))
							{
								EndAbilities(client);
							}
							
							if(GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon") == iGrapple)
							{
								g_bGrappling[client] = true;
							
								buttons |= IN_ATTACK;
								return Plugin_Changed;
							}
							
							if(TF2_IsPlayerInCondition(client, TFCond_Dazed))
								EndAbilities(client);
						}
					}
				}*/
				case TFClass_Engineer:
				{
					int iMetal = GetEntProp(client, Prop_Data, "m_iAmmo", 4, 3);
					if(iMetal < 200)
						SetEntProp(client, Prop_Data, "m_iAmmo", 200, 4, 3);
				}
				case TFClass_Spy:
				{
					int iTarget = FindTargetInViewCone(client, 1250.0, 20.0);

					if(iTarget != -1 && g_iTarget[client] == iTarget)
					{
						if(g_flLockOnTime[client] <= GetGameTime())
						{
							if(!g_bLocked[client])
							{
								EmitSoundToAll("misc/halloween/duck_pickup_pos_01.wav", client);
								g_bLocked[client] = true;
							}
							
							SetHudTextParams(0.55, 0.55, 0.1, 0, 255, 0, 0, 0, 0.0, 0.0, 0.0);
							ShowHudText(client, -1, "[已锁定: %N]", iTarget);
						}
						else
						{
							SetHudTextParams(0.55, 0.55, 0.1, 255, 0, 0, 0, 0, 0.0, 0.0, 0.0);
							ShowHudText(client, -1, "[锁定中: %N]", iTarget);
						}
					}
					else
					{
						g_iTarget[client] = iTarget;
						g_flLockOnTime[client] = GetGameTime() + 1.0;
						
						if(iTarget == -1 && g_bLocked[client])
						{
							EmitSoundToAll("misc/halloween/duck_pickup_neg_01.wav", client);
						
							g_bLocked[client] = false;
						}
					}
				}
			}
		}
		else	//Ability ended, remove ability things
		{
			if(g_bAbilityActive[client])
				EndAbilities(client);
		}
	}
	else
	{
		if(g_bDisabledUlt[client])
			return Plugin_Continue;
	
		char strProgressBar[64];

		if(g_OncePerRound && g_AbilityUsed[client])
		{
			Format(strProgressBar, sizeof(strProgressBar), "(本回合已使用)", strProgressBar);
			SetHudTextParams(-1.0, 1.0, 0.1, 51, 255, 255, 0, 0, 0.0, 0.0, 0.0);
			ShowSyncHudText(client, g_hHudInfo, "%s", strProgressBar);
		}
		else
		{
			if(flPercentage == 100.0)
			{
				switch(class)
				{
//					case TFClass_Scout:		Format(strProgressBar, sizeof(strProgressBar), "时间回溯[回溯到之前数秒的位置]");
					case TFClass_Scout:		Format(strProgressBar, sizeof(strProgressBar), "弹反");
					case TFClass_Engineer:	Format(strProgressBar, sizeof(strProgressBar), "融火核心[增加射速|无限金属]");
					case TFClass_Medic:		
					{
						float flPos[3];
						GetClientAbsOrigin(client, flPos);
					
						int iReviveCount = 0;
					
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && !IsPlayerAlive(i) && TF2_GetClientTeam(i) == TF2_GetClientTeam(client))
							{
								float flDistance = GetVectorDistance(flPos, flDeathPos[i]);
								if(flDistance <= 400.0)
								{
									iReviveCount++;
								}
							}
						}
						
						if(iReviveCount > 0)
						{
							SetHudTextParams(-1.0, 0.25, 0.1, 255, 0, 0, 0, 0, 0.0, 0.0, 0.0);
							ShowHudText(client, -1, "(☠x%i)\n队友死亡,3复活数", iReviveCount);
						}
						
						Format(strProgressBar, sizeof(strProgressBar), "英雄不朽[复活400Hu内随机三人]");
					}
					case TFClass_Heavy:		Format(strProgressBar, sizeof(strProgressBar), "粒子屏障[开启护盾与怒气击退]");
					case TFClass_Pyro:		Format(strProgressBar, sizeof(strProgressBar), "重力喷涌[投掷斥力重力井]");
					case TFClass_DemoMan:	Format(strProgressBar, sizeof(strProgressBar), "炸弹滚雷[鼠标控制|左键引爆|右键爬墙|空格跳]");
					case TFClass_Spy:		Format(strProgressBar, sizeof(strProgressBar), "午时已到[锁定完成后射击]");			//TODO: shoots every enemy in his line of sight. The weaker his targets are, the faster he’ll line up a killshot.
					case TFClass_Sniper:	Format(strProgressBar, sizeof(strProgressBar), "旋转火箭[？]");
					case TFClass_Soldier:	Format(strProgressBar, sizeof(strProgressBar), "天降正义[火箭弹幕]");
					default:				Format(strProgressBar, sizeof(strProgressBar), "Not implemented");
				}
				

				Format(strProgressBar, sizeof(strProgressBar), "%s\n[按魔法键]", strProgressBar);
			}
			else
			{
				for(int i = 0; i < flPercentage / 5; i++)
					Format(strProgressBar, sizeof(strProgressBar), "%s█", strProgressBar);
			}
		
			if(g_bIsMvM)
			{
				if(class == TFClass_Engineer)
					SetHudTextParams(0.17, 0.04, 0.1, 51, 255, 255, 0, 0, 0.0, 0.0, 0.0);
				else
					SetHudTextParams(0.04, 0.04, 0.1, 51, 255, 255, 0, 0, 0.0, 0.0, 0.0);
			}
			else
				SetHudTextParams(-1.0, 1.0, 0.1, 51, 255, 255, 0, 0, 0.0, 0.0, 0.0);
			ShowSyncHudText(client, g_hHudInfo, "%.0f%%\n%s", flPercentage, strProgressBar);
		}
	}
	
	return Plugin_Continue;	
}

void EndAbilities(int client)
{
	switch(TF2_GetPlayerClass(client))
	{
		case TFClass_Scout:
		{
//			SetVariantInt(0);
//			AcceptEntityInput(client, "SetForcedTauntCam");

			SDKUnhook(client, SDKHook_WeaponCanSwitchTo, Hook_WeaponCanSwitch);
			SDKUnhook(client, SDKHook_OnTakeDamage, Scout_Ontakedamage);
			
			SetEntityRenderMode(client, RENDER_NORMAL);
			SetEntityRenderColor(client, 255, 255, 255, 255);
			SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
			
			Address pAttrib = Address_Null;
			float flValue = 0.0;
			int iMelee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
			if(IsValidEntity(iMelee))
			{
				pAttrib = TF2Attrib_GetByName(iMelee, "hand scale");
				if(pAttrib != Address_Null)
				{
					flValue = TF2Attrib_GetValue(pAttrib);
					TF2Attrib_SetValue(pAttrib, flValue - 2.0);
					
					flValue = TF2Attrib_GetValue(pAttrib);
					if(flValue == 1.0)
					{
						TF2Attrib_RemoveByName(iMelee, "hand scale");
					}
					
					TF2Attrib_ClearCache(iMelee);
				}

			}
	
//			SendConVarValue(client, FindConVar("sv_client_predict"), "-1");
//			SetEntProp(client, Prop_Data, "m_bLagCompensation", true);
//			SetEntProp(client, Prop_Data, "m_bPredictWeapons", true);
		
/*			SetEntityMoveType(client, MOVETYPE_WALK);
			
			TF2_RemoveCondition(client, TFCond_Bonked);
			TF2_AddCondition(client, TFCond_MegaHeal, 1.0);
			TF2_SetFOV(client, GetEntProp(client, Prop_Send, "m_iDefaultFOV"), 1.0, 0);
			EmitSoundToAll("replay/rendercomplete.wav", client);
			EmitSoundToClient(client, "replay/rendercomplete.wav");
			
			if(g_hPositions[client] != null)
			{
				g_hPositions[client].Clear();
				g_hAngles[client].Clear();
				g_hHealthPoints[client].Clear();
				
				delete g_hPositions[client];
				delete g_hAngles[client];
				delete g_hHealthPoints[client];
			}*/
		}
		case TFClass_Engineer:
		{
			
			SetVariantString(strPlayerModel[client]);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
			
			StopSound(client, SNDCHAN_AUTO, ENGINE_LOOP);
			
			Address pAttrib = Address_Null;
			float flValue = 0.0;
				
			int iPrimary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
			if(IsValidEntity(iPrimary))
			{
				pAttrib = TF2Attrib_GetByName(iPrimary, "fire rate bonus HIDDEN");
				if(pAttrib != Address_Null)
				{
					flValue = TF2Attrib_GetValue(pAttrib);
					TF2Attrib_SetValue(pAttrib, flValue + 0.5);

					flValue = TF2Attrib_GetValue(pAttrib);
					if(flValue == 1.0)
					{
						TF2Attrib_RemoveByName(iPrimary, "fire rate bonus HIDDEN");
					}
					
					TF2Attrib_ClearCache(iPrimary);
				}
				
				pAttrib = TF2Attrib_GetByName(iPrimary, "reload time increased hidden");
				if(pAttrib != Address_Null)
				{
					flValue = TF2Attrib_GetValue(pAttrib);
					TF2Attrib_SetValue(pAttrib, flValue + 0.5);
					
					flValue = TF2Attrib_GetValue(pAttrib);
					if(flValue == 1.0)
					{
						TF2Attrib_RemoveByName(iPrimary, "reload time increased hidden");
					}
					
					TF2Attrib_ClearCache(iPrimary);
				}
			}
			
			int iSecondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
			if(IsValidEntity(iSecondary))
			{
				pAttrib = TF2Attrib_GetByName(iSecondary, "fire rate bonus HIDDEN");
				if(pAttrib != Address_Null)
				{
					flValue = TF2Attrib_GetValue(pAttrib);
					TF2Attrib_SetValue(pAttrib, flValue + 0.5);
					
					flValue = TF2Attrib_GetValue(pAttrib);
					if(flValue == 1.0)
					{
						TF2Attrib_RemoveByName(iSecondary, "fire rate bonus HIDDEN");
					}
					
					TF2Attrib_ClearCache(iSecondary);
				}

				pAttrib = TF2Attrib_GetByName(iSecondary, "reload time increased hidden");
				if(pAttrib != Address_Null)
				{
					flValue = TF2Attrib_GetValue(pAttrib);
					TF2Attrib_SetValue(pAttrib, flValue + 0.5);
					
					flValue = TF2Attrib_GetValue(pAttrib);
					if(flValue == 1.0)
					{
						TF2Attrib_RemoveByName(iSecondary, "reload time increased hidden");
					}
					
					TF2Attrib_ClearCache(iSecondary);
				}
			}
			
			int iMelee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
			if(IsValidEntity(iMelee))
			{
				pAttrib = TF2Attrib_GetByName(iMelee, "fire rate bonus HIDDEN");
				if(pAttrib != Address_Null)
				{
					flValue = TF2Attrib_GetValue(pAttrib);
					TF2Attrib_SetValue(pAttrib, flValue + 0.5);
					
					flValue = TF2Attrib_GetValue(pAttrib);
					if(flValue == 1.0)
					{
						TF2Attrib_RemoveByName(iMelee, "fire rate bonus HIDDEN");
					}
					
					TF2Attrib_ClearCache(iMelee);
				}
				
				pAttrib = TF2Attrib_GetByName(iMelee, "Construction rate increased");
				if(pAttrib != Address_Null)
				{
					flValue = TF2Attrib_GetValue(pAttrib);
					TF2Attrib_SetValue(pAttrib, flValue - 1.0);
					
					flValue = TF2Attrib_GetValue(pAttrib);
					if(flValue == 1.0)
					{
						TF2Attrib_RemoveByName(iMelee, "Construction rate increased");
					}
					
					TF2Attrib_ClearCache(iMelee);
				}
			}
		}
		
		case TFClass_DemoMan:
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
			
			TF2_RemoveCondition(client, TFCond_Bonked);
//			TF2_AddCondition(client, TFCond_MegaHeal, 0.01);
			SetClientViewEntity(client, client);
			SetVariantInt(0);
			AcceptEntityInput(client, "SetForcedTauntCam");
			SDKUnhook(client, SDKHook_OnTakeDamage, RB_Ontakedamage);
			
			if(RB_Ref[client] != INVALID_ENT_REFERENCE)
			{
				int RollerBomb = EntRefToEntIndex(RB_Ref[client]);
				
				char strName[64];
				GetEntPropString(RollerBomb, Prop_Data, "m_iName", strName, sizeof(strName));
				
				if(StrContains(strName, "RollerBomb") != -1)
				{
					if(GetEntPropEnt(RollerBomb, Prop_Send, "m_hOwnerEntity") == client)
					{
						StopSound(RollerBomb, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
						StopSound(RollerBomb, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
					
						AcceptEntityInput(RollerBomb, "Kill");
					}
				}
			}
			RB_Ref[client] = INVALID_ENT_REFERENCE;
			
/*			int index = -1;
			while((index = FindEntityByClassname(index, "prop_physics_multiplayer")) != -1)
			{
				if (IsValidEntity(index))
				{
					char strName[64];
					GetEntPropString(index, Prop_Data, "m_iName", strName, sizeof(strName));
					
					if(StrContains(strName, "RollerBomb") != -1)
					{
						if(GetEntPropEnt(index, Prop_Send, "m_hOwnerEntity") == client)
						{
//							StopSound(index, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
							StopSound(index, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
							StopSound(index, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
						
							AcceptEntityInput(index, "Kill");
						}
					}
				}
			}*/
		}
		
		case TFClass_Spy:
		{
			TF2_SetFOV(client, GetEntProp(client, Prop_Send, "m_iDefaultFOV"), 1.0, 0);
			
			EmitSoundToClient(client, "replay/cameracontrolmodeexited.wav");
			Overlay(client, "\"\"");
			
			EmitSoundToAll("replay/exitperformancemode.wav", client);
		}
		case TFClass_Soldier:
		{
			int index = -1;
			while ((index = FindEntityByClassname(index, "tf_point_weapon_mimic")) != -1)
				if (GetEntPropEnt(index, Prop_Send, "m_hOwnerEntity") == client)
					AcceptEntityInput(index, "Kill");
		
			SetEntityMoveType(client, MOVETYPE_WALK);
			Overlay(client, "\"\"");
		}
		
		case TFClass_Heavy:
		{
			if(FakeshieldRef[client] != INVALID_ENT_REFERENCE)
			{
				RemoveEntity(EntRefToEntIndex(FakeshieldRef[client]));
				FakeshieldRef[client] = INVALID_ENT_REFERENCE;
			}
		}
		
		case TFClass_Sniper:
		{		
			if(HR_Moveref[client] != INVALID_ENT_REFERENCE)
			{
				int entity = EntRefToEntIndex(HR_Moveref[client]);
				if(IsValidEntity(entity))
				{
					RemoveEntity(entity);
					HR_Moveref[client] = INVALID_ENT_REFERENCE;
				}
			}
			for(int i = 0; i < 3; i++)
			{
				if(HR_Rocketref[client][i] != INVALID_ENT_REFERENCE)
				{
					int entity = EntRefToEntIndex(HR_Rocketref[client][i]);
					if(IsValidEntity(entity))
					{
						StopSound(entity, SNDCHAN_AUTO, "npc/manhack/mh_engine_loop1.wav");
						RemoveEntity(entity);
						HR_Rocketref[client][i] = INVALID_ENT_REFERENCE;
					}
				}
			}

			if(HR_Angles[client] != INVALID_HANDLE && HR_Origin[client] != INVALID_HANDLE)
			{
				HR_Angles[client].Clear();
				HR_Origin[client].Clear();
				
				delete HR_Angles[client];
				delete HR_Origin[client];
			}

/*			int iGrapple = GetPlayerWeaponSlot(client, view_as<int>(TFWeaponSlot_PDA));
			if(IsValidEntity(iGrapple))
			{
				char strClass[64];
				GetEntityClassname(iGrapple, strClass, sizeof(strClass));
				if(StrEqual(strClass, "tf_weapon_grapplinghook"))
				{
					int iLastWep = GetEntPropEnt(client, Prop_Data, "m_hLastWeapon");
					if(IsValidEntity(iLastWep))
					{
						GetEntityClassname(iLastWep, strClass, sizeof(strClass));
						FakeClientCommand(client, "use %s", strClass);
						SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iLastWep);
					}
				
					TF2_RemoveWeaponSlot(client, TFWeaponSlot_PDA);
					TF2_RemoveWearable(client, iGrapple);
				}
			}
			
			g_bGrappling[client] = false;*/
		}
	}

	g_bAbilityActive[client] = false;
}

void OnGravitonThink(int iEnt)
{
	float flPos[3];
	GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", flPos);
	flPos[2] += 15.0;
	
	int iClient = GetEntPropEnt(iEnt, Prop_Data, "m_hThrower");
	
	if(GetEntProp(iEnt, Prop_Send, "m_bTouched") == 1)
	{
		if(GetEntProp(iEnt, Prop_Send, "m_bIsLive") == 0)
		{
			EmitSoundToAll("misc/halloween_eyeball/vortex_eyeball_moved.wav", iEnt);
			
			Particle_Create(iEnt, "eyeboss_tp_vortex", _, _, true);
			
			if(TF2_GetClientTeam(iClient) == TFTeam_Blue)
				Particle_Create(iEnt, "eyeboss_vortex_blue", _, _, true);
			else
				Particle_Create(iEnt, "eyeboss_vortex_red", _, _, true);
			
			SetEntProp(iEnt, Prop_Send, "m_bIsLive", 1);
		}
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				float flPlayer[3];
				GetClientAbsOrigin(i, flPlayer);
				
				float flDistance = GetVectorDistance(flPlayer, flPos);
				if(flDistance <= 275.0 && iClient != i && GetClientTeam(i) != GetClientTeam(iClient))
				{
					float flVelocity[3];
//					MakeVectorFromPoints(flPlayer, flPos, flVelocity);
					MakeVectorFromPoints(flPos, flPlayer, flVelocity); //push!
					ScaleVector(flVelocity, 400.0);
					
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, flVelocity);
//					SDKHooks_TakeDamage(i, iClient, iClient, GetRandomFloat(25.0, 88.0), DMG_GENERIC, _, flVelocity, flPos);
					SDKHooks_TakeDamage(i, iClient, iClient, GetRandomFloat(25.0, 88.0), DMG_GENERIC | DMG_PREVENT_PHYSICS_FORCE);
				}
			}
		}
		
		float flDetonateTime = GetEntPropFloat(iEnt, Prop_Data, "m_flDetonateTime");
		if(flDetonateTime <= GetGameTime())
		{
			SDKUnhook(iEnt, SDKHook_Think, OnGravitonThink);
	
			AcceptEntityInput(iEnt, "Kill");
		}
	}
}

int CreateLauncher(int client, float flPos[3], float flAng[3])
{
	int ent = CreateEntityByName("tf_point_weapon_mimic");
	DispatchKeyValueVector(ent, "origin", flPos);
	DispatchKeyValueVector(ent, "angles", flAng);
//	DispatchKeyValue(ent, "ModelOverride", "models/weapons/w_models/w_rocket_airstrike/w_rocket_airstrike.mdl");
	DispatchKeyValue(ent, "ModelOverride", "models/weapons/c_models/c_bread/c_bread_plainloaf.mdl");
//	DispatchKeyValue(ent, "ModelOverride", "models/buildables/sentry3_rockets.mdl");
	DispatchKeyValue(ent, "WeaponType", "0");
	DispatchKeyValue(ent, "SpeedMin", "1980");
	DispatchKeyValue(ent, "SpeedMax", "1980");
	DispatchKeyValue(ent, "Damage", "66");
	DispatchKeyValue(ent, "SplashRadius", "100");
	DispatchKeyValue(ent, "SpreadAngle", "5");
	DispatchKeyValue(ent, "spawnflags", "4");
//	DispatchKeyValue(ent, "Crits", "0");
	
	if(TF2_GetClientTeam(client) == TFTeam_Red)
		DispatchKeyValue(ent, "TeamNum", "2");
	
	DispatchSpawn(ent);

	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);

	CreateTimer(0.10, Timer_FireRocket, EntIndexToEntRef(ent), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	SetVariantString("OnUser1 !self:ClearParent::2.95:1");
	AcceptEntityInput(ent, "AddOutput");
	AcceptEntityInput(ent, "FireUser1");
	
	SetVariantString("OnUser2 !self:Kill::10.0:1");
	AcceptEntityInput(ent, "AddOutput");
	AcceptEntityInput(ent, "FireUser2");
	
	if(TF2_GetClientTeam(client) == TFTeam_Red)
	{
		SetVariantString("OnUser4 !activator,AddOutput,TeamNum 2");
		AcceptEntityInput(ent, "AddOutput");
	}
	
	return ent;
}

void FireRocket(int client)
{
	float flPos[3], flAng[3];
	GetClientEyeAngles(client, flAng);
	GetClientEyePosition(client, flPos);
	
	int l1 = CreateLauncher(client, flPos, flAng);
	SetEntProp(l1, Prop_Data, "m_nSimulationTick", 1);
	int l2 = CreateLauncher(client, flPos, flAng);
	SetEntProp(l2, Prop_Data, "m_nSimulationTick", 2);
} 

public Action Timer_FireRocket(Handle timer, int iRef)
{
	int ent = EntRefToEntIndex(iRef);
	if(ent != INVALID_ENT_REFERENCE)
	{
		int client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		int iLauncher = GetEntProp(ent, Prop_Data, "m_nSimulationTick");
		
		float flMaxs[3];
		GetEntPropVector(client, Prop_Send, "m_vecMaxs", flMaxs);
		
		float flPos[3], flAng[3], vLeft[3];
		GetClientEyeAngles(client, flAng);
		GetClientEyePosition(client, flPos);
		GetAngleVectors(flAng, NULL_VECTOR, vLeft, NULL_VECTOR);
		
		switch(iLauncher)
		{
			case 1:
			{
				flPos[0] += (vLeft[0] * -60);
				flPos[1] += (vLeft[1] * -60);
				flPos[2] += (vLeft[2] * -60);
			}
			case 2:
			{
				flPos[0] += (vLeft[0] * 60);
				flPos[1] += (vLeft[1] * 60);
				flPos[2] += (vLeft[2] * 60);
			}
		}
		
		flPos[2] -= GetRandomFloat(-(flMaxs[2] / 1.5), flMaxs[2] / 1.5);
		
		switch(GetRandomInt(0, 3))
		{
			case 0: DispatchKeyValue(ent, "Crits", "1");
			case 1, 2, 3: DispatchKeyValue(ent, "Crits", "0");
		}
//		SetEntProp(ent, Prop_Send, "m_bCrits", GetRandomInt(0, 3) ? false : true);
		
		DispatchKeyValueVector(ent, "origin", flPos);
		DispatchKeyValueVector(ent, "angles", flAng);
		
		switch(GetRandomInt(1, 3))
		{
			case 1: EmitSoundToAll("weapons/airstrike_fire_01.wav", ent);
			case 2: EmitSoundToAll("weapons/airstrike_fire_02.wav", ent);
			case 3: EmitSoundToAll("weapons/airstrike_fire_03.wav", ent);
		}
		
		AcceptEntityInput(ent, "FireOnce");
		
		return Plugin_Continue;
	}
	
	return Plugin_Stop;
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && g_bAbilityActive[client])
	{
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Spy:
			{
				if(weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
				{
					g_iDamageDone[client] = 0;
					g_flAbilityTime[client] = GetGameTime();
					
					if(g_bLocked[client] && g_iTarget[client] != -1)
					{
						SDKHooks_TakeDamage(g_iTarget[client], client, client, 370.3, DMG_BULLET|DMG_CRIT, weapon);
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public bool AimTargetFilter(int entity, int contentsMask, any iExclude)
{
    return !(entity == iExclude);
}

stock int FindTargetInViewCone(int iViewer, float max_distance = 0.0, float cone_angle = 180.0) // 180.0 could be for backstabs and stuff
{
	float flBestAngle = 180.0;
	int iBestTarget = -1;

	if (iViewer > 0 && iViewer <= MaxClients && IsClientInGame(iViewer) && IsPlayerAlive(iViewer))
	{
		if(max_distance < 0.0)
			max_distance = 0.0;
		if(cone_angle < 0.0)
			cone_angle = 0.0;
		
		float PlayerEyePos[3];
		float PlayerAimAngles[3];
		float PlayerToTargetVec[3];
		
		float OtherPlayerPos[3];
		GetClientEyePosition(iViewer,PlayerEyePos);
		GetClientEyeAngles(iViewer,PlayerAimAngles);
		
		float ThisAngle;
		float playerDistance;
		float PlayerAimVector[3];
		
		GetAngleVectors(PlayerAimAngles, PlayerAimVector, NULL_VECTOR, NULL_VECTOR);
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(i != iViewer && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != GetClientTeam(iViewer))
			{
				GetClientEyePosition(i, OtherPlayerPos);
			
				playerDistance = GetVectorDistance(PlayerEyePos, OtherPlayerPos);
				
				if(max_distance > 0.0 && playerDistance > max_distance)
				{
					continue;
				}
				
				SubtractVectors(OtherPlayerPos, PlayerEyePos, PlayerToTargetVec);
				
				ThisAngle = ArcCosine(GetVectorDotProduct(PlayerAimVector,PlayerToTargetVec) / (GetVectorLength(PlayerAimVector) * GetVectorLength(PlayerToTargetVec)));
				ThisAngle = ThisAngle * 360 / 2 / FLOAT_PI;

				if(ThisAngle <= cone_angle)
				{
					if(ThisAngle < flBestAngle)
					{
						iBestTarget = i;
						flBestAngle = ThisAngle;
					}
				}
			}
		}
		
		if(iBestTarget != -1)
		{
			GetClientEyePosition(iBestTarget, OtherPlayerPos);
			
			TR_TraceRayFilter(PlayerEyePos, OtherPlayerPos, MASK_ALL,RayType_EndPoint, AimTargetFilter, iViewer);
			if(TR_DidHit())
			{
				int entity = TR_GetEntityIndex();
				if(entity != iBestTarget)	//iBestTarget is not visible, remove target.
				{
					iBestTarget = -1;
				}
			}
		}
	}
	
	return iBestTarget;
}

public Action NormalSoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	// Robot sounds for the robot team!
	if(entity >= 1 && entity <= MaxClients && IsClientInGame(entity) && g_bAbilityActive[entity] && TF2_GetPlayerClass(entity) == TFClass_Engineer && !TF2_IsPlayerInCondition(entity, TFCond_HalloweenGhostMode))
	{
		TFTeam team = TF2_GetClientTeam(entity);
		TFTeam teamDisguised = view_as<TFTeam>(GetEntProp(entity, Prop_Send, "m_nDisguiseTeam"));
		if((team == TFTeam_Blue && teamDisguised != TFTeam_Red) || teamDisguised == TFTeam_Blue)
		{
			TFClassType class = TF2_GetPlayerClass(entity);
			if(class == TFClass_Unknown) return Plugin_Continue;

			if(teamDisguised != TFTeam_Unassigned) 
				class = view_as<TFClassType>(GetEntProp(entity, Prop_Send, "m_nDisguiseClass"));

			// Hook footstep sounds
			if(StrContains(sample, "player/footsteps/", false) != -1 && !TF2_IsPlayerInCondition(entity, TFCond_Cloaked))
			{
				if(class != TFClass_Medic) EmitSoundToAll(g_strSoundRobotFootsteps[GetRandomInt(0, sizeof(g_strSoundRobotFootsteps)-1)], entity, _, _, _, 0.13, GetRandomInt(95, 100));
				return Plugin_Stop;
			}

			// Hook falldamage sounds
			if(strcmp(sample, "player/pl_fallpain.wav") == 0)
			{
				volume = 1.0;
				strcopy(sample, sizeof(sample), g_strSoundRobotFallDamage[GetRandomInt(0, sizeof(g_strSoundRobotFallDamage)-1)]);
				return Plugin_Changed;
			}

			// Hook voice lines
			if(StrContains(sample, "vo/", false) != -1 && StrContains(sample, "vo/announcer", false) == -1)
			{
				char strClassMvM[20];
				if(GetEntProp(entity, Prop_Send, "m_bIsMiniBoss") == 1 && class != TFClass_Sniper && class != TFClass_Engineer && class != TFClass_Medic && class != TFClass_Spy)
				{
					// Lookup miniboss sounds
					ReplaceString(sample, sizeof(sample), "vo/", "vo/mvm/mght/", false);
					Format(strClassMvM, sizeof(strClassMvM), "%s_mvm_m", g_strClassName[view_as<int>(class)]);
				}
				else
				{
					ReplaceString(sample, sizeof(sample), "vo/", "vo/mvm/norm/", false);
					Format(strClassMvM, sizeof(strClassMvM), "%s_mvm", g_strClassName[view_as<int>(class)]);
				}
				
				ReplaceString(sample, sizeof(sample), ".wav", ".mp3", false); // shouldn't need this anymore
				ReplaceString(sample, sizeof(sample), g_strClassName[view_as<int>(class)], strClassMvM);
				
				char strFileSound[PLATFORM_MAX_PATH];
				Format(strFileSound, sizeof(strFileSound), "sound/%s", sample);
				if(FileExists(strFileSound, true))
				{
					PrecacheSound(sample);
					return Plugin_Changed;
				}
			}
		}
	}

	return Plugin_Continue;
}

#if defined _FF2_included
public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(client > 0 && client <= MaxClients && FF2)
	{
		g_bDisabledUlt[client] = false;
		g_iDamageDone[client] = 0;


		if(FF2_GetBossIndex(client)!=-1)
		{
			g_bDisabledUlt[client] = true;
			CreateTimer(7.0 ,Timer_DisableUlt, client, TIMER_FLAG_NO_MAPCHANGE);
//			EndAbilities(client);
		}

	}
}


public Action Timer_DisableUlt(Handle hTimer, int client)
{
	if(g_bDisabledUlt[client])
		return Plugin_Continue;
	if(FF2_GetBossIndex(client)!=-1)
	{
		g_bDisabledUlt[client] = true;
	}
	return Plugin_Continue;
}
#endif

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int client; client<=MaxClients; client++)
	{
		g_AbilityUsed[client] = false;
		g_iDamageDone[client] = 0;
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int client; client<=MaxClients; client++)
	{
		g_iDamageDone[client] = 0;
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(client > 0 && client <= MaxClients)
	{
		GetClientAbsOrigin(client, flDeathPos[client]);
		GetClientEyeAngles(client, flDeathAng[client]);
		
		if(g_bAbilityActive[client])
			EndAbilities(client);
	}
}

public void Event_PlayerChangeClass(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(client > 0 && client <= MaxClients)
	{
		if(g_bAbilityActive[client])
			EndAbilities(client);
	}
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
//	int iHealth = event.GetInt("health");
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	int iDamageAmount = event.GetInt("damageamount");
	
	if(iAttacker > 0 && iAttacker <= MaxClients && iAttacker != iVictim && !g_bAbilityActive[iAttacker])
	{
		#if defined _FF2_included
		if(FF2 && FF2_GetBossIndex(iAttacker) != -1)
			return;
		#endif
		g_iDamageDone[iAttacker] += iDamageAmount;
		
	//	PrintCenterText(iAttacker, "iVictim %N\niHealth %i\niAttacker %N\niDamageAmount %i\nTotal Damage Done: %i", iVictim, iHealth, iAttacker, iDamageAmount, g_iDamageDone[iAttacker]);
	
		int healers[MAXPLAYERS + 1];
		int healerCount;
		for(int target; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && IsPlayerAlive(target) && (GetHealingTarget(target, true)==iAttacker))
			{
				healers[healerCount] = target;
				healerCount++;
			}
		}
		for(int target; target<healerCount; target++)
		{
			if(IsValidClient(healers[target]) && IsPlayerAlive(healers[target]))
			{
					g_iDamageDone[healers[target]] += iDamageAmount/3;
			}
		}
	}
}

public void Event_NPCHurt(Event event, const char[] name, bool dontBroadcast)
{
/*	Server event "npc_hurt", Tick 44860:
	- "entindex" = "457"
	- "health" = "6274"
	- "attacker_player" = "68"
	- "weaponid" = "25"
	- "damageamount" = "6"
	- "crit" = "0"
	- "boss" = "0"*/
	
	int iAttacker = GetClientOfUserId(event.GetInt("attacker_player"));
	int iDmg = event.GetInt("damageamount");
	
	if(iAttacker > 0 && iAttacker <= MaxClients && IsClientInGame(iAttacker) && !g_bAbilityActive[iAttacker])
	{
		g_iDamageDone[iAttacker] += iDmg;
	}
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	return (entity != data);
}

stock void TF2_SetFOV(int client, int DefaultFov, float FOVRate, int fov)
{

	SetEntProp(client, Prop_Send, "m_iFOV", fov);
	SetEntPropFloat(client, Prop_Send, "m_flFOVRate", FOVRate);
/*
//	char temp[16];
//	GetClientInfo(client, "fov_desired", temp, sizeof(temp));
//	int DefaultFov = StringToInt(temp);
	SetFovAt[client] = GetEngineTime();

	int iFov = GetEntProp(client, Prop_Send, "m_iFOV");
	if(!fov)
//		fov = DefaultFov;
		SetEntProp(client, Prop_Send, "m_iFOV", 0);
	if(fov < iFov)
	{
		FovPerTick[client] = view_as<int>((iFov - fov) / (1.0 / FovTickTime));
		FovDecrease[client] = true;
		DesFov[client] = fov;
		SDKHook(client, SDKHook_PreThink, OnPreThink);

	}
	else if(fov > iFov)
	{
		FovPerTick[client] = view_as<int>((fov - iFov) / (1.0 / FovTickTime));
		FovDecrease[client] = false;
		DesFov[client] = fov;
		SDKHook(client, SDKHook_PreThink, OnPreThink);
	}
	else if(fov == iFov)
		return;
*/
}

/*public void OnPreThink(int client)
{
	float curTime = GetEngineTime();
	float deltaTime = (curTime - SetFovAt[client]) + FovTickTime;
	
	int iFov = GetEntProp(client, Prop_Send, "m_iFOV");
	
	if(deltaTime >= FovTickTime)
	{
		if(FovDecrease[client])
			SetEntProp(client, Prop_Send, "m_iFOV", iFov + FovPerTick[client]);
		else
			SetEntProp(client, Prop_Send, "m_iFOV", iFov - FovPerTick[client]);
		SetFovAt[client] = curTime + FovTickTime;
	}
	
	if(FovDecrease[client])
	{
		if(iFov <= DesFov[client])
		{
			SetEntProp(client, Prop_Send, "m_iFOV", DesFov[client]);
			SDKUnhook(client, SDKHook_PreThink, OnPreThink);
			return;
		}
	}
	else
	{
		if(iFov >= DesFov[client])
		{
			SetEntProp(client, Prop_Send, "m_iFOV", DesFov[client]);
			SDKUnhook(client, SDKHook_PreThink, OnPreThink);
			return;
		}
	}

//	if (curTime >= SetFovAt[client])
//		SetFovAt[client] = curTime + FovTickTime;
}*/

public bool TraceWallsOnly(int entity, int contentsMask)
{
	return false;
}

public bool TheTrace(int ent, int mask, any data)
{
	if (ent <= MaxClients)
		return false;

	char cls[32]; GetEntityClassname(ent, cls, sizeof(cls));
	if (StrContains(cls, "tf_projectile", false))
		return false;

	return true;
}

public MRESReturn DHook_UpdateShieldPosition(int shield)
{
	int owner = GetEntPropEnt(shield, Prop_Send, "m_hOwnerEntity");
	if (!IsValidEntity(owner))
		return MRES_Ignored;

	if((TF2_GetPlayerClass(owner) == TFClass_Heavy) && g_UpdatingPos[owner])
		return MRES_Supercede;

	g_UpdatingPos[owner] = true;
	return MRES_Ignored;
}

static void DHook_CreateDetour(GameData gamedata, const char[] name, DHookCallback preCallback = INVALID_FUNCTION, DHookCallback postCallback = INVALID_FUNCTION)
{
	Handle detour = DHookCreateFromConf(gamedata, name);
	if (!detour)
	{
		LogError("Failed to create detour: %s", name);
	}
	else
	{
		if (preCallback != INVALID_FUNCTION)
			if (!DHookEnableDetour(detour, false, preCallback))
				LogError("Failed to enable pre detour: %s", name);
		
		if (postCallback != INVALID_FUNCTION)
			if (!DHookEnableDetour(detour, true, postCallback))
				LogError("Failed to enable post detour: %s", name);
		
		delete detour;
	}
}

/*stock void CreateParticle(char[] particle, float pos[3])
{
	int tblidx = FindStringTable("ParticleEffectNames");
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;
	for(int i = 0; i < count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if(StrEqual(tmp, particle, false))
        {
            stridx = i;
            break;
        }
    }

	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", pos[0]);
	TE_WriteFloat("m_vecOrigin[1]", pos[1]);
	TE_WriteFloat("m_vecOrigin[2]", pos[2]);
	TE_WriteNum("m_iParticleSystemIndex", stridx);
	TE_WriteNum("entindex", -1);
	TE_WriteNum("m_iAttachType", 2);
	TE_SendToAll();
}*/

stock int Particle_Create(int iEntity, const char[] strParticleEffect, float flOffsetZ = 0.0, float flTimeExpire = 0.0, bool bParent = false)
{
	int iParticle = CreateEntityByName("info_particle_system");
	
	if(iParticle > MaxClients && IsValidEntity(iParticle))
	{
		float flPos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos);
		flPos[2] += flOffsetZ;
		
		TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(iParticle, "effect_name", strParticleEffect);
		DispatchSpawn(iParticle);
	
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "start");
		
		if(bParent)
		{
			SetVariantString("!activator");
			AcceptEntityInput(iParticle, "SetParent", iEntity);
		}
		
		if(flTimeExpire > 0.0)
		{
			char addoutput[64];
			Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1", flTimeExpire);
			SetVariantString(addoutput);
			AcceptEntityInput(iParticle, "AddOutput");
			AcceptEntityInput(iParticle, "FireUser1");
		}
		
		return iParticle;
	}
	
	return 0;
}

stock void Overlay(int client, char[] overlay) 
{
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT));
	ClientCommand(client, "r_screenoverlay %s", overlay);
}

stock void MeleeDare(int client)
{
	SetVariantString("weaponmode:melee");
	AcceptEntityInput(client, "AddContext");
	
	SetVariantString("crosshair_enemy:Yes");
	AcceptEntityInput(client, "AddContext");
	
	SetVariantString("TLK_PLAYER_BATTLECRY");
	AcceptEntityInput(client, "SpeakResponseConcept");
	    
	AcceptEntityInput(client, "ClearContext");
}

stock int GetHealingTarget(int client, bool checkgun=false)
{
	int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(!checkgun)
	{
		if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");

		return -1;
	}

	if(IsValidEntity(medigun))
	{
		static char classname[64];
		GetEntityClassname(medigun, classname, sizeof(classname));
		if(StrEqual(classname, "tf_weapon_medigun", false))
		{
			if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
				return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
		}
	}
	return -1;
}

//stock void FireBullet(int m_pAttacker, int iWeapon, float m_vecSrc[3], float m_vecDirShooting[3], float m_flDamage, float m_flDistance, int nDamageType, const char[] tracerEffect)
stock void FireBullet(int m_pAttacker, float m_vecSrc[3], float m_vecDirShooting[3], float m_flDamage, float m_flDistance, int nDamageType, const char[] tracerEffect)
{
	float vecEnd[3];
	vecEnd[0] = m_vecSrc[0] + m_vecDirShooting[0] * m_flDistance; 
	vecEnd[1] = m_vecSrc[1] + m_vecDirShooting[1] * m_flDistance;
	vecEnd[2] = m_vecSrc[2] + m_vecDirShooting[2] * m_flDistance;
	
	// Fire a bullet (ignoring the shooter).
	Handle trace = TR_TraceRayFilterEx(m_vecSrc, vecEnd, ( MASK_SOLID | CONTENTS_HITBOX ), RayType_EndPoint, WorldOnly, m_pAttacker);

	if ( TR_GetFraction(trace) < 1.0 )
	{
		// Verify we have an entity at the point of impact.
		if(TR_GetEntityIndex(trace) == -1)
		{
			delete trace;
			return;
		}
		
		float endpos[3];    TR_GetEndPosition(endpos, trace);
		
		if(TR_GetEntityIndex(trace) <= 0 || TR_GetEntityIndex(trace) > MaxClients)
		{
			float vecNormal[3];	TR_GetPlaneNormal(trace, vecNormal);
			GetVectorAngles(vecNormal, vecNormal);
			CreateParticle("impact_concrete", endpos, vecNormal);
		}
		
		// Regular impact effects.
		char effect[PLATFORM_MAX_PATH];
		Format(effect, PLATFORM_MAX_PATH, "%s", tracerEffect);
		
		if (tracerEffect[0])
		{
			if ( nDamageType & DMG_CRIT )
			{
				Format( effect, sizeof(effect), "%s_crit", tracerEffect );
			}

//			float origin[3], angles[3];
//			view_as<BaseNPC>(iWeapon).GetAttachment("muzzle", origin, angles);
//			ShootLaser(iWeapon, effect, origin, endpos, false );
//			float origin[3];
			ShootLaser(m_pAttacker, effect, m_vecDirShooting, m_vecSrc, endpos, false );
		}
		
	//	TE_SetupBeamPoints(m_vecSrc, endpos, g_iPathLaserModelIndex, g_iPathLaserModelIndex, 0, 30, 0.1, 0.1, 0.1, 5, 0.0, view_as<int>({255, 0, 255, 255}), 30);
	//	TE_SendToAll();
		
		SDKHooks_TakeDamage(TR_GetEntityIndex(trace), m_pAttacker, m_pAttacker, m_flDamage, nDamageType, -1, CalculateBulletDamageForce(m_vecDirShooting, 1.0), endpos);
	}
	
	delete trace;
}

public bool WorldOnly(int entity, int contentsMask, any iExclude)
{
	char class[64];
	GetEntityClassname(entity, class, sizeof(class));
	
	if(StrEqual(class, "func_respawnroomvisualizer"))
	{
		return false;
	}
	else if(StrContains(class, "tf_projectile_", false) != -1)
	{
		return false;
	}
	
	return !(entity == iExclude);
}

stock void CreateParticle(char[] particle, float pos[3], float ang[3])
{
	int tblidx = FindStringTable("ParticleEffectNames");
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;
	
	for(int i = 0; i < count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if(StrEqual(tmp, particle, false))
        {
            stridx = i;
            break;
        }
    }
    
	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", pos[0]);
	TE_WriteFloat("m_vecOrigin[1]", pos[1]);
	TE_WriteFloat("m_vecOrigin[2]", pos[2]);
	TE_WriteVector("m_vecAngles", ang);
	TE_WriteNum("m_iParticleSystemIndex", stridx);
	TE_WriteNum("entindex", -1);
	TE_WriteNum("m_iAttachType", 5);	//Dont associate with any entity
	TE_SendToAll();
}

stock void ShootLaser(int weapon, const char[] strParticle, float flAng[3], float flStartPos[3], float flEndPos[3], bool bResetParticles = false)
{
	int tblidx = FindStringTable("ParticleEffectNames");
	if (tblidx == INVALID_STRING_TABLE) 
	{
		LogError("Could not find string table: ParticleEffectNames");
		return;
	}
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;
	for (int i = 0; i < count; i++)
	{
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if (StrEqual(tmp, strParticle, false))
		{
			stridx = i;
			break;
		}
	}
	if (stridx == INVALID_STRING_INDEX)
	{
		LogError("Could not find particle: %s", strParticle);
		return;
	}

	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", flStartPos[0]);
	TE_WriteFloat("m_vecOrigin[1]", flStartPos[1]);
	TE_WriteFloat("m_vecOrigin[2]", flStartPos[2]);
	TE_WriteVector("m_vecAngles", flAng);
	TE_WriteNum("m_iParticleSystemIndex", stridx);
	TE_WriteNum("entindex", weapon);
	TE_WriteNum("m_iAttachType", 2);
	TE_WriteNum("m_iAttachmentPointIndex", 0);
	TE_WriteNum("m_bResetParticles", bResetParticles);    
	TE_WriteNum("m_bControlPoint1", 1);    
	TE_WriteNum("m_ControlPoint1.m_eParticleAttachment", 5);  
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[0]", flEndPos[0]);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[1]", flEndPos[1]);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[2]", flEndPos[2]);
	TE_SendToAll();
}

/*static DynamicHook DHooks_AddDynamicHook(GameData gamedata, const char[] name)
{
	DynamicHook hook = DynamicHook.FromConf(gamedata, name);
	if (!hook)
		LogError("Failed to create hook setup handle for %s", name);
	
	return hook;
}

static void DHooks_HookEntityInternal(DynamicHook hook, HookMode mode, int entity, DHookCallback callback)
{
	if (!hook)
		return;
	
	int hookid = hook.HookEntity(mode, entity, callback, DHookRemovalCB_OnHookRemoved);
	if (hookid != INVALID_HOOK_ID)
		g_dynamicHookIds.Push(hookid);
}

static void DHookRemovalCB_OnHookRemoved(int hookid)
{
	int index = g_dynamicHookIds.FindValue(hookid);
	if (index != -1)
		g_dynamicHookIds.Erase(index);
}*/

float[] CalculateBulletDamageForce( const float vecBulletDir[3], float flScale )
{
	float vecForce[3]; vecForce = vecBulletDir;
	NormalizeVector( vecForce, vecForce );
	ScaleVector(vecForce, FindConVar("phys_pushscale").FloatValue);
	ScaleVector(vecForce, flScale);
	return vecForce;
}

float[] GetVelocity(int entity)
{
	float vel[3], dummy[3];
	SDKCall(hGetVelocity, entity, vel, dummy);
	return vel;
}

float[] WorldSpaceCenter(int entity)
{
	float pos[3];
	if (hWorldSpaceCenter)
		SDKCall(hWorldSpaceCenter, entity, pos);
	else GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);	// If it doesn't exist then fall back to vecOrigin

	return pos;
}

stock bool IsValidClient(int client, bool replaycheck=true)
{
	if(client<1 || client>MaxClients)
		return false;

	if(!IsClientInGame(client))
		return false;

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
			return false;
	}
	return true;
}

stock float linearTween(float t, float b, float c, float d) 
{
	return c * t / d + b;
}

stock float fabs(float x)
{
	return x < 0 ? -x : x;
}

