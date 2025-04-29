//ability
//Lightning Sphere
//Spark Calibur
//Voltic Chain

//Reigeki

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <tf2>
#include <tf2_stocks>

enum 
{
	Reigeki = 0,
	LSphere,
	SCalibur,
	VChain,

	GVCount
};

//enum ParticleAttachment_t
enum
{
	PATTACH_ABSORIGIN = 0,			// Create at absorigin, but don't follow
	PATTACH_ABSORIGIN_FOLLOW,		// Create at absorigin, and update to follow the entity
	PATTACH_CUSTOMORIGIN,			// Create at a custom origin, but don't follow
	PATTACH_POINT,					// Create on attachment point, but don't follow
	PATTACH_POINT_FOLLOW,			// Create on attachment point, and update to follow the entity

	PATTACH_WORLDORIGIN,			// Used for control points that don't attach to an entity

	PATTACH_ROOTBONE_FOLLOW,		// Create at the root bone of the entity, and update to follow

	MAX_PATTACH_TYPES,
};

//enum struct te_tf_particle_effects_control_point_t
//{
//	ParticleAttachment_t m_eParticleAttachment;
//	float m_vecOffset[3];
//}


//float OFF_THE_MAP[3] = { 16383.0, 16383.0, -16383.0 };

bool PluginActiveThisRound = false;
bool RoundInProgress;
int BossTeam = view_as<int>(TFTeam_Blue);
bool GV_HasAbility[MAXPLAYERS + 1][GVCount];
float GV_EnergyPercent[MAXPLAYERS + 1];
bool GV_EnergyActive[MAXPLAYERS + 1];

//Reigeki
bool ReigekiActiveThisRound;

int ReigekiParticle[MAXPLAYERS + 1];
bool ReigekiOn[MAXPLAYERS + 1];
int Mark[3];
float MarkTime[3];
float EP[MAXPLAYERS + 1];
bool EPInCooldown[MAXPLAYERS + 1];
//float ReigekiDrain = 1.0;

int RG_LightningIndex;
//int RG_Sprite[3];
int RG_SpriteTexture[3];
bool RG_AttackDown[MAXPLAYERS + 1];
float RG_ImmuneUntil[MAXPLAYERS + 1][3]; // internal
float RG_Damage[MAXPLAYERS + 1]; // arg1
float RG_DamageGap[MAXPLAYERS + 1]; // arg2
float ReigekiDrain[MAXPLAYERS + 1]; // arg3
float RG_ProjSpeed[MAXPLAYERS + 1]; // arg4
float RG_TakeDamageMultiplier[MAXPLAYERS + 1]; // arg5
float RG_MarkDuration[MAXPLAYERS + 1]; //arg6


//Lightning Sphere

float LS_ReorientAt; // internal
int LS_OrbCount[MAXPLAYERS + 1]; // arg1
int LS_OrbYawPerSecond[MAXPLAYERS + 1]; // arg2
float LS_RocketReangleInterval[MAXPLAYERS + 1]; // arg3
float LSdamage[MAXPLAYERS + 1]; // arg4
float LS_Lifespan[MAXPLAYERS + 1]; // arg5
bool LS_UsePitch[MAXPLAYERS + 1]; // arg6
float LS_StartVelocity[MAXPLAYERS + 1]; // arg7
float LS_EndVelocity[MAXPLAYERS + 1]; // arg8
float LS_VelocityScaleFactor[MAXPLAYERS + 1]; //arg9
float LS_ReorientDelay[MAXPLAYERS + 1]; //arg 10
float LS_Cost[MAXPLAYERS + 1]; //arg 11
float LS_CoolDown[MAXPLAYERS + 1]; // arg 12 cooldown
char LS_RageSound[MAXPLAYERS + 1][80]; //arg 13

#define LS_MAX_PROJECTILES 50
int LS_EntRef[LS_MAX_PROJECTILES];
int LS_Owner[LS_MAX_PROJECTILES];
float LS_PitchAtZeroYaw[LS_MAX_PROJECTILES]; // should be negative the pitch of the user's eye angles
float LS_YawOffset[LS_MAX_PROJECTILES];
float LS_SpawnedAt[LS_MAX_PROJECTILES];
float LS_FullRotationTime[LS_MAX_PROJECTILES];
float LS_TimeInCurrentRotation[LS_MAX_PROJECTILES];
float LS_StartRotateTime[LS_MAX_PROJECTILES];

float LS_LastCastAT[MAXPLAYERS + 1];


//Spark Calibur
float SCdamage[MAXPLAYERS + 1]; // arg 1
int SC_Speed[MAXPLAYERS + 1]; // arg 2
int SC_Distance[MAXPLAYERS + 1]; // arg 3
//float SC_KnockbackIntensity[MAXPLAYERS + 1]; // arg2
float SC_Cost[MAXPLAYERS + 1]; //arg 4
float SC_ModelScale[MAXPLAYERS + 1]; //arg 5
bool SC_UsePitch[MAXPLAYERS + 1]; //arg 6
float SC_CoolDown[MAXPLAYERS + 1]; // arg 7 cooldown
char SC_Model[MAXPLAYERS + 1][128]; //arg 8
char SC_RageSound[MAXPLAYERS + 1][80]; //arg 9

float SC_LastCastAT[MAXPLAYERS + 1];



//Voltic Chain

int VC_Count[MAXPLAYERS + 1]; // arg1
float VC_Length[MAXPLAYERS + 1]; // arg2
float VC_Height[MAXPLAYERS + 1]; // arg3
float VCdamage[MAXPLAYERS + 1]; // arg4
float VC_Duration[MAXPLAYERS + 1]; // arg5
float VC_Cost[MAXPLAYERS + 1];// arg6
float VC_CoolDown[MAXPLAYERS + 1]; // arg 7 cooldown
int VC_Speed[MAXPLAYERS + 1]; // arg 8
float VC_CreateDelay[MAXPLAYERS + 1]; // arg 9
char VC_RageSound[MAXPLAYERS + 1][80]; //arg 10


bool VC_BeamActivate[MAXPLAYERS + 1];
float VC_ActivateTime = 0.7;
int VC_CountNow[MAXPLAYERS + 1];

#define VC_MAX_PROJECTILES 50
int VC_BeamEntRef[VC_MAX_PROJECTILES];
//int VC_StartPointRef[VC_MAX_PROJECTILES];
int VC_EndPointRef[VC_MAX_PROJECTILES];
float VC_LastCastAT[MAXPLAYERS + 1];



public void OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_Pre);
//	HookEvent("player_death", Event_PlayerDeath);
}

public void OnMapStart()
{

	RG_SpriteTexture[0] = PrecacheModel("materials/vgui/hud/autoaim.vmt", true);
	RG_SpriteTexture[1] = PrecacheModel("materials/sprites/hud/v_crosshair1.vmt", true);
	RG_SpriteTexture[2] = PrecacheModel("materials/sprites/minimap_icons/voiceicon.vmt", true);
	RG_LightningIndex = PrecacheModel("materials/sprites/bluelight1.vmt", true);
	PrecacheModel("materials/effects/workshop/unusual_chain.vmt", true);
	PrecacheSound("weapons/physcannon/superphys_small_zap4.wav", true);
	PrecacheSound("ambient/levels/citadel/zapper_loop1.wav", true);
	PrecacheSound("ambient/energy/zap2.wav", true);
	PrecacheSound("ambient/energy/zap7.wav", true);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{

	RoundInProgress = true;
	PluginActiveThisRound = false;
	ReigekiActiveThisRound = false;

	// initialize arrays
	for (int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
	{
		GV_EnergyActive[clientIdx] = false;
		GV_EnergyPercent[clientIdx] = 0.0;
	
		ReigekiParticle[clientIdx] = INVALID_ENT_REFERENCE;

		ReigekiOn[clientIdx] = false;
		EP[clientIdx] = 0.0;
		EPInCooldown[clientIdx] = false;
		RG_AttackDown[clientIdx] = false;

		GV_HasAbility[clientIdx][Reigeki] = false;
		GV_HasAbility[clientIdx][LSphere] = false;
		GV_HasAbility[clientIdx][SCalibur] = false;
		GV_HasAbility[clientIdx][VChain] = false;
		

		VC_CountNow[clientIdx] = 0;


		int bossIdx = FF2_GetBossIndex(clientIdx);
		if (bossIdx < 0)
			continue;

//		BossTeam = GetClientTeam(clientIdx);
		
		if(FF2_HasAbility(bossIdx, this_plugin_name, "ff2_Reigeki"))
		{
			GV_HasAbility[clientIdx][Reigeki] = true;
			PluginActiveThisRound = true;
			ReigekiActiveThisRound = true;

			RG_Damage[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_Reigeki", 1);
			RG_DamageGap[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_Reigeki", 2);
			ReigekiDrain[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_Reigeki", 3);
			RG_ProjSpeed[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_Reigeki", 4, 1200.0);
			RG_TakeDamageMultiplier[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_Reigeki", 5, 1.0);
			RG_MarkDuration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_Reigeki", 6, 10.0);
		}

		if(FF2_HasAbility(bossIdx, this_plugin_name, "ff2_LSphere"))
		{
			GV_HasAbility[clientIdx][LSphere] = true;
			PluginActiveThisRound = true;
			GV_EnergyActive[clientIdx] = true;

			LS_OrbCount[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, "ff2_LSphere", 1);
			LS_OrbYawPerSecond[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, "ff2_LSphere", 2);
			LS_RocketReangleInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_LSphere", 3);
			LSdamage[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_LSphere", 4);
			LS_Lifespan[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_LSphere", 5);
			LS_UsePitch[clientIdx] = view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, "ff2_LSphere", 6));
			LS_StartVelocity[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_LSphere", 7);
			LS_EndVelocity[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_LSphere", 8);
			LS_VelocityScaleFactor[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_LSphere", 9);
			LS_ReorientDelay[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_LSphere", 10);
			LS_Cost[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_LSphere", 11);
			LS_CoolDown[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_LSphere", 12);
//			ReadSound(clientIdx, "ff2_LSphere", 13, LS_RageSound[clientIdx]);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, "ff2_LSphere", 13, LS_RageSound[clientIdx], 80);
			if (strlen(LS_RageSound[clientIdx]) > 3)
				PrecacheSound(LS_RageSound[clientIdx]);
		}

		if(FF2_HasAbility(bossIdx, this_plugin_name, "ff2_SCalibur"))
		{
			GV_HasAbility[clientIdx][SCalibur] = true;
			PluginActiveThisRound = true;
			GV_EnergyActive[clientIdx] = true;

			SCdamage[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_SCalibur", 1);
			SC_Speed[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, "ff2_SCalibur", 2);
			SC_Distance[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, "ff2_SCalibur", 3);
			SC_Cost[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_SCalibur", 4);
			SC_ModelScale[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_SCalibur", 5, 3.0);
			SC_UsePitch[clientIdx] = view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, "ff2_SCalibur", 6));
			SC_CoolDown[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_SCalibur", 7);
//			ReadModel(clientIdx, "ff2_SCalibur", 8, SC_Model[clientIdx]);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, "ff2_SCalibur", 8, SC_Model[clientIdx], 128);
			if (strlen(SC_Model[clientIdx]) > 3)
				PrecacheModel(SC_Model[clientIdx]);
//			ReadSound(clientIdx, "ff2_SCalibur", 9, SC_RageSound[clientIdx]);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, "ff2_SCalibur", 9, SC_RageSound[clientIdx], 80);
			if (strlen(SC_RageSound[clientIdx]) > 3)
				PrecacheSound(SC_RageSound[clientIdx]);
		}

		if(FF2_HasAbility(bossIdx, this_plugin_name, "ff2_VChain"))
		{
			GV_HasAbility[clientIdx][VChain] = true;
			PluginActiveThisRound = true;
			GV_EnergyActive[clientIdx] = true;

			VC_Count[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, "ff2_VChain", 1);
			VC_Length[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_VChain", 2);
			VC_Height[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_VChain", 3);
			VCdamage[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_VChain", 4);
			VC_Duration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_VChain", 5);
			VC_Cost[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_VChain", 6);
			VC_CoolDown[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_VChain", 7);
			VC_Speed[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, "ff2_VChain", 8);
			VC_CreateDelay[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "ff2_VChain", 9);
//			ReadSound(clientIdx, "ff2_VChain", 10, VC_RageSound[clientIdx]);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, "ff2_VChain", 10, VC_RageSound[clientIdx], 80);
			if (strlen(VC_RageSound[clientIdx]) > 3)
				PrecacheSound(VC_RageSound[clientIdx]);
		}
		
		if (GV_HasAbility[clientIdx][Reigeki])
		{
			EP[clientIdx] = 100.0;

			for(int i = 0; i < 3; i++)
			{
				Mark[i] = 0;
				MarkTime[i] = 0.0;
//				RG_Sprite[i] = INVALID_ENT_REFERENCE;
			}
			// add hooks
			for (int client = 1; client <= MaxClients; client++)
			{
				if (IsValidClient(client))
				{
					SDKHook(client, SDKHook_OnTakeDamage, RG_OnTakeDamage);
//					PrintToChatAll("%iHooked", client);
				}
			}
		}

		if (GV_HasAbility[clientIdx][LSphere])
		{
			LS_LastCastAT[clientIdx] = 0.0;
			for (int i = 0; i < LS_MAX_PROJECTILES; i++)
				LS_EntRef[i] = INVALID_ENT_REFERENCE;
		}
		
		if (GV_HasAbility[clientIdx][SCalibur])
			SC_LastCastAT[clientIdx] = 0.0;
		
		if (GV_HasAbility[clientIdx][VChain])
		{
			VC_LastCastAT[clientIdx] = 0.0;
			VC_BeamActivate[clientIdx] = false;
			for (int i = 0; i < VC_MAX_PROJECTILES; i++)
			{
				VC_BeamEntRef[i] = INVALID_ENT_REFERENCE;
//				VC_StartPointRef[i] = INVALID_ENT_REFERENCE;
				VC_EndPointRef[i] = INVALID_ENT_REFERENCE;
			}
		}
	}
//	CreateTimer(0.1, EP_Manage, FF2_GetBossUserId(0), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	RoundInProgress = false;

	for (int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
	{
		GV_EnergyActive[clientIdx] = false;

		if (GV_HasAbility[clientIdx][Reigeki])
		{
			GV_HasAbility[clientIdx][Reigeki] = false;
			ReigekiEnd(clientIdx);
			for(int i = 0; i < 3; i++)
			{
				Mark[i] = 0;
				MarkTime[i] = 0.0;
				
//				int ent = EntRefToEntIndex(RG_Sprite[i]);
//				if(IsValidEntity(ent))
//					AcceptEntityInput(ent, "Kill");
//				RG_Sprite[i] = INVALID_ENT_REFERENCE;
			}
			// remove hooks
			for (int client = 1; client <= MaxClients; client++)
			{
				if (IsClientInGame(client))
					SDKUnhook(client, SDKHook_OnTakeDamage, RG_OnTakeDamage);
			}
		}

		if (GV_HasAbility[clientIdx][LSphere])
		{
			GV_HasAbility[clientIdx][LSphere] = false;

			for (int i = 0; i < LS_MAX_PROJECTILES; i++)
				LS_EntRef[i] = INVALID_ENT_REFERENCE;
		}
		if (GV_HasAbility[clientIdx][SCalibur])
			GV_HasAbility[clientIdx][SCalibur] = false;

		if (GV_HasAbility[clientIdx][VChain])
		{
			GV_HasAbility[clientIdx][VChain] = false;

			for (int i = 0; i < VC_MAX_PROJECTILES; i++)
			{
				VC_BeamEntRef[i] = INVALID_ENT_REFERENCE;
	//			VC_StartPointRef[i] = INVALID_ENT_REFERENCE;
				VC_EndPointRef[i] = INVALID_ENT_REFERENCE;
			}
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(!ReigekiActiveThisRound)
		return;
	if(!strcmp(classname, "tf_projectile_energy_ring"))
	{
//		SDKHook(entity, SDKHook_SpawnPost, SyringeSpawnPost);
		RequestFrame(SyringeSpawnPost, EntIndexToEntRef(entity));
	}
}

void SyringeSpawnPost(int entref)
{
	int entity = EntRefToEntIndex(entref);
	if(!IsValidEntity(entity))
		return;

	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(!IsValidClient(owner))
		return;
	if(!IsBoss(owner))
		return;



	float vecVelocity[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vecVelocity);
	NormalizeVector(vecVelocity, vecVelocity);
	ScaleVector(vecVelocity, RG_ProjSpeed[owner]);
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vecVelocity);

//	SDKHook(entity, SDKHook_StartTouch, OnSyringeTouch);
}
/*
public Action OnSyringeTouch(int entity, int victim)
{
	if(!IsValidEntity(entity) && !entity)
		return Plugin_Handled;

	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(victim == owner)
		return Plugin_Continue;

	if(IsValidClient(victim) && IsPlayerAlive(victim))
	{
		if(GetClientTeam(victim) == BossTeam)
			return Plugin_Continue;

		int num = 0;
		for(int i = 0; i < 3; i++)
		{
			if(!Mark[i] || !MarkTime[i])
			{
				Mark[i] = victim;
				MarkTime[i] = GetEngineTime();

				RemoveEntity(entity);
				return Plugin_Handled;
			}
			else
				num++;
		}
		if(num == 3)
		{
			float Markmin = MarkTime[0];
			int minnum = 0;
			for(int i = 1; i < 3; i++)
			{
				if(MarkTime[i] < Markmin)
				{
					Markmin = MarkTime[i];
					minnum = i;
				}
			}

			Mark[minnum] = victim;
			MarkTime[minnum] = GetEngineTime();
			SetVariantString("OnUser1 !self:Kill::0.01:1");
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");
			return Plugin_Handled;
		}
	}
	else if(IsValidEntity(victim))
	{
		char classname[128];
		GetEntityClassname(victim, classname, 128);
		bool isFuncBreakable = strcmp(classname, "func_breakable") == 0;
		bool buildingHit = (strcmp(classname, "obj_sentrygun") == 0) || (strcmp(classname, "obj_dispenser") == 0) || (strcmp(classname, "obj_teleporter") == 0);
		
		if (isFuncBreakable)
		{
			SDKHooks_TakeDamage(victim, owner, owner, 20.0, DMG_GENERIC, -1);
			SetVariantString("OnUser1 !self:Kill::0.01:1");
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");
			return Plugin_Handled;
		}
		else if (buildingHit)
		{
			SDKHooks_TakeDamage(victim, owner, owner, 10.0, DMG_GENERIC, -1);
			SetVariantString("OnUser1 !self:Kill::0.01:1");
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");
			return Plugin_Handled;
		}
	}

	return Plugin_Handled;
}*/

/*public Action Syringe_OtherTouches(int projectile, int victim)
{
	
	if(!IsValidEntity(projectile) && !projectile)
		return Plugin_Handled;
	int owner = GetEntPropEnt(projectile, Prop_Send, "m_hOwnerEntity");
	if(victim == owner)
		return Plugin_Continue;
	SetVariantString("OnUser1 !self:Kill::0.01:1");
	AcceptEntityInput(projectile, "AddOutput");
	AcceptEntityInput(projectile, "FireUser1");
	return Plugin_Handled;
}*/

/*public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(client > 0 && client <= MaxClients)
	{
		ReigekiParticle
	}
}*/

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float unusedangles[3], int &weapon)
{
	if (!PluginActiveThisRound || !RoundInProgress)
		return Plugin_Continue;
	else if(!IsLivingPlayer(client))
		return Plugin_Continue;
	float Curtime = GetEngineTime();

	if(GV_HasAbility[client][Reigeki])
		Reigeki_Tick(client, buttons, Curtime);
	if(GV_HasAbility[client][LSphere])
		LSphere_Tick(client, buttons, Curtime);
	if(GV_HasAbility[client][SCalibur])
		SCalibur_Tick(client, buttons, Curtime);
	if(GV_HasAbility[client][VChain])
		VChain_Tick(client, buttons, Curtime);
	if(GV_EnergyActive[client])
	{
		int bossIdx = FF2_GetBossIndex(client);
		float charge = FF2_GetBossCharge(bossIdx, 0);
		if (charge > 0.0)
		{
			GV_EnergyPercent[client] += charge;
			if (GV_EnergyPercent[client] > 100.0)
				GV_EnergyPercent[client] = 100.0;
			FF2_SetBossCharge(bossIdx, 0, 0.0);
		}
		SetHudTextParams( -1.0, 0.6, 0.32, 0, 68, 255, 255);
		ShowHudText(client, -1, "能量 : %.1f %", GV_EnergyPercent[client]);
	}

	return Plugin_Continue;
}

//w.i.p
/*public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	char command[64];
	kv.GetSectionName(command, sizeof(command));

	if(StrEqual(command, "+inspect_server"))
	{
	}

	return Plugin_Continue;
}*/

public Action FF2_OnAbility2(int bossIdx, const char[] plugin_name, const char[] ability_name, int status)
{
	if (strcmp(plugin_name, this_plugin_name) != 0)
		return Plugin_Continue;
	if (!strcmp(ability_name, "ff2_VChain"))
	{
		int clientIdx = GetClientOfUserId(FF2_GetBossUserId(bossIdx));
		PrintToServer("[Gunvolt] Super rare edge case of rage executing with 'ff2_VChain', this code isn't useless! Yay.");
		
		GV_EnergyPercent[clientIdx] = 100.0;
	}
	return Plugin_Continue;
}

//Reigeki**************************************************************

public Action RG_OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!IsValidClient(attacker))
		return Plugin_Continue;

	if(attacker == client)
		return Plugin_Continue;

	if(IsBoss(client) && ReigekiOn[client])
	{
		damage *= RG_TakeDamageMultiplier[client];
		return Plugin_Changed;
	}
	if(!IsBoss(attacker))
		return Plugin_Continue;
	char classname[128];
	GetEntityClassname(inflictor, classname, sizeof(classname));
	if (StrEqual(classname, "tf_projectile_lightningorb"))
	{
		damage = LSdamage[attacker];
		
		return Plugin_Changed;
	}

//	if(!IsValidEntity(weapon) || !IsPlayerAlive(client))
//		return Plugin_Continue;

//	if(GetClientTeam(client) == BossTeam)
//		return Plugin_Continue;


//	GetEntityClassname(weapon, classname, sizeof(classname));
	if(StrEqual(classname, "tf_projectile_energy_ring"))
	{

		int num = 0;
		for(int i = 0; i < 3; i++)
		{
			if(!Mark[i] || !MarkTime[i])
			{
				Mark[i] = client;
				MarkTime[i] = GetEngineTime();
//				CreateSprite(client, i);
				return Plugin_Continue;
			}
			else
				num++;
		}
		if(num == 3)
		{
			float Markmin = MarkTime[0];
			int minnum = 0;
			for(int i = 1; i < 3; i++)
			{
				if(MarkTime[i] < Markmin)
				{
					Markmin = MarkTime[i];
					minnum = i;
				}
			}
			
//			int ent = EntRefToEntIndex(RG_Sprite[minnum]);
//			if(IsValidEntity(ent))
//				AcceptEntityInput(ent, "Kill");

			Mark[minnum] = client;
			MarkTime[minnum] = GetEngineTime();
//			CreateSprite(client, minnum);
//			PrintToChat(attacker, "markreplacefuck");
		}
	}
	
	return Plugin_Continue;
}

/*void CreateSprite(int client, int num)
{
	if(IsLivingPlayer(client))
	{
		int particle = CreateEntityByName("env_spritetrail");
		if(particle != -1)
		{
			float pos[3];
			GetClientAbsOrigin(client, pos);
			pos[2] += 33.0;

			DispatchKeyValueVector(particle, "origin", pos);
			DispatchKeyValue(particle, "spritename", RG_SpriteTexture[num]);
			DispatchKeyValue(particle, "rendercolor", "255 255 255");
			SetEntPropFloat(particle, Prop_Send, "m_flTextureRes", 1.5);	

			DispatchKeyValue(particle, "rendermode", "5");
			DispatchKeyValue(particle, "renderamt", "200");

			DispatchKeyValue(particle, "lifetime", "0.08");
			DispatchKeyValue(particle, "startwidth", "80.0");
			DispatchKeyValue(particle, "endwidth", "40.0");

			DispatchSpawn(particle);

			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", client);

//			SetVariantString("OnUser1 !self:ClearParent::9.90:1");
//			AcceptEntityInput(particle, "AddOutput");
//			AcceptEntityInput(particle, "FireUser1");
			
			SetVariantString("OnUser2 !self:Kill::10.0:1");
			AcceptEntityInput(particle, "AddOutput");
			AcceptEntityInput(particle, "FireUser2");

			RG_Sprite[num] = EntIndexToEntRef(particle);
//			SDKHook(particle, SDKHook_SetTransmit, TransmitBossOnly);
		}
	}
}*/

/*public Action TransmitBossOnly(int particle, int client)
{
	if(!IsBoss(client))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}*/

void Reigeki_Tick(int client, int buttons, float curTime)
{

	EP[client] += 0.4;
	if (EP[client] > 100.0)
	{
		EP[client] = 100.0;
		EPInCooldown[client] = false;
	}


	bool attackDown = (buttons & IN_ATTACK2) != 0; //正在按下？
	bool shouldFire = attackDown & !RG_AttackDown[client];		//正在按下并且上一tick未按下？
	bool shouldRelease = !attackDown & RG_AttackDown[client];	//未按下并且上一tick已按下？
	RG_AttackDown[client] = attackDown;							//此tick已按下?留待下一tick使用

	if (TF2_IsPlayerInCondition(client, TFCond_Dazed) || TF2_IsPlayerInCondition(client, TFCond_Taunting))
		shouldFire = false;

	if(!IsLivingPlayer(client))
		ReigekiEnd(client);

//	PrintToChat(client, "fuck4");
	if (shouldRelease && ReigekiOn[client])
		ReigekiEnd(client);

//	PrintToChat(client, "fuck5");
	if(ReigekiOn[client])
	{
		if(!EP_ShouldConsume(client, ReigekiDrain[client]))
			ReigekiEnd(client);

		int ent = -1;
		float origin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		while ((ent = FindEntityByClassname(ent, "tf_projectile*")) != -1)
		{
			if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != client)
			{
				float buffer[3];
				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", buffer);
				if (GetVectorDistance(origin, buffer) < 200.0)
				{
//					te_tf_particle_effects_control_point_t controlPoint = { PATTACH_WORLDORIGIN, buffer };
					EmitAmbientSound("weapons/physcannon/superphys_small_zap4.wav", buffer, ent);
					TE_Particle("dxhr_arm_muzzleflash", 0.0, origin, NULL_VECTOR, NULL_VECTOR, ent, PATTACH_CUSTOMORIGIN, 0, false, _, _, _, 1, PATTACH_WORLDORIGIN, buffer);
					SetVariantString("OnUser1 !self:Kill::0.0:1");
					AcceptEntityInput(ent, "AddOutput");
					AcceptEntityInput(ent, "FireUser1");
				}
			}
		}
//		PrintToChat(client, "fuck6");
		for(int i = 0; i < 3; i++)
		{
			if(MarkTime[i] && Mark[i])
			{
				if(curTime - MarkTime[i] >= RG_MarkDuration[client])
				{
//					ent = EntRefToEntIndex(RG_Sprite[i]);
//					if(IsValidEntity(ent))
//						AcceptEntityInput(ent, "Kill");
						
					MarkTime[i] = 0.0;
					Mark[i] = 0;
					continue;
				}
				if(!IsLivingPlayer(Mark[i]))
				{
//					ent = EntRefToEntIndex(RG_Sprite[i]);
//					if(IsValidEntity(ent))
//						AcceptEntityInput(ent, "Kill");
						
					Mark[i] = 0;
					MarkTime[i] = 0.0;
					continue;
				}
				else if(RG_ImmuneUntil[client][i] > curTime)
					continue;
				RG_ImmuneUntil[client][i] = curTime + RG_DamageGap[client];
				
				EmitSoundToAll("ambient/energy/zap2.wav", Mark[i], _, _, _, 0.7);
				EmitSoundToAll("ambient/energy/zap7.wav", client, _, _, _, 0.5);
				
				int weapon = GetPlayerWeaponSlot(Mark[i], 4);
				if(IsValidEntity(weapon))
				{
					static char classname[64];
					GetEntityClassname(weapon, classname, sizeof(classname));
					if(StrEqual(classname, "tf_weapon_invis", false))
					{
						float meter = GetEntPropFloat(Mark[i], Prop_Send, "m_flCloakMeter");
						SetEntPropFloat(Mark[i], Prop_Send, "m_flRageMeter", (meter-5.0<0.0) ? 0.0 : meter-5.0);
					}
				}
				
				float damage = RG_Damage[client];
				if(TF2_IsPlayerInCondition(Mark[i], TFCond_DefenseBuffed))
					damage = RG_Damage[client] * 3.0;
				SDKHooks_TakeDamage(Mark[i], client, client, damage, DMG_SHOCK | DMG_PREVENT_PHYSICS_FORCE, -1);

				float buffer[3];
				GetEntPropVector(Mark[i], Prop_Send, "m_vecOrigin", buffer);
				origin[2] += 30.0; buffer[2] += 30.0;

				TE_SetupBeamPoints(origin, buffer, RG_LightningIndex, 0, 0, 0, RG_DamageGap[client]*0.85, 5.0, 5.0, 0, 2.0, {30, 144, 255, 255}, 0);
				TE_SendToAll();

			}
			else
			{
//				int sprite = EntRefToEntIndex(RG_Sprite[i]);
//				if(IsValidEntity(sprite))
//					AcceptEntityInput(sprite, "Kill");
					
				MarkTime[i] = 0.0;
				Mark[i] = 0;
				continue;
			}
		}
	}

	for(int i = 0; i < 3; i++)
	{
		if(MarkTime[i] && Mark[i])
		{
			float origin[3];
			GetClientEyePosition(Mark[i], origin);
			origin[2] -= 20.0;
			if(curTime - MarkTime[i] <= RG_MarkDuration[client])
			{
				TE_SetupGlowSprite(origin, RG_SpriteTexture[i], 0.1, 1.0, 120);
//				TE_SendToClient(client);
				TE_SendToAll();
			}
		}
	}

//	PrintToChat(client, "fuck7");
	if(shouldFire && EP_ShouldConsume(client, ReigekiDrain[client]))
	{
//		PrintToChat(client, "fuck3");
		ReigekiOn[client] = true;
		ReigekiParticle[client] = EntIndexToEntRef(AttachParticle(client, "utaunt_electric_mist", -1.0, {0.0, 0.0, 25.0}, true));
		EmitSoundToAll("ambient/levels/citadel/zapper_loop1.wav", client);
	}

	SetHudTextParams( -0.65, 0.48, 0.32, 30, 144, 255, 150);
	ShowHudText(client, -1, "EP : %0.1f %", EP[client]);
}

public void ReigekiEnd(int client)
{
//	PrintToChat(client, "fuck1");
	StopSound(client, SNDCHAN_AUTO, "ambient/levels/citadel/zapper_loop1.wav");
	ReigekiOn[client] = false;
	int ent = EntRefToEntIndex(ReigekiParticle[client]);
	if(IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "Kill");
		RemoveEntity(ent);
	}
	ReigekiParticle[client] = INVALID_ENT_REFERENCE;
//	PrintToChat(client, "fuck2");
}

public bool EP_ShouldConsume(int client, float cost) // this can only be called by the currently active ability
{
	if(EPInCooldown[client])
		return false;
	if(cost > EP[client])
	{
		if(EP[client] > 0)
		{
			EP[client] = 0.0;
			EPInCooldown[client] = true;
			return true;
		}
		else
			return false;
	}
	EP[client] -= cost;
	return true;
}

//Lightning Sphere******************************************************

void LSphere_Tick(int client, int buttons, float curTime)
{
	float timegap = curTime - LS_LastCastAT[client];
	if((buttons & IN_RELOAD) && (timegap > LS_CoolDown[client]))
	{
		if(GV_ConsumeEnergy(client, LS_Cost[client]))
		{
			Rage_Lightning_Sphere(client, curTime);
			LS_LastCastAT[client] = curTime;
		}
		else
		{
			PrintCenterText(client,"能量不足，需要%0.1f能量", LS_Cost[client]);
		}
	}
	else if((buttons & IN_RELOAD) && (timegap <= LS_CoolDown[client]))
	{
		float abiCD = LS_CoolDown[client] - timegap;
		PrintCenterText(client,"冷却中，还有%0.1f秒", abiCD);
	}


	for (int LSIdx = LS_MAX_PROJECTILES - 1; LSIdx >= 0; LSIdx--)
	{
		if (LS_EntRef[LSIdx] == INVALID_ENT_REFERENCE)
			continue;
		
		// hale must be alive
		int owner = LS_Owner[LSIdx];
		if (!IsLivingPlayer(owner))
		{
			LS_RemoveOrb(LSIdx);
			continue;
		}
		
		// rocket must not have reached EOL
		if (curTime >= LS_SpawnedAt[LSIdx] + LS_Lifespan[owner])
		{
			LS_RemoveOrb(LSIdx);
			continue;
		}
		
		// rocket must not have exploded
		int rocket = EntRefToEntIndex(LS_EntRef[LSIdx]);
		if (!IsValidEntity(rocket))
		{
			LS_RemoveOrb(LSIdx);
			continue;
		}
		
		// all that's left to do is reorient, if valid
		if(LS_StartRotateTime[LSIdx] > curTime)
			continue;
		float deltaTime = (curTime - LS_ReorientAt) + LS_RocketReangleInterval[client];
		if (deltaTime >= LS_RocketReangleInterval[client])
		{
			LS_TimeInCurrentRotation[LSIdx] += deltaTime;
			int sanity = 0;
			while (LS_TimeInCurrentRotation[LSIdx] > LS_FullRotationTime[LSIdx] && sanity < 50)
			{
				LS_TimeInCurrentRotation[LSIdx] -= LS_FullRotationTime[LSIdx];
				sanity++;
				
				if (sanity == LS_MAX_PROJECTILES)
					PrintToServer("[Gunvolt] ERROR: Sanity failed on orb ring, time in current rotation.");
			}
	
			LS_ReorientRocket(LSIdx, curTime);
		}
	}
	
	if (curTime >= LS_ReorientAt)
		LS_ReorientAt = curTime + LS_RocketReangleInterval[client];
}

void Rage_Lightning_Sphere(int client, float curTime)
{
//	int BossTeam = GetClientTeam(client);
	float position[3], angles[3];
	GetClientEyeAngles(client, angles);
	GetClientEyePosition(client, position);

	// find the first free
	int startAt = 0;
	for (startAt = 0; startAt < 50; startAt++)
	{
		if (LS_EntRef[startAt] == INVALID_ENT_REFERENCE)
			break;
	}
	
	// not good
	if (startAt == 50)
	{
		PrintToServer("[Gunvolt] WARNING: Somehow user reached orb projectile limit %d", 50);
		return;
	}
	
	// and our ending position
	int endAt = min(startAt + LS_OrbCount[client], LS_MAX_PROJECTILES) - 1;
	
	// get our rocket count, which is important for configuring our ring
	int orbCount = (endAt - startAt) + 1;
	if (orbCount <= 0)
	{
		PrintToServer("[Gunvolt] ERROR: Somehow set to spawn %d orb. Aborting.", orbCount);
		return;
	}
	
	// need the hale's eye angles
	float eyeAngles[3];
	GetClientEyeAngles(client, eyeAngles);
	
	// figure out the full rotation time now
	float fullRotationTime = 360.0 / LS_OrbYawPerSecond[client];
	
	// spawn 'em
	for (int LSIdx = startAt; LSIdx <= endAt; LSIdx++)
	{
		float rocketMotionValue = (eyeAngles[1] / 360.0) + (float(LSIdx - startAt) / float(orbCount));
		if (rocketMotionValue < 0.0)
			rocketMotionValue += 1.0;
		else if (rocketMotionValue >= 1.0)
			rocketMotionValue -= 1.0;
		int rocket = LS_CreateOrb(client, rocketMotionValue);
		if (rocket == -1)
			break;
	
		LS_EntRef[LSIdx] = EntIndexToEntRef(rocket);
		LS_Owner[LSIdx] = client;
		LS_PitchAtZeroYaw[LSIdx] = eyeAngles[0];
		LS_YawOffset[LSIdx] = eyeAngles[1];
		LS_SpawnedAt[LSIdx] = GetEngineTime();
		LS_FullRotationTime[LSIdx] = fullRotationTime;
		LS_TimeInCurrentRotation[LSIdx] = rocketMotionValue * fullRotationTime;
		LS_StartRotateTime[LSIdx] = LS_ReorientDelay[client] + curTime;

		//PrintToServer("orb %d, rmv=%f    timeincurrent=%f    fulltime=%f", LSIdx, rocketMotionValue, LS_TimeInCurrentRotation[LSIdx], LS_FullRotationTime[LSIdx]);
		
//		RequestFrame(KILLTHINK, LS_EntRef[LSIdx]);

	}
	// reset the reorientation timer
	LS_ReorientAt = GetEngineTime() + 0.02;
	
	if(strlen(LS_RageSound[client]) > 3)
		EmitSoundToAll(LS_RageSound[client]);
}

/*
void KILLTHINK(int entref)
{
	int rocket = EntRefToEntIndex(entref);
	if(!IsValidEntity(rocket))
		return;
	int m_aThinkFunctionsOffset = FindDataMapInfo(rocket, "m_aThinkFunctions");
//	PrintToChatAll("%i", m_aThinkFunctionsOffset);
	if(!m_aThinkFunctionsOffset)
	{
		return;
	}
	int size = LoadFromAddress(GetEntityAddress(rocket) + view_as<Address>(m_aThinkFunctionsOffset) + view_as<Address>(0x0C), NumberType_Int32);
//	PrintToChatAll("%i", size);
	Address m_aThinkFunctions = DereferencePointer(GetEntityAddress(rocket) + view_as<Address>(m_aThinkFunctionsOffset));

	for (int i; i < size; i++)
	{
		Address thinkfunc_t = m_aThinkFunctions + view_as<Address>(i * 0x10);

//		Address m_pfnThink = thinkfunc_t;
		Address m_iszContext = thinkfunc_t + view_as<Address>(0x04);
		Address m_nNextThinkTick = thinkfunc_t + view_as<Address>(0x08);
//		Address m_nLastThinkTick = thinkfunc_t + view_as<Address>(0x0C);
		
		
		int NextThinkTick, LastThinkTick;
		char szContext[32];
		bool Null;
		int thinkfuncaddress = LoadFromAddress(thinkfunc_t, NumberType_Int32);
//		PrintToChatAll("%i", thinkfuncaddress);
//		NextThinkTick = LoadFromAddress(m_nNextThinkTick, NumberType_Int32);
//		LastThinkTick = LoadFromAddress(m_nLastThinkTick, NumberType_Int32);
		//m_iszContext is string_t
		LoadStringFromAddress(DereferencePointer(m_iszContext), szContext, sizeof(szContext), Null);
		PrintToChatAll("%s", szContext);
		if(!Null)
		{
			if(StrEqual(szContext, "DistanceLimitThink") || StrEqual(szContext, "ExpireDelayThink"))
			{
				NextThinkTick = LoadFromAddress(m_nNextThinkTick, NumberType_Int32);
//				PrintToChatAll("%s's Next Think Tick is %i", szContext, NextThinkTick);
				StoreToAddress(m_nNextThinkTick, view_as<any>(-1), NumberType_Int32);
			}
		}
		
		int basethink =  LoadFromAddress(GetEntityAddress(rocket) + view_as<Address>(FindDataMapInfo(rocket, "m_pfnThink")), NumberType_Int32);
		PrintToChatAll("%i", basethink);
		//1918443520 is the address of VortexThink function
		StoreToAddress(GetEntityAddress(rocket) + view_as<Address>(FindDataMapInfo(rocket, "m_pfnThink")), view_as<any>(1918443520), NumberType_Int32);
		basethink =  LoadFromAddress(GetEntityAddress(rocket) + view_as<Address>(FindDataMapInfo(rocket, "m_pfnThink")), NumberType_Int32);
		PrintToChatAll("%i", basethink);
	}
}*/

int LS_CreateOrb(int owner, float orbMotionValue)
{
	// create our rocket. no matter what, it's going to spawn, even if it ends up being out of map
	char classname[48] = "CTFProjectile_SpellLightningOrb";
//	char classname[48] = "CTFProjectile_BallOfFire";
//	char classname[48] = "CTFProjectile MechanicalArmOrb";
	char entname[48] = "tf_projectile_lightningorb";
//	char entname[48] = "tf_projectile_mechanicalarmorb";
//	char entname[48] = "tf_projectile_pipe";
	
	int orb = CreateEntityByName(entname);
	if (!IsValidEntity(orb))
	{
		PrintToServer("[Gunvolt] Error: Invalid entity %s. Won't spawn orb.", entname);
		return -1;
	}
	
	// need boss origin
	float bossOrigin[3];
	GetEntPropVector(owner, Prop_Send, "m_vecOrigin", bossOrigin);
	bossOrigin[2] += 41.5; // don't spawn at the boss' feet
	
	// determine spawn position. no angle or velocity yet
	// position is basically, 1HU in front of the hale at 0.0N, 1HU behind the hale at 0.5N, going clockwise
	float spawnPosition[3];
	float tmpAngle[3];
	tmpAngle[0] = 0.0; // no pitch
	tmpAngle[1] = fixAngle(- orbMotionValue * 360.0);
	tmpAngle[2] = 0.0; // no roll
	Handle trace = TR_TraceRayFilterEx(bossOrigin, tmpAngle, (CONTENTS_SOLID | CONTENTS_WINDOW | CONTENTS_GRATE), RayType_Infinite, TraceWallsOnly);
	TR_GetEndPosition(spawnPosition, trace);
	CloseHandle(trace);
	ConformLineDistance(spawnPosition, bossOrigin, spawnPosition, 1.0);
	
	// deploy!
	TeleportEntity(orb, spawnPosition, NULL_VECTOR, NULL_VECTOR);
	SetEntProp(orb, Prop_Send, "m_bCritical", false); // no random crits
	SetEntPropFloat(orb, Prop_Send, "m_flDamage", LSdamage[owner]);
//	SetEntDataFloat(orb, FindSendPropInfo(classname, "m_iDeflected")+4, LSdamage[owner], true); // change rocket damage
	SetEntProp(orb, Prop_Send, "m_nSkin", 1); // set skin to blue team's
	SetEntPropEnt(orb, Prop_Send, "m_hOwnerEntity", owner);
	SetVariantInt(BossTeam);
	AcceptEntityInput(orb, "TeamNum", -1, -1, 0);
	SetVariantInt(BossTeam);
	AcceptEntityInput(orb, "SetTeam", -1, -1, 0); 
	DispatchSpawn(orb);
	return orb;
}

void LS_GetRocketAngle(int LSIdx, float angle[3])
{
	int owner = LS_Owner[LSIdx];
	float newYaw = fixAngle(-(360.0 * (LS_TimeInCurrentRotation[LSIdx] / LS_FullRotationTime[LSIdx])));
	float newPitch = 0.0;
	if (LS_UsePitch[owner])
	{
		if (newYaw >= -90.0 && newYaw <= 90.0)
			newPitch = (1.0 - (fabs(newYaw) / 90.0)) * LS_PitchAtZeroYaw[LSIdx];
		else if (newYaw < -90.0 || newYaw > 90.0)
			newPitch = -((fabs(newYaw) - 90.0) / 90.0) * LS_PitchAtZeroYaw[LSIdx];
	}
	newYaw = fixAngle(newYaw + LS_YawOffset[LSIdx]);
	
	angle[0] = newPitch;
	angle[1] = newYaw;
}

void LS_ReorientRocket(int LSIdx, float curTime)
{
	int orb = EntRefToEntIndex(LS_EntRef[LSIdx]);
	if (!IsValidEntity(orb))
	{
		// should never get here
		LS_RemoveOrb(LSIdx);
		return;
	}
	

	static Float:angle[3];
	static Float:velocity[3];
	LS_GetRocketAngle(LSIdx, angle);
	GetAngleVectors(angle, velocity, NULL_VECTOR, NULL_VECTOR);
	
	// velocity scaling requires knowing how far into the rocket's lifetime we are
	int owner = LS_Owner[LSIdx];
	float scaleFactor = LS_StartVelocity[owner] + (LS_VelocityScaleFactor[owner] * ((LS_EndVelocity[owner] - LS_StartVelocity[owner]) * ((curTime - LS_SpawnedAt[LSIdx]) / LS_Lifespan[owner])));
	scaleFactor = fmin(scaleFactor, fmax(LS_EndVelocity[owner], LS_StartVelocity[owner]));
	scaleFactor = fmax(scaleFactor, fmin(LS_EndVelocity[owner], LS_StartVelocity[owner]));
	ScaleVector(velocity, scaleFactor);
	
	TeleportEntity(orb, NULL_VECTOR, angle, velocity);
}


public void LS_RemoveOrb(LSIdx)
{
	if(IsValidEntity(EntRefToEntIndex(LS_EntRef[LSIdx])))
	{
		RemoveEntity(LS_EntRef[LSIdx]);
	}
	LS_EntRef[LSIdx] = INVALID_ENT_REFERENCE;
	
	for (int i = LSIdx; i < LS_MAX_PROJECTILES - 1; i++)
	{
		LS_EntRef[i] = LS_EntRef[i+1];
		LS_Owner[i] = LS_Owner[i+1];
		LS_PitchAtZeroYaw[i] = LS_PitchAtZeroYaw[i+1];
		LS_YawOffset[i] = LS_YawOffset[i+1];
		LS_SpawnedAt[i] = LS_SpawnedAt[i+1];
		LS_FullRotationTime[i] = LS_FullRotationTime[i+1];
		LS_TimeInCurrentRotation[i] = LS_TimeInCurrentRotation[i+1];
		LS_StartRotateTime[i] = LS_StartRotateTime[i+1];
	}
}


public bool TraceWallsOnly(int entity, int contentsMask)
{
	return false;
}

//Spark Calibur********************************************************

void SCalibur_Tick(int client, int buttons, float curTime)
{
	float timegap = curTime - SC_LastCastAT[client];
	if((buttons & IN_ATTACK3) && (timegap > SC_CoolDown[client]))
	{
		if(GV_ConsumeEnergy(client, SC_Cost[client]))
		{
			Rage_Spark_Calibur(client);
			SC_LastCastAT[client] = curTime;
		}
		else
		{
			PrintCenterText(client,"能量不足，需要%0.1f能量", SC_Cost[client]);
		}
	}
	else if((buttons & IN_ATTACK3) && (timegap <= SC_CoolDown[client]))
	{
		float abiCD = SC_CoolDown[client] - timegap;
		PrintCenterText(client,"冷却中，还有%0.1f秒", abiCD);
	}
}


void Rage_Spark_Calibur(int client)
{
	float pos[3], ang[3], fwd[3];

	GetClientEyePosition(client , pos);
	GetClientEyeAngles(client, ang);
	GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);

	pos[0] += 50*fwd[0];
	pos[1] += 50*fwd[1];
	pos[2] += 50*fwd[2];

	if(strlen(SC_RageSound[client]) > 3)
		EmitSoundToAll(SC_RageSound[client]);

	if(!SC_UsePitch[client])
		ang[0] = 0.0;

	int calibur = CreateEntityByName("prop_dynamic");
	if(!IsValidEntity(calibur))
	{
		PrintToServer("[Gunvolt] Error: Invalid entity prop_dynamic. Won't spawn SparkCalibur.");
		return;
	}
	//the blade

	if(strlen(SC_Model[client]) > 3)
		DispatchKeyValue(calibur, "model", SC_Model[client]);
	else
		DispatchKeyValue(calibur, "model", "models/buildables/sentry3_rockets.mdl");
//	DispatchKeyValue(calibur, "model", "models/freak_fortress_2/gunvolt/spark_calibur.mdl");
	DispatchKeyValueVector(calibur, "origin", pos);
	DispatchKeyValueVector(calibur, "angles", ang);
	DispatchKeyValueFloat(calibur, "modelscale", SC_ModelScale[client]);
	DispatchKeyValue(calibur, "rendermode", "1");
	SetEntProp(calibur, Prop_Send, "m_usSolidFlags", 0x0008|0x0004);
	SetEntProp(calibur, Prop_Data, "m_nSolidType", 6);
	SetEntProp(calibur, Prop_Send, "m_CollisionGroup", 2);
	DispatchSpawn(calibur);
	ActivateEntity(calibur);

	SetEntPropEnt(calibur, Prop_Send, "m_hOwnerEntity", client);

	int cmovelinear = CreateEntityByName("func_movelinear");
	if(!IsValidEntity(cmovelinear))
	{
		PrintToServer("[Gunvolt] Error: Invalid entity func_movelinear. Won't spawn SparkCalibur move.");
		return;
	}
	
	//movement
	DispatchKeyValue(cmovelinear, "targetname", "CALIBURMOVE");
	DispatchKeyValue(cmovelinear, "rendermode", "10");
	DispatchKeyValue(cmovelinear, "startposition", "0");

	char ArgStr[16];
	IntToString(SC_Speed[client], ArgStr, sizeof(ArgStr));
	DispatchKeyValue(cmovelinear, "speed", ArgStr);

	IntToString(SC_Distance[client], ArgStr, sizeof(ArgStr));
	DispatchKeyValue(cmovelinear, "movedistance", ArgStr);

	DispatchKeyValue(cmovelinear, "spawnflags", "8");
	DispatchKeyValueVector(cmovelinear, "movedir", ang);
	DispatchKeyValueVector(cmovelinear, "origin", pos);
	DispatchSpawn(cmovelinear);
	SetEntityModel(cmovelinear, "models/empty.mdl");					//This is IMPORTANT!!!
	SetEntityMoveType(cmovelinear, MOVETYPE_NOCLIP);
	SetEntProp(cmovelinear, Prop_Send, "m_nSolidType", 0);
	SetEntProp(cmovelinear, Prop_Send, "m_CollisionGroup", 0);

//	AcceptEntityInput(cmovelinear, "Open");

	SetVariantString("OnUser1 !self:Open::1.0:1");
	AcceptEntityInput(cmovelinear, "AddOutput");
	AcceptEntityInput(cmovelinear, "FireUser1");
	
	SetVariantString("OnUser2 !self:KillHierarchy::8.8:1");
	AcceptEntityInput(cmovelinear, "AddOutput");
	AcceptEntityInput(cmovelinear, "FireUser2");

//	DispatchKeyValue(cmovelinear, "OnFullyOpen", "!self,KillHierarchy,,0,-1");

	//match model size
//	float vMaxs[3] = {0.0, 0.0, 0.0};
//	float vMins[3] = {0.0, 0.0, 0.0};
//	SetEntPropVector(ctrigger, Prop_Send, "m_vecMaxs", vMaxs);
//	SetEntPropVector(ctrigger, Prop_Send, "m_vecMins", vMins);

	SetVariantString("!activator");
	AcceptEntityInput(calibur, "SetParent", cmovelinear);

	SDKHook(calibur, SDKHook_Touch, OnSCStartTouch);


//	CreateTimer(1.0, SCaliburMove, EntIndexToEntRef(calibur), TIMER_FLAG_NO_MAPCHANGE);
//	CreateTimer(1.5, SCaliburKill, EntIndexToEntRef(ctrigger), TIMER_FLAG_NO_MAPCHANGE);
}

/*public Action SCaliburMove(Handle htimer, int entref)
{
	if(!IsValidEntity(entref))
		return Plugin_Continue;

	float vec[3];
	GetEntPropVector(entref, Prop_Send, "m_angRotation", vec);
	ScaleVector(vec, 3000.0);
	TeleportEntity(entref, NULL_VECTOR, NULL_VECTOR, vec);

	CreateTimer(0.5, SCaliburKill, entref, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action SCaliburKill(Handle htimer, int entref)
{
	if(!IsValidEntity(entref))
		return Plugin_Continue;
	
	RemoveEntity(entref);

	return Plugin_Continue;
}*/

public void OnSCStartTouch(int entity, int victim)
{
	if(!IsValidClient(victim))
		return;

	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

	if(!IsLivingPlayer(owner))
		return;

	if(victim == owner)
		return;

	if(GetClientTeam(victim) == GetClientTeam(owner))
		return;

	float bladeOrigin[3], victimOrigin[3], knockbackVelocity[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", bladeOrigin);
	GetClientAbsOrigin(victim, victimOrigin);

	MakeVectorFromPoints(bladeOrigin, victimOrigin, knockbackVelocity);
	NormalizeVector(knockbackVelocity, knockbackVelocity);
	ScaleVector(knockbackVelocity, 4000.0);

	// absolute minimum Z is 300, otherwise victim will not move in many cases
	if (knockbackVelocity[2] < 300.0)
		knockbackVelocity[2] = 300.0;

	// knock the player back!

	SDKHooks_TakeDamage(victim, owner, owner, SCdamage[owner], DMG_SLASH | DMG_ALWAYSGIB, _, knockbackVelocity, bladeOrigin);
}

//Voltic Chain*******************************************************

void VChain_Tick(int client, int buttons, float curTime)
{
	float timegap = curTime - VC_LastCastAT[client];
	
	if((buttons & IN_USE) && (timegap > VC_CoolDown[client]))
	{
		if(GV_ConsumeEnergy(client, VC_Cost[client]))
		{
			Rage_Voltic_Chain(client);
			VC_LastCastAT[client] = curTime;
		}
		else
		{
			PrintCenterText(client,"能量不足，需要%0.1f能量", VC_Cost[client]);
		}
	}
	else if((buttons & IN_USE) && (timegap <= VC_CoolDown[client]))
	{
		float abiCD = VC_CoolDown[client] - timegap;
		PrintCenterText(client,"冷却中，还有%0.1f秒", abiCD);
	}

/*	for (int VCIdx = VC_MAX_PROJECTILES - 1; VCIdx >= 0; VCIdx--)
	{
		if (VC_BeamEntRef[VCIdx] == INVALID_ENT_REFERENCE)
		{
			if(VC_EndPointRef[VCIdx])
				RemoveEntity(VC_EndPointRef[VCIdx]);
			VC_EndPointRef[VCIdx] = INVALID_ENT_REFERENCE;
			continue;
		}
		
		// hale must be alive
		int owner = LS_Owner[VCIdx];
		if (!IsLivingPlayer(owner))
		{
			VChain_Remove(VCIdx);
			continue;
		}
	}*/
}

void Rage_Voltic_Chain(int client)
{
	VC_BeamActivate[client] = false;

	float pos[3];

	GetClientEyePosition(client , pos);
//	GetClientEyeAngles(client, ang);

//	ang[0] = 0.0;
//	GetAngleVectors(ang, fwd, right, NULL_VECTOR);

	float randombase[6]; // xMin, xMax, yMin, yMax, zMin, zMax;

	randombase[0] = pos[0] - VC_Length[client];
	randombase[1] = pos[0] + VC_Length[client];
	randombase[2] = pos[1] - VC_Length[client];
	randombase[3] = pos[1] + VC_Length[client];
	randombase[4] = pos[2] - VC_Height[client]*0.4;
	randombase[5] = pos[2] + VC_Height[client]*0.6;

	if(strlen(VC_RageSound[client]) > 3)
		EmitSoundToAll(VC_RageSound[client]);

	DataPack VCpack;
	CreateDataTimer(VC_CreateDelay[client], Timer_Voltic_Chain, VCpack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	VCpack.WriteCell(client);
	VCpack.WriteFloatArray(randombase, 6);

	VC_CountNow[client] = 0;
	
}

public Action Timer_Voltic_Chain(Handle htimer, DataPack VCpack)
{
	int client;
	float xMin, xMax, yMin, yMax, zMin, zMax;

	VCpack.Reset();
	client = VCpack.ReadCell();
	float randombase[6];
	VCpack.ReadFloatArray(randombase, 6);
	xMin = randombase[0]; xMax = randombase[1]; yMin = randombase[2]; yMax = randombase[3]; zMin = randombase[4]; zMax = randombase[5];

	VC_CountNow[client]++;

	float spawnpos[3], endpos[3];

/*	spawnpos[0] = GetRandomFloat(xMin, xMax);
	spawnpos[1] = GetRandomFloat(yMin, yMax);
	spawnpos[2] = GetRandomInt(0, 1) ? zMin : zMax;

	endpos[0] = GetRandomFloat(xMin, xMax);
	endpos[1] = GetRandomFloat(yMin, yMax);
	endpos[2] = (spawnpos[2] == zMax) ? zMin : zMax;*/

	switch(GetRandomInt(0,4))
	{
		case 0:
		{
			spawnpos[0] = GetRandomFloat(xMin, xMax);
			spawnpos[1] = GetRandomFloat(yMin, yMax);
			spawnpos[2] = GetRandomInt(0, 1) ? zMin : zMax;

			endpos[0] = GetRandomFloat(xMin, xMax);
			endpos[1] = GetRandomFloat(yMin, yMax);
			endpos[2] = (spawnpos[2] == zMax) ? zMin : zMax;
		}

		case 1, 2:
		{
			spawnpos[0] = GetRandomFloat(xMin, xMax);
			spawnpos[1] = GetRandomInt(0, 1) ? yMin : yMax;
			spawnpos[2] = GetRandomFloat(zMin, zMax);

			endpos[0] = GetRandomFloat(xMin, xMax);
			endpos[1] = (spawnpos[1] == yMax) ? yMin : yMax;
			endpos[2] = GetRandomFloat(zMin, zMax);
		}

		case 3, 4:
		{
			spawnpos[0] = GetRandomInt(0, 1) ? xMin : xMax;
			spawnpos[1] = GetRandomFloat(yMin, yMax);
			spawnpos[2] = GetRandomFloat(zMin, zMax);

			endpos[0] = (spawnpos[0] == xMax) ? xMin : xMax;
			endpos[1] = GetRandomFloat(yMin, yMax);
			endpos[2] = GetRandomFloat(zMin, zMax);
		}
	}
	float dir[3], distance;
	GetVectorAnglesTwoPoints(spawnpos, endpos, dir);
//	MakeVectorFromPoints(spawnpos, endpos, dir);
	distance = GetVectorDistance(spawnpos, endpos);

	if(VC_CountNow[client] >= VC_Count[client])
	{
		float FullyOpenTime = distance/600.0;
		CreateTimer(FullyOpenTime + VC_ActivateTime, VChain_TrunON, client, TIMER_FLAG_NO_MAPCHANGE);
//		delete VCpack;
		return Plugin_Stop;
	}

/*	int startpoint = CreateEntityByName("prop_dynamic");
	if(!IsValidEntity(startpoint))
	{
		PrintToServer("[Gunvolt] Error: Invalid startpoint prop_dynamic. Won't spawn Voltic Chain.");
		return Plugin_Continue;
	}
//	VC_StartPointRef[VC_CountNow[client] - 1] = EntIndexToEntRef(startpoint);
//	DispatchKeyValue(startpoint, "targetname", startEntName);
//	DispatchKeyValue(startpoint, "parentname", parentName);
	DispatchKeyValueVector(startpoint, "origin", spawnpos);
	DispatchKeyValue(startpoint, "model", "models/empty.mdl");
	DispatchKeyValue(startpoint, "solid", "0");
	DispatchKeyValue(startpoint, "rendermode", "10");
	DispatchSpawn(startpoint);*/


	int endpoint = CreateEntityByName("func_movelinear");
	if(!IsValidEntity(endpoint))
	{
		PrintToServer("[Gunvolt] Error: Invalid endpoint func_movelinear. Won't spawn Voltic Chain.");
		return Plugin_Continue;
	}

	int num = VC_CountNow[client] - 1;

	VC_EndPointRef[num] = EntIndexToEntRef(endpoint);
	char targetName[128];
	Format(targetName, sizeof(targetName), "movelinear%i", num);
	DispatchKeyValue(endpoint, "targetname", targetName);
	DispatchKeyValueVector(endpoint, "origin", spawnpos);
	DispatchKeyValue(endpoint, "rendermode", "10");
	DispatchKeyValue(endpoint, "spawnflags", "8");
	DispatchKeyValueVector(endpoint, "movedir", dir);

	DispatchKeyValue(endpoint, "startposition", "0");

	char ArgStr[16];
	IntToString(VC_Speed[client], ArgStr, sizeof(ArgStr));
	DispatchKeyValue(endpoint, "speed", ArgStr);

	IntToString(RoundFloat(distance), ArgStr, sizeof(ArgStr));
	DispatchKeyValue(endpoint, "movedistance", ArgStr);

	DispatchSpawn(endpoint);
	SetEntityModel(endpoint, "models/empty.mdl");

//	DispatchKeyValue(endpoint, "OnFullyOpen", "Rot,Kill,,0,-1");
	AcceptEntityInput(endpoint, "Open");

//	int beam = SpawnBeamRope(num, client, endpoint, spawnpos, dir,"materials/effects/workshop/unusual_chain.vmt", 20.0, {255, 255, 255, 255});
	int beam = SpawnBeamRope(num, client, spawnpos, dir,"materials/effects/workshop/unusual_chain.vmt", 20.0, {255, 255, 255, 255});
//	TeleportEntity(client, spawnpos, dir, NULL_VECTOR);
	
	if(!IsValidEntity(beam))
		return Plugin_Continue;
	
	VC_BeamEntRef[num] = EntIndexToEntRef(beam);

	return Plugin_Continue;
}

public Action VChain_TrunON(Handle htimer, int client)
{
	if(!IsPlayerAlive(client))
	{
		CreateTimer(0.0, VChainRemove, client, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}

	for(int count = VC_CountNow[client] - 1 ; count >= 0 ; count--)
	{
		int beam = EntRefToEntIndex(VC_BeamEntRef[count]);

		if(!IsValidEntity(beam))
		{
			VChain_Remove(count);
			continue;
		}
		
		SetEntityModel(beam, "materials/sprites/bluelight1.vmt");

	//	SetEntPropFloat(beam, Prop_Data, "m_noiseAmplitude", 5.0);
		SetVariantFloat(1.0);
		AcceptEntityInput(beam,"Noise");
		SetEntityRenderColor(beam, 0, 187, 255, 255);
		
		AcceptEntityInput(beam,"TurnOff");
		AcceptEntityInput(beam,"TurnOn");
	}

	VC_BeamActivate[client] = true;

	CreateTimer(VC_Duration[client], VChainRemove, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action VChainRemove(Handle htimer, int client)
{
	for(int i = 0; i<= VC_MAX_PROJECTILES-1; i++)
	{
		if(IsValidEntity(EntRefToEntIndex(VC_BeamEntRef[i])))
			RemoveEntity(VC_BeamEntRef[i]);
//		if(VC_StartPointRef[i])
//			RemoveEntity(VC_StartPointRef[i]);
		if(IsValidEntity(EntRefToEntIndex(VC_EndPointRef[i])))
			RemoveEntity(VC_EndPointRef[i]);
		VC_BeamEntRef[i] = INVALID_ENT_REFERENCE;
//		VC_StartPointRef[i] = INVALID_ENT_REFERENCE;
		VC_EndPointRef[i] = INVALID_ENT_REFERENCE;
	}
	return Plugin_Continue;
}

//int SpawnBeamRope(int num, int client, int entity2, const float startpos[3], const float dir[3], const char[] BeamMaterial, float width = 5.0, int rgba[4] = { 255, 255, 255, 255 })
int SpawnBeamRope(int num, int client, const float startpos[3], const float dir[3], const char[] BeamMaterial, float width = 5.0, int rgba[4] = { 255, 255, 255, 255 })
{
	int beam = CreateEntityByName( "env_beam" );
	if(!IsValidEntity(beam))
	{
		PrintToServer("[Gunvolt] Error: Invalid env_beam. Won't spawn Voltic Chain.");
		return -1;
	}

	DispatchKeyValueVector(beam, "origin", startpos);
	DispatchKeyValueVector(beam, "angles", dir);

	char targetName[128];
	Format(targetName, sizeof(targetName), "beamrope%i:%i", num, client);
	DispatchKeyValue(beam, "targetname", targetName);
//	DispatchKeyValue(beam, "damage", "0");
	DispatchKeyValue(beam, "spawnflags", "1");
	DispatchKeyValueFloat(beam, "BoltWidth", 20.0);
	DispatchKeyValue(beam, "TouchType", "3");
	DispatchKeyValue(beam, "rendermode", "1" );
//	DispatchKeyValue(beam, "TextureScroll", "20");
//	DispatchKeyValue(beam, "HDRColorScale", "1.0");
	DispatchKeyValue(beam, "texture", BeamMaterial);
	DispatchKeyValueFormat(beam, "rendercolor", "%d %d %d", rgba[0], rgba[1], rgba[2]);
	DispatchKeyValueFormat(beam, "renderamt", "%d", rgba[3]);
//	DispatchKeyValue(beam, "life", "0" ); 

	DispatchKeyValue(beam, "LightningStart", targetName);
	Format(targetName, sizeof(targetName), "movelinear%i", num);
	DispatchKeyValue(beam, "LightningEnd", targetName);

	DispatchKeyValue(beam, "OnTouchedByEntity", "!self,TurnOff,,0.02,-1");
	DispatchKeyValue(beam, "OnTouchedByEntity", "!self,TurnOn,,0.03,-1");

//	TeleportEntity(beam, startpos, NULL_VECTOR, NULL_VECTOR ); 

	DispatchSpawn(beam);

/*	SetEntPropEnt(beam, Prop_Send, "m_hAttachEntity", entity2, 1);
	if(!entity1)
		SetEntPropEnt(beam, Prop_Send, "m_hAttachEntity", beam, 0);
	else
		SetEntPropEnt(beam, Prop_Send, "m_hAttachEntity", entity1);

	SetEntProp(beam, Prop_Send, "m_nNumBeamEnts", 2);
	SetEntProp(beam, Prop_Send, "m_nBeamType", 2);
//	SetEntProp(beam, Prop_Data, "m_nRenderFX", 15);
*/
	SetEntPropEnt(beam, Prop_Data, "m_hOwnerEntity", client);
	SetEntPropFloat(beam, Prop_Data, "m_fWidth", width);
	SetEntPropFloat(beam, Prop_Data, "m_fEndWidth", width);
	ActivateEntity(beam);
	AcceptEntityInput(beam,"TurnOn");

	HookSingleEntityOutput(beam, "OnTouchedByEntity", OnBeamTouched, false);

	return beam;
}

public void OnBeamTouched (const char[] output, int caller, int activator, float delay)
{
//	char targetname[128];
//	GetEntPropString(caller, Prop_Data, "m_iName", targetname, sizeof(targetname));
//	if(strcmp(targetname, "beamrope") != 0)
//		return;

	if(!IsValidClient(activator))
		return;

	char sEntityTargetName[255];
	char sBuffer[2][128];
	int owner;
	GetEntPropString(caller, Prop_Data, "m_iName", sEntityTargetName, sizeof(sEntityTargetName));
	ExplodeString(sEntityTargetName, ":", sBuffer, sizeof(sBuffer), sizeof(sBuffer[]), true);
	if(!StrEqual(sBuffer[1], ""))
		owner = StringToInt(sBuffer[1]);

	if(!IsLivingPlayer(owner))
		return;
	if(!VC_BeamActivate[owner])
		return;
//	int boss = GetClientOfUserId(FF2_GetBossUserId(0));
	if(activator == owner)
		return;
	if(GetClientTeam(activator) == BossTeam)
		return;
	SDKHooks_TakeDamage(activator, owner, owner, VCdamage[owner], DMG_ENERGYBEAM | DMG_PREVENT_PHYSICS_FORCE, -1);

}

public void VChain_Remove(int count)
{
	if(IsValidEntity(EntRefToEntIndex(VC_BeamEntRef[count])))
		RemoveEntity(VC_BeamEntRef[count]);
//	RemoveEntity(VC_StartPointRef[count]);
	if(IsValidEntity(EntRefToEntIndex(VC_EndPointRef[count])))
		RemoveEntity(VC_EndPointRef[count]);
	VC_BeamEntRef[count] = INVALID_ENT_REFERENCE;
//	VC_StartPointRef[count] = INVALID_ENT_REFERENCE;
	VC_EndPointRef[count] = INVALID_ENT_REFERENCE;

	for (int i = count; i < VC_MAX_PROJECTILES - 1; i++)
	{
		VC_BeamEntRef[i] = VC_BeamEntRef[i+1];
//		VC_StartPointRef[i] = VC_StartPointRef[i+1];
		VC_EndPointRef[i] = VC_EndPointRef[i+1];
	}
}



public bool GV_ConsumeEnergy(int clientIdx, float cost) // this can only be called by the currently active ability
{
	if (cost > GV_EnergyPercent[clientIdx])
	{
		return false;
	}
	
	GV_EnergyPercent[clientIdx] -= cost;
	return true;
}


//STOCK****************************************************************

/*stock void FullyHookedDamage(int victim, int inflictor, int attacker, float damage, int damageType = DMG_GENERIC, int weapon = -1)
{
	char dmgStr[16];
	IntToString(RoundFloat(damage), dmgStr, sizeof(dmgStr));

	// took this from war3...I hope it doesn't double damage like I've heard old versions do
	int pointHurt = CreateEntityByName("point_hurt");
	if (IsValidEntity(pointHurt))
	{
		DispatchKeyValue(victim, "targetname", "halevictim");
		DispatchKeyValue(pointHurt, "DamageTarget", "halevictim");
		DispatchKeyValue(pointHurt, "Damage", dmgStr);
		DispatchKeyValueFormat(pointHurt, "DamageType", "%d", damageType);

		DispatchSpawn(pointHurt);
		if (IsLivingPlayer(attacker))
		{
			float attackerOrigin[3];
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", attackerOrigin);
			TeleportEntity(pointHurt, attackerOrigin, NULL_VECTOR, NULL_VECTOR);
		}
		AcceptEntityInput(pointHurt, "Hurt", attacker);
		DispatchKeyValue(pointHurt, "classname", "point_hurt");
		DispatchKeyValue(victim, "targetname", "noonespecial");
		RemoveEntity(EntIndexToEntRef(pointHurt));
	}
}*/

stock void TE_Particle(char[] Name, float delay = 0.0, float origin[3] = NULL_VECTOR, float start[3] = NULL_VECTOR, float angles[3] = NULL_VECTOR, entindex=-1, attachtype=-1, attachpoint=-1, bool resetParticles=true, customcolors = 0, float color1[3] = NULL_VECTOR, float color2[3] = NULL_VECTOR, int controlpoint = -1, controlpointattachment = -1, float controlpointoffset[3] = NULL_VECTOR)
{
	// find string table
	int tblidx = FindStringTable("ParticleEffectNames");
	if (tblidx == INVALID_STRING_TABLE)
	{
		LogError("Could not find string table: ParticleEffectNames");
		return;
	}
//	float delay = 3.0;
	// find particle index
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;

	for (int i = 0; i < count; i++)
	{
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if (StrEqual(tmp, Name, false))
		{
			stridx = i;
			break;
		}
	}
	if (stridx == INVALID_STRING_INDEX)
	{
		LogError("Could not find particle: %s", Name);
		return;
	}

	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", origin[0]);
	TE_WriteFloat("m_vecOrigin[1]", origin[1]);
	TE_WriteFloat("m_vecOrigin[2]", origin[2]);
	TE_WriteFloat("m_vecStart[0]", start[0]);
	TE_WriteFloat("m_vecStart[1]", start[1]);
	TE_WriteFloat("m_vecStart[2]", start[2]);
	TE_WriteVector("m_vecAngles", angles);
	TE_WriteNum("m_iParticleSystemIndex", stridx);
	if (entindex !=- 1)
	{
		TE_WriteNum("entindex", entindex);
	}
	if (attachtype != -1)
	{
		TE_WriteNum("m_iAttachType", attachtype);
	}
	if (attachpoint != -1)
	{
		TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
	}
	TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);

	if(customcolors)
	{
		TE_WriteNum("m_bCustomColors", customcolors);
		TE_WriteVector("m_CustomColors.m_vecColor1", color1);
		if(customcolors == 2)
		{
			TE_WriteVector("m_CustomColors.m_vecColor2", color2);
		}
	}
	if(controlpoint != -1)
	{
		TE_WriteNum("m_bControlPoint1", controlpoint);
		if(controlpointattachment != -1)
		{
			TE_WriteNum("m_ControlPoint1.m_eParticleAttachment", controlpointattachment);
			TE_WriteFloat("m_ControlPoint1.m_vecOffset[0]", controlpointoffset[0]);
			TE_WriteFloat("m_ControlPoint1.m_vecOffset[1]", controlpointoffset[1]);
			TE_WriteFloat("m_ControlPoint1.m_vecOffset[2]", controlpointoffset[2]);
		}
	}
	TE_SendToAll(delay);
}

stock int AttachParticle(int entity, const char[] szParticleType, float flTimeToDie = -1.0, float vOffsets[3] = {0.0,0.0,0.0}, bool bAttach = false, float flTimeToStart = -1.0)
{
	int particle = CreateEntityByName("info_particle_system");
	if (!IsValidEntity(particle))
		return -1;
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

stock void killEntityIn(int iEnt, float flSeconds)
{
	char szAddOutput[32];
	Format(szAddOutput, sizeof(szAddOutput), "OnUser1 !self,Kill,,%0.2f,1", flSeconds);
	SetVariantString(szAddOutput);
	AcceptEntityInput(iEnt, "AddOutput");
	AcceptEntityInput(iEnt, "FireUser1");
}

stock void ReadModel(int bossIdx, const char[] ability_name, int argInt, char modelFile[128])
{
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, modelFile, 128);
	if (strlen(modelFile) > 3)
		PrecacheModel(modelFile);
}

/*stock void ReadSound(int bossIdx, const char[] ability_name, int argInt, char soundFile[80])
{
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, soundFile, 80);
	if (strlen(soundFile) > 3)
		PrecacheSound(soundFile);
}*/

/*stock void RemoveEntity(int entity)
{
	if (IsValidEdict(entity) && entity > MaxClients)
	{
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR); // send it away first in case it feels like dying dramatically
		AcceptEntityInput(entity, "Kill");
	}
}*/

stock void DispatchKeyValueFormat(int entity, const char[] keyName, const char[] format, any:...)
{
	char value[256];
	VFormat(value, sizeof(value), format, 4);

	DispatchKeyValue(entity, keyName, value);
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

stock float ConformAxisValue(float src, float dst, float distCorrectionFactor)
{
	return src - ((src - dst) * distCorrectionFactor);
}

stock void ConformLineDistance(float result[3], float src[3], float dst[3], float maxDistance, bool canExtend = false)
{
	float distance = GetVectorDistance(src, dst);
	if (distance <= maxDistance && !canExtend)
	{
		// everything's okay.
		result[0] = dst[0];
		result[1] = dst[1];
		result[2] = dst[2];
	}
	else
	{
		// need to find a point at roughly maxdistance. (FP irregularities aside)
		float distCorrectionFactor = maxDistance / distance;
		result[0] = ConformAxisValue(src[0], dst[0], distCorrectionFactor);
		result[1] = ConformAxisValue(src[1], dst[1], distCorrectionFactor);
		result[2] = ConformAxisValue(src[2], dst[2], distCorrectionFactor);
	}
}

stock int abs(x)
{
	return x < 0 ? -x : x;
}

stock float fabs(float x)
{
	return x < 0 ? -x : x;
}

stock int min(int n1, int n2)
{
	return n1 < n2 ? n1 : n2;
}
stock float fmin(float n1, float n2)
{
	return n1 < n2 ? n1 : n2;
}

stock int max(int n1, int n2)
{
	return n1 > n2 ? n1 : n2;
}

stock float fmax(float n1, float n2)
{
	return n1 > n2 ? n1 : n2;
}

stock void GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	float tmpVec[3];
	//tmpVec[0] = startPos[0] - endPos[0];
	//tmpVec[1] = startPos[1] - endPos[1];
	//tmpVec[2] = startPos[2] - endPos[2];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}

stock bool IsBoss(int client)
{
	return (FF2_GetBossIndex(client)!=-1) ? true : false;
}

stock bool IsLivingPlayer(int clientIdx)
{
	if (clientIdx <= 0 || clientIdx > MaxClients)
		return false;
		
	return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
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

stock int LoadStringFromAddress(Address addr, char[] buffer, int maxlen,
		bool &bIsNullPointer = false) {
	if (!addr) {
		bIsNullPointer = true;
		return 0;
	}
	
	int c;
	char ch;
	do {
		ch = view_as<int>(LoadFromAddress(addr + view_as<Address>(c), NumberType_Int8));
		buffer[c] = ch;
	} while (ch && ++c < maxlen - 1);
	return c;
}

stock Address DereferencePointer(Address addr)
{
	return view_as<Address>(LoadFromAddress(addr, NumberType_Int32));
}
/*public int CheckRoundState()
{
	switch(GameRules_GetRoundState())
	{
		case RoundState_Init, RoundState_Pregame:
			return -1;

		case RoundState_StartGame, RoundState_Preround:
			return 0;

		case RoundState_RoundRunning, RoundState_Stalemate:  //Oh Valve.
			return 1;
	}
	return 2;
}*/