#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2>
#include <smlib>
#include <freak_fortress_2>
#include <morecolors>
#include <CBaseAnimatingOverlay>
#tryinclude <goomba>

#define MODEL_EMPTY "models/empty.mdl"

new IsPlayerCharging[MAXPLAYERS+1];
new Float:OFF_THE_MAP[3] = { 16383.0, 16383.0, -16383.0 };
bool Chargefree[MAXPLAYERS + 1] = true;

public Plugin:myinfo = 
{
    name = "[TF2] Charge freely ",
    author = "",
    description = "",
    version = "",
    url = ""
}

public OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	RegConsoleCmd("sm_cf", Command_Chargefreely);
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

public OnMapStart()
{
	CreateTimer(300.0, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
//	PrecacheModel("materials/sprites/laserbeam.vmt", true);
//	PrecacheModel("glow01.spr", true);
//	PrecacheModel(MODEL_EMPTY, true);

}

/*
public OnEntityCreated(entity, const String:sClassName[])
{
	if(StrEqual(sClassName,"func_movelinear"))
	{
		AcceptEntityInput(entity, "Open");
		CPrintToChatAll("rrr");
	}
}
*/

public Action Command_Chargefreely(int client, int args)
{
	if(!Chargefree[client])
	{
		SetConVarInt(FindConVar("sv_client_predict"), 0);
		CreateTimer(1.0, Timer_Freeze, client, TIMER_FLAG_NO_MAPCHANGE);
//		UpdateClientPredictValue(0);
		CPrintToChat(client, "{orange}自由冲锋模式\n该模式下正在冲锋时无法踩头");
		Chargefree[client] = true;
	}
	else if(Chargefree[client])
	{
		SetConVarInt(FindConVar("sv_client_predict"), -1);
		UpdateClientPredictValue(-1);
		SetEntProp(client, Prop_Send, "m_bIsPlayerSimulated", 1);
		SetEntProp(client, Prop_Send, "m_bSimulatedEveryTick", 1);
		SetEntProp(client, Prop_Send, "m_bAnimatedEveryTick", 1);
		SetEntProp(client, Prop_Send, "m_bClientSideAnimation", 1);
		SetEntProp(client, Prop_Send, "m_bClientSideFrameReset", 0);
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime());
		CPrintToChat(client, "{orange}普通冲锋模式");
		Chargefree[client] = false;
	}
}

public Action:Timer_Freeze(Handle:timer, any:client)
{
	SetEntProp(client, Prop_Send, "m_bIsPlayerSimulated", 0);
	SetEntProp(client, Prop_Send, "m_bSimulatedEveryTick", 0);
	SetEntProp(client, Prop_Send, "m_bAnimatedEveryTick", 0);
	SetEntProp(client, Prop_Send, "m_bClientSideAnimation", 0);
	SetEntProp(client, Prop_Send, "m_bClientSideFrameReset", 1);
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime()+10000.0);
}

public Action:Timer_Announce(Handle:timer)
{
	CPrintToChatAll("{olive}输入{orange}!cf{olive}或{orange}/cf{olive}切换冲锋模式");
	return Plugin_Continue;
}

public OnPreThink(client)
{
	if(Chargefree[client])
	{
		if(IsPlayerCharging[client]==1)
		{
			static Float:angles[3];
			GetClientEyeAngles(client, angles);
			static Float:velocity[3],Float:Horizon[3];
			GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
			Horizon[0]=velocity[0];
			Horizon[1]=velocity[1];
			Horizon[2]=0.0;
			ScaleVector(velocity, 750.0);
			ScaleVector(Horizon, 750.0);
			Horizon[2]=velocity[2];
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Horizon);
		}
	}
}

public Action:OnStomp(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower)
{
	if(!IsValidClient(attacker) || !IsValidClient(victim) || attacker==victim)
	{
		return Plugin_Continue;
	}
	if(Chargefree[attacker] && TF2_IsPlayerInCondition(attacker, TFCond_Charging))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	IsPlayerCharging[client]=0;
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	IsPlayerCharging[client]=0;
	return Plugin_Continue;
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if(!IsBoss(client) && condition==TFCond_Charging)
	{
		IsPlayerCharging[client]=1;
		CreateBullet(client);
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(!IsBoss(client) && condition==TFCond_Charging)
	{
		IsPlayerCharging[client]=0;
	}
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

CreateBullet(client)
{
	new ent = -1;
	char entName[64];
	CPrintToChatAll("yyyy");
	DispatchKeyValue(client, "targetname", "the_bullet_maker");
	while ((ent = FindEntityByClassname(ent, "env_entity_maker")) != -1)
	{
		CPrintToChatAll("ououou");
		Entity_GetName(ent, entName, sizeof(entName));
		if(!StrContains(entName, "xgak_maker"))
		{
			SetVariantString("the_bullet_maker"); 
			AcceptEntityInput(ent, "ForceSpawnAtEntityOrigin");
			CPrintToChatAll("wuwuwu");
		}
	}
}



/*CreateTemplate(client)
{
	decl Float:origin[3] = {0.0, 0.0, 0.0}, Float:direction[3] = {0.0, 0.0, 0.0};
//	new Float:direction[3] = {0.0, 0.0, 0.0};
	new Bullet_move;
	new Bullet_rot_1;
	new Bullet_move_sub[4];
	new Bullet_main;
	new Bullet_sprt;
	new Bullet_sprt_sub[4];
	new String:Rot[30];
//	decl String:Rot[30], String:Spr_main[30], String:Spr_main_trail[30], String:Moveline[30], String:Moveline_sub0[30], String:Moveline_sub1[30], String:Moveline_sub2[30], String:Moveline_sub3[30];
	Bullet_rot_1 = CreateEntityByName("func_rotating");
	if(Bullet_rot_1!=-1)
	{
		Format(Rot, sizeof(Rot), "Rot_%i", Bullet_rot_1);
		DispatchKeyValue(Bullet_rot_1, "targetname", Rot);
		DispatchKeyValueVector(Bullet_rot_1, "origin", origin);
		DispatchKeyValue(Bullet_rot_1, "rendermode", "10");
//		GetClientEyeAngles(client, angle);
		DispatchKeyValueVector(Bullet_rot_1, "angles", direction);
		DispatchKeyValueFloat(Bullet_rot_1, "fanfriction", 0.2);
		DispatchKeyValue(Bullet_rot_1, "spawnflags", "65");
		DispatchKeyValue(Bullet_rot_1, "solidbsp", "0");
		DispatchKeyValue(Bullet_rot_1, "maxspeed", "750");
		SetEntPropFloat(Bullet_rot_1, Prop_Data, "m_flTargetSpeed", 750.0);
		DispatchKeyValue(Bullet_rot_1, "dmg", "0");
		DispatchSpawn(Bullet_rot_1);
		SetEntityModel(Bullet_rot_1, MODEL_EMPTY);
		SetEntPropVector(Bullet_rot_1, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -50.0});
		SetEntPropVector(Bullet_rot_1, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 50.0});
		SetEntProp(Bullet_rot_1, Prop_Send, "m_nSolidType", 0);

	}
	Bullet_move = CreateEntityByName("func_movelinear");
	if(Bullet_move!=-1)
	{
		direction[0] = -90.0;

//		Format(Moveline, sizeof(Moveline), "Moveline_%i", Bullet_move);
		DispatchKeyValue(Bullet_move, "targetname", "Moveline");
		DispatchKeyValueVector(Bullet_move, "origin", origin);
		DispatchKeyValue(Bullet_move, "rendermode", "10");
		DispatchKeyValue(Bullet_move, "spawnflags", "8");
		DispatchKeyValueVector(Bullet_move, "movedir", direction);
		DispatchKeyValue(Bullet_move, "startposition", "0");
		DispatchKeyValue(Bullet_move, "speed", "500");
		DispatchKeyValue(Bullet_move, "movedistance", "2000");
		DispatchKeyValue(Bullet_move, "blockdamage", "0");
		DispatchKeyValue(Bullet_move, "parentname", Rot);
		SetEntPropEnt(Bullet_move, Prop_Data, "m_hMoveParent", Bullet_rot_1);
		SetEntPropEnt(Bullet_move, Prop_Data, "m_hParent", Bullet_rot_1);
		DispatchSpawn(Bullet_move);
		SetEntityModel(Bullet_move, MODEL_EMPTY);
		SetEntPropVector(Bullet_move, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -50.0});
		SetEntPropVector(Bullet_move, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 50.0});
		SetEntProp(Bullet_move, Prop_Send, "m_nSolidType", 2);
		decl Float: Pa_ori[3], Float: Pa_ori1[3];
		GetEntPropVector(Bullet_rot_1, Prop_Data, "m_vecOrigin", Pa_ori);

//		SetParent(Bullet_rot_1, Bullet_move);
//		DispatchKeyValue(Bullet_move, "OnFullyOpen", "!self,Close,,0,-1");
//		DispatchKeyValue(Bullet_move, "OnFullyClosed", "!self,open,,0,-1");
		DispatchKeyValue(Bullet_move, "OnFullyOpen", "Rot,Kill,,0,-1");
//		DispatchKeyValue(Bullet_move, "OnFullyOpen", "!self,Kill,,0,-1");
		AcceptEntityInput(Bullet_move, "Open");
	}
	for(new i=0;i<4;i++)
	{
		Bullet_move_sub[i] = CreateEntityByName("func_movelinear");
		if(Bullet_move_sub[i]!=-1)
		{
			direction[0] = 0.0;
			DispatchKeyValue(Bullet_move_sub[i], "spawnflags", "8");
			DispatchKeyValueVector(Bullet_move_sub[i], "origin", origin);
			DispatchKeyValue(Bullet_move_sub[i], "rendermode", "10");

			DispatchKeyValue(Bullet_move_sub[i], "startposition", "0");
			DispatchKeyValue(Bullet_move_sub[i], "speed", "150");
			DispatchKeyValue(Bullet_move_sub[i], "movedistance", "75");
			DispatchKeyValue(Bullet_move_sub[i], "blockdamage", "0");
			switch(i)
			{
				case 0:
				{
					origin[0] = 75.0;
					origin[1] = 0.0;
					direction[1] = 90.0;
//					Format(Moveline_sub0, sizeof(Moveline_sub0), "Moveline_sub_%i", Bullet_move_sub[i]);
					DispatchKeyValue(Bullet_move_sub[i], "targetname", "Moveline_sub0");
				}
				case 1:
				{
					origin[0] = 0.0;
					origin[1] = 75.0;
					direction[1] = 0.0;
//					Format(Moveline_sub1, sizeof(Moveline_sub1), "Moveline_sub_%i", Bullet_move_sub[i]);
					DispatchKeyValue(Bullet_move_sub[i], "targetname", "Moveline_sub1");
				}
				case 2:
				{
					origin[0] = -75.0;
					origin[1] = 0.0;
					direction[1] = -90.0;
//					Format(Moveline_sub2, sizeof(Moveline_sub2), "Moveline_sub_%i", Bullet_move_sub[i]);
					DispatchKeyValue(Bullet_move_sub[i], "targetname", "Moveline_sub2");
				}
				case 3:
				{
					origin[0] = 0.0;
					origin[1] = -75.0;
					direction[1] = -180.0;
//					Format(Moveline_sub3, sizeof(Moveline_sub3), "Moveline_sub_%i", Bullet_move_sub[i]);
					DispatchKeyValue(Bullet_move_sub[i], "targetname", "Moveline_sub3");
				}
			}
			DispatchKeyValue(Bullet_move_sub[i], "OnFullyOpen", "!self,Close,,0,-1");
			DispatchKeyValue(Bullet_move_sub[i], "OnFullyClosed", "!self,open,,0,-1");
			DispatchKeyValueVector(Bullet_move_sub[i], "movedir", direction);
			DispatchSpawn(Bullet_move_sub[i]);
			SetEntityModel(Bullet_move_sub[i], MODEL_EMPTY);
			SetEntPropVector(Bullet_move_sub[i], Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -50.0});
			SetEntPropVector(Bullet_move_sub[i], Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 50.0});
			SetEntProp(Bullet_move_sub[i], Prop_Send, "m_nSolidType", 2);
			SetParent(Bullet_move, Bullet_move_sub[i]);
			AcceptEntityInput(Bullet_move_sub[i], "Open");
		}
	}
	Bullet_main = CreateEntityByName("env_sprite");
	origin[0] = 0.0;
	origin[1] = 0.0;
	if(Bullet_main!=-1)
	{
//		Format(Spr_main, sizeof(Spr_main), "Bullet_%i", Bullet_main);
		DispatchKeyValue(Bullet_main, "targetname", "Spr_main");
		DispatchKeyValue(Bullet_main, "model", "glow01.spr");
		DispatchKeyValueVector(Bullet_main, "origin", origin);
		DispatchKeyValue(Bullet_main, "disablereceiveshadows", "1");
		DispatchKeyValue(Bullet_main, "framerate", "10.0");
		DispatchKeyValueFloat(Bullet_main, "HDRColorScale", 1.0);
		DispatchKeyValue(Bullet_main, "renderamt", "255");
		DispatchKeyValue(Bullet_main, "rendercolor", "255 0 255 255");
		DispatchKeyValue(Bullet_main, "spawnflags", "1");
		DispatchKeyValue(Bullet_main, "rendermode", "5");
		DispatchKeyValue(Bullet_main, "scale", "0.2");
		DispatchSpawn(Bullet_main);
		SetParent(Bullet_move, Bullet_main);
	}
	Bullet_sprt = CreateEntityByName("env_spritetrail");
	if(Bullet_sprt!=-1)
	{
//		Format(Spr_main_trail, sizeof(Spr_main_trail), "Bullet_sprt_%i", Bullet_sprt);
		DispatchKeyValue(Bullet_sprt, "targetname", "Spr_main_trail");
		DispatchKeyValueVector(Bullet_sprt, "origin", origin);
		DispatchKeyValue(Bullet_sprt, "spritename", "materials/sprites/laserbeam.vmt");
		DispatchKeyValue(Bullet_sprt, "rendercolor", "255 0 255 255");
		SetEntPropFloat(Bullet_sprt, Prop_Send, "m_flTextureRes", 0.10);

		DispatchKeyValue(Bullet_sprt, "rendermode", "5");
		DispatchKeyValue(Bullet_sprt, "renderamt", "255");

		DispatchKeyValue(Bullet_sprt, "lifetime", "0.75");
		DispatchKeyValue(Bullet_sprt, "startwidth", "10.0");
		DispatchKeyValue(Bullet_sprt, "endwidth", "1.0");

		DispatchSpawn(Bullet_sprt);
		SetParent(Bullet_move, Bullet_sprt);
	}
	for(new i=0;i<4;i++)
	{
		Bullet_sprt_sub[i] = CreateEntityByName("env_spritetrail");
		if(Bullet_sprt_sub[i]!=-1)
		{
//			DispatchKeyValue(Bullet_sprt_sub[i], "targetname", "Spr_sub");
			switch(i)
			{
				case 0:
				{
					origin[0] = 75.0;
					origin[1] = 0.0;

				}
				case 1:
				{
					origin[0] = 0.0;
					origin[1] = 75.0;
				}
				case 2:
				{
					origin[0] = -75.0;
					origin[1] = 0.0;
				}
				case 3:
				{
					origin[0] = 0.0;
					origin[1] = -75.0;
				}
			}
			DispatchKeyValueVector(Bullet_sprt_sub[i], "origin", origin);
			DispatchKeyValue(Bullet_sprt_sub[i], "spritename", "materials/sprites/laserbeam.vmt");
			DispatchKeyValue(Bullet_sprt_sub[i], "rendercolor", "255 0 255 255");
			SetEntPropFloat(Bullet_sprt_sub[i], Prop_Send, "m_flTextureRes", 0.10);

			DispatchKeyValue(Bullet_sprt_sub[i], "rendermode", "5");
			DispatchKeyValue(Bullet_sprt_sub[i], "renderamt", "255");

			DispatchKeyValue(Bullet_sprt_sub[i], "lifetime", "0.5");
			DispatchKeyValue(Bullet_sprt_sub[i], "startwidth", "3.0");
			DispatchKeyValue(Bullet_sprt_sub[i], "endwidth", "1.0");
			DispatchSpawn(Bullet_sprt_sub[i]);
			SetParent(Bullet_move_sub[i], Bullet_sprt_sub[i]);
		}
	}
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, direction);
	TeleportEntity(Bullet_rot_1, origin, direction, NULL_VECTOR);
}
*/

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

stock UpdateClientPredictValue(value)
{
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			SendConVarValue(client, FindConVar("sv_client_predict"), value ? "-1" : "0");
		}
	}
}