/*
demopan_charge:	arg0 - unused.
					arg1 - 1=Force to Charge (def.1)
					arg2 - 1=Charge ignore angle (def.1)
*/
#pragma semicolon 1

#include <sourcemod>

#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>


public Plugin:myinfo=
{
	name="Freak Fortress 2: demopan_charge",
	author="NONE",
	description="FF2: Demopan",
	version="1.0"
};

#define this_plugin_name 		"demopan_charge"

//#define BUTTONS_MOVEMENT		(IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT)

float g_flChargeRemain[MAXPLAYERS+1];
bool g_bChargeCorrection[MAXPLAYERS+1];

public OnPluginStart2()
{
	new version[3];
	FF2_GetFF2Version(version);
	if(version[0]==1 && (version[1]<10 || (version[1]==10 && version[2]<3)))
	{
		SetFailState("This subplugin depends on at least FF2 v1.10.3");
	}
	HookEvent("player_spawn", OnPlayerSpawnOrDeath);
	HookEvent("player_death", OnPlayerSpawnOrDeath);
}

public Action OnPlayerSpawnOrDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	g_flChargeRemain[client] = 0.0;
	g_bChargeCorrection[client] = false;
	// g_iCurrentChargeButton[client] = 0;

	return Plugin_Continue;
}

public Action:FF2_OnAbility2(boss, const String:plugin_name[], const String:ability_name[], status)
{

	if(!strcmp(ability_name, "demopan_charge"))
	{
		if(status == 0) 
			return Plugin_Continue;
		new client = GetClientOfUserId(FF2_GetBossUserId(boss));

		if(status == 1)
		{
			SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", 100.0);
			TF2_AddCondition(client, TFCond_Charging, 0.12);
		}
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float deVelocity[3], float deAngles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(FF2_GetRoundState() < 1)	
		return Plugin_Continue;

	int boss = FF2_GetBossIndex(client);
	if(!IsPlayerAlive(client)) 
		return Plugin_Continue;

	if(!FF2_HasAbility(boss, this_plugin_name, "demopan_charge"))
		return Plugin_Continue;

	// force charge
	if(boss != -1 && (FF2_GetAbilityArgument(boss, this_plugin_name, "demopan_charge", 1, 1) == 1))
	{
		if(!TF2_IsPlayerInCondition(client, TFCond_Charging)
			&& !TF2_IsPlayerInCondition(client, TFCond_Dazed)
			&& ((buttons & IN_ATTACK2) > 0)
			&& GetEntPropFloat(client, Prop_Send, "m_flChargeMeter") > 10.0)
		{
			SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", 100.0);
			TF2_AddCondition(client, TFCond_Charging, -1.0, client);

			g_bChargeCorrection[client] = true;
			RequestFrame(DemoChargeCorrection, client);
		}

		if(!g_bChargeCorrection[client])
			g_flChargeRemain[client] = GetEntPropFloat(client, Prop_Send, "m_flChargeMeter");
	}

	// Air charge
	// 데모판의 돌진을 감지하고 Y축 속도값을 시야와 일치하도록 변경
	if(boss != -1 && (FF2_GetAbilityArgument(boss, this_plugin_name, "demopan_charge", 2, 1) == 1))
	{
		float angles[3], yAngle;
		GetClientEyeAngles(client, angles);

		// y축 Index: angles = 0, velocity = 2
		// angles 시야 기준, 맨 아래 90 ~ 맨 위 -90
		if(TF2_IsPlayerInCondition(client, TFCond_Charging)
			&& (buttons & (IN_JUMP|IN_DUCK)) == 0
			&& (yAngle = angles[0] * -1.0) > 0.0)
		{
			float velocity[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

			velocity[2] = yAngle * 10.0;
			if(velocity[2] > 270.0) // maybe???
			{
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);

/*				if(boss == -1 || (FF2_GetAbilityArgument(boss, this_plugin_name, "demopan_charge", 2, 1) != 1))
				{
					float charge = GetEntPropFloat(client, Prop_Send, "m_flChargeMeter");
					charge -= (12.5 / GetTickInterval()) * 0.002;

					SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", charge);				
				}*/
			}
		}
	}

	return Plugin_Continue;
}

public void TF2_OnConditionRemoved(int client, TFCond cond)
{
	int boss = FF2_GetBossIndex(client);
	if(boss != -1 && cond == TFCond_Charging
		&& (FF2_GetAbilityArgument(boss, this_plugin_name, "demopan_charge", 1, 1) == 1))
	{
		SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", g_flChargeRemain[client]);
	}
}

public void DemoChargeCorrection(int client)
{
	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	if(GetVectorLength(velocity) > 300.0)
	{
		if(g_bChargeCorrection[client])
		{
			g_bChargeCorrection[client] = false;
			SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", g_flChargeRemain[client]);

			return;
		}
	}

	RequestFrame(DemoChargeCorrection, client);
	TF2_AddCondition(client, TFCond_Charging, -1.0, client);
}

stock bool IsBoss(int client)
{
	return FF2_GetBossIndex(client) != -1;
}