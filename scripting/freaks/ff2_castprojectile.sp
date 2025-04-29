/*
	Example Ability
	
 	"abilityX"
    {
        "name"          "rage_projectile"
        "arg1"			"1"			//Projectile Type, Int Value (-1 = Random Spell / -2 Random Projectile)
        "arg2"          "5"			//How many Projectile will casted?, Int Value
        "arg3"			"2.1"		//Duration between two casted projectile, Float Value
        "arg4"			"1100.0"	//Projectile speed, Float Value
        "arg5"			"5"			//Crit Chance, Int value (def %5/0.1)
        "arg6"			"10.0"		//Min Damage of Projectile (def 80)
        "arg7"			"50"		//Max Damage of Projectile (def 100)
        "plugin_name"   "ff2_castprojectile"
    }
    
    -All Arguments Required If Youre Using Projectile
    -Only First Four Argument Reuqired If Youre Using Spells
    -Know Issues:
    	1# Projectiles Still Shooting When Boss Dies
    	2# Boss's Melee Weapon Multiply Rocket's Damage
*/


#pragma semicolon 1

#include <tf2_stocks>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define ROCKET_SENTRY_SOUND "weapons/sentry_rocket.wav"
#define ROCKET_STANDART_SOUND "weapons/doom_rocket_launcher.wav"


public Plugin myinfo = 
{
	name = "Freak Fortress 2: Cast a Projectile",
	author = "J0BL3SS",
	description = "J0BL3SS's Cast a Projectile subplugin",
	version = "1.0.0",
};

public void OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	PrecacheSound(ROCKET_SENTRY_SOUND);
	PrecacheSound(ROCKET_STANDART_SOUND);
}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
	if (!strcmp(ability_name, "rage_projectile"))
		Rage_Projectile(boss, ability_name);
}


public Action Rage_Projectile(int boss, const char[] ability_name)
{
	float flDuration = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 3); //arg3
	int BossTeam = FF2_GetBossTeam();
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if (IsClientInGame(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient) == BossTeam)
			CreateTimer(flDuration, CastProjectile, iClient, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action CastProjectile(Handle timer, iClient)
{	
	int boss;
	int pNum = FF2_GetAbilityArgument(iClient, this_plugin_name, "rage_projectile", 1); //arg1
	int sCount = FF2_GetAbilityArgument(iClient, this_plugin_name, "rage_projectile", 2); //arg2

	static int sCasted = 0;
	
	if (sCasted >= sCount)
	{
		sCasted = 0;
		return Plugin_Stop;
	}
	if(pNum == 0) //Random All
	{
		pNum = GetRandomInt(1,8);
	}
	if(pNum == -1) //Random Spell
	{
		pNum = GetRandomInt(1,6);
	}
	if(pNum == -2) //Random Rocket
	{
		pNum = GetRandomInt(7,8);
	}
	if (IsClientInGame(iClient) && IsPlayerAlive(iClient))
	{
		switch(pNum)
	    {
	    	//Spells
	        case 1: CastSpell(iClient, boss, "tf_projectile_spellfireball");
	        case 2: CastSpell(iClient, boss, "tf_projectile_spellbats");
	        case 3: CastSpell(iClient, boss, "tf_projectile_lightningorb");
	        case 4: CastSpell(iClient, boss, "tf_projectile_spellmeteorshower");
	        case 5: CastSpell(iClient, boss, "tf_projectile_spellspawnboss");
	        case 6: CastSpell(iClient, boss, "tf_projectile_spellmeteorshower");
	        //Rockets
	        case 7: ShootRocket_Sentry(iClient, boss, "tf_projectile_sentryrocket"); 
	        case 8: ShootRocket_Standart(iClient, boss, "tf_projectile_rocket");
	        /*
	        case 6: ShootProjectile(iClient, boss, "tf_projectile_arrow");  
	        case 8: ShootProjectile(iClient, boss, "tf_projectile_healing_bolt");
	        case 9: ShootProjectile(iClient, boss, "tf_projectile_flare");
	        case 10: ShootProjectile(iClient, boss, "tf_projectile_energy_ball");
	        case 11: ShootProjectile(iClient, boss, "tf_projectile_cleaver");
	        case 12: ShootProjectile(iClient, boss, "tf_projectile_ball_ornament");
	        case 13: ShootProjectile(iClient, boss, "tf_projectile_balloffire");
	        case 14: ShootProjectile(iClient, boss, "tf_projectile_pipe");
	        case 15: ShootProjectile(iClient, boss, "tf_projectile_energy_ring");
	        */
	    }
	}
	else
	{
		return Plugin_Stop;
	}
	sCasted++;
	return Plugin_Continue;
}

int CastSpell(int Sclient, boss, char strEntname[48] = "")
{
	float flPspeed = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_projectile", 4, 1100.0); //arg4

	float flAng[3]; // original
	float flPos[3]; // original
	GetClientEyeAngles(Sclient, flAng);
	GetClientEyePosition(Sclient, flPos);
	
	int iTeam = GetClientTeam(Sclient);
	int iSpell = CreateEntityByName(strEntname);
	
	float flVel1[3];
	float flVel2[3];
	
	GetAngleVectors(flAng, flVel2, NULL_VECTOR, NULL_VECTOR);
	
	flVel1[0] = flVel2[0]*flPspeed; //Speed of projectile
	flVel1[1] = flVel2[1]*flPspeed;
	flVel1[2] = flVel2[2]*flPspeed;

	SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", Sclient);
	SetEntProp(iSpell, Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
	SetEntProp(iSpell, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iSpell, Prop_Send, "m_nSkin", (iTeam-2));
	
	TeleportEntity(iSpell, flPos, flAng, NULL_VECTOR);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0); 
	
	DispatchSpawn(iSpell);
	TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, flVel1);
	
	return iSpell;
}

int ShootRocket_Standart(int Sclient, boss, char strEntname[48] = "")
{
	float flPspeed = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_projectile", 4, 1100.0); //arg4
	int zCrits = FF2_GetAbilityArgument(boss, this_plugin_name, "rage_projectile", 5, 5); //arg5
	float sDmgMin = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_projectile", 6, 80.0); //arg6
	float sDmgMax = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_projectile", 7, 300.0); //arg7
	
	
	float flAng[3]; // original
	float flPos[3]; // original
	GetClientEyeAngles(Sclient, flAng);
	GetClientEyePosition(Sclient, flPos);
	
	int iTeam = GetClientTeam(Sclient);
	int iSpell = CreateEntityByName(strEntname);
	
	float flVel1[3];
	float flVel2[3];
	
	GetAngleVectors(flAng, flVel2, NULL_VECTOR, NULL_VECTOR);
	
	flVel1[0] = flVel2[0]*flPspeed; //Speed of projectile
	flVel1[1] = flVel2[1]*flPspeed;
	flVel1[2] = flVel2[2]*flPspeed;
	
	SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", Sclient);
	//SetEntPropFloat(iSpell, Prop_Send, "m_flDamage", GetRandomFloat(sDmgMin, sDmgMax));
	SetEntDataFloat(iSpell, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, GetRandomFloat(sDmgMin, sDmgMax), true);
	SetEntProp(iSpell, Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 3 ? 1 : 0), 1);
	SetEntProp(iSpell, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iSpell, Prop_Send, "m_nSkin", (iTeam-2));
	
	TeleportEntity(iSpell, flPos, flAng, NULL_VECTOR);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0); 
	
	DispatchSpawn(iSpell);
	TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, flVel1);
	
	EmitAmbientSound(ROCKET_STANDART_SOUND, flVel1, SOUND_FROM_WORLD);
	return iSpell;
}

int ShootRocket_Sentry(int Sclient, boss, char strEntname[48] = "")
{
	
	float flPspeed = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_projectile", 4, 1100.0); //arg4
	int zCrits = FF2_GetAbilityArgument(boss, this_plugin_name, "rage_projectile", 5, 5); //arg5
	float sDmgMin = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_projectile", 6, 80.0); //arg6
	float sDmgMax = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_projectile", 7, 300.0); //arg7
	
	float flAng[3]; // original
	float flPos[3]; // original
	GetClientEyeAngles(Sclient, flAng);
	GetClientEyePosition(Sclient, flPos);
	
	int iTeam = GetClientTeam(Sclient);
	int iSpell = CreateEntityByName(strEntname);
	
	float flVel1[3];
	float flVel2[3];
	
	GetAngleVectors(flAng, flVel2, NULL_VECTOR, NULL_VECTOR);
	
	flVel1[0] = flVel2[0]*flPspeed; //Speed of projectile
	flVel1[1] = flVel2[1]*flPspeed;
	flVel1[2] = flVel2[2]*flPspeed;
	
	
	SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", Sclient);
	//SetEntPropFloat(iSpell, Prop_Send, "m_flDamage", GetRandomFloat(sDmgMin, sDmgMax));
	SetEntDataFloat(iSpell, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, GetRandomFloat(sDmgMin, sDmgMax), true);
	SetEntProp(iSpell, Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= zCrits)? 1 : 0, 1);
	SetEntProp(iSpell, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iSpell, Prop_Send, "m_nSkin", (iTeam-2));
	
	TeleportEntity(iSpell, flPos, flAng, NULL_VECTOR);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0); 
	
	DispatchSpawn(iSpell);
	TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, flVel1);
	
	EmitAmbientSound(ROCKET_SENTRY_SOUND, flVel1, SOUND_FROM_WORLD);
	return iSpell;
}