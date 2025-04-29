// ---- Preprocessor -----------------------------------------------------------
#pragma semicolon 1 

// ---- Includes ---------------------------------------------------------------
#include <sourcemod>
#include <morecolors>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
#include <steamtools>
#include <tf2attributes>
#include <clientprefs>

// ---- Defines ----------------------------------------------------------------
#define DR_VERSION "0.2.1"
#define PLAYERCOND_SPYCLOAK (1<<4)
#define MAXGENERIC 25	//Used as a limit in the config file

#define TEAM_RED 2
#define TEAM_BLUE 3

#define DBD_UNDEF -1 //DBD = Don't Be Death
#define DBD_OFF 1
#define DBD_ON 2
#define DBD_THISMAP 3 // The cookie will never have this value
#define TIME_TO_ASK 30.0 //Delay between asking the client its preferences and it's connection/join.


// ---- Variables --------------------------------------------------------------
new bool:g_isDRmap = false;
new bool:g_onPreparation = false;
new g_timesplayed_asdeath[MAXPLAYERS+1];


//GenerealConfig
new bool:g_diablefalldamage;
new Float:g_runner_speed;
new Float:g_death_speed;

//Weapon-config
new bool:g_MeleeOnly;
new bool:g_MeleeRestricted;
new bool:g_RestrictAll;
new Handle:g_RestrictedWeps;
new bool:g_UseDefault;
new bool:g_UseAllClass;
new Handle:g_AllClassWeps;



// ---- Server's CVars Management ----------------------------------------------
new Handle:dr_queue;
new Handle:dr_unbalance;
new Handle:dr_autobalance;
new Handle:dr_firstblood;
new Handle:dr_scrambleauto;
new Handle:dr_airdash;
new Handle:dr_push;

new dr_queue_def = 0;
new dr_unbalance_def = 0;
new dr_autobalance_def = 0;
new dr_firstblood_def = 0;
new dr_scrambleauto_def = 0;
new dr_airdash_def = 0;
new dr_push_def = 0;


public OnPluginStart()
{
	//Cvars
	CreateConVar("sm_dr_version", DR_VERSION, "Death Run Redux Version.", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	
	//Creation of Tries
	g_RestrictedWeps = CreateTrie();
	g_AllClassWeps = CreateTrie();

	
	//Server's Cvars
	dr_queue = FindConVar("tf_arena_use_queue");
	dr_unbalance = FindConVar("mp_teams_unbalance_limit");
	dr_autobalance = FindConVar("mp_autoteambalance");
	dr_firstblood = FindConVar("tf_arena_first_blood");
	dr_scrambleauto = FindConVar("mp_scrambleteams_auto");
	dr_airdash = FindConVar("tf_scout_air_dash_count");
	dr_push = FindConVar("tf_avoidteammates_pushaway");

	//Hooks

	HookEvent("teamplay_round_start", OnPrepartionStart);
	HookEvent("arena_round_start", OnRoundStart); 
	HookEvent("post_inventory_application", OnPlayerInventory);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	
}

/* OnPluginEnd()
**
** When the plugin is unloaded. Here we reset all the cvars to their normal value.
** -------------------------------------------------------------------------- */
public OnPluginEnd()
{
	ResetCvars();
}

/* OnMapStart()
**
** Here we reset every global variable, and we check if the current map is a deathrun map.
** If it is a dr map, we get the cvars def. values and the we set up our own values.
** -------------------------------------------------------------------------- */
public OnMapStart()
{

	for(new i = 1; i <= MaxClients; i++)
			g_timesplayed_asdeath[i]=-1;
			
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	if (strncmp(mapname, "dr_", 3, false) == 0 || strncmp(mapname, "deathrun_", 9, false) == 0 || strncmp(mapname, "vsh_dr_", 6, false) == 0 || strncmp(mapname, "vsh_deathrun_", 6, false) == 0)
	{
		LogMessage("Deathrun map detected. Enabling Deathrun Gamemode.");
		g_isDRmap = true;
		Steam_SetGameDescription("DeathRun Redux");
		AddServerTag("deathrun");
//		for (new i = 1; i <= MaxClients; i++)
//		{
//			if (!AreClientCookiesCached(i))
//				continue;
//			OnClientCookiesCached(i);
//		}
		LoadConfigs();

	}
 	else
	{
		LogMessage("Current map is not a deathrun map. Disabling Deathrun Gamemode.");
		g_isDRmap = false;
		Steam_SetGameDescription("Team Fortress");	
		RemoveServerTag("deathrun");
	}
}

/* OnMapEnd()
**
** Here we reset the server's cvars to their default values.
** -------------------------------------------------------------------------- */
public OnMapEnd()
{
	ResetCvars();

}

/* LoadConfigs()
**
** Here we parse the data/deathrun/deathrun.cfg
** -------------------------------------------------------------------------- */
LoadConfigs()
{
	//--DEFAULT VALUES--
	//GenerealConfig
	g_diablefalldamage = false;
	g_runner_speed = 320.0;
	g_death_speed = 400.0;


	//Weapon-config
	g_MeleeOnly = true;
	g_MeleeRestricted = true;
	g_RestrictAll = true;
	ClearTrie(g_RestrictedWeps);
	g_UseDefault = true;
	g_UseAllClass = false;
	ClearTrie(g_AllClassWeps);

	
	decl String:mainfile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, mainfile, sizeof(mainfile), "data/deathrun/deathrun.cfg");
	
	if(!FileExists(mainfile))
	{
		SetFailState("Configuration file %s not found!", mainfile);
		return;
	}
	new Handle:hDR = CreateKeyValues("deathrun");
	if(!FileToKeyValues(hDR, mainfile))
	{
		SetFailState("Improper structure for configuration file %s!", mainfile);
		return;
	}
	if(KvJumpToKey(hDR,"default"))
	{
		g_diablefalldamage = bool:KvGetNum(hDR, "DisableFallDamage", _:g_diablefalldamage);

		if(KvJumpToKey(hDR,"speed"))
		{
			g_runner_speed = KvGetFloat(hDR,"runners",g_runner_speed);
			g_death_speed = KvGetFloat(hDR,"death",g_death_speed);
			KvGoBack(hDR);
		}
		

		KvGoBack(hDR);
	}
	
	
	KvRewind(hDR);
	if(KvJumpToKey(hDR,"weapons"))
	{
	
		g_MeleeOnly = bool:KvGetNum(hDR, "MeleeOnly", _:g_MeleeOnly);
		if(g_MeleeOnly)
		{
			g_MeleeRestricted = bool:KvGetNum(hDR, "RestrictedMelee",_:g_MeleeRestricted);
			if(g_MeleeRestricted)
			{
				KvJumpToKey(hDR,"MeleeRestriction");
				g_RestrictAll = bool:KvGetNum(hDR, "RestrictAll", _:g_RestrictAll);
				if(!g_RestrictAll)
				{
					KvJumpToKey(hDR,"RestrictedWeapons");
					new String:key[4], auxInt;
					for(new i=1; i<MAXGENERIC; i++)
					{
						IntToString(i, key, sizeof(key));
						auxInt = KvGetNum(hDR, key, -1);
						if(auxInt == -1)
						{
							break;
						}
						SetTrieValue(g_RestrictedWeps,key,auxInt);
					}
					KvGoBack(hDR);
				}
				g_UseDefault = bool:KvGetNum(hDR, "UseDefault", _:g_UseDefault);
				g_UseAllClass = bool:KvGetNum(hDR, "UseAllClass", _:g_UseAllClass);
				if(g_UseAllClass)
				{
					KvJumpToKey(hDR,"AllClassWeapons");
					new String:key[4], auxInt;
					for(new i=1; i<MAXGENERIC; i++)
					{
						IntToString(i, key, sizeof(key));
						auxInt = KvGetNum(hDR, key, -1);
						if(auxInt == -1)
						{
							break;
						}
						SetTrieValue(g_AllClassWeps,key,auxInt);
					}
					KvGoBack(hDR);
				}
				KvGoBack(hDR);
			}
			
		}
	}
	
	
	KvRewind(hDR);
	CloseHandle(hDR);
	
	decl String:mapfile[PLATFORM_MAX_PATH],String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	BuildPath(Path_SM, mapfile, sizeof(mapfile), "data/deathrun/maps/%s.cfg",mapname);
	if(FileExists(mapfile))
	{
		hDR = CreateKeyValues("drmap");
		if(!FileToKeyValues(hDR, mapfile))
		{
			SetFailState("Improper structure for configuration file %s!", mapfile);
			return;
		}
		
		g_diablefalldamage = bool:KvGetNum(hDR, "DisableFallDamage", _:g_diablefalldamage);

		if(KvJumpToKey(hDR,"speed"))
		{
			g_runner_speed = KvGetFloat(hDR,"runners",g_runner_speed);
			g_death_speed = KvGetFloat(hDR,"death",g_death_speed);
			
			KvGoBack(hDR);
		}
		KvRewind(hDR);
		CloseHandle(hDR);
	}

}

/* OnPrepartionStart()
**
** We setup the cvars again, balance the teams and we freeze the players.
** -------------------------------------------------------------------------- */
public Action:OnPrepartionStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_isDRmap)
	{
		g_onPreparation = true;
		
		//We force the cvars values needed every round (to override if any cvar was changed).
		SetupCvars();
		
		//We move the players to the corresponding team.

		
		//Players shouldn't move until the round starts
		for(new i = 1; i <= MaxClients; i++)
			if(IsClientInGame(i) && IsPlayerAlive(i))
				SetEntityMoveType(i, MOVETYPE_NONE);	


	}
}

/* OnRoundStart()
**
** We unfreeze every player.
** -------------------------------------------------------------------------- */
public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_isDRmap)
	{
		for(new i = 1; i <= MaxClients; i++)
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
					SetEntityMoveType(i, MOVETYPE_WALK);

			}
		g_onPreparation = false;
	}
}

/* TF2Items_OnGiveNamedItem_Post()
**
** Here we check for the demoshield and the sapper.
** -------------------------------------------------------------------------- */
public TF2Items_OnGiveNamedItem_Post(client, String:classname[], index, level, quality, ent)
{
	if(g_isDRmap && g_MeleeOnly)
	{
		if(StrEqual(classname,"tf_weapon_builder", false) || StrEqual(classname,"tf_wearable_demoshield", false))
			CreateTimer(0.1, Timer_RemoveWep, EntIndexToEntRef(ent));  
	}
}

/* Timer_RemoveWep()
**
** We kill the demoshield/sapper
** -------------------------------------------------------------------------- */
public Action:Timer_RemoveWep(Handle:timer, any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if( IsValidEntity(ent) && ent > MaxClients)
		AcceptEntityInput(ent, "Kill");
}  

/* OnPlayerInventory()
**
** Here we strip players weapons (if we have to).
** Also we give special melee weapons (again, if we have to).
** -------------------------------------------------------------------------- */
public Action:OnPlayerInventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_isDRmap)
	{
		if(g_MeleeOnly)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Grenade);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Building);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_PDA);
			
			
			if(g_MeleeRestricted)
			{
				new bool:replacewep = false;
				if(g_RestrictAll)
					replacewep=true;
				else
				{
					new wepEnt = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
					new wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex"); 
					new rwSize = GetTrieSize(g_RestrictedWeps);
					new String:key[4], auxIndex;
					for(new i = 1; i <= rwSize; i++)
					{
						IntToString(i,key,sizeof(key));
						if(GetTrieValue(g_RestrictedWeps,key,auxIndex))
							if(wepIndex == auxIndex)
								replacewep=true;
					}
				
				}
				if(replacewep)
				{
					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
					new weaponToUse = -1;
					if(g_UseAllClass)
					{
						new acwSize = GetTrieSize(g_AllClassWeps);
						new rndNum;
						if(g_UseDefault)
							rndNum = GetRandomInt(1,acwSize+1);
						else
							rndNum = GetRandomInt(1,acwSize);
						
						if(rndNum <= acwSize)
						{
							new String:key[4];
							IntToString(rndNum,key,sizeof(key));
							GetTrieValue(g_AllClassWeps,key,weaponToUse);
						}
						
					}
					new Handle:hItem = TF2Items_CreateItem(FORCE_GENERATION | OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES);
					
					//Here we give a melee to every class
					new TFClassType:iClass = TF2_GetPlayerClass(client);
					switch(iClass)
					{
						case TFClass_Scout:{
							TF2Items_SetClassname(hItem, "tf_weapon_bat");
							if(weaponToUse == -1)
								weaponToUse = 190;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Sniper:{
							TF2Items_SetClassname(hItem, "tf_weapon_club");
							if(weaponToUse == -1)
								weaponToUse = 190;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							TF2Items_SetItemIndex(hItem, 193);
							}
						case TFClass_Soldier:{
							TF2Items_SetClassname(hItem, "tf_weapon_shovel");
							if(weaponToUse == -1)
								weaponToUse = 196;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_DemoMan:{
							TF2Items_SetClassname(hItem, "tf_weapon_bottle");
							if(weaponToUse == -1)
								weaponToUse = 191;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Medic:{
							TF2Items_SetClassname(hItem, "tf_weapon_bonesaw");
							if(weaponToUse == -1)
								weaponToUse = 198;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Heavy:{
							TF2Items_SetClassname(hItem, "tf_weapon_fists");
							if(weaponToUse == -1)
								weaponToUse = 195;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Pyro:{
							TF2Items_SetClassname(hItem, "tf_weapon_fireaxe");
							if(weaponToUse == -1)
								weaponToUse = 192;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Spy:{
							TF2Items_SetClassname(hItem, "tf_weapon_knife");
							if(weaponToUse == -1)
								weaponToUse = 194;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Engineer:{
							TF2Items_SetClassname(hItem, "tf_weapon_wrench");
							if(weaponToUse == -1)
								weaponToUse = 197;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						}
							
					TF2Items_SetLevel(hItem, 69);
					TF2Items_SetQuality(hItem, 6);
					TF2Items_SetAttribute(hItem, 0, 150, 1.0); //Turn to gold on kill
					TF2Items_SetNumAttributes(hItem, 1);
					new iWeapon = TF2Items_GiveNamedItem(client, hItem);
					CloseHandle(hItem);
					
					EquipPlayerWeapon(client, iWeapon);
				}
			}
			TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
		}
	}
}

/* OnPlayerSpawn()
**
** Here we enable the glow (if we need to), we set the spy cloak and we move the death player.
** -------------------------------------------------------------------------- */
public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_isDRmap)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(g_diablefalldamage)
			TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
		if(g_MeleeOnly)
		{
			new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
			
			if (cond & PLAYERCOND_SPYCLOAK)
			{
				SetEntProp(client, Prop_Send, "m_nPlayerCond", cond | ~PLAYERCOND_SPYCLOAK);
			}
		}
		

		
		if(g_onPreparation)
			SetEntityMoveType(client, MOVETYPE_NONE);	
		
	}
}


/* OnPlayerDeath()
**
** Here we reproduce sounds if needed and activate the glow effect if needed
** -------------------------------------------------------------------------- */
public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_isDRmap)
	{

	}
	return Plugin_Continue;
}


/* OnGameFrame()
**
** We set the player max speed on every frame, and also we set the spy's cloak on empty.
** -------------------------------------------------------------------------- */
public OnGameFrame()
{
	if(g_isDRmap)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				if(GetClientTeam(i) == TEAM_RED )
					SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", g_runner_speed);
				else if(GetClientTeam(i) == TEAM_BLUE)
					SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", g_death_speed);
					
				if(g_MeleeOnly)
					if(TF2_GetPlayerClass(i) == TFClass_Spy)
						SetCloak(i, 1.0);
			}
		}
	}
}

/* TF2_SwitchtoSlot()
**
** Changes the client's slot to the desired one.
** -------------------------------------------------------------------------- */
stock TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:classname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
		{
			FakeClientCommandEx(client, "use %s", classname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

/* SetCloak()
**
** Function used to set the spy's cloak meter.
** -------------------------------------------------------------------------- */
stock SetCloak(client, Float:value)
{
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", value);
}

/* OnConfigsExecuted()
**
** Here we get the default values of the CVars that the plugin is going to modify.
** -------------------------------------------------------------------------- */
public OnConfigsExecuted()
{
	dr_queue_def= GetConVarInt(dr_queue);
	dr_unbalance_def = GetConVarInt(dr_unbalance);
	dr_autobalance_def = GetConVarInt(dr_autobalance);
	dr_firstblood_def = GetConVarInt(dr_firstblood);
	dr_scrambleauto_def = GetConVarInt(dr_scrambleauto);
	dr_airdash_def = GetConVarInt(dr_airdash);
	dr_push_def = GetConVarInt(dr_push);
}


/* SetupCvars()
**
** Modify several values of the CVars that the plugin needs to work properly.
** -------------------------------------------------------------------------- */
public SetupCvars()
{
	SetConVarInt(dr_queue, 0);
	SetConVarInt(dr_unbalance, 0);
	SetConVarInt(dr_autobalance, 0);
	SetConVarInt(dr_firstblood, 0);
	SetConVarInt(dr_scrambleauto, 0);
	SetConVarInt(dr_airdash, 0);
	SetConVarInt(dr_push, 0);
}

/* ResetCvars()
**
** Reset the values of the CVars that the plugin used to their default values.
** -------------------------------------------------------------------------- */
public ResetCvars()
{
	SetConVarInt(dr_queue, dr_queue_def);
	SetConVarInt(dr_unbalance, dr_unbalance_def);
	SetConVarInt(dr_autobalance, dr_autobalance_def);
	SetConVarInt(dr_firstblood, dr_firstblood_def);
	SetConVarInt(dr_scrambleauto, dr_scrambleauto_def);
	SetConVarInt(dr_airdash, dr_airdash_def);
	SetConVarInt(dr_push, dr_push_def);
	
	//We clear the tries
	ClearTrie(g_RestrictedWeps);
	ClearTrie(g_AllClassWeps);
}
