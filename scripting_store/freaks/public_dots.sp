#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <drain_over_time>
#include <drain_over_time_subplugin>

/**
 * Some default drain over time rages. It's a good example if you want to make your own.
 * Requires the drain over time platform:
 * - drain_over_time.sp
 * - drain_over_time.inc
 * - drain_over_time_subplugin.inc
 *
 * Known Issues:
 * WEAPON SWAP
 * - Uses different code for swapping weapons. This fixes the problem with melee swing sometimes not appearing, but causes some weapons which should be
 *   hidden to not be. If you have this problem with a hidden weapon, just use something else.
 * - Has a problem with old models like Vagineer where a weapon appears in the model's center. But this isn't an issue with pony models or stock class models.
 *
 * MODEL SWAP
 * - Could cause problems if your models' skeletons don't line up. Will be a train wreck if your models are rigged to different classes.
 *
 * TELEPORT
 * - It's just a straight port of the otokiru/War3 version, which means all the exploits and stuck bugs will still exist.
 *   I only ported it for demonstration purposes, since conceptually a point teleport makes an excellent one-use reload ability.
 * 
 * Credits:
 * - Most of the work: sarysa
 * - Special thanks to Skeith and Kralthe for testing the manic mode (weapon switch) stuff.
 */
 
new BossTeam = _:TFTeam_Blue;

// change this to minimize console output
new PRINT_DEBUG_INFO = true;

// for getting things off the map that have an undesirable destruction delay (i.e. certain particle effects)
new Float:OFF_THE_MAP[3] = { 16383.0, 16383.0, -16383.0 };

#define MAX_PLAYERS_ARRAY 33
#define MAX_PLAYERS (MAX_PLAYERS_ARRAY < (MaxClients + 1) ? MAX_PLAYERS_ARRAY : (MaxClients + 1))

// this is very generous as really only VSH servers with the RTD mod would have this many
// (RTD allows temporary sentries and permanent dispensers to be spawned by non-engineers)
#define MAX_BUILDINGS 32

// text string limits. I've set these as low as reasonably possible.
// Enumerated strings are VERY wasteful. every character is 4 bytes!
// but the only way to get something resembling a struct is using the enumeration trick below.
#define MAX_SOUND_FILE_LENGTH 80
#define MAX_MODEL_SWAP_LENGTH 80
#define MAX_WEAPON_NAME_LENGTH 40
#define MAX_WEAPON_ARG_LENGTH 256
#define MAX_EFFECT_NAME_LENGTH 48
#define MAX_ENTITY_CLASSNAME_LENGTH 48
#define MAX_COLOR_ID_LENGTH 7

new RoundInProgress = false;

// Weapon Swap
#define WS_STRING "dot_weapon_swap"
#define WS_CW_INTERVAL 0.5 // time between hack-fix for civilian hale
new bool:WS_ActiveThisRound = false; // internal
new Float:WS_CivilianWorkaroundAt;
new bool:WS_CanUse[MAX_PLAYERS_ARRAY];						// internal
new bool:WS_IsUsing[MAX_PLAYERS_ARRAY];						// internal
new String:WS_NewWeaponName[MAX_PLAYERS_ARRAY][MAX_WEAPON_NAME_LENGTH];		// arg1
new WS_NewWeaponIdx[MAX_PLAYERS_ARRAY];						// arg2
new String:WS_NewWeaponArgs[MAX_PLAYERS_ARRAY][MAX_WEAPON_ARG_LENGTH];		// arg3
new WS_NewWeaponVisibility[MAX_PLAYERS_ARRAY];					// arg4
new String:WS_OldWeaponName[MAX_PLAYERS_ARRAY][MAX_WEAPON_NAME_LENGTH];		// arg5
new WS_OldWeaponIdx[MAX_PLAYERS_ARRAY];						// arg6
new String:WS_OldWeaponArgs[MAX_PLAYERS_ARRAY][MAX_WEAPON_ARG_LENGTH];		// arg7
new WS_OldWeaponVisibility[MAX_PLAYERS_ARRAY];					// arg8

// Model Swap
#define MS_STRING "dot_model_swap"
new bool:MS_CanUse[MAX_PLAYERS_ARRAY];					// internal
new String:MS_OldModelSwap[MAX_PLAYERS_ARRAY][MAX_MODEL_SWAP_LENGTH]; 	// internal
new String:MS_NewModelSwap[MAX_PLAYERS_ARRAY][MAX_MODEL_SWAP_LENGTH];	// arg1

// Sentry Knockback Immunity
#define SKI_STRING "dot_sentry_knockback_immunity"
new bool:SKI_CanUse[MAX_PLAYERS_ARRAY];			// internal
new bool:SKI_SentryKnockbackImmune[MAX_PLAYERS_ARRAY];	// internal

// Looping Sound
#define LS_STRING "dot_looping_sound"
new bool:LS_CanUse[MAX_PLAYERS_ARRAY];				// internal
new String:LS_Sound[MAX_PLAYERS_ARRAY][MAX_SOUND_FILE_LENGTH];	// arg1
new LS_TicksBetweenUses[MAX_PLAYERS_ARRAY];			// arg2

// war3 teleport ported as a DOT rage
#define DT_STRING "dot_teleport"
new bool:DT_CanUse[MAX_PLAYERS_ARRAY]; // internal
new Float:DT_MaxDistance[MAX_PLAYERS_ARRAY]; // arg1
new String:DT_FailSound[MAX_PLAYERS_ARRAY][MAX_SOUND_FILE_LENGTH]; // arg2
new String:DT_OldLocationParticleEffect[MAX_PLAYERS_ARRAY][MAX_EFFECT_NAME_LENGTH]; // arg3
new String:DT_NewLocationParticleEffect[MAX_PLAYERS_ARRAY][MAX_EFFECT_NAME_LENGTH]; // arg4
new String:DT_UseSound[MAX_PLAYERS_ARRAY][MAX_SOUND_FILE_LENGTH]; // arg5

public Plugin:myinfo = {
	name = "Freak Fortress 2: Default DOTs",
	author = "sarysa",
	version = "1.0.0",
}

/**
 * METHODS REQUIRED BY ff2 subplugin
 */
public OnPluginStart2()
{
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

// this method required, but is not used by DOTs at all. Only use if you have DOTs and non-DOTs in the same file.
public Action:FF2_OnAbility2(index, const String:plugin_name[], const String:ability_name[], status) { return Plugin_Continue; }

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (PRINT_DEBUG_INFO)
		PrintToServer("[public_dots] Default DOTs: Event_RoundStart()");
		
	// NOTE: For DOTs, only basic inits go here. The real init happens on a time delay shortly after.
	// It is recommended you don't load anything related to DOTs until then.
	RoundInProgress = true;
	WS_ActiveThisRound = false;
	WS_CivilianWorkaroundAt = GetEngineTime() + WS_CW_INTERVAL;

	if (PRINT_DEBUG_INFO)
		PrintToServer("[public_dots] Event_RoundStart");
		
	// initialize each DOT's array
	for (new i = 0; i < MAX_PLAYERS; i++)
	{
		// Weapon Swap
		WS_CanUse[i] = false;
		WS_IsUsing[i] = false;
		
		// Model Swap
		MS_CanUse[i] = false;
		
		// Sentry Knockback Immunity
		SKI_CanUse[i] = false;
		SKI_SentryKnockbackImmune[i] = false;
		
		// Looping Sound
		LS_CanUse[i] = false;
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (PRINT_DEBUG_INFO)
		PrintToServer("[public_dots] Event_RoundEnd()");

	// round has ended, this'll kill the looping timer
	RoundInProgress = false;
	WS_ActiveThisRound = false;
		
	// clean up stuff
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (SKI_CanUse[clientIdx])
		{
			if (IsClientInGame(clientIdx))
				SDKUnhook(clientIdx, SDKHook_OnTakeDamage, SKIOnTakeDamage);
			SKI_CanUse[clientIdx] = false;
		}
	}
}

/**
 * METHODS REQUIRED BY dot subplugin
 */
DOTPostRoundStartInit()
{
	if (!RoundInProgress)
	{
		PrintToServer("[public_dots] DOTPostRoundStartInit() called when the round is over?! Shouldn't be possible!");
		return;
	}
	
	if (PRINT_DEBUG_INFO)
		PrintToServer("[public_dots] DOTPostRoundStartInit() called");
		
	for (new bossClientIdx = 1; bossClientIdx < MAX_PLAYERS; bossClientIdx++)
	{
		new bossIdx = FF2_GetBossIndex(bossClientIdx);
		if (bossIdx < 0)
			continue; // this may seem weird, but rages often break on duo bosses if the leader suicides. these DOTs can be an exception. :D

		// Weapon Swap
		WS_CanUse[bossClientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, WS_STRING);
		if (WS_CanUse[bossClientIdx])
		{
			WS_ActiveThisRound = true;
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, WS_STRING, 1, WS_NewWeaponName[bossClientIdx], MAX_WEAPON_NAME_LENGTH);
			WS_NewWeaponIdx[bossClientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, WS_STRING, 2);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, WS_STRING, 3, WS_NewWeaponArgs[bossClientIdx], MAX_WEAPON_ARG_LENGTH);
			WS_NewWeaponVisibility[bossClientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, WS_STRING, 4);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, WS_STRING, 5, WS_OldWeaponName[bossClientIdx], MAX_WEAPON_NAME_LENGTH);
			WS_OldWeaponIdx[bossClientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, WS_STRING, 6);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, WS_STRING, 7, WS_OldWeaponArgs[bossClientIdx], MAX_WEAPON_ARG_LENGTH);
			WS_OldWeaponVisibility[bossClientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, WS_STRING, 8);
			
			// switch out the user's primary weapon now, to avoid bugs like EVERY BONK BOY DERIVATIVE EVER MADE :P
			SwitchWeapon(bossClientIdx, WS_OldWeaponName[bossClientIdx], WS_OldWeaponIdx[bossClientIdx], WS_OldWeaponArgs[bossClientIdx], WS_OldWeaponVisibility[bossClientIdx]);
			
			if (PRINT_DEBUG_INFO)
				PrintToServer("[public_dots] Boss client %d will use Weapon Swap DOT this round.", bossClientIdx);
		}
		
		// Model Swap
		MS_CanUse[bossClientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, MS_STRING);
		if (MS_CanUse[bossClientIdx])
		{
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, MS_STRING, 1, MS_NewModelSwap[bossClientIdx], MAX_MODEL_SWAP_LENGTH);
			
			// precache the swap model now, if applicable
			if (strlen(MS_NewModelSwap[bossClientIdx]) > 3)
				PrecacheModel(MS_NewModelSwap[bossClientIdx]);

			// determine model for normal mode
			GetEntPropString(bossClientIdx, Prop_Data, "m_ModelName", MS_OldModelSwap[bossClientIdx], MAX_MODEL_SWAP_LENGTH);
			
			if (PRINT_DEBUG_INFO)
				PrintToServer("[public_dots] Boss client %d will use Model Swap DOT this round.", bossClientIdx);
		}
		
		// Sentry Knockback Immunity
		SKI_CanUse[bossClientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, SKI_STRING);
		if (SKI_CanUse[bossClientIdx]) // create hook for sentry knockback immunity
		{
			SDKHook(bossClientIdx, SDKHook_OnTakeDamage, SKIOnTakeDamage);
			
			if (PRINT_DEBUG_INFO)
				PrintToServer("[public_dots] Boss client %d will use Sentry Knockback Immunity DOT this round.", bossClientIdx);
		}
		
		// Looping Sound
		LS_CanUse[bossClientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, LS_STRING);
		if (LS_CanUse[bossClientIdx])
		{
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, LS_STRING, 1, LS_Sound[bossClientIdx], MAX_SOUND_FILE_LENGTH);
			LS_TicksBetweenUses[bossClientIdx] = RoundFloat(FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, LS_STRING, 2) * 10.0);
			if (LS_TicksBetweenUses[bossClientIdx] <= 0) // don't allow div 0
				LS_TicksBetweenUses[bossClientIdx] = 1;
		}
		
		// teleport
		DT_CanUse[bossClientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, DT_STRING);
		if (DT_CanUse[bossClientIdx])
		{
			DT_MaxDistance[bossClientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DT_STRING, 1);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, DT_STRING, 2, DT_FailSound[bossClientIdx], MAX_SOUND_FILE_LENGTH);
			if (strlen(DT_FailSound[bossClientIdx]) > 3)
				PrecacheSound(DT_FailSound[bossClientIdx]);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, DT_STRING, 3, DT_OldLocationParticleEffect[bossClientIdx], MAX_EFFECT_NAME_LENGTH);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, DT_STRING, 4, DT_NewLocationParticleEffect[bossClientIdx], MAX_EFFECT_NAME_LENGTH);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, DT_STRING, 5, DT_UseSound[bossClientIdx], MAX_SOUND_FILE_LENGTH);
			if (strlen(DT_FailSound[bossClientIdx]) > 3)
				PrecacheSound(DT_UseSound[bossClientIdx]);
		}
	}
}

OnDOTAbilityActivated(clientIdx)
{
	// Weapon Swap
	if (WS_CanUse[clientIdx])
	{
		WS_IsUsing[clientIdx] = true;
		SwitchWeapon(clientIdx, WS_NewWeaponName[clientIdx], WS_NewWeaponIdx[clientIdx], WS_NewWeaponArgs[clientIdx], WS_NewWeaponVisibility[clientIdx]);
	}
	
	// Model Swap
	if (MS_CanUse[clientIdx])
	{
		if (strlen(MS_NewModelSwap[clientIdx]) > 3)
			SwapModel(clientIdx, MS_NewModelSwap[clientIdx]);
	}
	
	// Sentry Knockback Immunity
	if (SKI_CanUse[clientIdx])
	{
		SKI_SentryKnockbackImmune[clientIdx] = true;
	}
	
	// Teleport
	if (DT_CanUse[clientIdx])
	{
		if (!DOTTeleport(clientIdx))
		{
			if (strlen(DT_FailSound[clientIdx]) > 3)
				EmitSoundToClient(clientIdx, DT_FailSound[clientIdx]);
			CancelDOTAbilityActivation(clientIdx);
			return;
		}
	}
}

OnDOTAbilityDeactivated(clientIdx)
{
	// Weapon Swap
	if (WS_CanUse[clientIdx])
	{
		WS_IsUsing[clientIdx] = false;
		SwitchWeapon(clientIdx, WS_OldWeaponName[clientIdx], WS_OldWeaponIdx[clientIdx], WS_OldWeaponArgs[clientIdx], WS_OldWeaponVisibility[clientIdx]);
	}
	
	// Model Swap
	if (MS_CanUse[clientIdx])
	{
		if (strlen(MS_NewModelSwap[clientIdx]) > 3) // if the manic mode model swap is invalid, then the switch will never have been made
			SwapModel(clientIdx, MS_OldModelSwap[clientIdx]);
	}
	
	// Sentry Knockback Immunity
	if (SKI_CanUse[clientIdx])
	{
		SKI_SentryKnockbackImmune[clientIdx] = false;
	}
}

OnDOTUserDeath(clientIdx, isInGame)
{
	// not used by any of these dots
	// there has to be a better way to suppress the warnings :P
	if (clientIdx || isInGame) { }
}

OnDOTAbilityTick(clientIdx, tickCount)
{
	// Looping Sound
	if (LS_CanUse[clientIdx] && tickCount % LS_TicksBetweenUses[clientIdx] == 0)
	{
		if (strlen(LS_Sound[clientIdx]) > 3)
			EmitSoundToAll(LS_Sound[clientIdx]);
	}
	
	// Teleport
	if (DT_CanUse[clientIdx])
	{
		// since DOT teleport is just a one-time action, deactivate it.
		ForceDOTAbilityDeactivation(clientIdx);
	}
}

/**
 * Ability Specific Methods
 */
// in manic mode, don't take knockback from sentries!
// note, sentry weapon entity is always -1 (recent edit, that "weapon" below is actually an entity index, bah)
new String:weaponBuffer[64]; // since this'd often get allocated like 500 times per hale match otherwise
public Action:SKIOnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (victim > 0 && victim < MAX_PLAYERS && GetClientTeam(victim) == BossTeam)
	{
		//PrintToServer("[public_dots] boss attacked for %f damage by weapon %i, a/i=%d,%d...", damage, weapon, attacker, inflictor);
		
		// for reference, tweaking the damageForce/damagePosition did nothing
		if (SKI_SentryKnockbackImmune[victim])
		{
			// validity check, in case player suicides for example
			if (attacker <= MAX_PLAYERS && attacker > 0)
			{
				// make sure it's an engineer as well
				if (TF2_GetPlayerClass(attacker) == TFClass_Engineer)
				{
					// one last check, check the object entity name
					if (IsValidEntity(inflictor))
					{
						GetEntityClassname(inflictor, weaponBuffer, 64);
						new weaponIdx = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
						if ((!strcmp("obj_sentrygun", weaponBuffer) || !strcmp("tf_projectile_sentryrocket", weaponBuffer)) || weaponIdx == 140) // included wrangler just in case
						{
							damagetype |= DMG_PREVENT_PHYSICS_FORCE;
							return Plugin_Changed;
						}
					}
				}
			}
		}
	}
	else
	{
		if (PRINT_DEBUG_INFO) // never seen this happen but it could be spam-tastic
			PrintToServer("[public_dots] someone we don't care about got attacked for %f damage?!", damage);
	}
	
	return Plugin_Continue;
}

SwitchWeapon(bossClient, String:weaponName[], weaponIdx, String:weaponAttributes[], visible)
{
	TF2_RemoveWeaponSlot(bossClient, TFWeaponSlot_Primary);
	TF2_RemoveWeaponSlot(bossClient, TFWeaponSlot_Secondary);
	TF2_RemoveWeaponSlot(bossClient, TFWeaponSlot_Melee);
	new weapon;
	weapon = SpawnWeapon(bossClient, weaponName, weaponIdx, 101, 5, weaponAttributes, visible);
	SetEntPropEnt(bossClient, Prop_Data, "m_hActiveWeapon", weapon);
}

SwapModel(bossClient, const String:model[])
{
	SetVariantString(model);
	AcceptEntityInput(bossClient, "SetCustomModel");
	SetEntProp(bossClient, Prop_Send, "m_bUseClassAnimations", 1);
}

/**
 * DOT_TELEPORT rages, ported from otokiru/War3Source
 */
public bool:TracePlayersAndBuildings(entity, contentsMask)
{
	if (!IsValidEntity(entity))
		return false;

	// check for mercs
	if (entity > 0 && entity < MAX_PLAYERS)
	{
		if (IsPlayerAlive(entity) && !TF2_IsPlayerInCondition(entity, TFCond_Cloaked))
			if (GetClientTeam(entity) != BossTeam)
				return true;
	}
	else
	{
		new String:classname[MAX_ENTITY_CLASSNAME_LENGTH];
		GetEntityClassname(entity, classname, MAX_ENTITY_CLASSNAME_LENGTH);
		if (!strcmp("obj_sentrygun", classname) || !strcmp("obj_dispenser", classname) || !strcmp("obj_teleporter", classname))
			return true;
	}
	
	return false;
}

new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};//,27,-27,30,-30,33,-33,40,-40}; //for human it needs to be smaller

public bool:CanHitThis(entityhit, mask, any:data)
{
	if(entityhit == data )
	{// Check if the TraceRay hit the itself.
		return false; // Don't allow self to be hit, skip this result
	}
	if (IsValidBoss(entityhit)){
		return false; //skip result, prend this space is not taken cuz they on same team
	}
	return true; // It didn't hit itself
}

public bool:GetEmptyLocationHull(client, Float:originalpos[3], Float:emptypos[3])
{
	new Float:mins[3];
	new Float:maxs[3];
	GetClientMins(client,mins);
	GetClientMaxs(client,maxs);
	new absincarraysize=sizeof(absincarray);
	new limit=5000;
	for(new x=0;x<absincarraysize;x++){
		if(limit>0){
			for(new y=0;y<=x;y++){
				if(limit>0){
					for(new z=0;z<=y;z++){
						new Float:pos[3]={0.0,0.0,0.0};
						AddVectors(pos,originalpos,pos);
						pos[0]+=float(absincarray[x]);
						pos[1]+=float(absincarray[y]);
						pos[2]+=float(absincarray[z]);
						TR_TraceHullFilter(pos,pos,mins,maxs,MASK_SOLID,CanHitThis,client);
						//new ent;
						if(!TR_DidHit(_))
						{
							AddVectors(emptypos,pos,emptypos); ///set this gloval variable
							limit=-1;
							break;
						}
						if(limit--<0){
							break;
						}
					}
					if(limit--<0){
						break;
					}
				}
			}
			if(limit--<0){
				break;
			}
		}
	}
} 

public bool:DOTTeleport(bossClientIdx)
{
	// taken directly from War3 otokiru with some tweaks
	new Float:eyeAngles[3];
	new Float:bossOrigin[3];
	GetClientEyeAngles(bossClientIdx, eyeAngles);
	new Float:endPos[3];
	new Float:startPos[3];
	GetClientEyePosition(bossClientIdx, startPos);
	new Float:dir[3];
	GetAngleVectors(eyeAngles, dir, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(dir, DT_MaxDistance[bossClientIdx]);
	AddVectors(startPos, dir, endPos);
	GetClientAbsOrigin(bossClientIdx, bossOrigin);
	TR_TraceRayFilter(startPos, endPos, MASK_ALL, RayType_EndPoint, TracePlayersAndBuildings);
	TR_GetEndPosition(endPos);
	new Float:distanceteleport = GetVectorDistance(startPos, endPos);
	GetAngleVectors(eyeAngles, dir, NULL_VECTOR, NULL_VECTOR);///get dir again
	ScaleVector(dir, distanceteleport - 33.0);

	AddVectors(startPos, dir, endPos);
	new Float:emptyPos[3];
	emptyPos[0] = 0.0;
	emptyPos[1] = 0.0;
	emptyPos[2] = 0.0;

	endPos[2] -= 30.0;
	GetEmptyLocationHull(bossClientIdx, endPos, emptyPos);

	if (GetVectorLength(emptyPos) < 1.0)
	{
		if (PRINT_DEBUG_INFO)
			PrintToServer("[public_dots] Teleport failure case: Bad location");
		PrintCenterText(bossClientIdx, "Cannot teleport there!");
		return false;
	}

	TeleportEntity(bossClientIdx, emptyPos, NULL_VECTOR, NULL_VECTOR);
	if (strlen(DT_UseSound[bossClientIdx]) > 3)
	{
		EmitSoundToAll(DT_UseSound[bossClientIdx]);
		EmitSoundToAll(DT_UseSound[bossClientIdx]);
	}
	
	ParticleEffectAt(startPos, DT_OldLocationParticleEffect[bossClientIdx]);
	ParticleEffectAt(emptyPos, DT_NewLocationParticleEffect[bossClientIdx]);
	
	return true;
}

/**
 * Workaround for weapon swap and FF2 1.10.0, some change made causing civilian.
 */
public OnGameFrame()
{
	if (WS_ActiveThisRound && RoundInProgress)
	{
		if (WS_CivilianWorkaroundAt >= GetEngineTime())
		{
			for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
			{
				if (WS_CanUse[clientIdx] && IsLivingPlayer(clientIdx))
				{
					new weapon = GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon");
					if (!IsValidEntity(weapon))
					{
						if (PRINT_DEBUG_INFO)
							PrintToServer("[public_dots] Boss %d is civilian. Restoring their weapon.", clientIdx);
						
						TF2_RemoveAllWeapons(clientIdx);
						if (WS_IsUsing[clientIdx])
							SwitchWeapon(clientIdx, WS_NewWeaponName[clientIdx], WS_NewWeaponIdx[clientIdx], WS_NewWeaponArgs[clientIdx], WS_NewWeaponVisibility[clientIdx]);
						else
							SwitchWeapon(clientIdx, WS_OldWeaponName[clientIdx], WS_OldWeaponIdx[clientIdx], WS_OldWeaponArgs[clientIdx], WS_OldWeaponVisibility[clientIdx]);
					}
				}
			}
			
			WS_CivilianWorkaroundAt = GetEngineTime() + WS_CW_INTERVAL;
		}
	}
}

/**
 * Support Methods
 */
stock ParticleEffect(clientIdx, String:effectName[], Float:duration)
{
	if (strlen(effectName) < 3)
		return; // nothing to display
	if (duration == 0.0)
		duration = 0.1; // probably doesn't matter for this effect, I just don't feel comfortable passing 0 to a timer
		
	new particle = AttachParticle(clientIdx, effectName, 75.0);
	if (IsValidEntity(particle))
		CreateTimer(duration, RemoveEntityDA, EntIndexToEntRef(particle));
}

// a duration of 0.0 below means that it won't be removed by a timer
// and instead must be managed by the programmer
stock ParticleEffectAt(Float:position[3], String:effectName[], Float:duration = 0.0)
{
	if (strlen(effectName) < 3)
		return -1; // nothing to display
		
	new particle = CreateEntityByName("info_particle_system");
	if (particle != -1)
	{
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "effect_name", effectName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		if (duration > 0.0)
			CreateTimer(duration, RemoveEntityDA, EntIndexToEntRef(particle));
	}
	return particle;
}

stock SetColorRGBA(color[4], r, g, b, a)
{
	color[0] = abs(r)%256;
	color[1] = abs(g)%256;
	color[2] = abs(b)%256;
	color[3] = abs(a)%256;
}

stock ParseColor(String:colorStr[])
{
	new ret = 0;
	ret |= charToHex(colorStr[0])<<20;
	ret |= charToHex(colorStr[1])<<16;
	ret |= charToHex(colorStr[2])<<12;
	ret |= charToHex(colorStr[3])<<8;
	ret |= charToHex(colorStr[4])<<4;
	ret |= charToHex(colorStr[5]);
	return ret;
}

stock ColorToDecimalString(String:buffer[12], rgb)
{
	Format(buffer, 12, "%d %d %d", GetR(rgb), GetG(rgb), GetB(rgb));
}

stock abs(x)
{
	return x < 0 ? -x : x;
}

stock Float:fabs(Float:x)
{
	return x < 0.0 ? -x : x;
}

stock Float:fsquare(Float:x)
{
	return x * x;
}

stock charToHex(c)
{
	if (c >= '0' && c <= '9')
		return c - '0';
	else if (c >= 'a' && c <= 'f')
		return c - 'a' + 10;
	else if (c >= 'A' && c <= 'F')
		return c - 'A' + 10;
	
	// this is a user error, so print this out (it won't spam)
	PrintToServer("[public_dots] Invalid hex character, probably while parsing something's color. Please only use 0-9 and A-F in your color. c=%d", c);
	return 0;
}

stock Float:ConformAxisValue(Float:src, Float:dst, Float:distCorrectionFactor)
{
	return src - ((src - dst) * distCorrectionFactor);
}

// if the distance between two points is greater than max distance allowed
// fills result with a new destination point that lines on the line between src and dst
stock ConformLineDistance(Float:result[3], const Float:src[3], const Float:dst[3], Float:maxDistance)
{
	new Float:distance = GetVectorDistance(src, dst);
	if (distance <= maxDistance)
	{
		// everything's okay.
		result[0] = dst[0];
		result[1] = dst[1];
		result[2] = dst[2];
	}
	else
	{
		// need to find a point at roughly maxdistance. (FP irregularities aside)
		new Float:distCorrectionFactor = maxDistance / distance;
		result[0] = ConformAxisValue(src[0], dst[0], distCorrectionFactor);
		result[1] = ConformAxisValue(src[1], dst[1], distCorrectionFactor);
		result[2] = ConformAxisValue(src[2], dst[2], distCorrectionFactor);
	}
}

// sourcepawn doesn't support macro methods :( boooo
stock GetA(c) { return abs(c>>24); }
stock GetR(c) { return abs((c>>16)&0xff); }
stock GetG(c) { return abs((c>>8 )&0xff); }
stock GetB(c) { return abs((c    )&0xff); }

/**
 * CODE BELOW WAS TAKEN FROM ff2_1st_set_abilities, I TAKE NO CREDIT FOR IT
 */
SpawnWeapon(client, String:name[], index, level, quality, String:attribute[], visible)
{
	new Handle:weapon=TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, quality);
	new String:attributes[32][32];
	new count = ExplodeString(attribute, ";", attributes, 32, 32);
	if(count%2!=0)
	{
		count--;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		new i2=0;
		for(new i=0; i<count; i+=2)
		{
			new attrib=StringToInt(attributes[i]);
			if(attrib==0)
			{
				LogError("Bad weapon attribute passed: %s ; %s", attributes[i], attributes[i+1]);
				return -1;
			}
			TF2Items_SetAttribute(weapon, i2, attrib, StringToFloat(attributes[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}

	if(weapon==INVALID_HANDLE)
	{
		return -1;
	}
	new entity=TF2Items_GiveNamedItem(client, weapon);
	CloseHandle(weapon);
	EquipPlayerWeapon(client, entity);
	
	// sarysa addition, since cheese's weapons are currently invisible
	if (!visible)
	{
		SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
		//SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", -1, _, 0);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
	}
	
	return entity;
}

stock bool:IsLivingPlayer(clientIdx)
{
	if (clientIdx <= 0 || clientIdx >= MAX_PLAYERS)
		return false;
		
	return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
}

stock bool:IsValidBoss(clientIdx)
{
	if (!IsLivingPlayer(clientIdx))
		return false;
		
	return GetClientTeam(clientIdx) == BossTeam;
}

/**
 * CODE BELOW TAKEN FROM default_abilities, I CLAIM NO CREDIT
 */
public Action:DestroyEntity(Handle:timer, any:entid) // well, this one's mine. ;P need to make slow kill entities disappear while they die.
{
	new entity = EntRefToEntIndex(entid);
	if (IsValidEdict(entity) && entity > MAX_PLAYERS)
	{
		// may not be the best way to handle this, but I can't find documentation re: toggling visibility. bah.
		// and the few lists of entity props I could find don't include it, so...
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR);
		RemoveEntityDA(timer, entid);
	}
}

public Action:RemoveEntityDA(Handle:timer, any:entid)
{
	new entity=EntRefToEntIndex(entid);
	if(IsValidEdict(entity) && entity>MAX_PLAYERS)
	{
			if(TF2_IsWearable(entity))
			{
				for(new client=1; client<MaxClients; client++)
				{
					if(IsValidEdict(client) && IsClientInGame(client))
					{
						TF2_RemoveWearable(client, entity);
					}
				}
			}
			else
			{
				AcceptEntityInput(entity, "Kill");
			}
	}
}

stock AttachParticle(entity, String:particleType[], Float:offset=0.0, bool:attach=true)
{
	new particle=CreateEntityByName("info_particle_system");

	if (!IsValidEntity(particle))
		return -1;
		
	decl String:targetName[128];
	decl Float:position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2]+=offset;
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	if(attach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	return particle;
}
