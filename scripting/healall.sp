#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <dhooks>
#include <freak_fortress_2>

//#pragma newdecls required

#define PLUGIN_NAME     "Example all-heal plugin"
#define PLUGIN_AUTHOR   "Naydef"
#define PLUGIN_VERSION  "1.0"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
};

Handle hDetourAllowedToHealTarget;

public OnPluginStart()
{
	Handle gamedatafile=LoadGameConfigFile("ghostbuster_defs.games");
	if(gamedatafile==null)
	{
		SetFailState("Cannot find file ghostbuster_defs.games!");
	}
	hDetourAllowedToHealTarget=DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
	if(hDetourAllowedToHealTarget==null)
	{
		SetFailState("Failed to create CWeaponMedigun::AllowedToHealTarget detour!");
	}
	//	Load the address of the function from PTaH's signature gamedata file.
	if(!DHookSetFromConf(hDetourAllowedToHealTarget, gamedatafile, SDKConf_Signature, "CWeaponMedigun::AllowedToHealTarget"))
	{
		SetFailState("Failed to load CWeaponMedigun::AllowedToHealTarget signature from gamedata");
	}
	//	Load the address of the function from PTaH's signature gamedata file.
	delete gamedatafile;
	
	//CWeaponMedigun::AllowedToHealTarget
	DHookAddParam(hDetourAllowedToHealTarget, HookParamType_CBaseEntity);
	
	//	Add a post hook on the function.
	if(!DHookEnableDetour(hDetourAllowedToHealTarget, false, Detour_AllowedToHealTargetPost))
	{
		SetFailState("Failed to detour CWeaponMedigun::AllowedToHealTarget!");
	}
	
	//	HookEvent("player_healed", OnPlayerHealed, EventHookMode_Pre);
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			SDKHook(i, SDKHook_PreThink, OnPreThink);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PreThink, OnPreThink);
}




public MRESReturn Detour_AllowedToHealTargetPost(int pThis, Handle hReturn, Handle hParams)
{
	if(pThis==-1 || DHookIsNullParam(hParams, 1))
		return MRES_Ignored;
	int target=DHookGetParam(hParams, 1);
	if(!IsValidClient(target))
		return MRES_Ignored;

//	int targettoheal=DHookGetParam(hParams, 1);
	
//	if(IsValidEntity(targettoheal) && targettoheal>MaxClients)
//	{
//		if(HasEntProp(targettoheal, Prop_Send, "m_iHealth"))
//		{
//			int health=GetEntProp(targettoheal, Prop_Send, "m_iHealth");
//			SetEntProp(targettoheal, Prop_Send, "m_iHealth", health+5);
//		}
//	}
	DHookSetReturn(hReturn, true); // Just try the medigun in the game :)


	decl String:parentName[16];
	Format(parentName, sizeof(parentName), "client_%d", target);
	
	DispatchKeyValue(target, "targetname", parentName);
	
	decl Float:clientOrigin[3],Float:eyepos[3] ,Float:destination[3] ,Float:angle[3];
	GetClientEyePosition(target, eyepos);
	GetClientAbsOrigin(target, clientOrigin);
	angle[0] = 0.0;angle[1] = 0.0;angle[2] = 0.0;
//	clientOrigin[2] += 4.0; // avoid beam ring to stick into ground
	destination[1] = clientOrigin[1];
	destination[2] = (clientOrigin[2] + eyepos[2])/2.0;
	destination[0] = clientOrigin[0];
	
	/* *** Create hook entity 1 *** */
	new startEnt = CreateEntityByName("prop_dynamic");
	
	decl String:startEntName[32];
	Format(startEntName, sizeof(startEntName), "start_%d", startEnt);
	
	DispatchKeyValue(startEnt, "targetname", startEntName);
	DispatchKeyValue(startEnt, "parentname", parentName);
	DispatchKeyValue(startEnt, "model", "models/advisor.mdl");
	DispatchKeyValue(startEnt, "solid", "0");
	DispatchKeyValue(startEnt, "rendermode", "10");
	
	DispatchSpawn(startEnt);
	
//	clientOrigin[1] += 100.0;
	destination[1] += 100.0;
	TeleportEntity(startEnt, destination, angle, NULL_VECTOR);
	
	SetVariantString(parentName);
	AcceptEntityInput(startEnt, "SetParent");
	CreateTimer(10.0, Timer_Kill1, startEnt);
	
	/* *** Create hook entity 2 *** */
	new endEnt = CreateEntityByName("prop_dynamic");
	
	decl String:endEntName[32];
	Format(endEntName, sizeof(endEntName), "end_%d", endEnt);
	
	DispatchKeyValue(endEnt, "targetname", endEntName);
	DispatchKeyValue(endEnt, "parentname", parentName);
	DispatchKeyValue(endEnt, "model", "models/advisor.mdl");
	DispatchKeyValue(endEnt, "solid", "0");
	DispatchKeyValue(endEnt, "rendermode", "10");
	
	DispatchSpawn(endEnt);
	
//	clientOrigin[1] -= 200.0;
	destination[1] -= 200.0;
	TeleportEntity(endEnt, destination, angle, NULL_VECTOR);
	
	SetVariantString(parentName);
	AcceptEntityInput(endEnt, "SetParent");
	CreateTimer(10.0, Timer_Kill2, endEnt);


	new entity = CreateEntityByName("env_beam");
	if(entity != -1)
	{
		DispatchKeyValue(entity, "damage", "0");
		DispatchKeyValue(entity, "framestart", "0");
		DispatchKeyValue(entity, "BoltWidth", "10");
		DispatchKeyValue(entity, "renderfx", "0");
		DispatchKeyValue(entity, "TouchType", "3");
		DispatchKeyValue(entity, "framerate", "0");
		DispatchKeyValue(entity, "decalname", "Bigshot");
		DispatchKeyValue(entity, "TextureScroll", "50");
		DispatchKeyValue(entity, "HDRColorScale", "1.0");
		DispatchKeyValue(entity, "texture", "materials/sprites/laserbeam.vmt");
		DispatchKeyValue(entity, "life", "1");
		DispatchKeyValue(entity, "LightningStart", startEntName);
		DispatchKeyValue(entity, "LightningEnd", endEntName);

		DispatchKeyValue(entity, "spawnflags", "8");
		DispatchKeyValue(entity, "NoiseAmplitude", "0");
		DispatchKeyValue(entity, "Radius", "256");
		DispatchKeyValue(entity, "rendercolor", "0 255 255");
		DispatchKeyValue(entity, "renderamt", "100");
		DispatchSpawn(entity);


		CreateTimer(10.0, Timer_Killbeam, entity);
	}
	
	
	
	return MRES_ChangedOverride;
} 

/*
public Action:OnPlayerHealed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new healer = GetClientOfUserId(GetEventInt(event, "healer"));
	new patient = GetClientOfUserId(GetEventInt(event, "patient"));
	new amount = GetEventInt(event, "amount");
	if(!IsValidClient(healer) || !IsValidClient(patient) || healer == patient)
		return Plugin_Continue;
	CPrintToChatAll("fuck you");
	if(TF2_GetClientTeam(healer) != TF2_GetClientTeam(patient))
	{
		CPrintToChatAll("fucked yet");
		if(!TF2_IsPlayerInCondition(patient, TFCond_Cloaked) || !TF2_IsPlayerInCondition(patient, TFCond_Disguised))
		{
			amount = -20;
			SetEventInt(event, "amount", amount);
			CPrintToChatAll("fuck man");
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}
*/

public OnPreThink(client)
{
	new patient = TF2_GetHealingTarget(client);
	if(!IsValidClient(patient))
		return;
	if(TF2_GetClientTeam(client) != TF2_GetClientTeam(patient))
	{
		if(!TF2_IsPlayerInCondition(patient, TFCond_Cloaked) || !TF2_IsPlayerInCondition(patient, TFCond_Disguised))
		{
			SDKHooks_TakeDamage(patient, client, client, 1.0);
		}
	}


}



stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;

	return IsClientInGame(client);
}

stock TF2_GetHealingTarget(client)
{
	new String:classname[64];
	TF2_GetCurrentWeaponClass(client, classname, sizeof(classname));

	if(StrEqual(classname, "CWeaponMedigun"))
	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(GetEntProp(index, Prop_Send, "m_bHealing") == 1)
		{
			return GetEntPropEnt(index, Prop_Send, "m_hHealingTarget");
		}
	}
	return -1;
}

stock TF2_GetCurrentWeaponClass(client, String:name[], maxlength) {
	if(client > 0) {
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (index > 0)
			GetEntityNetClass(index, name, maxlength);
	}
}

stock SetParent(iParent, iChild, const String:szAttachment[] = "", Float:vOffsets[3] = {0.0,0.0,0.0})
{
	SetVariantString("!activator");
	AcceptEntityInput(iChild, "SetParent", iParent, iChild);

	if (szAttachment[0] != '\0') // Use at least a 0.01 second delay between SetParent and SetParentAttachment inputs.
	{
		SetVariantString(szAttachment); // "head"

	if (!AreVectorsEqual(vOffsets, Float:{0.0,0.0,0.0})) // NULL_VECTOR
	{
		decl Float:vPos[3];
		GetEntPropVector(iParent, Prop_Send, "m_vecOrigin", vPos);
		AddVectors(vPos, vOffsets, vPos); 
		TeleportEntity(iChild, vPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(iChild, "SetParentAttachmentMaintainOffset", iParent, iChild);
	}
	else
	{
		AcceptEntityInput(iChild, "SetParentAttachment", iParent, iChild);
	}
	}
}

stock bool:AreVectorsEqual(Float:vVec1[3], Float:vVec2[3])
{
	return (vVec1[0] == vVec2[0] && vVec1[1] == vVec2[1] && vVec1[2] == vVec2[2]);
}

public Action:Timer_Kill1(Handle:htimer, int ent)
{
	AcceptEntityInput(ent, "Kill");
}

public Action:Timer_Kill2(Handle:htimer, int ent)
{
	AcceptEntityInput(ent, "Kill");
}

public Action:Timer_Killbeam(Handle:htimer, int ent)
{
	AcceptEntityInput(ent, "Kill");
}
