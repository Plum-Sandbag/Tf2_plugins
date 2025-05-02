#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
#include <ff2_ams>
#include <ff2_dynamic_defaults>
#include <tf2attributes>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define PAULINE_LIFE			"freak_fortress_2/pauline/bgm_breakfree.mp3"		// life lost, will be stopped when round ends
new g_pauline_life;
new pauline_boss;

#define PAULINE "breakfree"
#define INACTIVE 100000000.0

public Plugin:myinfo = {
	name	= "Change Theme on Lifelose",
	author	= "M7",
	version = "1.0",
};

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", event_round_start, EventHookMode_PostNoCopy);
	
	HookEvent("teamplay_round_active", event_round_active, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", event_round_active, EventHookMode_PostNoCopy);
	
	HookEvent("teamplay_round_win", event_round_end, EventHookMode_PostNoCopy);
	
	PrecacheSound(PAULINE_LIFE);
}

public event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState()!=1)
		return;
	
	g_pauline_life = 0;
	pauline_boss = 0;
}

public event_round_active(Handle:event, const String:name[], bool:dontBroadcast)
{
	GetBossVars();
}

GetBossVars()
{
	if (FF2_HasAbility(0, this_plugin_name, PAULINE))
	{
		new userid = FF2_GetBossUserId(0);
		new client = GetClientOfUserId(userid);
		if (client && IsClientInGame(client) && IsPlayerAlive(client))
		{
			pauline_boss = client;
			return;
		}
	}
	
	pauline_boss = 0;
}

public event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if (IsValidClient(client))
		{
			g_pauline_life = 0;
			pauline_boss = 0;
			StopSound(client, SNDCHAN_AUTO, PAULINE_LIFE);
		}
	}
}

public Action:FF2_OnAbility2(boss, const String:plugin_name[], const String:ability_name[], status)
{
	return Plugin_Continue;
}

public Action:FF2_OnLoseLife(index)
{		
	if (!g_pauline_life && pauline_boss && GetClientOfUserId(FF2_GetBossUserId(index)) == pauline_boss && IsPlayerAlive(pauline_boss))
	{		
		FF2_StopMusic(0);
		
		EmitSoundToAll(PAULINE_LIFE);
		
		g_pauline_life++;
	}
	return Plugin_Continue;
}

public Action:FF2_OnMusic(String:path[], &Float:time)
{
	if (g_pauline_life)
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

stock bool:IsValidClient(client, bool:isPlayerAlive=false)
{
	if (client <= 0 || client > MaxClients) return false;
	if(isPlayerAlive) return IsClientInGame(client) && IsPlayerAlive(client);
	return IsClientInGame(client);
}