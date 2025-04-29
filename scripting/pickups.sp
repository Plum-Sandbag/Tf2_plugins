/**
    friagram@gmail.com
	
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
**/

// args for sounds for each mode

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <tf2_stocks>
#include <sdkhooks>

new g_BossTeam=_:TFTeam_Blue;


////////////////////////////////////////////////////////////////////////////////////////////////////////////

public Plugin:myinfo = 
{
	name = "Freak Fortress 2: Boss Item Pickup",
	author = "Friagram",
	description = "Prevents bosses from interacting with items.",
	version = "1.0",
	url = "http://steamcommunity.com/groups/poniponiponi"
};

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", event_round_start, EventHookMode_PostNoCopy);
}

public event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(5.0, Timer_GetBossInfo, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_GetBossInfo(Handle:hTimer)
{
	if(FF2_IsFF2Enabled())
	{
		g_BossTeam = FF2_GetBossTeam();
	}
	else
	{
		g_BossTeam = 0;
	}

	return Plugin_Continue;
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrContains(classname, "item_healthkit") != -1 || StrContains(classname, "item_ammopack") != -1 || StrEqual(classname, "tf_ammo_pack"))
	{
		SDKHook(entity, SDKHook_Spawn, OnItemSpawned);
	}
}

public OnItemSpawned(entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnItemTouch);
	SDKHook(entity, SDKHook_Touch, OnItemTouch);
}

public Action:OnItemTouch(item, entity)                                     // Control Flag Events
{
	if (entity > 0 && entity <= MaxClients && GetClientTeam(entity) == g_BossTeam)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	return Plugin_Continue;
}