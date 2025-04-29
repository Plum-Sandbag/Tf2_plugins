#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <freak_fortress_2>
#include <tf2>
#include <sdkhooks>

#define SPRITE_ARROW "materials/freak_fortress_2/Ani_Arrow.vmt"
//#define MODEL_EMPTY "models/empty.mdl"
#define PLUGIN_VERSION "1.0"
int Ref_Sprite[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE,...};
bool LateLoaded;
new Float:playerpos[3];
new Float:bosspos[3];
public Plugin:myinfo =
{
	name = "Head Arrow",
	author = "XGAK",
	description = "Display an arrow above boss's head",
	version = PLUGIN_VERSION,
	url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	LateLoaded = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	if(LateLoaded)
		OnMapStart();
	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("teamplay_round_win", OnRoundEnd);
}

public void OnPluginEnd()
{
	OnMapEnd();
}

public void OnMapStart()
{
	PrecacheModel(SPRITE_ARROW, true);
//	PrecacheModel(MODEL_EMPTY, true);
	AddFileToDownloadsTable(SPRITE_ARROW);
	AddFileToDownloadsTable("materials/freak_fortress_2/Ani_Arrow.vtf");
}

public void OnMapEnd()
{
	for(new i=1;i<=MaxClients;i++)
	{
		new ent = EntRefToEntIndex(Ref_Sprite[i]);
		if(ent != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(ent, "Kill");
		}
	}
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(!FF2_IsFF2Enabled())
	{
		return;
	}
	CreateSprite(GetClientOfUserId(FF2_GetBossUserId(0)));
}

public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	decl ent;
	new bossid = GetClientOfUserId(FF2_GetBossUserId(0));
	ent = EntRefToEntIndex(Ref_Sprite[bossid]);
	if(ent != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent, "Kill");
	}

	return Plugin_Continue;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if(IsBoss(client))
	{
		if(condition==TFCond_Cloaked || condition==TFCond_Stealthed || condition==TFCond_StealthedUserBuffFade || TFCond_Disguised)
		{
			int ent = EntRefToEntIndex(Ref_Sprite[client]);
			if(ent != INVALID_ENT_REFERENCE)
				AcceptEntityInput(ent, "HideSprite");
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if(IsBoss(client))
	{
		if(condition==TFCond_Cloaked || condition==TFCond_Stealthed || condition==TFCond_StealthedUserBuffFade || TFCond_Disguised)
		{
			int ent = EntRefToEntIndex(Ref_Sprite[client]);
			if(ent != INVALID_ENT_REFERENCE)
				AcceptEntityInput(ent, "ShowSprite");
		}
	}
}

public Action Hook_SetParticleTransmit(int entity, int client)
{
	setFlags(entity);
	if(IsBoss(client))
		return Plugin_Handled;
	new bossindex = GetClientOfUserId(FF2_GetBossUserId(0));
	GetClientEyePosition(bossindex, bosspos);
	GetClientEyePosition(client, playerpos);
	if(!CanSeeTarget(playerpos, bosspos, bossindex))
		return Plugin_Handled;
	return Plugin_Continue;
}

//taken from halloween_2013 subplugin.
void CreateSprite(int client)
{
		decl particle;
		decl Float:pos[3];
		particle = EntRefToEntIndex(Ref_Sprite[client]);
		if(particle != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(particle, "Kill");
		}
		particle = CreateEntityByName("env_sprite");
		if (particle != -1)
		{
			GetClientAbsOrigin(client, pos);
			pos[2] += 155.0;
			DispatchKeyValue(particle, "model", SPRITE_ARROW);
			DispatchKeyValueVector(particle, "origin", pos);
			DispatchKeyValue(particle, "disablereceiveshadows", "1");
			DispatchKeyValue(particle, "framerate", "3.0");
//			DispatchKeyValueFloat(particle, "GlowProxySize", 10.0);
			DispatchKeyValueFloat(particle, "HDRColorScale", 1.0);
			DispatchKeyValue(particle, "renderamt", "255");
			DispatchKeyValue(particle, "rendercolor", "255 255 255 255");
//			DispatchKeyValue(particle, "renderfx", "0");
			DispatchKeyValue(particle, "spawnflags", "1");
			DispatchKeyValue(particle, "rendermode", "7");
			DispatchKeyValue(particle, "scale", "0.02");
			DispatchSpawn(particle);

			int iLink = CreateLink(client);
//			SetVariantString("!activator");
//			AcceptEntityInput(particle, "SetParent", iLink); 
//			SetVariantString("head"); 
//			AcceptEntityInput(particle, "SetParentAttachment", iLink); 

//			SetEntPropEnt(particle, Prop_Send, "m_hEffectEntity", iLink);

//			SetVariantString("!activator");
//			AcceptEntityInput(particle, "SetParent", client);

			SetParent(iLink, particle, "", pos);

			Ref_Sprite[client] = EntIndexToEntRef(particle);
			SetEdictFlags(particle, GetEdictFlags(particle)&(~FL_EDICT_ALWAYS) ); // allow settransmit hooks
			SDKHookEx(particle, SDKHook_SetTransmit, Hook_SetParticleTransmit);
		}
}

//taken from Pelipoika's BackpackDispenser plugin.
stock int CreateLink(int iClient)
{
	int iLink = CreateEntityByName("tf_taunt_prop");
	DispatchKeyValue(iLink, "targetname", "DispenserLink");
	DispatchSpawn(iLink); 
	
//	SetEntityModel(iLink, MODEL_EMPTY);
	char strModel[PLATFORM_MAX_PATH];
	GetEntPropString(iClient, Prop_Data, "m_ModelName", strModel, PLATFORM_MAX_PATH);
	SetEntityModel(iLink, strModel);


	SetEntProp(iLink, Prop_Send, "m_fEffects", 16|64);
	
	decl Float:Pos[3];
	Pos[0] = 0.0;Pos[1] = 0.0;Pos[2] = 0.1;
	SetParent(iClient, iLink, "", Pos);
	
	return iLink;
}

//taken from Pelipoika's Dispenser rockets plugin.
bool:CanSeeTarget(Float:startpos[3], Float:targetpos[3], target)        // Tests to see if vec1 > vec2 can "see" target
{
    TR_TraceRayFilter(startpos, targetpos, MASK_SOLID, RayType_EndPoint, TraceRayFilterClients, target);
    if(TR_GetEntityIndex() == target)
    {
        return true;
    }
    return false;
}

public bool:TraceRayFilterClients(entity, mask, any:data)
{
    if(entity > 0 && entity <=MaxClients)                    // only hit the client we're aiming at
    {
        if(entity == data)
            return true;
        else
            return false;
    }
    return true;
}

//Credits to Chdata
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

void setFlags(int edict)
{
	if (GetEdictFlags(edict) & FL_EDICT_ALWAYS)
	{
		SetEdictFlags(edict, (GetEdictFlags(edict) ^ FL_EDICT_ALWAYS));
	}
}

bool:IsBoss(client)
{
	return (FF2_GetBossIndex(client)!=-1) ? true : false;
}

bool:IsValidClient(int client, bool replaycheck=true)
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
