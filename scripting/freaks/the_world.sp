//"abilityX"
//{
//	"name"	"the_world"
//	"arg1"	"10.0"				//duration
//	"arg2"	"320.0"				//damage
//	"plugin_name"	"the_world"
//}

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <tf2>
#include <tf2_stocks>

#define ABILITY_NAME1 "the_world"
#define spirite "spirites/zerogxplode.spr"

#define MAXENTITIES 2048

new MoveType:iPrevCollision[MAXENTITIES+1]={MOVETYPE_WALK, ...};


new Handle:g_CTFGrenadeDetonate = null;
new Float:rageTime;
new Float:stabdamage = 320.0;


new Float:flHypeMeter[MAXPLAYERS+1];
new Float:flRage[MAXPLAYERS+1];
new Float:flRage0[MAXPLAYERS+1];
new Float:flCharge[MAXPLAYERS+1];
new Float:flCharge0[MAXPLAYERS+1];
new Float:flDrinkMeter[MAXPLAYERS+1];
new Float:flRage1[MAXPLAYERS+1];
new Float:flUberCharge[MAXPLAYERS+1];
new Float:flRage2[MAXPLAYERS+1];
new Float:flChargeMeter[MAXPLAYERS+1];
new Float:flCloak[MAXPLAYERS+1];
//new shield[MAXPLAYERS+1];
new health[MAXPLAYERS+1];
new T_targeted[MAXPLAYERS+1];
new Float:duration;
//new Nadethink;
new BossTeam=_:TFTeam_Blue;
new bool:ISTIMEFREEZED = false;



public OnPluginStart2()
{
	new Handle:GameData_TW = LoadGameConfigFile("CTFGrenadeDetonate");
	if (GameData_TW == INVALID_HANDLE)
	{
		decl String:path[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, path, sizeof(path), "gamedata/CTFGrenadeDetonate.txt");
		LogError("Unable to load required gamedata in %s", path);
		SetFailState("Unable to load required gamedata in %s", path);
	}
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(GameData_TW, SDKConf_Virtual, "GrenadeDetonate"); //CTFGrenadePipebombProjectile::Detonate(void)
	g_CTFGrenadeDetonate = EndPrepSDKCall();
	if(!g_CTFGrenadeDetonate)
		LogError("[Gamedata] Could not find CTFGrenadePipebombProjectile::Detonate");
	CloseHandle(GameData_TW);

	HookEvent("teamplay_round_win", event_round_end);
	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("player_death", OnPlayerDeath);

//	for(new i=1; i<=MaxClients; i++)
//	{
//		if(IsValidClient(i))
//		{
//			SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
//		}
//	}
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.3, Timer_GetBossTeam, _, TIMER_FLAG_NO_MAPCHANGE);
	ISTIMEFREEZED = false;
	return Plugin_Continue;
}

//public OnClientPostAdminCheck(client)
//{
//	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
//
//}

public Action:FF2_OnAbility2(boss, const String:plugin_name[], const String:ability_name[], action)
{
	if(StrEqual(ability_name, ABILITY_NAME1, false) && boss!=-1)
	{
		char sound[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, ABILITY_NAME1, 3, sound, sizeof(sound));
		if(sound[0] != '\0')
		{
			EmitSoundToAll(sound);
		}
		CreateTimer(2.0, Timer_TheWorld, boss, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	ISTIMEFREEZED = false;
	char classname[60];
	SetConVarInt(FindConVar("sv_client_predict"), 1);

	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i) && !IsBoss(i))
		{
			SetClientOverlay(i, "");
			SetEntityMoveType(i, MOVETYPE_WALK);
			SetEntProp(i, Prop_Send, "m_bIsPlayerSimulated", 1);
			SetEntProp(i, Prop_Send, "m_bSimulatedEveryTick", 1);
			SetEntProp(i, Prop_Send, "m_bAnimatedEveryTick", 1);
			SetEntProp(i, Prop_Send, "m_bClientSideAnimation", 1);
			SetEntProp(i, Prop_Send, "m_bClientSideFrameReset", 0);
			SetEntPropFloat(i, Prop_Send, "m_flNextAttack", GetGameTime());
			new weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(weapon))
			{
				SetEntProp(weapon, Prop_Send, "m_bIsPlayerSimulated", 1);
				SetEntProp(weapon, Prop_Send, "m_bAnimatedEveryTick", 1);
				SetEntProp(weapon, Prop_Send, "m_bSimulatedEveryTick", 1);
				SetEntProp(weapon, Prop_Send, "m_bClientSideAnimation", 1);
				SetEntProp(weapon, Prop_Send, "m_bClientSideFrameReset", 0);
			}
			TF2_RemoveCondition(i, TFCond_FreezeInput);
		}
		iPrevCollision[i]=MOVETYPE_WALK; // Reset
		SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamageTW);
	}

	for(int entity =  MaxClients + 1; entity <= MAXENTITIES; entity++)
	{
		if(IsValidEntity(entity))
		{
			GetEntityClassname(entity, classname, sizeof(classname));
			if(!StrContains(classname, "obj_"))
			{
				if(TF2_GetObjectType(entity) == TFObject_Dispenser
				|| TF2_GetObjectType(entity) == TFObject_Teleporter
				|| TF2_GetObjectType(entity) == TFObject_Sentry)
				{
					SetEntProp(entity, Prop_Send, "m_bDisabled", 0);
					SetEntProp(entity, Prop_Send, "m_bIsPlayerSimulated", 1);
					SetEntProp(entity, Prop_Send, "m_bAnimatedEveryTick", 1);
					SetEntProp(entity, Prop_Send, "m_bSimulatedEveryTick", 1);
					SetEntProp(entity, Prop_Send, "m_bClientSideAnimation", 1);
					SetEntProp(entity, Prop_Send, "m_bClientSideFrameReset", 0);
				}
			}
			if(!StrContains(classname, "tf_projectile"))
			{
				SetEntityMoveType(entity, MOVETYPE_FLY);
				AcceptEntityInput(entity, "Kill");
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if((GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
		return Plugin_Continue;
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int boss=FF2_GetBossIndex(client); // Boss is an attacker
	if(!IsValidClient(client))
		return Plugin_Continue;
	if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) && client != boss)
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamageTW);
		return Plugin_Continue;
	}
	if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) && client == boss)
	{
		ISTIMEFREEZED = false;
		char classname[60];
		SetConVarInt(FindConVar("sv_client_predict"), 1);

		for(new i=1; i<=MaxClients; i++)
		{
			if(IsValidClient(i) && !IsBoss(i))
			{
				SetClientOverlay(i, "");
				SetEntityMoveType(i, MOVETYPE_WALK);
				SetEntProp(i, Prop_Send, "m_bIsPlayerSimulated", 1);
				SetEntProp(i, Prop_Send, "m_bSimulatedEveryTick", 1);
				SetEntProp(i, Prop_Send, "m_bAnimatedEveryTick", 1);
				SetEntProp(i, Prop_Send, "m_bClientSideAnimation", 1);
				SetEntProp(i, Prop_Send, "m_bClientSideFrameReset", 0);
				SetEntPropFloat(i, Prop_Send, "m_flNextAttack", GetGameTime());
				new weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(weapon))
				{
					SetEntProp(weapon, Prop_Send, "m_bIsPlayerSimulated", 1);
					SetEntProp(weapon, Prop_Send, "m_bAnimatedEveryTick", 1);
					SetEntProp(weapon, Prop_Send, "m_bSimulatedEveryTick", 1);
					SetEntProp(weapon, Prop_Send, "m_bClientSideAnimation", 1);
					SetEntProp(weapon, Prop_Send, "m_bClientSideFrameReset", 0);
				}
				TF2_RemoveCondition(i, TFCond_FreezeInput);
			}
			iPrevCollision[i]=MOVETYPE_WALK; // Reset
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamageTW);
		}

		for(int entity =  MaxClients + 1; entity <= MAXENTITIES; entity++)
		{
			if(IsValidEntity(entity))
			{
				GetEntityClassname(entity, classname, sizeof(classname));
				if(!StrContains(classname, "obj_"))
				{
					if(TF2_GetObjectType(entity) == TFObject_Dispenser
					|| TF2_GetObjectType(entity) == TFObject_Teleporter
					|| TF2_GetObjectType(entity) == TFObject_Sentry)
					{
						SetEntProp(entity, Prop_Send, "m_bDisabled", 0);
						SetEntProp(entity, Prop_Send, "m_bIsPlayerSimulated", 1);
						SetEntProp(entity, Prop_Send, "m_bAnimatedEveryTick", 1);
						SetEntProp(entity, Prop_Send, "m_bSimulatedEveryTick", 1);
						SetEntProp(entity, Prop_Send, "m_bClientSideAnimation", 1);
						SetEntProp(entity, Prop_Send, "m_bClientSideFrameReset", 0);
					}
				}
				if(!StrContains(classname, "tf_projectile"))
				{
					SetEntityMoveType(entity, MOVETYPE_FLY);
					AcceptEntityInput(entity, "Kill");
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_GetBossTeam(Handle:timer)
{
	BossTeam=FF2_GetBossTeam();
	return Plugin_Continue;
}

public OnGameFrame()
{
	if(ISTIMEFREEZED)
	{
		for(int client =1;client <=MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				if(IsPlayerAlive(client))
				{
					if(!IsBoss(client))
					{

						SetEntProp(client, Prop_Send, "m_iHealth", health[client]);
						if(flHypeMeter[client] != 255.0) SetEntPropFloat(client, Prop_Send, "m_flHypeMeter", flHypeMeter[client]);
						if(flRage[client] != 255.0)	SetEntPropFloat(client, Prop_Send, "m_flRageMeter", flRage[client]);
						if(flRage0[client] != 255.0)	SetEntPropFloat(client, Prop_Send, "m_flRageMeter", flRage0[client]);
						if(flCharge[client] != 255.0)	SetEntPropFloat(GetPlayerWeaponSlot(client, TFWeaponSlot_Primary), Prop_Send, "m_flChargedDamage", flCharge[client]);
//						if(flCharge0[client] != 255.0)	SetEntPropFloat(GetPlayerWeaponSlot(client, TFWeaponSlot_Primary), Prop_Send, "m_flChargedDamage", flCharge0[client]);
						if(flDrinkMeter[client] != 255.0)	SetEntPropFloat(client, Prop_Send, "m_flEnergyDrinkMeter", flDrinkMeter[client]);
						if(flRage1[client] != 255.0)	SetEntPropFloat(client, Prop_Send, "m_flRageMeter", flRage1[client]);
						if(flUberCharge[client] != 255.0)	SetEntPropFloat(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary), Prop_Send, "m_flChargeLevel", flUberCharge[client]);
						if(flRage2[client] != 255.0)	SetEntPropFloat(client, Prop_Send, "m_flRageMeter", flRage2[client]);
						if(flChargeMeter[client] != 255.0)	SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", flChargeMeter[client]);
						if(flCloak[client] != 255.0)	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", flCloak[client]);
				
					}
				}
			}
		}
	}
}

public RageBoss(bossid)
{
	new boss = GetClientOfUserId(bossid);
	char classname[60];
	SetConVarInt(FindConVar("sv_client_predict"), 0);
	UpdateClientPredictValue(boss, -1);
//	new bossindex = GetClientOfUserId(FF2_GetBossUserId(0));
	duration = FF2_GetAbilityArgumentFloat(0, this_plugin_name, ABILITY_NAME1 , 1, 10.0);
	rageTime = GetEngineTime() + FF2_GetAbilityArgumentFloat(0, this_plugin_name, ABILITY_NAME1 , 1, 10.0);
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i) && !IsBoss(i))
		{
			SetClientOverlay(i, "debug/yuv");
//			SetClientOverlay(i, "models/vgui/deathcam_rt");
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamageTW);
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamageTW);
			
//			new entity0=-1;
			T_targeted[i]=0;
//			shield[i]=0;
			health[i]=GetClientHealth(i);
			flHypeMeter[i] = 255.0;
			flRage[i] = 255.0;
			flRage0[i] = 255.0;
			flCharge[i] = 255.0;
			flCharge0[i] = 255.0;
			flDrinkMeter[i] = 255.0;
			flRage1[i] = 255.0;
			flUberCharge[i] = 255.0;
			flRage2[i] = 255.0;
			flChargeMeter[i] = 255.0;
			flCloak[i] = 255.0;
//			while((entity0=FindEntityByClassname(entity0, "tf_wearable_demoshield"))!=-1)  //Demoshields
//			{
//				if(GetEntPropEnt(entity0, Prop_Send, "m_hOwnerEntity")== i && !GetEntProp(entity0, Prop_Send, "m_bDisguiseWearable"))
//				{
//					shield[i]=entity0;
//				}
//			}
			if(TF2_IsPlayerInCondition(i, TFCond_Ubercharged))
				TF2_AddCondition(i, TFCond_Ubercharged, FF2_GetAbilityArgumentFloat(0, this_plugin_name, ABILITY_NAME1 , 1, 10.0));
			iPrevCollision[i] = GetEntityMoveType(i);
			SetEntityMoveType(i, MOVETYPE_NONE);

			SetEntProp(i, Prop_Send, "m_bIsPlayerSimulated", 0);
			SetEntProp(i, Prop_Send, "m_bSimulatedEveryTick", 0);
			SetEntProp(i, Prop_Send, "m_bAnimatedEveryTick", 0);
			SetEntProp(i, Prop_Send, "m_bClientSideAnimation", 0);
			SetEntProp(i, Prop_Send, "m_bClientSideFrameReset", 1);
			SetEntPropFloat(i, Prop_Send, "m_flNextAttack", GetGameTime()+10000.0);
			new weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(weapon))
			{
				SetEntProp(weapon, Prop_Send, "m_bIsPlayerSimulated", 0);
				SetEntProp(weapon, Prop_Send, "m_bAnimatedEveryTick", 0);
				SetEntProp(weapon, Prop_Send, "m_bSimulatedEveryTick", 0);
				SetEntProp(weapon, Prop_Send, "m_bClientSideAnimation", 0);
				SetEntProp(weapon, Prop_Send, "m_bClientSideFrameReset", 1);
			}
			TF2_AddCondition(i, TFCond_FreezeInput, FF2_GetAbilityArgumentFloat(0, this_plugin_name, ABILITY_NAME1 , 1, 10.0));
			new Primary=GetPlayerWeaponSlot(i, TFWeaponSlot_Primary);
			if(Primary!=-1)
			{
				int iWeaponIndex1 = GetEntProp(Primary, Prop_Send, "m_iItemDefinitionIndex");
				switch(iWeaponIndex1)
				{
					case 13,200,45,220,669,799,808,888,897,906,915,964,973,1078,1103,15002,15015,15021,15029,15036,15053://primary
					{
						flHypeMeter[i]=GetEntPropFloat(i, Prop_Send, "m_flHypeMeter");
						if(TF2_IsPlayerInCondition(i, TFCond_CritHype))
						{
							new Float:Hype=flHypeMeter[i];
							TF2_AddCondition(i, TFCond_CritHype, (Hype/100*10) + duration);
						}
//						CreateTimer(0.1, Timer_Freeze_Hype, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}

					case 15,202,41,298,312,424,654,793,802,811,832,850,882,891,900,909,958,967,15004,15020,15026,15031,15040,15055,594://primary
					{
						flRage[i]=GetEntPropFloat(i, Prop_Send, "m_flRageMeter");
						if(TF2_IsPlayerInCondition(i, TFCond_CritMmmph))
						{
							new Float:Mmmph = flRage[i];
							TF2_AddCondition(i, TFCond_CritMmmph, (Mmmph/100*10) + duration);
						}
//						CreateTimer(0.1, Timer_Freeze_Rage, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}

					case 752:
					{
						flRage0[i]=GetEntPropFloat(i, Prop_Send, "m_flRageMeter");
//						CreateTimer(0.1, Timer_Freeze_Rage_0, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						flCharge[i]=GetEntPropFloat(Primary, Prop_Send, "m_flChargedDamage");
//						CreateTimer(0.1, Timer_Freeze_HeadCharge, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}

					case 14,201,230,402,526,664,792,801,851,881,890,899,908,957,966,15000,15007,15019,15023,15033,15059,30665://primary
					{
						flCharge0[i]=GetEntPropFloat(Primary, Prop_Send, "m_flChargedDamage");
//						CreateTimer(0.1, Timer_Freeze_Snipe, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
			new Secondary=GetPlayerWeaponSlot(i, TFWeaponSlot_Secondary);
			if(Secondary!=-1)
			{
				int iWeaponIndex2 = GetEntProp(Secondary, Prop_Send, "m_iItemDefinitionIndex");
				switch(iWeaponIndex2)
				{
					case 46,163,1145://secondary
					{
						flDrinkMeter[i]=GetEntPropFloat(i, Prop_Send, "m_flEnergyDrinkMeter");
						if(TF2_IsPlayerInCondition(i, TFCond_Bonked))
						{
							new Float:Bonk = flDrinkMeter[i];
							TF2_AddCondition(i, TFCond_Bonked, (Bonk/100*8) + duration);
						}
						if(TF2_IsPlayerInCondition(i, TFCond_CritCola))
						{
							new Float:Cola = flDrinkMeter[i];
							TF2_AddCondition(i, TFCond_HalloweenCritCandy, (Cola/100*8) + duration);
						}
//						PrintToServer("drink meter of player %d is %f .",i,flDrinkMeter[i]);//debug
//						CreateTimer(0.1, Timer_Freeze_Drink, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
			
					case 29,211,35,411,663,796,805,885,894,903,912,961,970,998,15008,15010,15025,15039,15050://secondary
					{
						flRage1[i]=GetEntPropFloat(i, Prop_Send, "m_flRageMeter");
//						CreateTimer(0.1, Timer_Freeze_Rage_1, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						flUberCharge[i]=GetEntPropFloat(Secondary, Prop_Send, "m_flChargeLevel");
//						PrintToServer("uber rate of player %d is %f .",i,flUberCharge[i]);//debug
//						CreateTimer(0.1, Timer_Freeze_Uber, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
			
					case 129,226,354,1001://secondary
					{
						flRage2[i]=GetEntPropFloat(i, Prop_Send, "m_flRageMeter");
						if(TF2_IsPlayerInCondition(i, TFCond_Buffed))
						{
							new Float:Buff = flRage2[i];
							TF2_AddCondition(i, TFCond_Buffed, (Buff/100*10) + duration);
						}
						if(TF2_IsPlayerInCondition(i, TFCond_DefenseBuffed))
						{
							new Float:Def = flRage2[i];
							TF2_AddCondition(i, TFCond_DefenseBuffed, (Def/100*10) + duration);
						}
						if(TF2_IsPlayerInCondition(i, TFCond_RegenBuffed))
						{
							new Float:Regen = flRage2[i];
							TF2_AddCondition(i, TFCond_RegenBuffed, (Regen/100*10) + duration);
						}
//						CreateTimer(0.1, Timer_Freeze_Rage_2, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}

					case 131,406,1099,1144://secondry
					{
						flChargeMeter[i]=GetEntPropFloat(i, Prop_Send, "m_flChargeMeter");
//						CreateTimer(0.1, Timer_Freeze_Charge, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
			if(TF2_GetPlayerClass(i)==TFClass_Spy)
			{
				flCloak[i]=GetEntPropFloat(i, Prop_Send, "m_flCloakMeter");
//				CreateTimer(0.1, Timer_Freeze_Cloak, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	for(int entity = MaxClients + 1; entity <= MAXENTITIES; entity++)
	{
		if(IsValidEntity(entity))
		{
			iPrevCollision[entity] = GetEntityMoveType(entity);
			GetEntityClassname(entity, classname, sizeof(classname));
			if(!StrContains(classname, "obj_"))
			{
				if(TF2_GetObjectType(entity) == TFObject_Dispenser
				|| TF2_GetObjectType(entity) == TFObject_Teleporter
				|| TF2_GetObjectType(entity) == TFObject_Sentry)
				{
					SetEntProp(entity, Prop_Send, "m_bDisabled", 1);
					SetEntProp(entity, Prop_Send, "m_bIsPlayerSimulated", 0);
					SetEntProp(entity, Prop_Send, "m_bAnimatedEveryTick", 0);
					SetEntProp(entity, Prop_Send, "m_bSimulatedEveryTick", 0);
					SetEntProp(entity, Prop_Send, "m_bClientSideAnimation", 0);
					SetEntProp(entity, Prop_Send, "m_bClientSideFrameReset", 1);
				}
			}
			if(!StrContains(classname, "tf_projectile"))
			{
				iPrevCollision[entity]=GetEntityMoveType(entity);
				SetEntityMoveType(entity, MOVETYPE_NONE);
				SetEntProp(entity, Prop_Send, "m_nForceBone", 998);
				if(StrEqual(classname, "tf_projectile_pipe"))
				{
					SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
				}
			}
		}
	}
	
	CreateTimer(duration, Timer_EndAbility, bossid, TIMER_FLAG_NO_MAPCHANGE);
	ISTIMEFREEZED = true;
}

public Action:Timer_TheWorld(Handle:timer, any:client)
{
	RageBoss(FF2_GetBossUserId(0));
}

public Action:Timer_EndAbility(Handle:htimer, int bossindex)
{
	ISTIMEFREEZED = false;
	new boss = GetClientOfUserId(bossindex);
	char classname[60];
	SetConVarInt(FindConVar("sv_client_predict"), 1);

	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i) && !IsBoss(i))
		{
			SetClientOverlay(i, "");
			if(T_targeted[i]==1)
			{
//				new attacker = GetClientOfUserId(FF2_GetBossUserId(0));
				stabdamage=FF2_GetAbilityArgumentFloat(0, this_plugin_name, ABILITY_NAME1 , 2, 320.0);
				SDKHooks_TakeDamage(i, boss, boss, stabdamage, DMG_SLASH|DMG_ALWAYSGIB);
				T_targeted[i]=0;
			}
			SetEntityMoveType(i, iPrevCollision[i]);
			SetEntProp(i, Prop_Send, "m_bIsPlayerSimulated", 1);
			SetEntProp(i, Prop_Send, "m_bSimulatedEveryTick", 1);
			SetEntProp(i, Prop_Send, "m_bAnimatedEveryTick", 1);
			SetEntProp(i, Prop_Send, "m_bClientSideAnimation", 1);
			SetEntProp(i, Prop_Send, "m_bClientSideFrameReset", 0);
			SetEntPropFloat(i, Prop_Send, "m_flNextAttack", GetGameTime());
			new weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(weapon))
			{
				SetEntProp(weapon, Prop_Send, "m_bIsPlayerSimulated", 1);
				SetEntProp(weapon, Prop_Send, "m_bAnimatedEveryTick", 1);
				SetEntProp(weapon, Prop_Send, "m_bSimulatedEveryTick", 1);
				SetEntProp(weapon, Prop_Send, "m_bClientSideAnimation", 1);
				SetEntProp(weapon, Prop_Send, "m_bClientSideFrameReset", 0);
			}
			TF2_RemoveCondition(i, TFCond_FreezeInput);
		}
		else
		{
			iPrevCollision[i]=MOVETYPE_WALK; // Reset
		}
		SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamageTW);
	}

	for(int entity =  MaxClients + 1; entity <= MAXENTITIES; entity++)
	{
		if(IsValidEntity(entity))
		{
			GetEntityClassname(entity, classname, sizeof(classname));
			if(!StrContains(classname, "obj_"))
			{
				if(TF2_GetObjectType(entity) == TFObject_Dispenser
				|| TF2_GetObjectType(entity) == TFObject_Teleporter
				|| TF2_GetObjectType(entity) == TFObject_Sentry)
				{
					SetEntProp(entity, Prop_Send, "m_bDisabled", 0);
					SetEntProp(entity, Prop_Send, "m_bIsPlayerSimulated", 1);
					SetEntProp(entity, Prop_Send, "m_bAnimatedEveryTick", 1);
					SetEntProp(entity, Prop_Send, "m_bSimulatedEveryTick", 1);
					SetEntProp(entity, Prop_Send, "m_bClientSideAnimation", 1);
					SetEntProp(entity, Prop_Send, "m_bClientSideFrameReset", 0);
				}
			}
			if(!StrContains(classname, "tf_projectile"))
			{
				SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", boss);
				if(GetEntProp(entity, Prop_Send, "m_nForceBone") == 998)
					SetEntityMoveType(entity, iPrevCollision[entity]);
				else
					SetEntityMoveType(entity, MOVETYPE_FLY);
				SetVariantInt(BossTeam);
				AcceptEntityInput(entity, "TeamNum", -1, -1, 0);
				SetVariantInt(BossTeam);
				AcceptEntityInput(entity, "SetTeam", -1, -1, 0);
				SetEntProp(entity, Prop_Send, "m_nSkin", (BossTeam==_:TFTeam_Blue) ? 1 : 0);
				// invert angles
				new Float:angle[3];
				GetEntPropVector(entity, Prop_Data, "m_angRotation", angle);
				angle[0] = -angle[0]; //fixAngle(angle[0] + 180.0);
				angle[1] = fixAngle(angle[1] + 180.0);
				// redo velocity
				new Float:velocity[3];
				GetAngleVectors(angle, velocity, NULL_VECTOR, NULL_VECTOR);
				if(StrEqual(classname, "tf_projectile_pipe_remote"))
				{
					SetEntPropEnt(entity, Prop_Data, "m_hThrower", boss);

					new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
					if(client > 0 && client <= MaxClients && IsClientInGame(client))			// will probably just be -1, but whatever.
					{
						if(g_CTFGrenadeDetonate)
							SDKCall(g_CTFGrenadeDetonate, entity);
						new Float:pos[3];
						GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
						DoExplosion(client, 100, 146, pos);
					}
					AcceptEntityInput(entity, "Kill");

				}
				if(StrEqual(classname, "tf_projectile_pipe"))
				{

					SetEntPropEnt(entity, Prop_Data, "m_hThrower", boss);

					SetEntityMoveType(entity, MOVETYPE_FLYGRAVITY);
					SDKHook(entity, SDKHook_StartTouch, ProjectileTouchHook);
					SDKHook(entity, SDKHook_Touch, ProjectileTouchHook);
					ScaleVector(velocity, 500.0);
				}
				else
					ScaleVector(velocity, 800.0);
				TeleportEntity(entity, NULL_VECTOR, angle, velocity);
				if(HasEntProp(entity, Prop_Send, "m_iDeflected"))
					SetEntProp(entity, Prop_Send, "m_iDeflected", GetEntProp(entity, Prop_Send, "m_iDeflected")+1);
			}
		}
	}


	return Plugin_Continue;
}


public Action:ProjectileTouchHook(entity, other)			// Wat happens when this projectile touches something
{

	SDKUnhook(entity, SDKHook_StartTouch, ProjectileTouchHook);

	if(g_CTFGrenadeDetonate)
		SDKCall(g_CTFGrenadeDetonate, entity);

	if(other > 0 && other <= MaxClients)
	{
		new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(client > 0 && client <= MaxClients && IsClientInGame(client))			// will probably just be -1, but whatever.
		{
			new Float:pos[3];
			GetEntPropVector(other, Prop_Send, "m_vecOrigin", pos);
			DoExplosion(other, 100, 146, pos);
		}
		AcceptEntityInput(entity, "Kill");
	}
	else
		AcceptEntityInput(entity, "Kill");
}


public Action:OnTakeDamageTW(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(!IsValidClient(attacker) || TF2_IsPlayerInCondition(client, TFCond_Ubercharged) || TF2_IsPlayerInCondition(client, TFCond_Bonked) || (rageTime <= GetEngineTime()))
	{
		return Plugin_Continue;
	}
	if(IsBoss(attacker) && IsValidClient(client) &&  (rageTime > GetEngineTime()))
	{
		if(FF2_GetClientShield(client) > 0)
		{
			TF2_AddCondition(client, TFCond_Bonked, rageTime-GetEngineTime());
			TF2_AddCondition(client, TFCond_MegaHeal, rageTime-GetEngineTime());
//			return Plugin_Continue;
		}
		damage=0.0;
		T_targeted[client] = 1;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if(client<=0 || client>MaxClients) return false;
	return IsClientInGame(client);
}

bool:IsBoss(client)
{
	return (FF2_GetBossIndex(client)!=-1) ? true : false;
}

stock Float:fixAngle(Float:angle)
{
	new sanity = 0;
	while (angle < -180.0 && (sanity++) <= 10)
		angle = angle + 360.0;
	while (angle > 180.0 && (sanity++) <= 10)
		angle = angle - 360.0;
		
	return angle;
}

stock DoExplosion(owner, damage, radius, Float:pos[3])
{
    new explode = CreateEntityByName("env_explosion");
    if(!IsValidEntity(explode))
        return;
    DispatchKeyValue(explode, "targetname", "explode");
    DispatchKeyValue(explode, "spawnflags", "2");
    DispatchKeyValue(explode, "rendermode", "5");
    DispatchKeyValue(explode, "fireballsprite", spirite);

    SetEntPropEnt(explode, Prop_Data, "m_hOwnerEntity", owner);
    SetEntProp(explode, Prop_Data, "m_iMagnitude", damage);
    SetEntProp(explode, Prop_Data, "m_iRadiusOverride", radius);

    TeleportEntity(explode, pos, NULL_VECTOR, NULL_VECTOR);
    DispatchSpawn(explode);
    ActivateEntity(explode);
    AcceptEntityInput(explode, "Explode");
    AcceptEntityInput(explode, "Kill");
}

stock UpdateClientPredictValue(int client, value)
{
//	for(new client=1; client<=MaxClients; client++)
//	{
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		SendConVarValue(client, FindConVar("sv_client_predict"), value ? "-1" : "0");
	}
//	}
}

void SetClientOverlay(int client, char[] strOverlay)
{
	new iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
	SetCommandFlags("r_screenoverlay", iFlags);
	ClientCommand(client, "r_screenoverlay \"%s\"", strOverlay);
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
}

