#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

/**
 * A platform for drain over time rages. Combines all the common aspects of such rages to
 * simplify other drain over time rages' code and configuration.
 *
 * KNOWN ISSUES:
 *	- Turning all three Vaccinator conditions on at the same time is definitely unsafe, a certain key combo from the player
 *		(reload, attack, movement dirs) can crash the server, usually when spamming R.
 *		As for individual Vaccinator conditions, your guess is as good as mine.
 */

// change this to minimize console output
new PRINT_DEBUG_INFO = true;

#define MAX_PLAYERS_ARRAY 36
#define MAX_PLAYERS (MAX_PLAYERS_ARRAY < (MaxClients + 1) ? MAX_PLAYERS_ARRAY : (MaxClients + 1))

// text string limits
#define MAX_SOUND_FILE_LENGTH 80
#define MAX_WEAPON_NAME_LENGTH 40
#define MAX_EFFECT_NAME_LENGTH 48

// handle needed for the method shared by sub-plugins
new Handle:Handle_OnDOTAbilityActivated;
new Handle:Handle_OnDOTAbilityDeactivated;
new Handle:Handle_OnDOTUserDeath; // in case cleanup is necessary
new Handle:Handle_OnDOTAbilityTick;
new Handle:Handle_DOTPostRoundStartInit;

// shared variables
new bool:RoundInProgress = false;

// according to the good folks at AlliedModders, this is as close as I'll get to a struct or a class
// but this mod needs to handle multiple bosses.
#define MAX_CONDITIONS 10
#define CONDITION_DELIM " ; " // I'm going with this because people are already using this format for weapon attributes
#define CONDITION_STRING_LENGTH (MAX_CONDITIONS * 3 + ((MAX_CONDITIONS - 1) * 3) + 1) // ### ; ### ; ### ; ###... (3-digit conditions will exist pretty soon, I'd think)
enum DOTUser
{
	DOTUserId,		// internal, ensure the user ID of the DOT user is 
	bool:UsingThisPlugin,	// internal, true means client is using this plugin this round
	TimeOfLastSound,	// internal, prevents sound spam on activate/deactivate
	bool:ReloadDown,	// internal, for managing reload key state
	bool:RageActive,	// internal, is the rage active/draining currently?
	ActiveTickCount,	// internal, how many 0.1ms ticks has this rage been active?
	bool:IsAlive,		// internal, track living state in case things need to be cleaned up
	bool:OverlayVisible,	// internal, is the reload overlay visible?
	bool:ActivationCancel,	// internal, did the subplugin cancel activation?
	bool:ForceDeactivation,	// internal, did the subplugin deactivate the DOT in its tick loop?
	bool:DOTUsable,		// internal, only checked if the user has DOTs. allows toggling of DOT usability.
	bool:IsOnCooldown,	// internal, is the ability currently on cooldown?
	CooldownTicksRemaining,	// internal, how many ticks remaining on cooldown?
	Float:MinRage,		// arg1: minimum rage to activate
	Float:RageDrain,	// arg2: rage drain per second
	Float:EnterPenalty,	// arg3: rage penalty for activation
	Float:ExitPenalty,	// arg4: rage penalty for early deactivation
	String:EntrySound[MAX_SOUND_FILE_LENGTH],	// arg5: Rage entry sound
	String:ExitSound[MAX_SOUND_FILE_LENGTH],	// arg6: Rage exit sound
	String:EntryEffect[MAX_EFFECT_NAME_LENGTH],	// arg7: Rage entry particle effect
	Float:EntryEffectDuration,	// arg8: Duration of said particle effect
	String:ExitEffect[MAX_EFFECT_NAME_LENGTH],	// arg9: Rage exit particle effect
	Float:ExitEffectDuration,	// arg10: Duration of said particle effect
	ConditionChanges[MAX_CONDITIONS],	// arg11: Conditions to add (and then subsequently remove) during the reload-activated rage.
	bool:NoOverlay,		// arg12: Don't use overlay
	CooldownDurationTicks,	// arg13: Tick count for cooldown
	ActivationKey,		// arg14: Activation key (IN_RELOAD or IN_ATTACK3)
}
#define DOT_STRING "dot_base"
new Clients[MAX_PLAYERS_ARRAY][DOTUser];
new bool:ActiveThisRound = false;

public Plugin:myinfo = {
	name = "Freak Fortress 2: Drain Over Time Platform",
	author = "sarysa",
	version = "1.0.0",
}

OnDOTAbilityActivated(clientIdx)
{
	new Action:act=Plugin_Continue;	
	Call_StartForward(Handle_OnDOTAbilityActivated);
	Call_PushCell(clientIdx);
	Call_Finish(act);
}

OnDOTAbilityDeactivated(clientIdx)
{
	new Action:act=Plugin_Continue;	
	Call_StartForward(Handle_OnDOTAbilityDeactivated);
	Call_PushCell(clientIdx);
	Call_Finish(act);
}

OnDOTAbilityTick(clientIdx, tickCount)
{
	new Action:act=Plugin_Continue;	
	Call_StartForward(Handle_OnDOTAbilityTick);
	Call_PushCell(clientIdx);
	Call_PushCell(tickCount);
	Call_Finish(act);
}

OnDOTUserDeath(clientIdx, isInGame)
{
	if (isInGame)
		RemoveDOTOverlay(clientIdx);

	new Action:act=Plugin_Continue;	
	Call_StartForward(Handle_OnDOTUserDeath);
	Call_PushCell(clientIdx);
	Call_PushCell(isInGame);
	Call_Finish(act);
}

DOTPostRoundStartInit()
{
	new Action:act=Plugin_Continue;
	Call_StartForward(Handle_DOTPostRoundStartInit);
	Call_Finish(act);
}

public OnPluginStart2()
{
	// handles for global forwards
	Handle_OnDOTAbilityActivated = CreateGlobalForward("OnDOTAbilityActivatedInternal", ET_Hook, Param_Cell);
	Handle_OnDOTAbilityDeactivated = CreateGlobalForward("OnDOTAbilityDeactivatedInternal", ET_Hook, Param_Cell);
	Handle_OnDOTAbilityTick = CreateGlobalForward("OnDOTAbilityTickInternal", ET_Hook, Param_Cell, Param_Cell);
	Handle_DOTPostRoundStartInit = CreateGlobalForward("DOTPostRoundStartInitInternal", ET_Hook);
	Handle_OnDOTUserDeath = CreateGlobalForward("OnDOTUserDeathInternal", ET_Hook, Param_Cell, Param_Cell);
	
	// natives, which allow subplugins to interact with this plugin
	//CreateNative("CancelDOTAbilityActivation", CancelDOTAbilityActivation);
	//CreateNative("ForceDOTAbilityDeactivation", ForceDOTAbilityDeactivation);
	//CreateNative("SetDOTUsability", SetDOTUsability);
	
	// events to listen to
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public OnMapStart()
{
}

public Action:Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	// set all clients to inactive
	for (new i = 0; i < MAX_PLAYERS; i++)
	{
		Clients[i][UsingThisPlugin] = false;
		Clients[i][ReloadDown] = false;
		Clients[i][RageActive] = false;
		Clients[i][IsAlive] = false;
		Clients[i][OverlayVisible] = false;
		Clients[i][ActivationCancel] = false;
		Clients[i][DOTUsable] = true;
		Clients[i][NoOverlay] = false;
		Clients[i][IsOnCooldown] = false;
		for (new j = 0; j < MAX_CONDITIONS; j++)
			Clients[i][ConditionChanges][j] = -1;
	}
		
	// set this to false, don't even start the looping timer if nothing uses this subplugin this round
	ActiveThisRound = false;
	
	// round is now in progress
	RoundInProgress = true;
	
	// post-round start inits
	CreateTimer(0.3, Timer_PostRoundStartInits);
}

public Action:Event_RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	// round has ended, this'll kill the looping timer
	RoundInProgress = false;
	
	// remove overlays for all bosses
	for (new i = 0; i < MAX_PLAYERS; i++)
	{
		if (Clients[i][UsingThisPlugin])
			RemoveDOTOverlay(i);
	}
}

// if one or more bosses with DOT is found, save their parameters now and start the timer
// it's worth noting that some strange behavior was discovered when I did prints...
// this timer executed twice for some unknown reason, and the second time it executed
// it  reported the boss being present but without the ability.
// not sure why that happens (it certainly isn't up to the specifications)
// but if you ever modify this timer, make sure the second execution doesn't undermine
// the first. in other words, don't set any negatives here -- leave that to RoundStart above.
public Action:Timer_PostRoundStartInits(Handle:timer)
{
	// edge case: user suicided
	if (!RoundInProgress)
	{
		PrintToServer("Timer_PostRoundStartInits() in %s called after round ended. User probably suicided.", this_plugin_name);
		return Plugin_Stop;
	}
		
	new dotUserCount = 0;
		
	// some things we'll be checking on for later
	for (new bossClientIdx = 1; bossClientIdx < MAX_PLAYERS; bossClientIdx++) // make no boss count assumptions, though anything above 3 is very weird
	{
		new bossIdx = FF2_GetBossIndex(bossClientIdx);
		if (bossIdx < 0)
			continue;
			
		if (FF2_HasAbility(bossIdx, this_plugin_name, DOT_STRING))
		{
			ActiveThisRound = true; // looks like we'll start the looping timer.
			new String:conditionStr[CONDITION_STRING_LENGTH];
			new String:conditions[MAX_CONDITIONS][4];

			// now lets set this user's parameters!
			Clients[bossClientIdx][DOTUserId] = GetClientUserId(bossClientIdx);
			Clients[bossClientIdx][UsingThisPlugin] = true;
			Clients[bossClientIdx][IsAlive] = true;
			Clients[bossClientIdx][MinRage] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DOT_STRING, 1);
			Clients[bossClientIdx][RageDrain] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DOT_STRING, 2);
			Clients[bossClientIdx][EnterPenalty] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DOT_STRING, 3);
			Clients[bossClientIdx][ExitPenalty] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DOT_STRING, 4);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, DOT_STRING, 5, Clients[bossClientIdx][EntrySound], MAX_SOUND_FILE_LENGTH);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, DOT_STRING, 6, Clients[bossClientIdx][ExitSound], MAX_SOUND_FILE_LENGTH);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, DOT_STRING, 7, Clients[bossClientIdx][EntryEffect], MAX_EFFECT_NAME_LENGTH);
			Clients[bossClientIdx][EntryEffectDuration] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DOT_STRING, 8);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, DOT_STRING, 9, Clients[bossClientIdx][ExitEffect], MAX_EFFECT_NAME_LENGTH);
			Clients[bossClientIdx][ExitEffectDuration] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DOT_STRING, 10);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, DOT_STRING, 11, conditionStr, CONDITION_STRING_LENGTH);
			if (strlen(conditionStr) > 0)
			{
				new conditionCount = ExplodeString(conditionStr, CONDITION_DELIM, conditions, MAX_CONDITIONS, 4);
				for (new condIdx = 0; condIdx < conditionCount; condIdx++)
				{
					Clients[bossClientIdx][ConditionChanges][condIdx] = StringToInt(conditions[condIdx]);
					PrintToServer("Condition: %d", Clients[bossClientIdx][ConditionChanges][condIdx]);
				}
			}
			Clients[bossClientIdx][NoOverlay] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, DOT_STRING, 12) == 1;
			Clients[bossClientIdx][CooldownDurationTicks] = RoundFloat(FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DOT_STRING, 13) * 10.0);
			Clients[bossClientIdx][ActivationKey] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, DOT_STRING, 14);
			
			// fix activation key
			if (Clients[bossClientIdx][ActivationKey] == 1)
				Clients[bossClientIdx][ActivationKey] = IN_ATTACK3;
			else
				Clients[bossClientIdx][ActivationKey] = IN_RELOAD;

			// warn user of mistake
			if (Clients[bossClientIdx][MinRage] <= Clients[bossClientIdx][EnterPenalty])
				PrintToServer("For %d, minimum rage (%f) <= rage entry cost (%f), should set minimum higher!", bossClientIdx, Clients[bossClientIdx][MinRage], Clients[bossClientIdx][EnterPenalty]);

			// init this just in case
			Clients[bossClientIdx][TimeOfLastSound] = GetTime();

			// precache sounds if necessary
			if (strlen(Clients[bossClientIdx][EntrySound]) > 3)
				PrecacheSound(Clients[bossClientIdx][EntrySound]);
			if (strlen(Clients[bossClientIdx][ExitSound]) > 3)
				PrecacheSound(Clients[bossClientIdx][ExitSound]);

			// debug only
			dotUserCount++;
		}
	}

	if (ActiveThisRound)
	{
		if (PRINT_DEBUG_INFO)
			PrintToServer("DOT rage on %d boss(es) this round.", dotUserCount);
		DOTPostRoundStartInit();
		CreateTimer(0.1, TickDOTs, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		if (PRINT_DEBUG_INFO)
			PrintToServer("No DOT rage users this round.");
	}
	
	return Plugin_Stop;
}

//public CancelDOTAbilityActivation(Handle:plugin, numParams)
public CancelDOTAbilityActivation(bossClientIdx)
{
	//new bossClientIdx = GetNativeCell(1);
	Clients[bossClientIdx][ActivationCancel] = true;
}

//public ForceDOTAbilityDeactivation(Handle:plugin, numParams)
public ForceDOTAbilityDeactivation(bossClientIdx)
{
	//new bossClientIdx = GetNativeCell(1);
	if (Clients[bossClientIdx][RageActive])
		Clients[bossClientIdx][ForceDeactivation] = true;
}

//public SetDOTUsability(Handle:plugin, numParams)
public SetDOTUsability(bossClientIdx, usability)
{
	//new bossClientIdx = GetNativeCell(1);
	//new bool:usability = GetNativeCell(2) == 1;
	Clients[bossClientIdx][DOTUsable] = usability == 1;
}

// ensure that sounds are not spammed by user spamming R. two seconds between sounds played
PlaySoundLocal(bossClientIdx, const String:soundPath[])
{
	if (Clients[bossClientIdx][TimeOfLastSound] + 2 > GetTime()) // two second interval check
		return; // prevent spam
	else if (strlen(soundPath) < 3)
		return; // nothing to play
		
	// play a speech sound that travels normally, local from the player.
	// I can swear that sounds are louder from eye position than origin...
	decl Float:playerPos[3];
	//GetEntPropVector(bossClientIdx, Prop_Send, "m_vecOrigin", playerPos);
	GetClientEyePosition(bossClientIdx, playerPos);
	EmitAmbientSound(soundPath, playerPos, bossClientIdx);
	Clients[bossClientIdx][TimeOfLastSound] = GetTime();
}

// also need to ensure this one isn't spammed
TransitionEffect(bossClientIdx, String:effectName[], Float:duration)
{
	if (strlen(effectName) < 3)
		return; // nothing to play
	if (duration == 0.0)
		duration = 0.1; // probably doesn't matter for this effect, I just don't feel comfortable passing 0 to a timer
		
	new Float:bossPos[3];
	GetEntPropVector(bossClientIdx, Prop_Send, "m_vecOrigin", bossPos);
	new particle = AttachParticle(bossClientIdx, effectName, 75.0);
	if (IsValidEntity(particle))
		CreateTimer(duration, RemoveEntityDA, EntIndexToEntRef(particle));
}

// repeating timers documented here: https://wiki.alliedmods.net/Timers_%28SourceMod_Scripting%29
new overlayTickCount = 0;
public Action:TickDOTs(Handle:timer)
{
	// only a round over check should stop the plugin.
	if (!RoundInProgress)
		return Plugin_Stop;
		
	overlayTickCount++;
		
	for (new bossClientIdx = 0; bossClientIdx < MAX_PLAYERS; bossClientIdx++)
	{
		// only bother if client is using the plugin
		if (!Clients[bossClientIdx][UsingThisPlugin])
			continue;
		else if (!IsClientInGame(bossClientIdx) || !IsPlayerAlive(bossClientIdx))
		{
			// need to report the death, mainly for multiboss scenarios and cleaning up
			// entities indirectly linked to the boss
			if (Clients[bossClientIdx][IsAlive])
			{
				Clients[bossClientIdx][IsAlive] = false;
				OnDOTUserDeath(bossClientIdx, IsClientInGame(bossClientIdx) ? 1 : 0);
			}
			continue;
		}
		else if (bossClientIdx != GetClientOfUserId(Clients[bossClientIdx][DOTUserId]))
		{
			// whoa, wtf...
			PrintToServer("DOT user client idx usurped in a 100ms time frame. Yikes.");
			Clients[bossClientIdx][IsAlive] = false;
			OnDOTUserDeath(bossClientIdx, 0);
			continue;
		}
		
		if (Clients[bossClientIdx][IsOnCooldown])
		{
			Clients[bossClientIdx][CooldownTicksRemaining]--;
			if (Clients[bossClientIdx][CooldownTicksRemaining] <= 0)
				Clients[bossClientIdx][IsOnCooldown] = false;
		}
			
		new bool:dotRageStart = false;
		new bool:dotRageStop = false;
		new Float:ragePenalty = 0.0;
		new bossIdx = FF2_GetBossIndex(bossClientIdx);
		new Float:rage = FF2_GetBossCharge(bossIdx, 0);

		// check key state, all we can get is the held state so use that to determine press/release
		new buttons = GetClientButtons(bossClientIdx);
		if (buttons & Clients[bossClientIdx][ActivationKey]) // reload pressed!
		{
			// key pressed?
			if (!Clients[bossClientIdx][ReloadDown])
			{
				if (Clients[bossClientIdx][RageActive]) // player manually stops the DOT
				{
					ragePenalty = Clients[bossClientIdx][ExitPenalty];
					dotRageStop = true;
				}
				else if (rage >= Clients[bossClientIdx][MinRage]) // player enters manic mode
					dotRageStart = true;

				Clients[bossClientIdx][ReloadDown] = true;
			}
		}
		else
		{
			// key released?
			if (Clients[bossClientIdx][ReloadDown])
				Clients[bossClientIdx][ReloadDown] = false;
		}
		
		// drain rage if DOT is active
		if (Clients[bossClientIdx][RageActive])
		{
			rage -= Clients[bossClientIdx][RageDrain];
			if (rage < 0.0)
			{
				dotRageStop = true; // force player out of manic mode
				rage = 0.0;
			}
			FF2_SetBossCharge(bossIdx, 0, rage);
		}
		
		// don't start rage if on cooldown
		if (Clients[bossClientIdx][IsOnCooldown])
			dotRageStart = false;

		// leaks shouldn't ever happen here, but it's better for most plugins to get the exit after the enter
		if (dotRageStart && Clients[bossClientIdx][DOTUsable] && !Clients[bossClientIdx][ForceDeactivation])
		{
			OnDOTAbilityActivated(bossClientIdx);
			if (!Clients[bossClientIdx][ActivationCancel])
			{
				if (PRINT_DEBUG_INFO)
					PrintToServer("%d entered DOT rage. (cooldown=%d ticks)", bossClientIdx, Clients[bossClientIdx][CooldownDurationTicks]);
				PlaySoundLocal(bossClientIdx, Clients[bossClientIdx][EntrySound]);
				TransitionEffect(bossClientIdx, Clients[bossClientIdx][EntryEffect], 1.5);
				Clients[bossClientIdx][RageActive] = true;
				Clients[bossClientIdx][ActiveTickCount] = 0;
				ragePenalty = Clients[bossClientIdx][EnterPenalty];
				RemoveDOTOverlay(bossClientIdx);

				// add conditions
				for (new condIdx = 0; condIdx < MAX_CONDITIONS; condIdx++)
				{
					if (Clients[bossClientIdx][ConditionChanges][condIdx] == -1)
						break;

					TF2_AddCondition(bossClientIdx, TFCond:Clients[bossClientIdx][ConditionChanges][condIdx], -1.0);
				}
				
				// cooldown
				if (Clients[bossClientIdx][CooldownDurationTicks] > 0)
				{
					Clients[bossClientIdx][IsOnCooldown] = true;
					Clients[bossClientIdx][CooldownTicksRemaining] = Clients[bossClientIdx][CooldownDurationTicks];
				}
			}
		}
		if (Clients[bossClientIdx][RageActive] && !Clients[bossClientIdx][ActivationCancel] && !Clients[bossClientIdx][ForceDeactivation])
		{
			OnDOTAbilityTick(bossClientIdx, Clients[bossClientIdx][ActiveTickCount]);
			Clients[bossClientIdx][ActiveTickCount]++;
		}
		if (dotRageStop || Clients[bossClientIdx][ActivationCancel] || (Clients[bossClientIdx][RageActive] && Clients[bossClientIdx][ForceDeactivation]))
		{
			OnDOTAbilityDeactivated(bossClientIdx);
			if (!Clients[bossClientIdx][ActivationCancel])
			{
				if (PRINT_DEBUG_INFO)
					PrintToServer("%d exited DOT rage.", bossClientIdx);
				PlaySoundLocal(bossClientIdx, Clients[bossClientIdx][ExitSound]);
				TransitionEffect(bossClientIdx, Clients[bossClientIdx][ExitEffect], 1.5);
				Clients[bossClientIdx][RageActive] = false;

				// remove conditions
				for (new condIdx = 0; condIdx < MAX_CONDITIONS; condIdx++)
				{
					if (Clients[bossClientIdx][ConditionChanges][condIdx] == -1)
						break;
					
					if (TF2_IsPlayerInCondition(bossClientIdx, TFCond:Clients[bossClientIdx][ConditionChanges][condIdx]))
						TF2_RemoveCondition(bossClientIdx, TFCond:Clients[bossClientIdx][ConditionChanges][condIdx]);
				}
			}
			Clients[bossClientIdx][ActivationCancel] = false;
			Clients[bossClientIdx][ForceDeactivation] = false;
		}
		
		// in some cases, standard rages may force the deactivation of a DOT, but it has no way of knowing if it's
		// really active. just silently set this to false in such a case.
		if (!Clients[bossClientIdx][RageActive] && Clients[bossClientIdx][ForceDeactivation])
			Clients[bossClientIdx][ForceDeactivation] = false;
		
		// handle any rage penalties, entry or exit
		if (ragePenalty > 0)
		{
			rage -= ragePenalty;
			if (rage < 0.0)
				rage = 0.0;
			FF2_SetBossCharge(bossIdx, 0, rage);
		}
		
		// DOT overlay, some conditions for its appearance and removal
		if (!Clients[bossClientIdx][RageActive] && rage >= Clients[bossClientIdx][MinRage] && !Clients[bossClientIdx][IsOnCooldown])
			DisplayDOTOverlay(bossClientIdx);
		else if ((rage < Clients[bossClientIdx][MinRage] || Clients[bossClientIdx][IsOnCooldown]) && Clients[bossClientIdx][OverlayVisible])
			RemoveDOTOverlay(bossClientIdx); // this only happens if standard 100% rage is used
	}
	
	return Plugin_Continue;
}

// unused, but required
public Action:FF2_OnAbility2(index, const String:plugin_name[], const String:ability_name[], status) { return Plugin_Continue; }

/**
 * READ THE LONG-WINDED COMMENTS BEFORE COPYING WHAT I DID.
 */
DisplayDOTOverlay(bossClientIdx)
{
	// ohai
	// So you may be wondering how I got this overlay to show up, when you don't even need to be a coder
	// to realize how screwed up the HUD overlays are.
	// Simple answer: I cheated.
	// I created a client command overlay similar to what Demopan uses, but I gave it to the hale.
	// This is after careful consideration of a couple things:
	// - Hales don't get overlays, except in rare cases for cosmetic reasons. (i.e. Doomguy)
	// - I'd have to modify the FF2 source to tack on my message to an existing overlay. That's a no-no.
	// - There's a limited number of overlays available...probably six. Adding my own overlay would destroy another, or just not appear.
	// So with that in mind I'm doing it this way. Keep this in mind if you copy this code. If you use this in your DOT...
	// well...don't.
	// The problem is you can only have one of these, period.
	// So if you use this code, remember that any existing overlay that client uses will vanish when you add yours.
	// And vice versa.
	// Server operators (who code) have it easy. :P Getting to pick and choose what HUDs are worth it and fixing the overuse in the FF2 code...
	// oh yeah, this isn't localized. Sorry about that.
	new bool:shouldExecute = (overlayTickCount % 5 == 0) || !Clients[bossClientIdx][OverlayVisible];
	shouldExecute = shouldExecute && !Clients[bossClientIdx][NoOverlay];
	if (!shouldExecute)
		return;
		
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	if ((overlayTickCount / 5) % 2 == 0)
	{
		if (Clients[bossClientIdx][ActivationKey] == IN_RELOAD)
			ClientCommand(bossClientIdx, "r_screenoverlay freak_fortress_2/dots/reload_overlay1");
		else
			ClientCommand(bossClientIdx, "r_screenoverlay freak_fortress_2/dots/attack3_overlay1");
	}
	else
	{
		if (Clients[bossClientIdx][ActivationKey] == IN_RELOAD)
			ClientCommand(bossClientIdx, "r_screenoverlay freak_fortress_2/dots/reload_overlay2");
		else
			ClientCommand(bossClientIdx, "r_screenoverlay freak_fortress_2/dots/attack3_overlay2");
	}
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
	
	Clients[bossClientIdx][OverlayVisible] = true;
}

RemoveDOTOverlay(bossClientIdx)
{
	if (!IsClientInGame(bossClientIdx) || Clients[bossClientIdx][NoOverlay])
		return;
		
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	ClientCommand(bossClientIdx, "r_screenoverlay \"\"");
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
	
	Clients[bossClientIdx][OverlayVisible] = false;
}

/**
 * CODE BELOW TAKEN FROM default_abilities, I CLAIM NO CREDIT
 */
public Action:RemoveEntityDA(Handle:timer, any:entid)
{
	new entity=EntRefToEntIndex(entid);
	if(IsValidEdict(entity) && entity>MAX_PLAYERS)
	{
		AcceptEntityInput(entity, "Kill");
	}
}

AttachParticle(entity, String:particleType[], Float:offset=0.0, bool:attach=true)
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
