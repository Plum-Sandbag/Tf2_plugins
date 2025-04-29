/*
"abilityX"
{
	"name"			"stun_them"
	"arg0"			"0"		// Ignored
	"arg1"			"9.0"	//	Stun duration
	"arg2"			"161"	//	index of the weapon you want
	"plugin_name"	"let_them_sleep"
}
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <tf2>
#include <tf2_stocks>

#define ABILITY_NAME "stun_them"

new Float:STUN_TIME = 9.0;

public OnPluginStart2()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			SDKHook(i, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
		}
	}
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
}


public Hook_OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype, weapon, Float:damageForce[3], Float:damagePosition[3])
{

	new bossindex=FF2_GetBossIndex(attacker);
	
	if(bossindex==-1)
	{
		return;
	}
	
	if(TF2_IsPlayerInCondition(victim, TFCond_Ubercharged))
	{
		return;
	}
	
	else
	{
		if(FF2_HasAbility(bossindex, this_plugin_name, ABILITY_NAME))
		{
			STUN_TIME = FF2_GetAbilityArgumentFloat(bossindex, this_plugin_name, ABILITY_NAME, 1, 9.0);
			new index = FF2_GetAbilityArgument(bossindex, this_plugin_name, ABILITY_NAME, 2);
			if(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==index)  //big kill
			{
				TF2_StunPlayer(victim, STUN_TIME, 0.0, TF_STUNFLAGS_NORMALBONK|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
			}
		}
	}
}

public void FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
	//Nope
}

stock bool IsValidClient(int client)
{
	if(client<=0 || client>MaxClients) return false;
	return IsClientInGame(client);
}
