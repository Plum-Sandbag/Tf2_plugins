#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <dhooks>
#include <freak_fortress_2>
#include <tf2items>
#include <tf2attributes>


#include<stocksoup/sdkports/util>
#define AMOVETYPE 4
#define CONTENTS_REDTEAM	CONTENTS_TEAM1
#define CONTENTS_BLUETEAM	CONTENTS_TEAM2

bool HasBlink[MAXPLAYERS+1];
float m_MoveKeyDownTimes[MAXPLAYERS+1][AMOVETYPE];
float m_flNextDoubleTapTeleportTime[MAXPLAYERS+1] = {0.0, ...};

#pragma newdecls required

#define PLUGIN_NAME     "Weapon Enhancement"
#define PLUGIN_AUTHOR   "NONE"
#define PLUGIN_VERSION  "1.0"

//#define BRICKMODEL "models/weapons/c_models/c_brick/c_brick.mdl"

#define MDL_BOMBLET			"models/weapons/w_models/w_stickybomb.mdl"
#define EGG					"models/player/saxton_hale/w_easteregg.mdl"
//#define SPHERE_GV			"models/items/gunvolt_sphere.mdl"

//Handle g_CTFGrenadeDetonate = null;
//Handle ClassicTimer[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
Handle HomingArry;

enum
{
	hEntref = 0,
	hTarget
};

bool HasClassic[MAXPLAYERS + 1];
int ClassicHITs[MAXPLAYERS + 1];
bool BisonTouched[2048];
bool SteakEaten[MAXPLAYERS + 1];
bool HeavyRaging[MAXPLAYERS + 1];
bool HeavyRageHit[MAXPLAYERS + 1];
float HeavyRagingTime[MAXPLAYERS + 1];
bool Heavy_WasOnGroundLastTick[MAXPLAYERS + 1];

int ClassicStack[MAXPLAYERS + 1];
int TrailIndex;

//bool Rocket_Created = false;
//int Rocket_Bonus[4];
//int target[4];

//int offs_CTFPlayer_iTauntAttack;

Handle hGetVelocity;
Handle hWorldSpaceCenter;
static DynamicHook hHookResolveFlyCollisionCustom;

ConVar cvar_steak_dmg;
ConVar cvar_steak_radius;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
};

public void OnPluginStart()
{
/*	Handle GameData_TW = LoadGameConfigFile("CTFGrenadeDetonate");
	if (GameData_TW == INVALID_HANDLE)
	{
		char path[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, path, sizeof(path), "gamedata/CTFGrenadeDetonate.txt");
		LogError("Unable to load required gamedata in %s", path);
//		SetFailState("Unable to load required gamedata in %s", path);
	}
	StartPrepSDKCall(SDKCall_Entity);
	
	PrepSDKCall_SetFromConf(GameData_TW, SDKConf_Virtual, "GrenadeDetonate"); //CTFGrenadePipebombProjectile::Detonate(void)
	g_CTFGrenadeDetonate = EndPrepSDKCall();
	if(g_CTFGrenadeDetonate == null)
		LogError("Weapon Enhancement: Failed to create call: GrenadeDetonate");
*/
	GameData conf = LoadGameConfigFile("weapon_enhance");
	if (!conf)
		SetFailState("Could not find gamedata for weapon_enhance");

	Handle hook = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
	DHookSetFromConf(hook, conf, SDKConf_Signature, "CTFPlayer::DoTauntAttack");
	if (!DHookEnableDetour(hook, false, CTFPlayer_DoTauntAttack))
		LogError("Could not load detour for CTFPlayer::DoTauntAttack!");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "CBaseEntity::GetVelocity");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain, 0, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain, 0, VENCODE_FLAG_COPYBACK);
	if (!(hGetVelocity = EndPrepSDKCall()))
		SetFailState("Could not initialize call to CBaseEntity::GetVelocity");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "CBaseEntity::WorldSpaceCenter");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByRef);
	if (!(hWorldSpaceCenter = EndPrepSDKCall()))
		LogError("Could not initialize call to CBaseEntity::WorldSpaceCenter. Falling back to m_vecOrigin.");

//	Address pTauntAttackInfo = GameConfGetAddress(conf,
//			"CTFPlayer::DoTauntAttack()::TauntAttackOffset");
//	offs_CTFPlayer_iTauntAttack = LoadFromAddress(pTauntAttackInfo, NumberType_Int32);
//	if (offs_CTFPlayer_iTauntAttack & 0xFFFF != offs_CTFPlayer_iTauntAttack) {
//		SetFailState("Couldn't determine offset for CTFPlayer::m_iTauntAttack.");
//	}

	hHookResolveFlyCollisionCustom = DHook_CreateVirtual(conf, "CBaseEntity::ResolveFlyCollisionCustom");
	
	delete conf;

	cvar_steak_dmg = CreateConVar("tf2_we_steak_dmg", "222", "Heavy steak explosion damage parameter ");
	cvar_steak_radius = CreateConVar("tf2_we_steak_radius", "100", "Heavy steak explosion radius ");

	HookEvent("post_inventory_application", Event_OnInventoryApplicationPost);
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("arena_win_panel", OnRoundEnd, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_hurt", OnPlayerHurt);
	AddNormalSoundHook(Hook_WeaponSound);
	
	HomingArry = CreateArray(2);
}

DynamicHook DHook_CreateVirtual(GameData hGameData, const char[] sName)
{
	DynamicHook hHook = DynamicHook.FromConf(hGameData, sName);
	if (!hHook)
		LogError("Failed to create hook: %s", sName);
	
	return hHook;
}

/*public void OnMapEnd()
{
	for (int clientIdx = 1; clientIdx < 33; clientIdx++)
	{
		if(ClassicTimer[clientIdx] != INVALID_HANDLE)
		{
			KillTimer(ClassicTimer[clientIdx]);
			ClassicTimer[clientIdx] = INVALID_HANDLE;
		}
	}
}*/

public void Event_OnInventoryApplicationPost(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId((event.GetInt("userid")));
	HasClassic[client] = false;
	HasBlink[client] = false;
	int active_weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(active_weapon <= 0 || active_weapon > 2048)
		return;
	if(!IsValidEntity(active_weapon))
		return;
	GetBlinkAttriState(client, active_weapon);
	CreateTimer(1.0, Timer_MakeWeapon, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);

	return;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
//	PrecacheModel(EGG, true);
//	PrecacheModel(BRICKMODEL, true);
//	PrecacheModel("flaming_slap_3", true);
	for (int clientIdx = 1; clientIdx < 33; clientIdx++)
	{
//		HasClassic[clientIdx] = false;
//		if(ClassicTimer[clientIdx] != INVALID_HANDLE)
//		{
//			KillTimer(ClassicTimer[clientIdx]);
//			ClassicTimer[clientIdx] = INVALID_HANDLE;
//		}
		if(IsValidClient(clientIdx))
		{
			SDKHook(clientIdx, SDKHook_TraceAttack, OnAttacked);
			SDKHook(clientIdx, SDKHook_OnTakeDamage, CL_Ontakedamage);

//			CreateTimer(1.0, Timer_MakeWeapon, GetClientUserId(clientIdx), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Timer_MakeWeapon(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	int boss = GetClientOfUserId(FF2_GetBossUserId(0));
	if(!IsValidClient(client))
		return Plugin_Continue;
	if(!IsPlayerAlive(client) || IsBoss(client))
		return Plugin_Continue;
	if(boss)
	{
		if(GetClientTeam(client) == GetClientTeam(boss))
			return Plugin_Continue;
	}
	int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(weapon))
	{
		int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if(index==1098)
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
			weapon = SpawnWeapon(client, "tf_weapon_sniperrifle", 1098, 1, 0, "144 ; 3 ; 106 ; 0.99 ; 112 ; 5 ; 387 ; 1 ; 37 ; 5 ; 1 ; 0.07 ; 207 ; 0.6 ; 6 ; 0.08 ; 25 ; 0.01 ; 333 ; 134; 16 ;1");
			if(IsValidEntity(weapon))
			{
				HasClassic[client] = true;
				ClassicHITs[client] = 0;
				ClassicStack[client] = 0;
//				if(ClassicTimer[client] != INVALID_HANDLE)
//					KillTimer(ClassicTimer[client]);
//				ClassicTimer[client] = CreateTimer(0.3, ClassicCountTimer, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(0.3, ClassicCountTimer, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else if((index==811) || (index==832))
		{

		}
	}
	return Plugin_Continue;
}

public Action ClassicCountTimer(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	int boss = GetClientOfUserId(FF2_GetBossUserId(0));
//	if(ClassicTimer[client] == INVALID_HANDLE)
//		return Plugin_Stop;
	if(!HasClassic[client])
	{
//		ClassicTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	if(!IsLivingPlayer(client))
	{
//		ClassicTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	if(IsLivingPlayer(boss))
	{
		if(IsBoss(client) || (GetClientTeam(client) == GetClientTeam(boss)))
		{
//			ClassicTimer[client] = INVALID_HANDLE;
			return Plugin_Stop;
		}
	}
	SetHudTextParams( -0.65, 0.48, 0.32, 255, 102, 200, 255);
	ShowHudText(client, -1, "HIT : %i / 30\nBOMB : %i ", ClassicHITs[client], ClassicStack[client]);
	return Plugin_Continue;
}

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{

	for (int clientIdx = 1; clientIdx < 33; clientIdx++)
	{
		HasClassic[clientIdx] = false;
		if(IsValidClient(clientIdx))
		{
			SDKUnhook(clientIdx, SDKHook_TraceAttack, OnAttacked);
			SDKUnhook(clientIdx, SDKHook_OnTakeDamage, CL_Ontakedamage);
			SDKUnhook(clientIdx, SDKHook_PreThink, OnPreThink_Heavy);
//			SDKUnhook(clientIdx, SDKHook_PreThink, Blink_Prethink);
		}
		
	}

}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client=GetClientOfUserId(GetEventInt(event, "userid"));
	SteakEaten[client] = false;
	HeavyRaging[client] = false;
	SDKUnhook(client, SDKHook_PreThink, OnPreThink_Heavy);
	
	for(int i = 0; i < AMOVETYPE; i++)
	{
		m_MoveKeyDownTimes[client][i] = 0.0;
	}
	m_flNextDoubleTapTeleportTime[client] = 0.0;
//	HasBlink[client] = false;
	
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client=GetClientOfUserId(GetEventInt(event, "userid"));
	HeavyRaging[client] = false;
	SDKUnhook(client, SDKHook_PreThink, OnPreThink_Heavy);
//	SDKUnhook(client, SDKHook_PreThink, Blink_Prethink);
	return Plugin_Continue;
}

public void OnMapStart()
{
//	PrecacheModel("flaming_slap_3");
	PrecacheModel(EGG, true);
	PrecacheModel(MDL_BOMBLET, true);
	PrecacheSound("weapons/capper_shoot.wav");
	TrailIndex = PrecacheModel("materials/sprites/laserbeam.vmt", true);
//	PrecacheModel(SPHERE_GV, true);
}

public Action OnStomp(int attacker, int victim, float &damageMultiplier, float &damageBonus, float &JumpPower)
{
	if(!IsValidClient(attacker) || !IsValidClient(victim) || attacker==victim)
		return Plugin_Continue;
	if(HeavyRaging[attacker])
		return Plugin_Handled;
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, SDKHook_OnWeaponEquipPost);
	SDKHook(client, SDKHook_WeaponSwitchPost, SDKHook_OnWeaponSwitchPost);
//	SDKHook(client, SDKHook_TraceAttack, OnAttacked);
}
public void OnClientDisconnect(int client)
{
//	SDKUnhook(client, SDKHook_TraceAttack, OnAttacked); 
}

void SDKHook_OnWeaponEquipPost(int client, int weapon)
{
	GetBlinkAttriState(client, weapon);
}

void SDKHook_OnWeaponSwitchPost(int client, int weapon)
{
	if(!IsValidEntity(weapon))
		return;
	DataPack hPack = new DataPack();
	hPack.WriteCell(EntIndexToEntRef(client));
	hPack.WriteCell(EntIndexToEntRef(weapon));
	
	RequestFrame(Frame_GetBlinkAttriState, hPack);
}

void Frame_GetBlinkAttriState(DataPack hPack)
{
	hPack.Reset();

	int client = EntRefToEntIndex(hPack.ReadCell());
	int weapon = EntRefToEntIndex(hPack.ReadCell());

	delete hPack;

	if(client == -1 || weapon == -1)
		return;

	if(weapon != GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
		return;

	GetBlinkAttriState(client, weapon);

	return;
}

void GetBlinkAttriState(int client, int weapon)
{
	if(TF2Attrib_GetByDefIndex(weapon, 4336) == Address_Null)
		return;
	if(TF2Attrib_GetValue(TF2Attrib_GetByDefIndex(weapon, 4336)))
	{
		HasBlink[client] = true;
		SDKHook(client, SDKHook_PreThink, Blink_Prethink);
	}
}

public void Blink_Prethink(int client)
{
	if(!HasBlink[client])
	{
		SDKUnhook(client, SDKHook_PreThink, Blink_Prethink);
		return;
	}
	if(!IsLivingPlayer(client))
	{
		HasBlink[client] = false;
		return;
	}
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(!IsValidEntity(weapon))
		return;
	if(TF2Attrib_GetByDefIndex(weapon, 4336) == Address_Null)
		return;
	if(!TF2Attrib_GetValue(TF2Attrib_GetByDefIndex(weapon, 4336)))
		return;
	
	CheckForDoubleTap(client);
}

public Action Hook_WeaponSound(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if(StrContains(sample, "sniper_rifle_classic_shoot", false) != -1)
	{
		volume *= 0.50;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action CL_Ontakedamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!IsValidClient(attacker))
		return Plugin_Continue;
	if(IsValidEntity(inflictor))
	{
		if(!HasClassic[attacker])
			return Plugin_Continue;
		char zclassname[258];
		if(GetEntityClassname(inflictor, zclassname, sizeof(zclassname)) && !strcmp(zclassname, "tf_projectile_energy_ring"))
		{
			damage = 33.3;
			damagetype |= DMG_CRIT;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
//	int weapon = GetEventInt(event, "weaponid");

	if (!IsValidClient(attacker))
		return Plugin_Continue;

	if(IsBoss(attacker))
		return Plugin_Continue;

	if(victim==attacker)
		return Plugin_Continue;

	int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(!IsValidEntity(weapon))
		return Plugin_Continue;

	if(GetEventInt(event, "weaponid") == TF_WEAPON_SNIPERRIFLE)
	{
		if(GetEventInt(event, "custom") == TF_CUSTOM_BLEEDING)
			return Plugin_Continue;
		if(HasClassic[attacker] && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 1098)
		{
			ClassicCount(attacker, victim, weapon);
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

/*public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	if(!IsLivingPlayer(client))
		return Plugin_Continue;
	if(IsBoss(client))
		return Plugin_Continue;
	
	char strCmd[256];
	kv.GetSectionName(strCmd, 256);

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(!IsValidEntity(weapon))
		return Plugin_Continue;
	if((GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 811) || (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 832))
	{
		int iAmmoCount = TF2_GetWeaponAmmo(weapon);
		if(StrEqual(strCmd, "+attack") && iAmmoCount >= 20)
		//fireball or sth
		if(StrEqual(strCmd, "+attack2") && iAmmoCount > 0)
		//fly
		if(StrEqual(strCmd, "+attack3") && (GetClientButtons(client) & IN_ATTACK2) && !(GetEntityFlags(client) & FL_ONGROUND))
		//kick
	}
	

}*/

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float unusedangles[3], int &weapon)
{
	if(!IsLivingPlayer(client))
		return Plugin_Continue;
	if(!IsValidEntity(weapon))
		return Plugin_Continue;
	if(HasClassic[client])
	{
		if((ClassicStack[client] > 0) && (buttons & IN_ATTACK2 != 0))
		{
			int ClientTeam = GetClientTeam(client);
			float position[3], velocity[3], angles[3];
			GetClientEyeAngles(client, angles);
			GetClientEyePosition(client, position);
			GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
			
			// throw from lower than our eyes (but sitll centered)
			position[2] += 5.0;

			// increase pitch to try and match how projectiles arc upwards at first
			angles[2] += 45.0;

			// Scale our init velocity with speed as a multiplier
			ScaleVector(velocity, 1500.0);
			
			// but increase upward velocity so that it's a lil easier to throw
			velocity[2] += 55.0;
			
			// Spawn brick projectile
			int newbrick = CreateEntityByName("tf_projectile_throwable_brick");

			// set its team to ours
			SetVariantInt(ClientTeam);
			AcceptEntityInput(newbrick, "TeamNum", -1, -1, 0);
			SetVariantInt(ClientTeam);
			AcceptEntityInput(newbrick, "SetTeam", -1, -1, 0); 
			SetEntProp(newbrick, Prop_Send, "m_nSkin", (ClientTeam==view_as<int>(TFTeam_Blue)) ? 1 : 0);

			// assign the owner
			SetEntPropEnt(newbrick, Prop_Send, "m_hOwnerEntity", client);

			// assign the thrower
			SetEntPropEnt(newbrick, Prop_Send, "m_hThrower", client);

			// assign the weapon launching the brick
			SetEntPropEnt(newbrick, Prop_Send, "m_hLauncher", client);
			SetEntPropEnt(newbrick, Prop_Send, "m_hOriginalLauncher", client);

			// Should be using an extension but this should be good enough
			SetEntPropVector(newbrick, Prop_Send, "m_vInitialVelocity", velocity);
			
			SetEntPropFloat(newbrick, Prop_Send, "m_flDamage", 200.0);

			// Spawn that thang!
			DispatchSpawn(newbrick);
			TeleportEntity(newbrick, position, angles, velocity);
			CreateParticle(newbrick, "spell_teleport_red", true);
			// ActivateEntity(newbrick);

			// TODO TODO TODO: Set the model up properly so that it doesn't use the bread model's hitbox
			// Currently it clips into the ground a bit. Too bad!

			// for some reason this needs to be after we spawn it
//			SetEntityModel(newbrick, BRICKMODEL);
			
			SDKHook(newbrick, SDKHook_StartTouch, OnBrickTouch);
//			SDKHook(newbrick, SDKHook_Touch, OnBrickTouch);
			
			ClassicStack[client]--;
			CreateTimer(0.5, Timer_Cluster, EntIndexToEntRef(newbrick), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}


public Action Timer_Cluster(Handle timer, any entref)
{
	if(!IsValidEntity(entref))
		return Plugin_Continue;
	int owner = GetEntPropEnt(entref, Prop_Send, "m_hOwnerEntity");
	if(!IsValidClient(owner))
		return Plugin_Continue;
	float pos[3];

	int ent[4] = { -1, -1, -1};
	for(int i=0; i<3; i++)
	{
		ent[i] = CreateEntityByName("tf_projectile_pipe");
		if(ent[i] != -1)
		{
			GetEntPropVector(entref, Prop_Data, "m_vecOrigin", pos);
			SetEntPropEnt(ent[i], Prop_Data, "m_hThrower", owner);
			SetEntProp(ent[i], Prop_Send, "m_iTeamNum", GetClientTeam(owner));
			SetEntProp(ent[i], Prop_Send, "m_bCritical", true);
			SetEntPropFloat(ent[i], Prop_Send, "m_flModelScale", 0.8);
			SetEntPropFloat(ent[i], Prop_Send, "m_flDamage", 72.0);
			
			DispatchSpawn(ent[i]);
			
			SetEntityModel(ent[i], MDL_BOMBLET);
			
			float ang[3];
			ang[0] = GetRandomFloat(-90.0, 90.0); 			//Left, Right
			ang[1] = GetRandomFloat(-90.0, 90.0); 			//Forward, Back
			ang[2] = GetRandomFloat(240.0, 340.0); 			//Up, Down
			
//			ScaleVector(ang, 100.0);
			
			if(i<3)
				pos[i] += 5.0;
			else
				pos[2] -= 5.0;
			TeleportEntity(ent[i], pos, NULL_VECTOR, ang);							//Teleport bomblet to momma stickybomb
		}
	}
	return Plugin_Continue;
}

public Action OnBrickTouch(int brick, int victim)
{
	int owner = GetEntPropEnt(brick, Prop_Send, "m_hOwnerEntity");
	if(!IsValidClient(owner))
		return Plugin_Continue;
	if(IsValidClient(victim))
	{
		if(owner == victim)
			return Plugin_Continue;
		if(GetClientTeam(owner) == GetClientTeam(victim))
			return Plugin_Continue;
	}
	int explode = CreateEntityByName("env_explosion");
	if(!IsValidEntity(explode))
		return Plugin_Continue;
	float pos[3];
	GetEntPropVector(brick, Prop_Data, "m_vecOrigin", pos);
	DispatchKeyValue(explode, "targetname", "explode");
	DispatchKeyValue(explode, "spawnflags", "0");
	DispatchKeyValue(explode, "rendermode", "5");
//	DispatchKeyValue(explode, "fireballsprite", spirite);

	SetEntPropEnt(explode, Prop_Data, "m_hOwnerEntity", owner);
	
	char intAsString[12];
	Format(intAsString, 12, "%d", RoundFloat(120.0));
	DispatchKeyValue(explode, "iMagnitude", intAsString);
	DispatchKeyValueFloat(explode, "DamageForce", 1.0);
	Format(intAsString, 12, "%d", RoundFloat(146.0));
	DispatchKeyValue(explode, "iRadiusOverride", intAsString);
	
//	SetEntPropFloat(explode, Prop_Data, "m_iMagnitude", 120.0);
//	SetEntPropFloat(explode, Prop_Data, "m_iRadiusOverride", 146);

	TeleportEntity(explode, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(explode);
//	ActivateEntity(explode);
	AcceptEntityInput(explode, "Explode");
	AcceptEntityInput(explode, "Kill");
	return Plugin_Continue;
}
public Action OnAttacked(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if(hitgroup != 1)
	{
/*		if(!IsValidClient(victim))
			return Plugin_Continue;
		if(IsBoss(attacker))
			return Plugin_Continue;
		int weapon = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);
		if(!IsValidEntity(weapon))
			return Plugin_Continue;
		if(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 1098)
			ClassicCount(attacker, victim, weapon); */
		return Plugin_Continue;
	}
	if(damagetype & DMG_CRIT)
		return Plugin_Continue;
	if (!IsValidClient(attacker))
		return Plugin_Continue;
	if(IsBoss(attacker))
		return Plugin_Continue;
	int weapon = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);
	if(!IsValidEntity(weapon))
		return Plugin_Continue;
	static char classname[32];
	if(GetEntityClassname(weapon, classname, sizeof(classname)) && !StrContains(classname, "tf_weapon_minigun", false))
	{
		damagetype |= DMG_CRIT|DMG_BULLET;
		return Plugin_Changed;
	}
	if(GetEntityClassname(weapon, classname, sizeof(classname)) && !StrContains(classname, "tf_weapon_sniperrifle", false))
	{
		if(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 1098)
		{
//			ClassicCount(attacker, victim, weapon);
			damage *= 1.79;
			damagetype |= DMG_CRIT;
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

void ClassicCount(int attacker, int victim, int weapon)
{
	if(ClassicHITs[attacker] > 30)
	{
		ClassicHITs[attacker] = 0;
		if(ClassicStack[attacker] < 3)
			ClassicStack[attacker]++;
	}
	else
	{
		ClassicHITs[attacker]++;
		switch(ClassicHITs[attacker])
		{
			case 10, 20, 30:
			{
				int pew = CreateEntityByName("tf_projectile_energy_ring");
				if(IsValidEntity(pew))
				{
					int theTeam = GetClientTeam(attacker);
					float pos[3], ang[3], vec[3], right[3];
					GetClientEyeAngles(attacker, ang);
					GetClientEyePosition(attacker, pos);
					EmitAmbientSound("weapons/capper_shoot.wav", pos, attacker);
					GetAngleVectors(ang, vec, right, NULL_VECTOR);

					pos[0] += vec[0]*20.0 + right[0]*20.0;
					pos[1] += vec[1]*20.0 + right[1]*20.0;
					pos[2] += vec[2]*20.0 + right[2]*20.0 + 20.0;
					
					ScaleVector(vec, 1500.0);
					vec[2] += 100.0;
					
					ang[2] -= 25.0;
					
					// set its team to ours
					SetVariantInt(theTeam);
					AcceptEntityInput(pew, "TeamNum", -1, -1, 0);
					SetVariantInt(theTeam);
					AcceptEntityInput(pew, "SetTeam", -1, -1, 0); 
					SetEntProp(pew, Prop_Send, "m_nSkin", (theTeam==view_as<int>(TFTeam_Blue)) ? 1 : 0);

					// assign the owner
					SetEntPropEnt(pew, Prop_Send, "m_hOwnerEntity", attacker);

					// assign the weapon launching
					SetEntPropEnt(pew, Prop_Send, "m_hLauncher", weapon);
					SetEntPropEnt(pew, Prop_Send, "m_hOriginalLauncher", weapon);

					// Should be using an extension but this should be good enough
					SetEntPropVector(pew, Prop_Send, "m_vInitialVelocity", vec);
					
	//				SetEntPropFloat(pew, Prop_Send, "m_flDamage", 150.0);
//					DispatchKeyValue(pew, "classname", "tf_projectile_energy_ring");
					TeleportEntity(pew, pos, ang, vec);
					DispatchSpawn(pew);
//					CreateParticle(pew, "raygun_projectile_red_crit", true); //raygun_projectile_red_crit

					TE_SetupBeamFollow(pew, TrailIndex, 0, 2.0, 1.0, 1.0, 10, {255, 102, 200, 255});
					TE_SendToAll();

					int array[2];
					array[hEntref] = EntIndexToEntRef(pew);
					array[hTarget] = victim;
					PushArrayArray(HomingArry, array);
				}
			}
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)	//Sanvich detection
{
	if (condition == TFCond_Taunting && TF2_GetPlayerClass(client) == TFClass_Heavy && SteakEaten[client])
	{
		SteakEaten[client] = false;
		HeavyRaging[client] = true;
		HeavyRageHit[client] = false;
		HeavyRagingTime[client] = GetEngineTime() + 6.0;

		SDKHook(client, SDKHook_PreThink, OnPreThink_Heavy);
		SDKHook(client, SDKHook_StartTouch, OnHeavyTouch);
//		TF2_AddCondition(client, TFCond_Charging, 5.0);
		float position[3], velocity[3], targetpos[3];
		velocity[0] = 0.0; velocity[1] = 0.0; velocity[2] = 750.0;
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", position);
		if(TestTeleportLocation(client, position, targetpos, 0.0, 0.0, 95.0))
		{
			position[2] += 10.0;
			
			TeleportEntity(client, position, NULL_VECTOR, velocity);
		}
		CreateTimer(6.0, Timer_StopRaging, client, TIMER_FLAG_NO_MAPCHANGE);
		position[0] = 0.0; position[1] = 0.0; position[2] = 35.0;
		AttachParticle(client, "flaming_slap_3", 5.0, position, true);
	}
}

public void OnGameFrame()
{
	for(int i = GetArraySize(HomingArry) - 1; i >= 0; i--)
	{
		int iData[2];
		GetArrayArray(HomingArry, i, iData);
		if(!IsValidEntity(iData[hEntref]))
		{
			RemoveFromArray(HomingArry, i);
			return;
		}
		if(!IsLivingPlayer(iData[hTarget]))
		{
			RemoveFromArray(HomingArry, i);
			return;
		}
		HomingProjectile_TurnToTarget(iData[hTarget],iData[hEntref]);
	}
}

public MRESReturn DHook_ResolveFlyCollisionCustom(int iProjectile, DHookParam hParams)
{
	if (GetEntProp(iProjectile, Prop_Send, "m_nForceBone") >= 16)
		return MRES_Ignored;
	
	return MRES_Supercede;
}

public MRESReturn CTFPlayer_DoTauntAttack(int pThis)
{
	if (!TF2_IsPlayerInCondition(pThis, TFCond_Taunting) || !IsPlayerAlive(pThis))
		return MRES_Ignored;

	int tauntatk = GetEntData(pThis, FindSendPropInfo("CTFPlayer", "m_iSpawnCounter") - 24);
//	int tauntatk = GetEntData(pThis, offs_CTFPlayer_iTauntAttack);
	if (tauntatk == 6) //TAUNTATK_SCOUT_GRAND_SLAM
	{

		float vecForward[3];
		float ang[3]; GetClientEyeAngles(pThis, ang);
//		ang[2] = GetEntPropFloat(pThis, Prop_Send, "m_angEyeAngles[1]");
		ang[0] = ang[2] = 0.0;
		GetAngleVectors(ang, vecForward, NULL_VECTOR, NULL_VECTOR);

		float vecCenter[3], vecFwdScaled[3];
		vecFwdScaled = vecForward;
		ScaleVector(vecFwdScaled, 64.0);
		AddVectors(WorldSpaceCenter(pThis), vecFwdScaled, vecCenter);

		float vecSize[3] = {24.0, 24.0, 24.0};
		ScaleVector(vecSize, 1.5);
//		vecSize[2] = 24.0;
		// Respect the scale
		float vecSizeN[3];
		vecSizeN[0] = -vecSize[0];
		vecSizeN[1] = -vecSize[1];
		vecSizeN[2] = -vecSize[2];

//		float vecStart[3], vecEnd[3];
//		SubtractVectors(vecCenter, vecSize, vecStart);
//		AddVectors(vecCenter, vecSize, vecEnd);

		ArrayList objects = new ArrayList();	// Half-assed UTIL_EntitiesInBox
//		TR_EnumerateEntitiesHull(vecCenter, vecCenter, vecStart, vecEnd, PARTITION_SOLID_EDICTS, ReflectHullTrace, objects);

		TR_TraceHullFilter(vecCenter, vecCenter, vecSizeN, vecSize, MASK_SOLID, ReflectHullTrace, objects);

		float vecToTarget[3];
		int pTarget;
		for (int i = 0; i < objects.Length; ++i)
		{
			pTarget = objects.Get(i);
			SubtractVectors(WorldSpaceCenter(pTarget), WorldSpaceCenter(pThis), vecToTarget);
			NormalizeVector(vecToTarget, vecToTarget);

			float flDot = GetVectorDotProduct(vecForward, vecToTarget);
			if (flDot < 0.70)
				continue;


//			if (GetEntProp(pTarget, Prop_Send, "m_iTeamNum") == GetEntProp(pThis, Prop_Send, "m_iTeamNum"))
//				continue;

			// Do a quick trace and make sure we have LOS.
			TR_TraceRayFilter(WorldSpaceCenter(pThis), WorldSpaceCenter(pTarget), MASK_SOLID, RayType_EndPoint, TheTrace, pThis);

			// This was literally hit or miss, opting for direct line instead
//			if (TR_GetFraction() < 1.0)
//				continue;

			if (!TR_DidHit() || TR_GetEntityIndex() == pTarget)
			{

				if(IsLivingPlayer(pTarget) && pTarget != pThis)
				{

					float vecForward_Tar[3];
					vecForward_Tar = vecForward;
					ScaleVector(vecForward_Tar, 2500.0);
					vecForward_Tar[2] += 600.0;
					EmitSoundToAll("player/pl_impact_stun.wav", pThis);
					
					TeleportEntity(pTarget, NULL_VECTOR, NULL_VECTOR, vecForward_Tar);
				}
				else if (GetEntProp(pTarget, Prop_Send, "m_iTeamNum") != GetEntProp(pThis, Prop_Send, "m_iTeamNum"))
					Deflect(pTarget, pThis, ang, vecForward, true);
			}
		}

		delete objects;
	}
	
	return MRES_Ignored;
}

void Deflect(int ent, int owner, float vecEye[3], float vecFwd[3], bool grandslam = false)
{
	float vecVel[3]; vecVel = GetVelocity(ent);
	float speed = GetVectorLength(vecVel);

	ScaleVector(vecFwd, speed);
	ScaleVector(vecFwd, 1.15);	// To be fair you are SWINGING a bat, so velocity should go up, right?
												// Or down if you want that

	EmitSoundToAll("mvm/melee_impacts/bat_baseball_hit_robo01.wav", owner);

	if (grandslam)
	{
		ScaleVector(vecFwd, 1.15);
		// And the crowd goes WILD
		CreateTimer(0.5, Timer_Cheer, GetClientUserId(owner), TIMER_FLAG_NO_MAPCHANGE);
	}

	TeleportEntity(ent, NULL_VECTOR, vecEye, vecFwd);

	SetEntProp(ent, Prop_Send, "m_iDeflected", GetEntProp(ent, Prop_Send, "m_iDeflected")+1);
	char classname[32]; GetEntityClassname(ent, classname, sizeof(classname));

	if (!StrEqual(classname, "tf_projectile_pipe_remote", false))	// Shouldn't own sticky bombs
	{
		int team = GetClientTeam(owner);
		if (HasEntProp(ent, Prop_Send, "m_hDeflectOwner"))
			SetEntPropEnt(ent, Prop_Send, "m_hDeflectOwner", owner);
		if (HasEntProp(ent, Prop_Send, "m_hLauncher"))
			SetEntPropEnt(ent, Prop_Send, "m_hLauncher", owner);
		if (HasEntProp(ent, Prop_Send, "m_hThrower"))
			SetEntPropEnt(ent, Prop_Send, "m_hThrower", owner);		// ONE of these HAS to work

		SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", owner);
		SetEntProp(ent, Prop_Send, "m_iTeamNum", team);
		SetEntProp(ent, Prop_Send, "m_nSkin", team-2);
	}
}

public Action Timer_Cheer(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client)
		EmitSoundToAll("passtime/crowd_cheer.wav", client);
	return Plugin_Continue;
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

public bool ReflectHullTrace(int ent, int mask, ArrayList objs)
{
	if (ent <= MaxClients)
	{
		if(IsLivingPlayer(ent))
		{
			if (objs.FindValue(ent) != -1)	// o_0
				return false;
			objs.Push(ent);
		}
		return false;
	}
	if (!HasEntProp(ent, Prop_Send, "m_iDeflected"))
		return false;

	char cls[32]; GetEntityClassname(ent, cls, sizeof(cls));
	if (strncmp(cls, "tf_proj", 7, false))
		return false;

	if (objs.FindValue(ent) != -1)	// o_0
		return false;

//	TR_ClipCurrentRayToEntity(MASK_SOLID, ent);
//	if (!TR_DidHit())
//		return false;

	objs.Push(ent);
	return false;
}


public void OnEntityCreated(int entity, const char[] classname)
{

	if(!strcmp(classname, "tf_projectile_energy_ring"))
	{
		RequestFrame(BisonPostSpawnPost, EntIndexToEntRef(entity));
		hHookResolveFlyCollisionCustom.HookEntity(Hook_Pre, entity, DHook_ResolveFlyCollisionCustom);
		CreateTimer(20.0, Timer_Killbison, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);

		BisonTouched[entity] = false;
	}
	if(!strcmp(classname, "tf_projectile_energy_ball"))
	{
		RequestFrame(CowPostSpawnPost, EntIndexToEntRef(entity));
	}
	if(!strcmp(classname, "instanced_scripted_scene"))
		SDKHook(entity, SDKHook_Spawn, OnSceneSpawned);
//	if(!strcmp(classname, "tf_projectile_arrow"))
//		RequestFrame(ArrowPostSpawnPost, EntIndexToEntRef(entity));
}

/*public void ArrowPostSpawnPost(int entref)
{
	if (!IsValidEntity(entref))
		return;
	int arrow = EntRefToEntIndex(entref);
	SetEntData(arrow, FindSendPropInfo("CTFProjectile_Arrow", "m_bCritical") + 1, 1, 1, true); // arrow penetration
//	SetEntityModel(arrow, SPHERE_GV);
	SetEntProp(arrow, Prop_Send, "m_CollisionGroup", 27); // TFCOLLISION_GROUP_ROCKET_BUT_NOT_WITH_OTHER_ROCKETS
	SetEntProp(arrow, Prop_Send, "m_nSolidType", 6);
	SetEntProp(arrow, Prop_Send, "m_usSolidFlags", 12); // FSOLID_NOT_SOLID | FSOLID_TRIGGER
	SetEntityRenderMode(arrow, RENDER_TRANSCOLOR);
//	SetEntProp(arrow, Prop_Data, "m_nRenderFX", 11);
//	SetEntityMoveType(arrow, MOVETYPE_NOCLIP);
	SDKHook(arrow, SDKHook_ShouldCollide, OnArrowTouch);
}

public bool OnArrowTouch(int entity, int collisiongroup, int contentsmask, bool originalResult)
{
	if(collisiongroup & CONTENTS_PLAYERCLIP != 0)
		return true;
	return originalResult;
}*/

public void OnEntityDestroyed(int iEntity)
{
/*	if(!IsValidEntity(iEntity))
		return;
	char sClassName[96];
	if(GetEntityClassname(iEntity, sClassName, sizeof(sClassName)))
	{
		if(!strcmp(sClassName, "tf_projectile_jar"))
		{
		
		}
	}
*/
}

public Action OnSceneSpawned(int entity)
{
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwner");
//	int boss = GetClientOfUserId(FF2_GetBossUserId(0));
//	if(!IsValidClient(boss))
//		return Plugin_Continue;
	char scenefile[128];
//	PrintToChat(client, "TEST");
	GetEntPropString(entity, Prop_Data, "m_iszSceneFile", scenefile, sizeof(scenefile));
	if(!strcmp(scenefile, "scenes/player/heavy/low/taunt04.vcd"))
	{
//		PrintToChat(client, "TEST 1");
//		if(!IsBoss(client) && GetClientTeam(client) != GetClientTeam(boss))
		if(IsBoss(client))
			return Plugin_Continue;
		int wep = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(!IsValidEntity(wep))
			return Plugin_Continue;
		int index = GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex");
		if(index == 311)
			SteakEaten[client] = true;
	}
	return Plugin_Continue;
}

public Action OnHeavyTouch(int client, int victim)
{
//	float origin[3], angles[3], targetpos[3];
	if(!HeavyRageHit[client] && HeavyRaging[client])
	{
		SDKUnhook(client, SDKHook_PreThink, OnPreThink_Heavy);
/*		if(IsValidClient(victim) && IsPlayerAlive(victim) && GetClientTeam(client) != GetClientTeam(victim))
		{
			GetClientEyeAngles(client, angles);
			GetClientEyePosition(client, origin);
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", targetpos);
			GetAngleVectors(angles, angles, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(angles, angles);
			SubtractVectors(targetpos, origin, origin);
			
			if(GetVectorDotProduct(origin, angles) > 0.0)
			{
				SDKHooks_TakeDamage(victim, client, client, 400.0, DMG_CRUSH|DMG_ALWAYSGIB);
				TF2_RemoveCondition(client, TFCond_Charging);
				HeavyRageHit[client] = true;
				CreateTimer(1.0, Timer_ResetHit, client, TIMER_FLAG_NO_MAPCHANGE);
				HeavyRaging[client] = false;
//				float position[3];
//				GetEntPropVector(client, Prop_Data, "m_vecOrigin", position);
				float angle[3];
				GetEntPropVector(client, Prop_Data, "m_angRotation", angle);
				angle[0] = -angle[0]; //fixAngle(angle[0] + 180.0);
				angle[1] = fixAngle(angle[1] + 180.0);
				
				float velocity[3];
				GetAngleVectors(angle, velocity, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(velocity, 550.0);
				velocity[2] = 450.0;
				TeleportEntity(client, position, NULL_VECTOR, velocity);
			}
		}*/

		HeavyRageHit[client] = true;
		CreateTimer(1.0, Timer_ResetHit, client, TIMER_FLAG_NO_MAPCHANGE);
		HeavyRaging[client] = false;
		SDKUnhook(client, SDKHook_StartTouch, OnHeavyTouch);
		RequestFrame(HeavyTouchPost, client);

	}
	return Plugin_Continue;
}

public void HeavyTouchPost(int client) {
	float origin[3], angles[3];
	GetClientEyeAngles(client, angles);
	GetAngleVectors(angles, angles, NULL_VECTOR, NULL_VECTOR);
	NegateVector(angles);
	NormalizeVector(angles, angles);
	ScaleVector(angles, 650.0);
	angles[2] = 450.0;
	
	TF2_AddCondition(client, TFCond_Bonked, 0.1);
	TF2_AddCondition(client, TFCond_MegaHeal, 1.0);
	
	int explosion=CreateEntityByName("env_explosion");
	DispatchKeyValueFloat(explosion, "DamageForce", 0.0);
	DispatchKeyValue(explosion, "targetname", "explosion");
//	DispatchKeyValue(explosion, "spawnflags", "2048");
	DispatchKeyValue(explosion, "rendermode", "5");
	DispatchKeyValue(explosion, "fireballsprite", "spirites/zerogxplode.spr");

	SetEntProp(explosion, Prop_Data, "m_iMagnitude", cvar_steak_dmg.IntValue);
	SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", cvar_steak_radius.IntValue);

	SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", client);

	DispatchSpawn(explosion);
	
//		float EntPos[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", origin);
	
	TeleportEntity(explosion, origin, NULL_VECTOR, NULL_VECTOR);
	
	AcceptEntityInput(explosion, "Explode");
	AcceptEntityInput(explosion, "Kill");
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, angles);
	
//	PrintToChat(client, "boom");
}

public Action Timer_StopRaging(Handle timer, int client)
{
	HeavyRaging[client] = false;
	SDKUnhook(client, SDKHook_PreThink, OnPreThink_Heavy);
	return Plugin_Continue;
}

public Action Timer_ResetHit(Handle timer, int client)
{
	HeavyRageHit[client] = false;
	return Plugin_Continue;
}

public void OnPreThink_Heavy(int client)
{
	if(HeavyRaging[client])
	{
		float TimeRemain = HeavyRagingTime[client] - GetEngineTime();
		if(TimeRemain < 0)
			return;
		if(TimeRemain > 5.5)
			return;
		float angles[3];
		GetClientEyeAngles(client, angles);
		float velocity[3], Horizon[3];
		GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
		Horizon[0]=velocity[0];
		Horizon[1]=velocity[1];
		Horizon[2]=0.0;
		ScaleVector(velocity, 750.0);
		ScaleVector(Horizon, 750.0);
		Horizon[2]=velocity[2];

		if(TimeRemain >= 1.0)
			Horizon[2] *= TimeRemain/4.0;
		else
			Horizon[2] += 0.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Horizon);
		
		bool onGround = (GetEntityFlags(client) & FL_ONGROUND) != 0;
		if (onGround && !Heavy_WasOnGroundLastTick[client])
		{
			SDKUnhook(client, SDKHook_StartTouch, OnHeavyTouch);
			if(!HeavyRageHit[client] && HeavyRaging[client])
			{
				HeavyRageHit[client] = true;
				CreateTimer(1.0, Timer_ResetHit, client, TIMER_FLAG_NO_MAPCHANGE);
				HeavyRaging[client] = false;

				SDKUnhook(client, SDKHook_PreThink, OnPreThink_Heavy);

				RequestFrame(HeavyTouchPost, client);
			}
		}
		Heavy_WasOnGroundLastTick[client] = onGround;

	}
}

public void CowPostSpawnPost(int entref) {
//	int entity = EntRefToEntIndex(entref);
	if (!IsValidEntity(entref))
	{
		return;
	}
	int owner = GetEntPropEnt(entref, Prop_Send, "m_hOwnerEntity");
	
	if(!IsValidClient(owner))
		return;
//	PrintToChat(owner, "TEST");
	char targetname[128];
	GetEntPropString(entref, Prop_Data, "m_iName", targetname, sizeof(targetname));
	if(!StrContains(targetname, "BonusBall"))
		return;
	if(GetEntProp(entref, Prop_Send, "m_bChargedShot"))
	{
//		PrintToChat(owner, "TEST 2");
		SDKHook(entref, SDKHook_StartTouch, OnCowTouch);
		SDKHook(entref, SDKHook_Touch, OnCowTouch);
	}
}

public Action OnCowTouch(int entity, int client)
{
	if (!IsValidEntity(entity))
		return Plugin_Continue;
	if(!GetEntProp(entity, Prop_Send, "m_bChargedShot"))
		return Plugin_Continue;
	if(!IsValidClient(client))
		return Plugin_Continue;
	int iLauncher = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");
	if(!IsValidEntity(iLauncher))
		return Plugin_Continue;
	if(!HasEntProp(iLauncher, Prop_Send, "m_iItemDefinitionIndex"))
		return Plugin_Continue;
	if(GetEntProp(iLauncher, Prop_Send, "m_iItemDefinitionIndex") != 441)
		return Plugin_Continue;
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	int boss = GetClientOfUserId(FF2_GetBossUserId(0));
	if(!IsValidClient(owner) || !IsValidClient(boss))
		return Plugin_Continue;
	if(owner == client)
		return Plugin_Continue;
	if(GetClientTeam(owner) == GetClientTeam(client))
		return Plugin_Continue;
	if(!IsBoss(owner) && GetClientTeam(owner) != GetClientTeam(boss))
	{
		int index = GetEntProp(GetPlayerWeaponSlot(owner, TFWeaponSlot_Primary), Prop_Send, "m_iItemDefinitionIndex");
		if(index == 441)
		{
			TF2_StunPlayer(client, 0.3, 0.0, TF_STUNFLAGS_BIGBONK, owner); 
//			PrintToChat(owner, "Direct HIT");
			float pos[3];
			pos[2] = 90.0;
			pos[0] = 40.0; pos[1] = 40.0;//target[0] = client;
			CreateRocket(owner, client, pos, 85.0, 900.0, true);
//			Rocket_Bonus[0] = EntIndexToEntRef(CreateRocket(owner, client, pos, 200.0, 1200.0, true));
			pos[0] = -40.0;pos[1] = -40.0;//target[1] = client;
			CreateRocket(owner, client, pos, 85.0, 900.0, true);
//			Rocket_Bonus[1] = EntIndexToEntRef(CreateRocket(owner, client, pos, 200.0, 1200.0, true));
			pos[0] = 40.0; pos[1] = -40.0;//target[2] = client;
			CreateRocket(owner, client, pos, 85.0, 900.0, true);
//			Rocket_Bonus[2] = EntIndexToEntRef(CreateRocket(owner, client, pos, 200.0, 1200.0, true));
			pos[0] = -40.0; pos[1] = 40.0;//target[3] = client;
			CreateRocket(owner, client, pos, 85.0, 900.0, true);
//			Rocket_Bonus[3] = EntIndexToEntRef(CreateRocket(owner, client, pos, 200.0, 1200.0, true));
		}
	}
	return Plugin_Continue;
}

public int CreateRocket(int clientIdx, int victim, float posoffset[3], float damage, float speed, bool isCharged)
{
	// create our rocket. no matter what, it's going to spawn, even if it ends up being out of map
	char classname[48] = "CTFProjectile_EnergyBall";
	char entname[48] = "tf_projectile_energy_ball";
	int ClientTeam = GetClientTeam(clientIdx);
	int rocket = CreateEntityByName(entname);
	if (!IsValidEntity(rocket))
	{
		PrintToServer("Error: Invalid entity %s. Won't spawn rocket. This is my fault.", entname);
		return -1;
	}
	
	// determine spawn position
	float spawnPosition[3];
	if(!IsValidClient(victim))
	{
		GetEntPropVector(clientIdx, Prop_Data, "m_vecOrigin", spawnPosition);
		spawnPosition[2] += 70.0;
	}
	else
	{
		GetEntPropVector(victim, Prop_Data, "m_vecOrigin", spawnPosition);
		spawnPosition[0] += posoffset[0];
		spawnPosition[1] += posoffset[1];
		spawnPosition[2] += posoffset[2];
	}
//	// get angles for rocket (smart targeting)
	float spawnAngles[3];
//	float eyePos[3];
//	float eyeAngles[3];
//	GetClientEyePosition(clientIdx, eyePos);
//	GetClientEyeAngles(clientIdx, eyeAngles);
		
	// trace
	float endPos[3];
	GetEntPropVector(victim, Prop_Data, "m_vecOrigin", endPos);
//	Handle trace = TR_TraceRay(spawnPosition, endPos, MASK_SOLID, RayType_EndPoint, TraceRedPlayersAndBuildings);
//	TR_GetEndPosition(endPos, trace);
//	CloseHandle(trace);
		
	// get the angle the line from the rocket spawn to the object we care about. that's our spawn angle.
	GetRayAngles(spawnPosition, endPos, spawnAngles);
	
	// determine velocity
	float spawnVelocity[3];
	GetAngleVectors(spawnAngles, spawnVelocity, NULL_VECTOR, NULL_VECTOR);
	spawnVelocity[0] *= speed;
	spawnVelocity[1] *= speed;
	spawnVelocity[2] *= speed;
	
	// deploy!
	TeleportEntity(rocket, spawnPosition, spawnAngles, spawnVelocity);
	SetEntProp(rocket, Prop_Send, "m_bChargedShot", isCharged); // charged shot
	SetEntDataFloat(rocket, FindSendPropInfo(classname, "m_iDeflected") + 4, damage, true); // credit to voogru
	SetEntProp(rocket, Prop_Send, "m_nSkin", (ClientTeam==view_as<int>(TFTeam_Blue)) ? 1 : 0);
	SetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity", clientIdx);
	SetVariantInt(ClientTeam);
	AcceptEntityInput(rocket, "TeamNum", -1, -1, 0);
	SetVariantInt(ClientTeam);
	AcceptEntityInput(rocket, "SetTeam", -1, -1, 0); 
	DispatchKeyValue(rocket, "targetname", "BonusBall");
	DispatchKeyValue(rocket, "model", EGG);
	DispatchSpawn(rocket);
	
	// to get stats from the user's melee weapon
	SetEntPropEnt(rocket, Prop_Send, "m_hOriginalLauncher", GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Primary));
	SetEntPropEnt(rocket, Prop_Send, "m_hLauncher", GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Primary));
	
//	SetEntProp(rocket, Prop_Send, "m_nModelIndex", EGG);
//	CreateParticle(rocket, "rocket_trail_classic", true);
	
	return rocket;
}

stock int CreateParticle(int iEntity, char[] strParticle, bool bAttach = false, char[] strAttachmentPoint="", float fOffset[3]={0.0, 0.0, 0.0})
{
    int iParticle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(iParticle))
    {
        float fPosition[3], fAngles[3], fForward[3], fRight[3], fUp[3];
        
        // Retrieve entity's position and angles
        GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPosition);
		
        // Determine vectors and apply offset
        GetAngleVectors(fAngles, fForward, fRight, fUp);
        fPosition[0] += fRight[0]*fOffset[0] + fForward[0]*fOffset[1] + fUp[0]*fOffset[2];
        fPosition[1] += fRight[1]*fOffset[0] + fForward[1]*fOffset[1] + fUp[1]*fOffset[2];
        fPosition[2] += fRight[2]*fOffset[0] + fForward[2]*fOffset[1] + fUp[2]*fOffset[2];
        
        // Teleport and attach to client
        TeleportEntity(iParticle, fPosition, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(iParticle, "effect_name", strParticle);

        if (bAttach)
        {
            SetVariantString("!activator");
            AcceptEntityInput(iParticle, "SetParent", iEntity, iParticle, 0);            
            
            if (!StrEqual(strAttachmentPoint, ""))
            {
                SetVariantString(strAttachmentPoint);
                AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iParticle, iParticle, 0);                
            }
        }

        // Spawn and start
        DispatchSpawn(iParticle);
        ActivateEntity(iParticle);
        AcceptEntityInput(iParticle, "Start");
    }

    return iParticle;
}

public void BisonPostSpawnPost(int entref) {
	int entity = EntRefToEntIndex(entref);
	if (!IsValidEntity(entity))
	{
		return;
	}
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	int boss = GetClientOfUserId(FF2_GetBossUserId(0));
	if(!IsValidClient(owner) || !IsValidClient(boss))
	{
		return;
	}
	if(!IsBoss(owner) && GetClientTeam(owner) != GetClientTeam(boss))
	{
		int wep = GetPlayerWeaponSlot(owner, TFWeaponSlot_Secondary);
		if(!IsValidEntity(wep))
			return;
		int index = GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex");
		if(index == 442)
		{
			float vecVelocity[3];
			GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vecVelocity);
			// the pomson starts to break down around 3600HU/s (3x speed)
			ScaleVector(vecVelocity, 0.48);
			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vecVelocity);
			SetEntProp(entity, Prop_Send, "m_nForceBone", 0);
			SDKHook(entity, SDKHook_StartTouch, OnBisonTouch);
//			SDKHook(entref, SDKHook_Touch, OnBisonTouch);
		}
	}
}

public Action OnBisonTouch(int entity, int other)
{
	int touchnum = GetEntProp(entity, Prop_Send, "m_nForceBone");
	if(touchnum >= 16)
		return Plugin_Continue;
	if( other > 0 && other <= MaxClients )
		return Plugin_Continue;
	
	SDKHook(entity, SDKHook_Touch, OnBisonTouched);

	return Plugin_Handled;
}

public Action OnBisonTouched(int iProjectile, int iWall)
{
	float vOrigin[3];
	GetEntPropVector(iProjectile, Prop_Data, "m_vecOrigin", vOrigin);
	
	float vAngles[3];
	GetEntPropVector(iProjectile, Prop_Data, "m_angRotation", vAngles);
	
	float vVelocity[3];
	vVelocity = GetVelocity(iProjectile);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TEF_ExcludeEntity, iProjectile);
	
	if(!TR_DidHit(trace))
	{
		CloseHandle(trace);
		return Plugin_Continue;
	}
	
	float vNormal[3];
	TR_GetPlaneNormal(trace, vNormal);
	
	CloseHandle(trace);
	
//	PrintToChatAll("Surface Normal: [%.2f, %.2f, %.2f]", vNormal[0], vNormal[1], vNormal[2]);
	
	float dotProduct = GetVectorDotProduct(vNormal, vVelocity);
	
	ScaleVector(vNormal, dotProduct);
	ScaleVector(vNormal, 2.0);
	
	float vBounceVec[3];
	SubtractVectors(vVelocity, vNormal, vBounceVec);
	
	float vNewAngles[3];
	GetVectorAngles(vBounceVec, vNewAngles);
	
//	float offset[3];
//	GetAngleVectors(vAngles, offset, NULL_VECTOR, NULL_VECTOR);
//	ScaleVector(offset, 5.0);
//	vOrigin[0] -= offset[0];
//	vOrigin[1] -= offset[1];
//	vOrigin[2] -= offset[2];
	
	TeleportEntity(iProjectile, vOrigin, vNewAngles, vBounceVec);

//	PrintToChatAll("Angles: [%.2f, %.2f, %.2f] -> [%.2f, %.2f, %.2f]", vAngles[0], vAngles[1], vAngles[2], vNewAngles[0], vNewAngles[1], vNewAngles[2]);
//	PrintToChatAll("Velocity: [%.2f, %.2f, %.2f] |%.2f| -> [%.2f, %.2f, %.2f] |%.2f|", vVelocity[0], vVelocity[1], vVelocity[2], GetVectorLength(vVelocity), vBounceVec[0], vBounceVec[1], vBounceVec[2], GetVectorLength(vBounceVec));

	EmitSoundToAll("weapons/fx/rics/bison_projectile_impact_world.wav", iProjectile, _, SNDLEVEL_TRAIN,_,0.1);

	int touchnum = GetEntProp(iProjectile, Prop_Send, "m_nForceBone");
//	PrintToChatAll("Touchnum: %d, touch by %d", touchnum, iWall);
	touchnum++;
	SetEntProp(iProjectile, Prop_Send, "m_nForceBone", touchnum);

	SDKUnhook(iProjectile, SDKHook_Touch, OnBisonTouched);
	return Plugin_Handled;
}

public bool TEF_ExcludeEntity(int entity, int contentsMask, int data)
{
	return (entity != data);
}

/*public Action OnBisonTouch(int entity, int client)
{
//	if (!IsValidEntity(entity))
//		return Plugin_Continue;
	if(!IsValidClient(client))
		return Plugin_Continue;
	if(BisonTouched[entity])
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
			SDKHooks_TakeDamage(client, client, client, 3.0, DMG_SHOCK);
		return Plugin_Continue;
	}
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	int boss = GetClientOfUserId(FF2_GetBossUserId(0));
	if(!IsValidClient(owner) || !IsValidClient(boss))
		return Plugin_Continue;
	if(owner == client)
		return Plugin_Continue;
	if(GetClientTeam(owner) == GetClientTeam(client))
		return Plugin_Continue;
//	if(!IsBoss(owner) && GetClientTeam(owner) != GetClientTeam(boss))
//	{
//		int index = GetEntProp(GetPlayerWeaponSlot(owner, TFWeaponSlot_Secondary), Prop_Send, "m_iItemDefinitionIndex");
//		if(index == 442)
//		{
	float vecVelocity[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vecVelocity);
	// the pomson starts to break down around 3600HU/s (3x speed)
	ScaleVector(vecVelocity, 0.25);
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vecVelocity);
	BisonTouched[entity] = true;
	CreateTimer(0.1, Timer_Backbison, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
//		}
//	}
	return Plugin_Continue;
}

public Action Timer_Backbison(Handle timer, int entref)
{
//	int entity = EntRefToEntIndex(entref);
	if (IsValidEntity(entref))
	{
	
		float angle[3];
		GetEntPropVector(entref, Prop_Data, "m_angRotation", angle);
		angle[0] = -angle[0]; //fixAngle(angle[0] + 180.0);
		angle[1] = fixAngle(angle[1] + 180.0);
		
		// redo velocity
		float velocity[3];
		GetAngleVectors(angle, velocity, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(velocity, 350.0);
		
		// move the entref out a little to prevent touches from stacking
		float position[3];
		GetEntPropVector(entref, Prop_Data, "m_vecOrigin", position);
		//new Float:offset[3];
		//GetAngleVectors(angle, offset, NULL_VECTOR, NULL_VECTOR);
		//ScaleVector(offset, 5.0);
		//position[0] -= offset[0];
		//position[1] -= offset[1];
		//position[2] -= offset[2];
		
		// teleport
		TeleportEntity(entref, position, angle, velocity);
	}
	return Plugin_Continue;
}*/

public Action Timer_Killbison(Handle timer, int entref)
{
//	int entity = EntRefToEntIndex(entref);
	if (IsValidEntity(entref))
	{
		AcceptEntityInput(entref, "Kill");
	}
	return Plugin_Continue;
}

void HomingProjectile_TurnToTarget(int client, int iProjectile)
{
	if(!IsValidEntity(iProjectile))
	return;
	float flTargetPos[3];
	GetClientAbsOrigin(client, flTargetPos);
	float flRocketPos[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flRocketPos);

//	float flInitialVelocity[3];
//	GetEntPropVector(iProjectile, Prop_Send, "m_vInitialVelocity", flInitialVelocity);
//	float flSpeedInit = GetVectorLength(flInitialVelocity);
//	float flSpeedBase = flSpeedInit * 1500.0;
	
	//flTargetPos[2] += 50.0;
	flTargetPos[2] += 30 + Pow(GetVectorDistance(flTargetPos, flRocketPos), 2.0) / 10000;
	
	float flNewVec[3];
	SubtractVectors(flTargetPos, flRocketPos, flNewVec);
	NormalizeVector(flNewVec, flNewVec);
	
	float flAng[3];
	GetVectorAngles(flNewVec, flAng);

//	float flSpeedNew = flSpeedBase;

	
	ScaleVector(flNewVec, 1500.0);
	TeleportEntity(iProjectile, NULL_VECTOR, flAng, flNewVec);
}

//public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
//{
//	return Plugin_Continue;
//}

stock int SpawnWeapon(	int client, char[] name, int index, int level, int qual, const char[] att)
{
	Handle hWeapon=TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if(hWeapon==INVALID_HANDLE)
	{
		return -1;
	}

	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	char atts[32][32];
	int count=ExplodeString(att, ";", atts, 32, 32);

	if(count % 2)
	{
		--count;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		int i2;
		for(int i; i<count; i+=2)
		{
			int attrib=StringToInt(atts[i]);
			if(!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
				delete hWeapon;
				return -1;
			}

			TF2Items_SetAttribute(hWeapon, i2, attrib, StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(hWeapon, 0);
	}

	int entity=TF2Items_GiveNamedItem(client, hWeapon);
	delete hWeapon;
	
	if(entity == -1)
		return -1;
	
	EquipPlayerWeapon(client, entity);
	
	SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);
	
	return entity;
}

stock int AttachParticle(int entity, const char[] szParticleType, float flTimeToDie = -1.0, float vOffsets[3] = {0.0,0.0,0.0}, bool bAttach = false, float flTimeToStart = -1.0)
{
    int particle = CreateEntityByName("info_particle_system");
    if (IsValidEntity(particle))
    {
        float vPos[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
        AddVectors(vPos, vOffsets, vPos);
        TeleportEntity(particle, vPos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", szParticleType);
        DispatchSpawn(particle);
        if (bAttach)
        {
            SetParent(entity, particle);
            SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
        }
        ActivateEntity(particle);
        if (flTimeToStart > 0.0)
        {
            char szAddOutput[32];
            Format(szAddOutput, sizeof(szAddOutput), "OnUser1 !self,Start,,%0.2f,1", flTimeToStart);
            SetVariantString(szAddOutput);
            AcceptEntityInput(particle, "AddOutput");
            AcceptEntityInput(particle, "FireUser1");
            if (flTimeToDie > 0.0)
                flTimeToDie += flTimeToStart;
        }
        else
            AcceptEntityInput(particle, "Start");

        if (flTimeToDie > 0.0)
            killEntityIn(particle, flTimeToDie); // Interestingly, OnUser1 can be used multiple times, as the code above won't conflict with this.
        return particle;
    }
    return -1;
}

stock void killEntityIn(int iEnt, float flSeconds)
{
    char szAddOutput[32];
    Format(szAddOutput, sizeof(szAddOutput), "OnUser1 !self,Kill,,%0.2f,1", flSeconds);
    SetVariantString(szAddOutput);
    AcceptEntityInput(iEnt, "AddOutput");
    AcceptEntityInput(iEnt, "FireUser1");
}

stock void SetParent(int parent, int child)
{
    SetVariantString("!activator");
    AcceptEntityInput(child, "SetParent", parent, child);
}

stock float fixAngle(float angle)
{
	int sanity = 0;
	while (angle < -180.0 && (sanity++) <= 10)
		angle = angle + 360.0;
	while (angle > 180.0 && (sanity++) <= 10)
		angle = angle - 360.0;
		
	return angle;
}

stock void GetRayAngles(float startPoint[3], float endPoint[3], float angle[3])
{
	float tmpVec[3];
	tmpVec[0] = endPoint[0] - startPoint[0];
	tmpVec[1] = endPoint[1] - startPoint[1];
	tmpVec[2] = endPoint[2] - startPoint[2];
	GetVectorAngles(tmpVec, angle);
}

public bool TestTeleportLocation(int clientIdx, float origin[3], float targetPos[3], float xOffset, float yOffset, float zOffset)
{
	// test the path to the offset, ensure no obstructions
	float endPos[3];
	targetPos[0] = origin[0] + xOffset;
	targetPos[1] = origin[1] + yOffset;
	targetPos[2] = origin[2] + zOffset;
	
	float mins[3];
	float maxs[3];
	GetEntPropVector(clientIdx, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(clientIdx, Prop_Send, "m_vecMaxs", maxs);
	Handle trace = TR_TraceHullFilterEx(origin, targetPos, mins, maxs, MASK_PLAYERSOLID, TraceWallsOnly);
	TR_GetEndPosition(endPos, trace);
	CloseHandle(trace);
	
	// first, the distance check
	if (GetVectorDistance(origin, endPos, true) < GetVectorDistance(origin, targetPos, true))
	{
//		if (PRINT_DEBUG_SPAM)
//			PrintToServer("Distance check failed. Start: %f,%f,%f    End: %f,%f,%f", origin[0], origin[1], origin[2], endPos[0], endPos[1], endPos[2]);
		return false;
	}
		
	// if this is just a teleport above, we've already succeeded
	if (xOffset == 0.0 && yOffset == 0.0)
		return true;
		
	// otherwise, do the pit test, ensuring the teleporter doesn't teleport above a hole (don't want unreachable players)
	float pitFailPos[3];
	pitFailPos[0] = targetPos[0];
	pitFailPos[1] = targetPos[1];
	pitFailPos[2] = targetPos[2] - 40.0;
	trace = TR_TraceHullFilterEx(targetPos, pitFailPos, mins, maxs, MASK_PLAYERSOLID, TraceWallsOnly);
	TR_GetEndPosition(endPos, trace);
	CloseHandle(trace);
	
	if (GetVectorDistance(targetPos, endPos, true) >= GetVectorDistance(targetPos, pitFailPos, true))
	{
//		if (PRINT_DEBUG_SPAM)
//			PrintToServer("Pit test failed. Start: %f,%f,%f    End: %f,%f,%f", targetPos[0], targetPos[1], targetPos[2], endPos[0], endPos[1], endPos[2]);
		return false;
	}
	
	// success!
	return true;
}

public bool TraceWallsOnly(int entity, int contentsMask)
{
	return false;
}



//-----------------------------------------------------------------------------
// Purpose: See if the player's double tapped movement keys
//-----------------------------------------------------------------------------
void CheckForDoubleTap(int client)
{
	float flMaxDoubleTapTimeDelta = 0.1;

	static const int aMoveType[4] =
	{ 
		IN_MOVELEFT, 
		IN_MOVERIGHT, 
		IN_FORWARD, 
		IN_BACK,
		// Add movetypes here
	};

	for ( int i = 0; i < AMOVETYPE; ++i )
	{
		// Record when they let go of the key
		if ( ( GetEntProp(client, Prop_Data, "m_nOldButtons") & aMoveType[i] ) && !( GetEntProp(client, Prop_Data, "m_nButtons") & aMoveType[i] ) )
		{
				m_MoveKeyDownTimes[client][i] = GetGameTime();
		}
		// If the button is down now, and wasn't before...
		else if ( ( GetEntProp(client, Prop_Data, "m_nButtons") & aMoveType[i] ) && !( GetEntProp(client, Prop_Data, "m_nOldButtons") & aMoveType[i] ) )
		{
			// ...check the time delta - if it's within range, consider it a double-tap. 
			if ( GetGameTime() - m_MoveKeyDownTimes[client][i] <= flMaxDoubleTapTimeDelta )
			{
				OnDoubleTapped(client, aMoveType[i] );
			}
		}
	}
}

//-----------------------------------------------------------------------------
// Purpose: See if the player's double tapped movement keys
//-----------------------------------------------------------------------------
void OnDoubleTapped(int client, int Button )
{
	int iTeleportMove = 1;
//	CALL_ATTRIB_HOOK_INT_ON_OTHER( m_pTFPlayer, iTeleportMove, ability_doubletap_teleport );
	if ( iTeleportMove )
	{
		float vecDir[3], vecForward[3], vecRight[3];
		GetClientEyeAngles(client, vecDir);
		GetAngleVectors( vecDir, vecForward, vecRight, NULL_VECTOR );
		
//		vecForward[2] =
		
		if ( Button == IN_MOVELEFT )
		{
			NegateVector(vecRight);
			TeleportMove(client, vecRight, 592.0 );
		}
		else if ( Button == IN_MOVERIGHT )
		{
			TeleportMove(client, vecRight, 592.0 );
		}
		else if ( Button == IN_FORWARD )
		{
			TeleportMove(client, vecForward, 592.0 );
		}
		else if ( Button == IN_BACK )
		{
			NegateVector(vecForward);
			TeleportMove(client, vecForward, 592.0 );
		}
	}

	// DevMsg( "Double Tap! (%i)\n", nKey );
}


//-----------------------------------------------------------------------------
// Purpose: 
//-----------------------------------------------------------------------------
//void TeleportMove(int client, float vecDirection[3], float flDist)
void TeleportMove(int client, float vecDirection[3], float flSpeed)
{
	if ( m_flNextDoubleTapTeleportTime[client] > GetGameTime() )
		return;

/*	float mins[3], maxs[3];
	GetEntPropVector(client, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", maxs);

	// Try full distance
	float vecOrigin[3], vecPos[3];
	GetClientAbsOrigin(client, vecOrigin);
	ScaleVector(vecDirection, flDist);
	AddVectors(vecOrigin, vecDirection, vecPos);
	
	vecPos[2] += 75.0;
	
//	Handle trace = TR_TraceHullFilterEx(vecOrigin, vecPos, mins, maxs, view_as<int>(TF2_GetClientTeam(client))-2 ? MASK_PLAYERSOLID|CONTENTS_BLUETEAM : MASK_PLAYERSOLID|CONTENTS_REDTEAM, TraceIgnoreTeammates, client);
	Handle trace = TR_TraceHullFilterEx(vecOrigin, vecPos, mins, maxs, MASK_PLAYERSOLID, TraceIgnoreTeammates, client);
	if(!TR_DidHit(trace))
	{
		float fraction = TR_GetFraction(trace);
		if(fraction >= 1)
			return;
		float sumVec[3];
		SubtractVectors(vecPos, vecOrigin, sumVec);
		ScaleVector(sumVec, fraction);
		AddVectors(vecOrigin, sumVec, vecPos); 
	}
	float endPos[3];
	TR_GetEndPosition(endPos, trace);
	CloseHandle(trace);*/

	ScaleVector(vecDirection, flSpeed);
	
	
	SetEntPropEnt(client, Prop_Send, "m_hGroundEntity", -1);
	
	int iFlags = GetEntityFlags(client);
	iFlags &= ~FL_ONGROUND;
	SetEntityFlags(client, iFlags);

	if(vecDirection[2] <269.0 && vecDirection[2] >= 0.0)	//JUMP_MIN_SPEED	268.3281572999747
		vecDirection[2] = 269.0;

	// Go there
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecDirection);

//#ifdef GAME_DLL
	// Screen flash
	int color[4] = { 255, 255, 255, 50 };
	UTIL_ScreenFade(client, color, 0.25, 0.4, FFADE_IN);		//stocksoup/sdkports/util.inc

	SetVariantString("TLK_PLAYER_BATTLECRY");
	AcceptEntityInput(client, "SpeakResponseConcept");
//#endif // GAME_DLL

	// Cooldown
	m_flNextDoubleTapTeleportTime[client] = GetGameTime() + 2.0;
}

public bool TraceIgnoreTeammates(int ent, int mask, int client)
{
	if (ent <= MaxClients)
	{
		if(IsLivingPlayer(ent))
		{
			if(TF2_GetClientTeam(ent) == TF2_GetClientTeam(client))
				return false;
		}
	}
	return true;
}



float[] WorldSpaceCenter(int entity)
{
	float pos[3];
	if (hWorldSpaceCenter)
		SDKCall(hWorldSpaceCenter, entity, pos);
	else GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);	// If it doesn't exist then fall back to vecOrigin

	return pos;
}

float[] GetVelocity(int entity)
{
	float vel[3], dummy[3];
	SDKCall(hGetVelocity, entity, vel, dummy);
	return vel;
}

bool IsBoss(int client)
{
	return (FF2_GetBossIndex(client)!=-1) ? true : false;
}

bool IsValidClient(int client, bool replaycheck=true)
{
	if(client<=0 || client>MaxClients)
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

bool IsLivingPlayer(int clientIdx)
{
	if (clientIdx <= 0 || clientIdx >= MAXPLAYERS)
		return false;
		
	return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
}
