#pragma semicolon 1

#define DDCOMPILE true

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <tf2items>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#if DDCOMPILE
#include <ff2_dynamic_defaults>
#endif
#undef REQUIRE_PLUGIN
#tryinclude <ff2_ams>
#tryinclude <goomba>
#tryinclude <revivemarkers>
#tryinclude <tf2attributes>
#define REQUIRE_PLUGIN

#pragma newdecls required

#define MAJOR_REVISION	"1"
#define MINOR_REVISION	"9"
#define STABLE_REVISION	"0"
#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define FAR_FUTURE		100000000.0
#define MAXTF2PLAYERS		36
#define MAXSOUNDPATH		80
#define MAXMODELPATH		128
#define MAXMATERIALPATH 	128
#define MAXNAMELENGTH		64
#define MAXFORMULASLENGTH	1024
#define MAXCLASSNAMELENGTH	64
#define	MAXATTRIBUTELENGTH	128
#define MAXABILITYLENGTH	64
#define MAXARGLENGTH		64
#define MAXBOSSSOUNDLENGTH	64
#define MAXLOADOUTS		9
#define MAXWEAPONS		10

#define INTRO		"special_introoverlay"
#define LASTBACKUP	"special_lastmanbackup"
#define NOKNOCKBACK	"special_noplayerknockback"
#define TEAMWEAPON	"rage_teamnewweapon"
#define TEAMWEAPONAMS	"ams_teamnewweapon"
#define WEIGHDOWN	"special_weighdown"
#define BLOCKRAGE	"rage_preventrage"
#define MUSIC		"rage_music"
#define MINIONBOSS	"special_minionboss"
#define SUMMON		"rage_summon"
#define SUMMONAMS	"ams_summon"
#define ANIMATION	"rage_animation"
#define ANIMATIONINTRO	"special_animationintro"
#define MEMEMARKER	"special_revivemarker"

#define SOUNDBACKUP	"sound_backup"
#define SOUNDBACKVO	"sound_backup_vo"
#define SOUNDLIGHT	"sound_weighdown"
#define SOUNDHEAVY	"sound_weighdown_slam"
#define SOUNDANIMATION	"sound_animation_"

#define MVMINTRO	"music/mvm_class_select.wav"
#define MVMINTRO_VOL	1.0
#define DEATH		"mvm/mvm_player_died.wav"
#define DEATH_VOL	1.0
#define GAMEOVER	"music/mvm_lost_wave.wav"
#define GAMEOVER_VOL	0.85

Handle OnHaleRage;
Handle OnHaleWeighdown;
float OFF_THE_MAP[3] = {16383.0, 16383.0, -16383.0};
bool UnofficialFF2;

#if defined _revivemarkers_included_
bool revivemarkers = false;
#endif

#if defined _tf2attributes_included
bool tf2attributes = false;
bool NoKnockback = false;
Handle hPlayTaunt;
int NextAnimationId[MAXTF2PLAYERS];
float NextAnimation[MAXTF2PLAYERS];
char CurrentAnimation[MAXTF2PLAYERS][MAXABILITYLENGTH];
#endif

#if defined _ff2_ams_included
int TotalPlayers;
int Players;
//int Bosses;
#endif

int LastMannBackup[MAXTF2PLAYERS];
bool IsBackup[MAXTF2PLAYERS];
float WeighdownTime[MAXTF2PLAYERS];
float RageBlockTimer[MAXTF2PLAYERS];
float RageBlockCurrent[MAXTF2PLAYERS];
bool IsBossMinion[MAXTF2PLAYERS];
int CloneOwner[MAXTF2PLAYERS];
char CloneVo[MAXTF2PLAYERS][MAXBOSSSOUNDLENGTH];
float CloneInvuln[MAXTF2PLAYERS];
TFTeam CloneTeam[MAXTF2PLAYERS];
bool CloneDeath[MAXTF2PLAYERS];
int CloneHealth[MAXTF2PLAYERS];
float ReviveMoveAt[MAXTF2PLAYERS];
float ReviveGoneAt[MAXTF2PLAYERS];
int ReviveIndex[MAXTF2PLAYERS];
int ReviveTimes[MAXTF2PLAYERS][2];

//#if defined _goomba_included_
bool TempGoomba;
//#endif
bool TempSlam;
float MusicTimer;
char MusicPath[MAXSOUNDPATH];
float MusicTime;
char MusicName[MAXNAMELENGTH];
char MusicArtist[MAXNAMELENGTH];
float MinionStab[2];
bool Revives;
TFTeam ReviveTeam;
int ReviveHide[2];
float ReviveLife[2];
int ReviveLimit[2];
bool ReviveSound[2];

static const char RobotBosses[][] =
{
	"models/bots/demo/bot_sentry_buster.mdl",
	"models/bots/scout_boss/bot_scout_boss.mdl",
	"models/bots/sniper/bot_sniper.mdl",
	"models/bots/soldier_boss/bot_soldier_boss.mdl",
	"models/bots/demo_boss/bot_demo_boss.mdl",
	"models/bots/medic/bot_medic.mdl",
	"models/bots/heavy_boss/bot_heavy_boss.mdl",
	"models/bots/pyro_boss/bot_pyro_boss.mdl",
	"models/bots/spy/bot_spy.mdl",
	"models/bots/engineer/bot_engineer.mdl"
};

enum Operators
{
	Operator_None = 0,
	Operator_Add,
	Operator_Subtract,
	Operator_Multiply,
	Operator_Divide,
	Operator_Exponent,
};

public Plugin myinfo =
{
	name		=	"Freak Fortress 2: Bat's Public Pack",
	author		=	"Batfoxkid",
	description	=	"Various small and public requested abilities",
	version		=	PLUGIN_VERSION
};

// SourceMod Events

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	OnHaleRage = CreateGlobalForward("VSH_OnDoRage", ET_Hook, Param_FloatByRef);
	OnHaleWeighdown = CreateGlobalForward("VSH_OnDoWeighdown", ET_Hook);

	#if defined _revivemarkers_included_
	MarkNativeAsOptional("SpawnRMarker");
	MarkNativeAsOptional("DespawnRMarker");
	MarkNativeAsOptional("SetReviveCount");
	MarkNativeAsOptional("SetDecayTime");
	#endif

	#if defined _tf2attributes_included
	MarkNativeAsOptional("TF2Attrib_SetByDefIndex");
	MarkNativeAsOptional("TF2Attrib_RemoveByDefIndex");
	#endif

	#if defined _FFBAT_included
	MarkNativeAsOptional("FF2_EmitVoiceToAll");
	MarkNativeAsOptional("FF2_GetBossName");
	MarkNativeAsOptional("FF2_GetForkVersion");
	MarkNativeAsOptional("FF2_LogError");
	#endif
	return APLRes_Success;
}

public void OnPluginStart2()
{
	int version[3];
	FF2_GetFF2Version(version);
	if(version[0] != 1)
		SetFailState("This subplugin is only for FF2 v1.0 versions!");

	#if defined _FFBAT_included
	if(version[1] > 10)
	{
		FF2_GetForkVersion(version);
		//if(version[0]==1 && (version[1]>18 || (version[1]==18 && version[2]>5)))	Unofficial never had an official
		if(version[0] && version[1])	// version of 1.11 until it's 1.19, by that time everything here is included
			UnofficialFF2 = true;
	}
	#endif

	AddCommandListener(OnVoiceline, "voicemenu");
	AddNormalSoundHook(HookSound);

	HookEvent("teamplay_round_start", OnRoundSetup, EventHookMode_PostNoCopy);
	HookEvent("object_deflected", OnObjectDeflected, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", OnRoundStart, EventHookMode_PostNoCopy);

	PrecacheSound(MVMINTRO, true);
	PrecacheSound(DEATH, true);
	PrecacheSound(GAMEOVER, true);

	#if defined _tf2attributes_included
	tf2attributes = LibraryExists("tf2attributes");

	Handle conf = LoadGameConfigFile("tf2.tauntem");
	if(conf == INVALID_HANDLE)
	{
		LogError2("[Plugin] Unable to load gamedata/tf2.tauntem.txt.");
	}
	else
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CTFPlayer::PlayTauntSceneFromItem");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		hPlayTaunt = EndPrepSDKCall();
		if(hPlayTaunt == INVALID_HANDLE)
			LogError2("[Plugin] Unable to initialize call to CTFPlayer::PlayTauntSceneFromItem.");
	}
	delete conf;
	#endif

	if(FF2_IsFF2Enabled())
	{
		if(FF2_GetRoundState() == 1)	// In case the plugin is loaded in late
		{
			MusicTimer = FAR_FUTURE;
			OnRoundStart(view_as<Event>(INVALID_HANDLE), "plugin_lateload", false);
		}
		else if(FF2_GetRoundState() == 0)	// Either loaded late or it's the first round
		{
			CreateTimer(0.3, CheckAbility, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public void OnLibraryAdded(const char[] name)
{
	#if defined _tf2attributes_included
	if(!strcmp(name, "tf2attributes", false))
		tf2attributes = true;
	#endif
}

public void OnLibraryRemoved(const char[] name)
{
	#if defined _tf2attributes_included
	if(!strcmp(name, "tf2attributes", false))
		tf2attributes = false;
	#endif

	#if defined _revivemarkers_included_
	if(!strcmp(name, "revivemarkers", false))
		revivemarkers = false;
	#endif
}

public void OnPluginEnd()
{
	OnRoundEnd(view_as<Event>(INVALID_HANDLE), "plugin_end", false);
}

// TF2 Events

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(!FF2_IsFF2Enabled())
		return;

	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client))
			continue;

		int boss = FF2_GetBossIndex(client);
		if(boss < 0)
			continue;

		if(FF2_HasAbility(boss, this_plugin_name, NOKNOCKBACK))
		#if defined _tf2attributes_included
		{
			if(tf2attributes)
			{
				for(int target=1; target<=MaxClients; target++)
				{
					if(!IsValidClient(client))
						continue;

					if(!IsPlayerAlive(client))
						continue;

					boss = FF2_GetBossIndex(client);
					if(boss >= 0)
						continue;

					TF2Attrib_SetByDefIndex(target, 252, 0.0);
				}
				NoKnockback = true;
			}
			else
			{
				LogError2("[Plugin] tf2attributes is not available for %s's %s", this_plugin_name, NOKNOCKBACK);
			}
		}

		NextAnimationId[client] = 0;
		NextAnimation[client] = 0.0;
		#else
			LogError2("[Plugin] %s is not compiled with tf2attributes to use %s", this_plugin_name, NOKNOCKBACK);
		#endif

		#if defined _ff2_ams_included
		if(FF2_HasAbility(boss, this_plugin_name, TEAMWEAPONAMS))
		{
			if(AMS_IsSubabilityReady(boss, this_plugin_name, TEAMWEAPONAMS))
				AMS_InitSubability(boss, client, this_plugin_name, TEAMWEAPONAMS, "TNW");
		}

		if(FF2_HasAbility(boss, this_plugin_name, SUMMONAMS))
		{
			if(AMS_IsSubabilityReady(boss, this_plugin_name, SUMMONAMS))
				AMS_InitSubability(boss, client, this_plugin_name, SUMMONAMS, "SUM");
		}
		#endif

		if(FF2_HasAbility(boss, this_plugin_name, MINIONBOSS) && GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
			MinionStab[GetClientTeam(client)-2] = FF2_GetArgF(boss, this_plugin_name, MINIONBOSS, "backstab", 1, 300.0);

		if(FF2_HasAbility(boss, this_plugin_name, MEMEMARKER) && GetClientTeam(client)>view_as<int>(TFTeam_Spectator))	// Never know in the future where spec bosses become a thing
		{
			int team = GetClientTeam(client)==view_as<int>(TFTeam_Blue) ? view_as<int>(TFTeam_Red) : view_as<int>(TFTeam_Blue);
			if(ReviveTeam == TFTeam_Unassigned)
			{
				ReviveTeam = view_as<TFTeam>(team);
			}
			else if(ReviveTeam != view_as<TFTeam>(team)) // Both teams have a revive marker boss
			{
				ReviveTeam = TFTeam_Spectator; // Randomize
			}

			team -= 2;
			Revives = true;
			ReviveLife[team] = FF2_GetArgF(boss, this_plugin_name, MEMEMARKER, "lifetime", 1, 60.0);
			ReviveLimit[team] = FF2_GetArgI(boss, this_plugin_name, MEMEMARKER, "limit", 2, 3);
			ReviveHide[team] = FF2_GetArgI(boss, this_plugin_name, MEMEMARKER, "hide", 3, 1);
			ReviveSound[team] = view_as<bool>(FF2_GetArgI(boss, this_plugin_name, MEMEMARKER, "sound", 4));
			#if defined _revivemarkers_included_
			if(LibraryExists("revivemarkers"))
			{
				revivemarkers = true;
				SetReviveCount(ReviveLife[team]);
				SetDecayTime(ReviveLife[team]);
			}
			#endif
		}
	}

	if(Revives)
	{
		for(int client=1; client<=MaxClients; client++)
		{
			if(!IsValidClient(client) || IsFakeClient(client))
				continue;

			if(ReviveTeam!=TFTeam_Spectator && ReviveTeam!=TF2_GetClientTeam(client))
				continue;

			EmitSoundToClient(client, MVMINTRO, _, _, _, _, MVMINTRO_VOL);
			SetHudTextParams(-1.0, 0.67, 4.0, 255, 0, 0, 255);
			ShowHudText(client, -1, "Medics can revive players this round!");
		}
	}
}

public void OnRoundSetup(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.3, CheckAbility, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action CheckAbility(Handle timer)
{
	bool enabled = FF2_IsFF2Enabled();
	for(int client=1; client<=MaxClients; client++)
	{
		IsBackup[client] = false;
		CloneOwner[client] = -1;
		if(!IsValidClient(client) || !enabled)
			continue;

		int boss = FF2_GetBossIndex(client);
		if(boss < 0)
			continue;

		if(FF2_HasAbility(boss, this_plugin_name, INTRO))
			CreateTimer(FF2_GetArgF(boss, this_plugin_name, INTRO, "delay", 4, 3.25), Apply_Overlay, boss, TIMER_FLAG_NO_MAPCHANGE);

		#if defined _tf2attributes_included
		if(FF2_HasAbility(boss, this_plugin_name, ANIMATIONINTRO) && hPlayTaunt!=INVALID_HANDLE && tf2attributes)
		{
			NextAnimationId[client] = 1;
			NextAnimation[client] = GetEngineTime()+FF2_GetArgF(boss, this_plugin_name, ANIMATIONINTRO, "delay", 1, 3.25);
			if(!FF2_GetArgI(boss, this_plugin_name, ANIMATIONINTRO, "control", 2))
				TF2_AddCondition(client, TFCond_HalloweenKartNoTurn, TFCondDuration_Infinite);

			if(FF2_GetArgI(boss, this_plugin_name, ANIMATIONINTRO, "freeze", 3, 1))
			{
				static float velocity[3];
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
			}

			strcopy(CurrentAnimation[client], MAXABILITYLENGTH, ANIMATIONINTRO);
			SDKHook(client, SDKHook_PreThink, AnimationThink);
		}
		#endif
	}
	return Plugin_Continue;
}

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	MusicTimer = FAR_FUTURE;
	TotalPlayers = 0;
	MinionStab[0] = 0.0;
	MinionStab[1] = 0.0;
	Revives = false;
	ReviveTeam = TFTeam_Unassigned;

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			if(CloneOwner[client] >= 0)
			{
				CloneOwner[client] = -1;
				SDKUnhook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
				FF2_SetFF2flags(client, FF2_GetFF2flags(client) & ~FF2FLAG_CLASSTIMERDISABLED);
			}

			if(IsBossMinion[client])
				SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}

		ReviveTimes[client][0] = 0;
		ReviveTimes[client][1] = 0;
		ReviveGoneAt[client] = 0.0;
		NextAnimationId[client] = 0;
		NextAnimation[client] = 0.0;
		IsBossMinion[client] = false;
		RageBlockTimer[client] = 0.0;
		RageBlockCurrent[client] = 0.0;
		LastMannBackup[client] = 0;
	}

	#if defined _revivemarkers_included_
	if(revivemarkers)
	{
		SetReviveCount(-1);
		SetDecayTime(-1);
	}
	#endif

	#if defined _tf2attributes_included
	if(!NoKnockback || !tf2attributes)
	{
		NoKnockback = false;
		return;
	}

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
			TF2Attrib_RemoveByDefIndex(client, 252);
	}
	#endif
}

public Action OnPlayerDeathPre(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(!attacker)
		return Plugin_Continue;

	int boss = FF2_GetBossIndex(attacker);
	if(boss < 0)
		return Plugin_Continue;

	if(!FF2_HasAbility(boss, this_plugin_name, WEIGHDOWN))
		return Plugin_Continue;

	if(TempGoomba)
	{
		event.SetString("weapon", "mantreads");
		event.SetString("weapon_logclassname", "slam");
	}
	else if(TempSlam)
	{
		event.SetString("weapon", "firedeath");
		event.SetString("weapon_logclassname", "slam");
	}
	return Plugin_Continue;
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(FF2_GetRoundState()!=1 || (event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER))
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client)
		return;

	int boss = FF2_GetBossIndex(client);
	if(boss >= 0)
	{
		if(CloneDeath[client])
		{
			CloneDeath[client] = false;
			int attacker = GetClientOfUserId(event.GetInt("attacker"));
			for(int target=1; target<=MaxClients; target++)
			{
				if(!IsValidClient(target) || !IsPlayerAlive(target) || CloneOwner[target]!=boss)
					continue;

				CloneInvuln[target] = 0.0;
				if(IsValidClient(attacker))
				{
					SDKHooks_TakeDamage(target, attacker, attacker, 9001.0);
				}
				else if(view_as<int>(CloneTeam[client]) > view_as<int>(TFTeam_Spectator))
				{
					if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
						ChangeClientTeam(target, view_as<int>(CloneTeam[target]));
				}
				else
				{
					if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
						ChangeClientTeam(target, GetClientTeam(client)==view_as<int>(TFTeam_Blue) ? view_as<int>(TFTeam_Red) : view_as<int>(TFTeam_Blue));
				}
			}
		}
		return;
	}

	IsBackup[client] = false;

	if(IsBossMinion[client])
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		IsBossMinion[client] = false;
	}

	if(CloneOwner[client] >= 0)
	{
		CloneOwner[client] = -1;
		SDKUnhook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
		FF2_SetFF2flags(client, FF2_GetFF2flags(client) & ~FF2FLAG_CLASSTIMERDISABLED);

		if(view_as<int>(CloneTeam[client]) > view_as<int>(TFTeam_Spectator))
		{
			if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
				TF2_ChangeClientTeam(client, CloneTeam[client]);
		}
		else
		{
			if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
				TF2_ChangeClientTeam(client, GetClientTeam(client)==view_as<int>(TFTeam_Blue) ? TFTeam_Red : TFTeam_Blue);
		}
	}

	if(Revives)
	{
		switch(ReviveTeam)
		{
			case TFTeam_Spectator:
			{
				DropReviveMarker(client, GetRandomInt(0, 1));
			}
			case TFTeam_Red:
			{
				DropReviveMarker(client, 0);
			}
			case TFTeam_Blue:
			{
				DropReviveMarker(client, 1);
			}
		}
	}
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = GetClientTeam(client);
	if(!IsValidClient(client) || IsBoss(client) || team<=view_as<int>(TFTeam_Spectator))
		return;

	if(MinionStab[team-2] > 0)
	{
		IsBossMinion[client] = true;
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}

	ReviveGoneAt[client] = 0.0;
	if(Revives)
	{
		ReviveTimes[client][team-2]++;
		if(ReviveTeam==TFTeam_Spectator)
		{
			if(ReviveTimes[client][team-2] == ReviveLimit[team-2])
			{
				SetHudTextParams(-1.0, 0.67, 4.0, 255, 0, 0, 255);
				ShowHudText(client, -1, "You can no longer be revived on %s!", team==2 ? "RED" : "BLU");
			}
			else if(ReviveTimes[client][team-2]+1 == ReviveLimit[team-2])
			{
				SetHudTextParams(-1.0, 0.67, 4.0, 255, 85, 85, 255);
				ShowHudText(client, -1, "You can be revived 1 more time on %s", team==2 ? "RED" : "BLU");
			}
			else if(ReviveTimes[client][team-2] < ReviveLimit[team-2])
			{
				SetHudTextParams(-1.0, 0.67, 4.0, 255, 170, 170, 255);
				ShowHudText(client, -1, "You can be revived %i more times on %s", ReviveLimit[team-2]-ReviveTimes[client][team-2], team==2 ? "RED" : "BLU");
			}
		}
		else if(ReviveTeam==view_as<TFTeam>(team))
		{
			if(ReviveTimes[client][team-2] == ReviveLimit[team-2])
			{
				SetHudTextParams(-1.0, 0.67, 4.0, 255, 0, 0, 255);
				ShowHudText(client, -1, "You can no longer be revived!");
			}
			else if(ReviveTimes[client][team-2]+1 == ReviveLimit[team-2])
			{
				SetHudTextParams(-1.0, 0.67, 4.0, 255, 85, 85, 255);
				ShowHudText(client, -1, "You can be revived 1 more time");
			}
			else if(ReviveTimes[client][team-2] < ReviveLimit[team-2])
			{
				SetHudTextParams(-1.0, 0.67, 4.0, 255, 170, 170, 255);
				ShowHudText(client, -1, "You can be revived %i more times", ReviveLimit[team-2]-ReviveTimes[client][team-2]);
			}
		}
	}
}

public Action OnObjectDeflected(Event event, const char[] name, bool dontBroadcast)
{
	if(event.GetInt("weaponid"))  //0 means that the client was airblasted, which is what we want
		return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("ownerid"));
	int boss = FF2_GetBossIndex(client);
	if(boss < 0)
		return Plugin_Continue;

	if(!FF2_HasAbility(boss, this_plugin_name, WEIGHDOWN))
		return Plugin_Continue;

	SetEntityGravity(client, FF2_GetArgF(boss, this_plugin_name, WEIGHDOWN, "gravity", 3, 1.0));
	return Plugin_Continue;
}

#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=7
public Action HookSound(int clients[64], int &numClients, char sound[PLATFORM_MAX_PATH], int &client, int &channel, float &volume, int &level, int &pitch, int &flags)
#else
public Action HookSound(int clients[64], int &numClients, char sound[PLATFORM_MAX_PATH], int &client, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
#endif
{
	if(!IsValidClient(client) || channel<1)
		return Plugin_Continue;

	if(CloneOwner[client]<0 || TF2_IsPlayerInCondition(client, TFCond_Disguised))
		return Plugin_Continue;

	if(!strlen(CloneVo[client]) || StrEqual("0", CloneVo[client]))
		return Plugin_Continue;

	if(StrEqual("1", CloneVo[client]) && (channel==SNDCHAN_VOICE || (channel==SNDCHAN_STATIC && !StrContains(sound, "vo"))))
		return Plugin_Stop;

	TFClassType class = TF2_GetPlayerClass(client);
	if(StrEqual("2", CloneVo[client]) || (StrEqual("3", CloneVo[client]) && class!=TFClass_Engineer && class!=TFClass_Sniper && class!=TFClass_Medic && class!=TFClass_Spy))
	{
		if(StrContains(sound, "player/footsteps/", false)!=-1 && class!=TFClass_Medic)
		{
			int rand = GetRandomInt(1, 18);
			Format(sound, sizeof(sound), "mvm/player/footsteps/robostep_%s%i.wav", (rand < 10) ? "0" : "", rand);
			pitch = GetRandomInt(95, 100);
			EmitSoundToAll(sound, client, _, _, _, 0.25, pitch);
			return Plugin_Changed;
		}

		if(channel==SNDCHAN_VOICE || (channel==SNDCHAN_STATIC && !StrContains(sound, "vo")))
		{
			if(volume == 0.99997)
				return Plugin_Continue;

			ReplaceString(sound, sizeof(sound), "vo/", "vo/mvm/norm/", false);
			ReplaceString(sound, sizeof(sound), ".wav", ".mp3", false);
			static char classname[10], classname_mvm[15];
			TF2_GetNameOfClass(class, classname, sizeof(classname));
			Format(classname_mvm, sizeof(classname_mvm), "%s_mvm", classname);
			ReplaceString(sound, sizeof(sound), classname, classname_mvm, false);
			PrecacheSound(sound);
			return Plugin_Changed;
		}
	}
	else if(StrEqual("3", CloneVo[client]))
	{
		if(StrContains(sound, "player/footsteps/", false)!=-1)
		{
			Format(sound, sizeof(sound), "mvm/giant_common/giant_common_step_0%i.wav", GetRandomInt(1, 8));
			pitch = GetRandomInt(95, 100);
			EmitSoundToAll(sound, client, _, _, _, 0.25, pitch);
			return Plugin_Changed;
		}

		if(channel==SNDCHAN_VOICE || (channel==SNDCHAN_STATIC && !StrContains(sound, "vo")))
		{
			if(volume == 0.99997)
				return Plugin_Continue;

			ReplaceString(sound, sizeof(sound), "vo/", "vo/mvm/mght/", false);
			static char classname[10], classname_mvm_m[20];
			TF2_GetNameOfClass(class, classname, sizeof(classname));
			Format(classname_mvm_m, sizeof(classname_mvm_m), "%s_mvm_m", classname);
			ReplaceString(sound, sizeof(sound), classname, classname_mvm_m, false);
			PrecacheSound(sound);
			return Plugin_Changed;
		}
	}
	else if(channel==SNDCHAN_VOICE || (channel==SNDCHAN_STATIC && !StrContains(sound, "vo")))
	{
		static char temp[MAXSOUNDPATH];
		if(FF2_RandomSound(CloneVo[client], temp, MAXSOUNDPATH, CloneOwner[client]))
		{
			strcopy(sound, PLATFORM_MAX_PATH, temp);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action OnVoiceline(int client, const char[] command, int args)
{
	if(!IsPlayerAlive(client) || !IsBackup[client])
		return Plugin_Continue;

	static char arg1[4], arg2[4];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if(!StringToInt(arg1) || !StringToInt(arg2))
		return Plugin_Continue;

	static char sound[MAXSOUNDPATH];
	if(FF2_RandomSound(SOUNDBACKVO, sound, MAXSOUNDPATH, 0))
		EmitVoiceToAll(sound, client);

	return Plugin_Handled;
}

public void OnGameFrame()
{
	if(MusicTimer > GetEngineTime())
		return;

	MusicTimer = FAR_FUTURE;
	FF2_StartMusic();
}

// FF2 Events

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
	int slot = FF2_GetArgI(boss, this_plugin_name, ability_name, "slot", 0);
	if(!slot)  //Rage
	{
		if(!boss)
		{
			Action action = Plugin_Continue;
			Call_StartForward(OnHaleRage);
			float distance = FF2_GetRageDist(boss, this_plugin_name, ability_name);
			float newDistance = distance;
			Call_PushFloatRef(newDistance);
			Call_Finish(action);
			if(action!=Plugin_Continue && action!=Plugin_Changed)
			{
				return Plugin_Continue;
			}
			else if(action == Plugin_Changed)
			{
				distance = newDistance;
			}
		}
	}

	if(!StrContains(ability_name, TEAMWEAPON))
	{
		int bossTeam = GetClientTeam(GetClientOfUserId(FF2_GetBossUserId(boss)));
		for(int target=1; target<=MaxClients; target++)
		{
			if(!IsValidClient(target))
				continue;

			if(IsPlayerAlive(target) && GetClientTeam(target)==bossTeam)
				Rage_New_Weapon(target, boss, ability_name);
		}
	}
	else if(StrEqual(ability_name, WEIGHDOWN))
	{
		int client = GetClientOfUserId(FF2_GetBossUserId(boss));
		if((GetEntityFlags(client) & FL_ONGROUND))
		{
			if(GetEntityGravity(client) == 6.0)
			{
				char sound[MAXTF2PLAYERS];
				static float ang[3];
				GetClientEyeAngles(client, ang);
				if(WeighdownTime[client]<GetGameTime() &&
				  !TF2_IsPlayerInCondition(client, TFCond_Slowed) &&
				  !TF2_IsPlayerInCondition(client, TFCond_Parachute) &&
				   ang[0] > 60.0)
				{
					PeformSlam(client);
					if(FF2_RandomSound(SOUNDHEAVY, sound, MAXTF2PLAYERS, boss))
					{
						EmitSoundToAll(sound, client, _, _, _, _, _, client);
					}
					else if(FF2_RandomSound(SOUNDLIGHT, sound, MAXTF2PLAYERS, boss))
					{
						EmitSoundToAll(sound, client, _, _, _, _, _, client);
					}
				}
				else if(FF2_RandomSound(SOUNDLIGHT, sound, MAXTF2PLAYERS, boss))
				{
					EmitSoundToAll(sound, client, _, _, _, _, _, client);
				}
			}

			SetEntityGravity(client, FF2_GetArgF(boss, this_plugin_name, WEIGHDOWN, "gravity", 3, 1.0));
			return Plugin_Continue;
		}

		#if DDCOMPILE
		if(FF2_GetArgF(boss, this_plugin_name, WEIGHDOWN, "mobility", 4, -1.0)>0 && DD_GetMobilityCooldown(client)>FF2_GetArgF(boss, this_plugin_name, WEIGHDOWN, "mobility", 4))
			return Plugin_Continue;
		#endif

		if(GetEntityGravity(client)==6.0 ||
		 !(GetClientButtons(client) & IN_DUCK) ||
		   FF2_GetArgI(boss, this_plugin_name, WEIGHDOWN, "disable", 1) ||
		   TF2_IsPlayerInCondition(client, TFCond_Slowed) ||
		   TF2_IsPlayerInCondition(client, TFCond_Parachute) ||
		   TF2_IsPlayerInCondition(client, TFCond_AirCurrent))
			return Plugin_Continue;

		Action action = Plugin_Continue;
		Call_StartForward(OnHaleWeighdown);
		Call_Finish(action);
		if(action!=Plugin_Continue && action!=Plugin_Changed)
			return Plugin_Continue;

		float velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
		velocity[2] = FF2_GetArgF(boss, this_plugin_name, WEIGHDOWN, "speed", 2, -1000.0);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
		SetEntityGravity(client, 6.0);
		WeighdownTime[client] = GetEngineTime()+FF2_GetArgF(boss, this_plugin_name, WEIGHDOWN, "delay", 5, 0.2);
	}
	else if(StrEqual(ability_name, BLOCKRAGE))
	{
		int client = GetClientOfUserId(FF2_GetBossUserId(boss));
		RageBlockCurrent[client] = FF2_GetBossCharge(boss, slot);
		CreateTimer(0.1, Timer_RageBlock, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(!StrContains(ability_name, MUSIC))
	{
		float duration = FF2_GetArgF(boss, this_plugin_name, ability_name, "duration", 1);
		if(duration <= 0)
		{
			MusicTimer = FAR_FUTURE;
		}
		else
		{
			MusicTimer = GetEngineTime()+duration;
		}

		FF2_GetArgS(boss, this_plugin_name, ability_name, "path", 2, MusicPath, MAXSOUNDPATH);
		MusicTime = FF2_GetArgF(boss, this_plugin_name, ability_name, "time", 3, FAR_FUTURE);
		FF2_GetArgS(boss, this_plugin_name, ability_name, "name", 4, MusicName, MAXNAMELENGTH);
		FF2_GetArgS(boss, this_plugin_name, ability_name, "artist", 5, MusicArtist, MAXNAMELENGTH);
		FF2_StartMusic();
	}
	else if(!StrContains(ability_name, SUMMON))
	{
		Rage_Summon(GetClientOfUserId(FF2_GetBossUserId(boss)), boss, ability_name);
	}
	else if(!StrContains(ability_name, ANIMATION))
	{
		#if defined _tf2attributes_included
		if(hPlayTaunt!=INVALID_HANDLE && tf2attributes)
		{
			int client = GetClientOfUserId(FF2_GetBossUserId(boss));
			NextAnimationId[client] = 1;
			NextAnimation[client] = GetEngineTime()+FF2_GetArgF(boss, this_plugin_name, ability_name, "delay", 1);
			if(!FF2_GetArgI(boss, this_plugin_name, ability_name, "control", 2))
				TF2_AddCondition(client, TFCond_HalloweenKartNoTurn, TFCondDuration_Infinite);

			if(FF2_GetArgI(boss, this_plugin_name, ability_name, "freeze", 3, 1))
			{
				static float velocity[3];
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
			}

			strcopy(CurrentAnimation[client], MAXABILITYLENGTH, ability_name);
			SDKHook(client, SDKHook_PreThink, AnimationThink);
		}
		else if(!tf2attributes)
		{
			LogError2("[Plugin] tf2attributes is not available for %s's %s", this_plugin_name, ability_name);
		}
		#else
		LogError2("[Plugin] %s is not compiled with tf2attributes to use %s", this_plugin_name, ability_name);
		#endif
	}
	return Plugin_Continue;
}

public void FF2_OnAlivePlayersChanged(int players, int bosses)
{
	if(!FF2_IsFF2Enabled() || !bosses || !players || FF2_GetRoundState()!=1)
		return;

	#if defined _ff2_ams_included
	Players = players;
	//Bosses = bosses;
	if(TotalPlayers > players)
		TotalPlayers = players;
	#endif

	int boss;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client))
			continue;

		boss = FF2_GetBossIndex(client);
		if(boss < 0)
			continue;

		if(!FF2_HasAbility(boss, this_plugin_name, LASTBACKUP))
			continue;

		if(LastMannBackup[boss] >= FF2_GetArgI(boss, this_plugin_name, LASTBACKUP, "backups", 2, 1))
			continue;

		if(GetClientTeam(client) == FF2_GetBossTeam())
		{
			if(players > FF2_GetArgI(boss, this_plugin_name, LASTBACKUP, "amount", 1, 1))
				continue;
		}
		else if(bosses > FF2_GetArgI(boss, this_plugin_name, LASTBACKUP, "amount", 1, 1))
		{
			continue;
		}
		CreateTimer(FF2_GetArgF(boss, this_plugin_name, LASTBACKUP, "delay", 3, 0.05), Timer_Backup, boss, TIMER_FLAG_NO_MAPCHANGE);
	}
	return;
}

public void FF2_PreAbility(int boss, const char[] pluginName, const char[] abilityName, int slot, bool &enabled)
{
	if(!slot && GetEngineTime()<RageBlockTimer[GetClientOfUserId(FF2_GetBossUserId(boss))])
		enabled = false;
}

public Action FF2_OnMusic(char[] path, float &time)
{
	if(MusicTimer > GetEngineTime())
		return Plugin_Continue;

	if(!strlen(MusicPath))
		return Plugin_Stop;

	strcopy(path, PLATFORM_MAX_PATH, MusicPath);
	time = MusicTime;
	return Plugin_Changed;
}

//#if defined _FFBAT_included
public Action FF2_OnMusic2(char[] path, float &time, char[] name, char[] artist)
{
	if(MusicTimer > GetEngineTime())
		return Plugin_Continue;

	if(!strlen(MusicPath))
		return Plugin_Stop;

	strcopy(path, PLATFORM_MAX_PATH, MusicPath);
	time = MusicTime;
	strcopy(name, PLATFORM_MAX_PATH, MusicName);
	strcopy(artist, PLATFORM_MAX_PATH, MusicArtist);
	return Plugin_Changed;
}
//#endif

// Goomba Events

//#if defined _goomba_included_
public Action OnStomp(int attacker, int victim, float &damageMult, float &damageBonus, float &jumpPower)
{
	if(!IsPlayerAlive(attacker))
		return Plugin_Continue;

	if(IsBossMinion[victim])
	{
		damageMult = GetConVarFloat(FindConVar("ff2_goomba_damage"));
		jumpPower = GetConVarFloat(FindConVar("ff2_goomba_jump"));
		return Plugin_Changed;
	}

	if(GetEntityGravity(attacker) != 6.0)
		return Plugin_Continue;

	if(!IsPlayerAlive(victim) || FF2_GetBossIndex(victim)>=0)
		return Plugin_Continue;

	int boss = FF2_GetBossIndex(attacker);
	if(boss < 0)
		return Plugin_Continue;

	if(!FF2_HasAbility(boss, this_plugin_name, WEIGHDOWN))
		return Plugin_Continue;

	TempGoomba = true;
	SDKHooks_TakeDamage(victim, attacker, attacker, damageMult*GetClientHealth(victim)+damageBonus, DMG_PREVENT_PHYSICS_FORCE|DMG_CRUSH|DMG_ALWAYSGIB, -1);
	TempGoomba = false;
	WeighdownTime[attacker] = GetGameTime()+(FF2_GetArgF(boss, this_plugin_name, WEIGHDOWN, "delay", 5, 0.2)/2.0);
	return Plugin_Handled;
}
//#endif

// AMS Events

#if defined _ff2_ams_included
public bool TNW_CanInvoke(int client)
{
	/*int clones = GetClientTeam(client)==FF2_GetBossTeam() ? Bosses : Players;
	return clones>1;*/
	return true;
}

public void TNW_Invoke(int client)
{
	int bossTeam = GetClientTeam(client);
	for(int target=1; target<=MaxClients; target++)
	{
		if(!IsValidClient(target))
			continue;

		if(IsPlayerAlive(target) && GetClientTeam(target)==bossTeam)
			Rage_New_Weapon(target, FF2_GetBossIndex(client), TEAMWEAPONAMS);
	}
}

public bool SUM_CanInvoke(int client)
{
	return TotalPlayers>Players;
}

public void SUM_Invoke(int client)
{
	Rage_Summon(client, FF2_GetBossIndex(client), SUMMONAMS);
}
#endif

// Intro Overlay

public Action Apply_Overlay(Handle timer, int boss)
{
	int bossTeam = GetClientTeam(GetClientOfUserId(FF2_GetBossUserId(boss)));
	char overlay[MAXMATERIALPATH];
	FF2_GetArgS(boss, this_plugin_name, INTRO, "overlay", 1, overlay, MAXMATERIALPATH);
	Format(overlay, MAXMATERIALPATH, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && (GetClientTeam(target)!=bossTeam || FF2_GetArgI(boss, this_plugin_name, INTRO, "self", 2, 0)))
			ClientCommand(target, overlay);
	}
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
	CreateTimer(FF2_GetArgF(boss, this_plugin_name, INTRO, "duration", 3, 3.25), Remove_Overlay, boss, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Remove_Overlay(Handle timer, int boss)
{
	int bossTeam = GetClientTeam(GetClientOfUserId(FF2_GetBossUserId(boss)));
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && (GetClientTeam(target)!=bossTeam || FF2_GetArgI(boss, this_plugin_name, INTRO, "self", 2, 0)))
			ClientCommand(target, "r_screenoverlay \"\"");
	}
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
	return Plugin_Continue;
}

// Lastmann Backup

public Action Timer_Backup(Handle timer, int boss)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState()!=1)
		return Plugin_Continue;

	if(LastMannBackup[boss] >= FF2_GetArgI(boss, this_plugin_name, LASTBACKUP, "backups", 2, 1))
		return Plugin_Continue;

	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	int weaponMode=FF2_GetArgI(boss, this_plugin_name, LASTBACKUP, "weapon mode", 4, 2);
	char model[MAXMODELPATH];
	FF2_GetArgS(boss, this_plugin_name, LASTBACKUP, "model", 5, model, sizeof(model));
	int class=FF2_GetArgI(boss, this_plugin_name, LASTBACKUP, "class", 6);
	float ratio=FF2_GetArgF(boss, this_plugin_name, LASTBACKUP, "ratio", 7, 0.0);
	char classname[64];
	FF2_GetArgS(boss, this_plugin_name, LASTBACKUP, "classname", 8, classname, sizeof(classname));
	int index=FF2_GetArgI(boss, this_plugin_name, LASTBACKUP, "index", 9, 191);
	char attributes[256];
	FF2_GetArgS(boss, this_plugin_name, LASTBACKUP, "attributes", 10, attributes, sizeof(attributes));
	int ammo=FF2_GetArgI(boss, this_plugin_name, LASTBACKUP, "ammo", 11, -1);
	int clip=FF2_GetArgI(boss, this_plugin_name, LASTBACKUP, "clip", 12, -1);
	char healthformula[MAXFORMULASLENGTH];
	FF2_GetArgS(boss, this_plugin_name, LASTBACKUP, "health", 13, healthformula, MAXFORMULASLENGTH);

	int alive, dead, total;
	Handle players=CreateArray();
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target))
		{
			TFTeam team = TF2_GetClientTeam(target);
			if(team>TFTeam_Spectator && team!=TF2_GetClientTeam(client))
			{
				if(IsPlayerAlive(target))
				{
					alive++;
				}
				else if(FF2_GetBossIndex(target)==-1)  //Don't let dead bosses become clones
				{
					PushArrayCell(players, target);
					dead++;
				}
				total++;
			}
		}
	}

	int health = ParseFormula(boss, healthformula, 0, total);
	int totalMinions = (ratio<1 ? RoundToCeil(total*ratio) : RoundToCeil(ratio));
	int clone, temp, entity;
	bool HasSummoned = false;
	for(int i=1; i<=dead && i<=totalMinions; i++)
	{
		temp = GetRandomInt(0, GetArraySize(players)-1);
		clone = GetArrayCell(players, temp);
		RemoveFromArray(players, temp);

		TF2_RespawnPlayer(clone);

		if(class)
			TF2_SetPlayerClass(clone, view_as<TFClassType>(class), _, false);

		IsBackup[clone] = true;
		HasSummoned = true;

		if(strlen(model))
		{
			SetVariantString(model);
			AcceptEntityInput(clone, "SetCustomModel");
			SetEntProp(clone, Prop_Send, "m_bUseClassAnimations", 1);

			Handle data;
			CreateDataTimer(0.1, Timer_EquipModel, data, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(data, GetClientUserId(clone));
			WritePackString(data, model);
		}

		switch(weaponMode)
		{
			case 0:
			{
				TF2_RemoveAllWeapons(clone);
			}
			case 1:
			{
				TF2_RemoveAllWeapons(clone);
				if(!strlen(classname))
					strcopy(classname, sizeof(classname), "tf_weapon_bottle");

				if(!strlen(attributes))
					strcopy(attributes, sizeof(attributes), "68 ; -1");

				int weapon = FF2_SpawnWeapon(clone, classname, index, 101, 5, attributes);
				if(StrEqual(classname, "tf_weapon_builder") && index!=735)  //PDA, normal sapper
				{
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
				}
				else if(StrEqual(classname, "tf_weapon_sapper") || index==735)  //Sappers, normal sapper
				{
					SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
					SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
				}

				if(IsValidEntity(weapon))
				{
					SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", weapon);
					SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", -1);
				}

				FF2_SetAmmo(clone, weapon, ammo, clip);
			}
		}

		if(health)
		{
			SetEntProp(clone, Prop_Data, "m_iMaxHealth", health);
			SetEntProp(clone, Prop_Data, "m_iHealth", health);
			SetEntProp(clone, Prop_Send, "m_iHealth", health);
		}

		entity = -1;
		while((entity=FindEntityByClassname2(entity, "tf_wear*")) != -1)
		{
			if(clone == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))
			{
				switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
				{
					case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 5607:  //Action slot items
					{
						//NOOP
					}
					default:
					{
						TF2_RemoveWearable(clone, entity);
					}
				}
			}
		}

		entity = -1;
		while((entity=FindEntityByClassname2(entity, "tf_powerup_bottle")) != -1)
		{
			if(clone == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))
				TF2_RemoveWearable(clone, entity);
		}
	}
	CloseHandle(players);

	LastMannBackup[boss]++;

	if(!HasSummoned)
		return Plugin_Continue;

	char message[128];
	if(FF2_GetArgS(boss, this_plugin_name, LASTBACKUP, "message", 14, message, sizeof(message)))
	{
		char icon[64];
		FF2_GetArgS(boss, this_plugin_name, LASTBACKUP, "icon", 15, icon, sizeof(icon));
		int color = FF2_GetArgI(boss, this_plugin_name, LASTBACKUP, "color", 16, view_as<int>(TFTeam_Red));
		if(strlen(icon))
		{
			ShowGameText(0, icon, color, message);
		}
		else
		{
			ShowGameText(0, _, color, message);
		}
	}

	char sound[MAXSOUNDPATH];
	if(FF2_RandomSound(SOUNDBACKUP, sound, MAXSOUNDPATH, boss))
		EmitVoiceToAll(sound);

	return Plugin_Continue;
}

// Team New Weapon

void Rage_New_Weapon(int client, int boss, const char[] ability_name)
{
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	char classname[64], attributes[256];
	FF2_GetArgS(boss, this_plugin_name, ability_name, "classname", 1, classname, sizeof(classname));
	FF2_GetArgS(boss, this_plugin_name, ability_name, "attributes", 3, attributes, sizeof(attributes));

	int slot = FF2_GetArgI(boss, this_plugin_name, ability_name, "weapon slot", 4);
	TF2_RemoveWeaponSlot(client, slot);

	int index = FF2_GetArgI(boss, this_plugin_name, ability_name, "index", 2);
	int weapon = FF2_SpawnWeapon(client, classname, index, FF2_GetArgI(boss, this_plugin_name, ability_name, "level", 8, 101), FF2_GetArgI(boss, this_plugin_name, ability_name, "quality", 9, 7), attributes);
	if(StrEqual(classname, "tf_weapon_builder") && index!=735)  //PDA, normal sapper
	{
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
	}
	else if(StrEqual(classname, "tf_weapon_sapper") || index==735)  //Sappers, normal sapper
	{
		SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
		SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
	}

	if(FF2_GetArgI(boss, this_plugin_name, ability_name, "force switch", 6))
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);

	int ammo = FF2_GetArgI(boss, this_plugin_name, ability_name, "ammo", 5);
	int clip = FF2_GetArgI(boss, this_plugin_name, ability_name, "clip", 7);
	if(ammo || clip)
		FF2_SetAmmo(client, weapon, ammo, clip);
}

// Weighdown

public void PeformSlam(int client)
{
	if(client <= 0)
		return;

	int boss = FF2_GetBossIndex(client);
	if(!FF2_HasAbility(boss, this_plugin_name, WEIGHDOWN))
		return;

	char particle[48];
	if(FF2_GetArgS(boss, this_plugin_name, WEIGHDOWN, "particle", 11, particle, sizeof(particle)))
	{
		int index = -1;
		char attachment[48];
		if(FF2_GetArgS(boss, this_plugin_name, WEIGHDOWN, "attachment", 12, attachment, sizeof(attachment)))
		{
			index = AttachParticleToAttachment(client, particle, attachment);
		}
		else
		{
			index = AttachParticle(client, particle, 70.0, true);
		}

		if(IsValidEntity(index))
			CreateTimer(FF2_GetArgF(boss, this_plugin_name, WEIGHDOWN, "lifetime", 13, 1.0), Timer_RemoveEntity, EntIndexToEntRef(index), TIMER_FLAG_NO_MAPCHANGE);
	}

	float distance = FF2_GetArgF(boss, this_plugin_name, WEIGHDOWN, "range", 20, FF2_GetRageDist(boss, this_plugin_name, WEIGHDOWN));
	if(distance <= 0)
		return;

	#if defined _sdkhooks_included
	float initialDamage = FF2_GetArgF(boss, this_plugin_name, WEIGHDOWN, "damage", 21)/3.0;
	float damage;
	#endif
	bool friendlyFire = view_as<bool>(FF2_GetArgI(boss, this_plugin_name, WEIGHDOWN, "friendly", 22, GetConVarInt(FindConVar("mp_friendlyfire"))));

	char tempString[256];
	FF2_GetArgS(boss, this_plugin_name, WEIGHDOWN, "self condition", 23, tempString, sizeof(tempString));
	if(strlen(tempString))
		SetCondition(client, tempString);

	float tempFloat = FF2_GetArgF(boss, this_plugin_name, WEIGHDOWN, "self stun", 24);
	if(tempFloat > 0)
		TF2_StunPlayer(client, tempFloat, 1.0, TF_STUNFLAGS_NORMALBONK, client);

	tempFloat = FF2_GetArgF(boss, this_plugin_name, WEIGHDOWN, "self ignite", 25);
	if(tempFloat > 0)
	#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=9
		TF2_IgnitePlayer(client, client);
	#else
		TF2_IgnitePlayer(client, client, tempFloat);
	#endif

	FF2_GetArgS(boss, this_plugin_name, WEIGHDOWN, "condition", 26, tempString, sizeof(tempString));
	float stunTime = FF2_GetArgF(boss, this_plugin_name, WEIGHDOWN, "stun", 27);
	tempFloat = FF2_GetArgF(boss, this_plugin_name, WEIGHDOWN, "ignite", 28);
	float knockback = FF2_GetArgF(boss, this_plugin_name, WEIGHDOWN, "knockback", 29);

	float bossPosition[3], targetPosition[3], vectorDistance;
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", bossPosition);

	TempSlam = true;
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && (friendlyFire || GetClientTeam(target)!=GetClientTeam(client)) && target!=client && !IsInvuln(target))
		{
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPosition);
			vectorDistance = GetVectorDistance(bossPosition, targetPosition);
			if(vectorDistance <= distance)
			{
				if(!IsInvuln(target))
				{
					if(tempFloat > 0)
					#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=9
						TF2_IgnitePlayer(target, client);
					#else
						TF2_IgnitePlayer(target, client, tempFloat);
					#endif

					#if defined _sdkhooks_included
					if(initialDamage > 0)
					{
						if(vectorDistance <= 0)
						{
							SDKHooks_TakeDamage(target, client, client, 9001.0, DMG_PREVENT_PHYSICS_FORCE|DMG_CRUSH, -1);
						}
						else
						{
							damage = distance/vectorDistance*initialDamage;
							if(damage > 0)
								SDKHooks_TakeDamage(target, client, client, damage, DMG_PREVENT_PHYSICS_FORCE|DMG_CRUSH, -1);
						}
					}

					if(!IsPlayerAlive(client))
						continue;
					#endif

					TF2_RemoveCondition(target, TFCond_Parachute);

					if(strlen(tempString))
						SetCondition(target, tempString);

					if(stunTime > 0)
						TF2_StunPlayer(target, stunTime, 1.0, TF_STUNFLAGS_NORMALBONK, client);
				}
			}

			if(knockback!=0 && !TF2_IsPlayerInCondition(target, TFCond_MegaHeal))
			{
				static float angles[3];
				static float velocity[3];
				GetVectorAnglesTwoPoints(bossPosition, targetPosition, angles);
				GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(velocity, knockback);
				velocity[2] = 300.0;
				TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, velocity);
			}
		}
	}
	TempSlam = false;
}

// Prevent Rage

public Action Timer_RageBlock(Handle timer, int client)
{
	if(IsValidClient(client))
	{
		RageBlockTimer[client] = GetEngineTime()+FF2_GetArgF(FF2_GetBossIndex(client), this_plugin_name, BLOCKRAGE, "duration", 1, 10.0);
		SDKHook(client, SDKHook_PreThink, RageBlockThink);
	}
	return Plugin_Continue;
}

public void RageBlockThink(int client)
{
	if(GetEngineTime() >= RageBlockTimer[client])
	{
		SDKUnhook(client, SDKHook_PreThink, RageBlockThink);
		return;
	}

	if(IsPlayerAlive(client) && IsBoss(client))
		FF2_SetBossCharge(FF2_GetBossIndex(client), 0, RageBlockCurrent[client]);
}

// Boss Minion

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!IsValidClient(client) || FF2_GetBossIndex(client)>=0)
		return Plugin_Continue;

	if(IsBossMinion[client])
	{
		if(damagetype & DMG_FALL)
			return Plugin_Handled;

		if(IsValidClient(attacker))
		{
			bool bIsBackstab, bIsTelefrag;
			if(damagecustom==TF_CUSTOM_BACKSTAB)
			{
				bIsBackstab=true;
			}
			else if(damagecustom==TF_CUSTOM_TELEFRAG)
			{
				bIsTelefrag=true;
			}
			else if(weapon!=4095 && IsValidEntity(weapon) && weapon==GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee) && damage>1000.0)
			{
				char classname[32];
				if(GetEntityClassname(weapon, classname, sizeof(classname)) && !StrContains(classname, "tf_weapon_knife", false))
				{
					bIsBackstab=true;
				}
			}
			else if(!IsValidEntity(weapon) && (damagetype & DMG_CRUSH)==DMG_CRUSH && damage==1000.0)
			{
				bIsTelefrag=true;
			}

			int index;
			char classname[64];
			if(IsValidEntity(weapon) && weapon>MaxClients && attacker<=MaxClients)
			{
				GetEntityClassname(weapon, classname, sizeof(classname));
				if(!StrContains(classname, "eyeball_boss"))  //Dang spell Monoculuses
				{
					index=-1;
					Format(classname, sizeof(classname), "");
				}
				else
				{
					index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
				}
			}
			else
			{
				index=-1;
				Format(classname, sizeof(classname), "");
			}

			//Sniper rifles aren't handled by the switch/case because of the amount of reskins there are
			if(!StrContains(classname, "tf_weapon_sniperrifle"))
			{
				float charge=(IsValidEntity(weapon) && weapon>MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
				if(index==752)  //Hitman's Heatmaker
				{
					float focus=10+(charge/10);
					if(TF2_IsPlayerInCondition(attacker, TFCond_FocusBuff))
					{
						focus/=3;
					}
					float rage=GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
					SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", (rage+focus>100) ? 100.0 : rage+focus);
				}
				else if(index!=230 && index!=402 && index!=526 && index!=30665)  //Sydney Sleeper, Bazaar Bargain, Machina, Shooting Star
				{
					int current=FF2_GetClientGlow(client);
					float time=(current>10 ? 1.0 : 2.0);
					time+=(current>10 ? (current>20 ? 1.0 : 2.0) : 4.0)*(charge/100.0);
					if(time>25.0)
					{
						time=25.0;
					}
					FF2_SetClientGlow(client, time);
				}

				if(!(damagetype & DMG_CRIT))
				{
					Handle cvar;
					if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed))
					{
						cvar = FindConVar("ff2_sniper_dmg_mini");
						if(cvar == INVALID_HANDLE)
						{
							damage *= 2.2;
						}
						else
						{
							damage *= GetConVarFloat(cvar);
						}
					}
					else
					{
						cvar = FindConVar("ff2_sniper_dmg");
						if(index!=230)  //Sydney Sleeper
						{
							if(cvar == INVALID_HANDLE)
							{
								damage *= 3.0;
							}
							else
							{
								damage *= GetConVarFloat(cvar);
							}
						}
						else
						{
							if(cvar == INVALID_HANDLE)
							{
								damage *= 2.4;
							}
							else
							{
								damage *= GetConVarFloat(cvar)*0.8;
							}
						}
					}
					return Plugin_Changed;
				}
			}
			else if(!StrContains(classname, "tf_weapon_compound_bow") && UnofficialFF2)
			{
				if((damagetype & DMG_CRIT))
				{
					Handle cvar = FindConVar("ff2_sniper_bow");
					if(cvar != INVALID_HANDLE)
					{
						damage *= GetConVarFloat(cvar);
						return Plugin_Changed;
					}
				}
				else if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed))
				{
					Handle cvar = FindConVar("ff2_sniper_bow_mini");
					if(cvar != INVALID_HANDLE)
					{
						if(GetConVarFloat(cvar)>0)
						{
							damage *= GetConVarFloat(cvar);
							return Plugin_Changed;
						}
						cvar = FindConVar("ff2_sniper_bow_non");
						if(cvar != INVALID_HANDLE)
						{
							if(GetConVarFloat(cvar)>0)
							{
								damage *= GetConVarFloat(cvar);
								return Plugin_Changed;
							}
						}
					}
					cvar = FindConVar("ff2_sniper_bow_non");
					if(cvar != INVALID_HANDLE)
					{
						if(GetConVarFloat(cvar)>0)
						{
							damage *= GetConVarFloat(cvar);
							return Plugin_Changed;
						}
					}
				}
				else
				{
					Handle cvar = FindConVar("ff2_sniper_bow_non");
					if(cvar != INVALID_HANDLE)
					{
						if(GetConVarFloat(cvar)>0)
						{
							damage *= GetConVarFloat(cvar);
							return Plugin_Changed;
						}
					}
				}
				return Plugin_Continue;
			}

			switch(index)
			{
				case 61, 1006:  //Ambassador, Festive Ambassador
				{
					Handle cvar = FindConVar("ff2_hardcodewep");
					if(cvar != INVALID_HANDLE)
					{
						if(GetConVarInt(cvar)>1)
							return Plugin_Continue;
					}

					if(damagecustom==TF_CUSTOM_HEADSHOT)
					{
						damage=85.0;  //Final damage 255
						return Plugin_Changed;
					}
				}
				case 132, 266, 482, 1082:  //Eyelander, HHHH, Nessie's Nine Iron, Festive Eyelander
				{
					IncrementHeadCount(attacker);
				}
				case 214:  //Powerjack
				{
					Handle cvar = FindConVar("ff2_hardcodewep");
					if(cvar != INVALID_HANDLE)
					{
						if(GetConVarInt(cvar)>1)
							return Plugin_Continue;
					}

					int health=GetClientHealth(attacker);
					int newhealth=health+25;
					if(newhealth<=GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
						SetEntityHealth(attacker, newhealth);

					if(!UnofficialFF2 && TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
					{
						TF2_RemoveCondition(attacker, TFCond_OnFire);
					}
				}
				case 307:  //Ullapool Caber
				{
					if(UnofficialFF2 && !GetEntProp(weapon, Prop_Send, "m_iDetonated"))	// If using ullapool caber, only trigger if bomb hasn't been detonated
                        		{
						damage = MinionStab[GetClientTeam(client)-2]*GetRandomFloat(0.6, 0.8);
						damagetype |= DMG_CRIT;

						float position[3];
						GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", position);

						EmitSoundToClient(attacker, "ambient/lightsoff.wav", _, _, _, _, 0.6, _, _, position, _, false);
						EmitSoundToClient(client, "ambient/lightson.wav", _, _, _, _, 0.6, _, _, position, _, false);

						return Plugin_Changed;
					}
				}
				case 310:  //Warrior's Spirit
				{
					Handle cvar = FindConVar("ff2_hardcodewep");
					if(cvar != INVALID_HANDLE)
					{
						if(GetConVarInt(cvar)>1)
							return Plugin_Continue;
					}

					int health=GetClientHealth(attacker);
					int newhealth=health+50;
					if(newhealth<=GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
						SetEntityHealth(attacker, newhealth);

					if(!UnofficialFF2 && TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
					{
						TF2_RemoveCondition(attacker, TFCond_OnFire);
					}
				}
				case 317:  //Candycane
				{
					SpawnSmallHealthPackAt(client, GetClientTeam(attacker), attacker);
				}
				case 327:  //Claidheamh Mòr
				{
					Handle cvar = FindConVar("ff2_hardcodewep");
					if(cvar != INVALID_HANDLE)
					{
						if(GetConVarInt(cvar)>1)
							return Plugin_Continue;
					}

					float charge=GetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter");
					if(charge+25.0>=100.0)
					{
						SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", 100.0);
					}
					else
					{
						SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", charge+25.0);
					}
				}
				case 348:  //Sharpened Volcano Fragment
				{
					if(UnofficialFF2)
					{
						Handle cvar = FindConVar("ff2_hardcodewep");
						if(cvar != INVALID_HANDLE)
						{
							if(GetConVarInt(cvar)>1)
								return Plugin_Continue;
						}

						int health=GetClientHealth(attacker);
						int max=GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
						int newhealth=health+5;
						if(health<max+60)
						{
							if(newhealth>max+60)
							{
								newhealth=max+60;
							}
							SetEntityHealth(attacker, newhealth);
						}
					}
				}
				case 357:  //Half-Zatoichi
				{
					int health=GetClientHealth(attacker);
					int max=GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
					int max2=RoundToFloor(max*2.0);
					if(!UnofficialFF2)	// Official only version
					{
						int newhealth=health+50;
						if(health<max2)
						{
							if(newhealth>max2)
							{
								newhealth=max2;
							}
							SetEntityHealth(attacker, newhealth);
						}
						if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(attacker, TFCond_OnFire);
						}
					}
					else if(GetEntProp(weapon, Prop_Send, "m_bIsBloody"))	// Less effective used more than once
					{
						int newhealth=health+25;
						if(health<max2)
						{
							if(newhealth>max2)
							{
								newhealth=max2;
							}
							SetEntityHealth(attacker, newhealth);
						}
					}
					else	// Most effective on first hit
					{
						int newhealth=health+RoundToFloor(max/2.0);
						if(health<max2)
						{
							if(newhealth>max2)
							{
								newhealth=max2;
							}
							SetEntityHealth(attacker, newhealth);
						}
						if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(attacker, TFCond_OnFire);
						}
					}
					SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
					if(GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy")<1)
					{
						SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
					}
				}
				case 416:  //Market Gardener (courtesy of Chdata)
				{
					if(RemoveCond(attacker, TFCond_BlastJumping))
                        		{
						damage = MinionStab[GetClientTeam(client)-2]*GetRandomFloat(0.7, 1.1);
						damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;

						float position[3];
						GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", position);

						EmitSoundToClient(attacker, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);
						EmitSoundToClient(client, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);

						return Plugin_Changed;
					}
				}
				case 525, 595:  //Diamondback, Manmelter
				{
					Handle cvar = FindConVar("ff2_hardcodewep");
					if(cvar != INVALID_HANDLE)
					{
						if(GetConVarInt(cvar)>1)
							return Plugin_Continue;
					}

					if(GetEntProp(attacker, Prop_Send, "m_iRevengeCrits"))  //If a revenge crit was used, give a damage bonus
					{
						damage=85.0;  //255 final damage
						return Plugin_Changed;
					}
				}
				case 528:  //Short Circuit
				{
					Handle cvar = FindConVar("ff2_circuit_stun");
					if(cvar == INVALID_HANDLE)
						return Plugin_Continue;

					if(GetConVarFloat(cvar)<=0)
						return Plugin_Continue;

					TF2_StunPlayer(client, GetConVarFloat(FindConVar("ff2_circuit_stun")), 0.0, TF_STUNFLAGS_SMALLBONK|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
					EmitSoundToAll("weapons/barret_arm_zap.wav", client);
					EmitSoundToClient(client, "weapons/barret_arm_zap.wav");
				}
				case 593:  //Third Degree
				{
					int healers[MAXPLAYERS];
					int healerCount;
					for(int healer; healer<=MaxClients; healer++)
					{
						if(IsValidClient(healer) && IsPlayerAlive(healer) && (GetHealingTarget(healer, true)==attacker))
						{
							healers[healerCount]=healer;
							healerCount++;
						}
					}

					for(int healer; healer<healerCount; healer++)
					{
						if(IsValidClient(healers[healer]) && IsPlayerAlive(healers[healer]))
						{
							int medigun=GetPlayerWeaponSlot(healers[healer], TFWeaponSlot_Secondary);
							if(IsValidEntity(medigun))
							{
								char medigunClassname[64];
								GetEntityClassname(medigun, medigunClassname, sizeof(medigunClassname));
								if(StrEqual(medigunClassname, "tf_weapon_medigun", false))
								{
									float uber=GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")+(0.1/healerCount);
									if(uber>1.0)
									{
										uber=1.0;
									}
									SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", uber);
								}
							}
						}
					}
				}
				case 594:  //Phlogistinator
				{
					Handle cvar = FindConVar("ff2_hardcodewep");
					if(cvar != INVALID_HANDLE)
					{
						if(GetConVarInt(cvar)>1)
							return Plugin_Continue;
					}

					if(!TF2_IsPlayerInCondition(attacker, TFCond_CritMmmph))
					{
						damage/=2.0;
						return Plugin_Changed;
					}
				}
			}

			if(bIsBackstab)
			{
				damage = MinionStab[GetClientTeam(client)-2]*GetRandomFloat(0.8, 1.2);
				damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;
				damagecustom = 0;

				EmitSoundToClient(client, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
				EmitSoundToClient(attacker, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);

				SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+2.0);
				SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime()+2.0);
				SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+2.0);

				int viewmodel=GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
				if(viewmodel>MaxClients && IsValidEntity(viewmodel) && TF2_GetPlayerClass(attacker)==TFClass_Spy)
				{
					int melee = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
					int animation = 42;
					switch(melee)
					{
						case 225, 356, 423, 461, 574, 649, 1071, 30758:  //Your Eternal Reward, Conniver's Kunai, Saxxy, Wanga Prick, Big Earner, Spy-cicle, Golden Frying Pan, Prinny Machete
							animation=16;

						case 638:  //Sharp Dresser
							animation=32;
					}
					SetEntProp(viewmodel, Prop_Send, "m_nSequence", animation);
				}
				switch(index)
				{
					case 225, 574:	// Eternal Reward, Wanga Prick
					{
						RandomlyDisguise(client);
					}
					case 356:	// Conniver's Kunai
					{
						int health=GetClientHealth(attacker)+200;
						if(health>600)
						{
							health=600;
						}
						SetEntProp(attacker, Prop_Data, "m_iHealth", health);

						if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(attacker, TFCond_OnFire);
						}
					}
					case 461:	// Big Earner
					{
						SetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter", 100.0);	//Full cloak
						TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 3.0);  //Speed boost
					}
				}
			
				if(index!=225 && index!=574)  //Your Eternal Reward, Wanga Prick
				{
					float position[3];
					GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", position);

					EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
					EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
				}

				if(GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary)==525)  //Diamondback
					SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", GetEntProp(attacker, Prop_Send, "m_iRevengeCrits")+3);

				return Plugin_Changed;
			}
			else if(bIsTelefrag)
			{
				damagecustom = 0;
				if(!IsPlayerAlive(attacker))
				{
					damage = 1.0;
				}
				else
				{
					damage = 9001.0;
				}
				return Plugin_Changed;
			}
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

stock int GetIndexOfWeaponSlot(int client, int slot)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	return (weapon>MaxClients && IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}

stock void RandomlyDisguise(int client)	// From FF2's built-in random disguise
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		int disguiseTarget = -1;
		int team = UnofficialFF2 ? TF2_GetClientTeam(client)==TFTeam_Red ? view_as<int>(TFTeam_Blue) : view_as<int>(TFTeam_Red) : GetClientTeam(client);

		Handle disguiseArray = CreateArray();
		for(int clientcheck; clientcheck<=MaxClients; clientcheck++)
		{
			if(IsValidClient(clientcheck) && GetClientTeam(clientcheck)==team && clientcheck!=client)
				PushArrayCell(disguiseArray, clientcheck);
		}

		if(GetArraySize(disguiseArray) <= 0)
		{
			disguiseTarget = client;
		}
		else
		{
			disguiseTarget = GetArrayCell(disguiseArray, GetRandomInt(0, GetArraySize(disguiseArray)-1));
			if(!IsValidClient(disguiseTarget))
				disguiseTarget = client;
		}

		int class = GetRandomInt(0, 4);
		TFClassType classArray[] = {TFClass_Scout, TFClass_Pyro, TFClass_Medic, TFClass_Engineer, TFClass_Sniper};
		CloseHandle(disguiseArray);

		if(TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			TF2_DisguisePlayer(client, view_as<TFTeam>(team), classArray[class], disguiseTarget);
		}
		else
		{
			TF2_AddCondition(client, TFCond_Disguised, -1.0);
			SetEntProp(client, Prop_Send, "m_nDisguiseTeam", team);
			SetEntProp(client, Prop_Send, "m_nDisguiseClass", classArray[class]);
			SetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex", disguiseTarget);
			SetEntProp(client, Prop_Send, "m_iDisguiseHealth", 200);
		}
	}
}

stock int SpawnSmallHealthPackAt(int client, int team=0, int attacker)
{
	if(!IsValidClient(client) || !IsPlayerAlive(client))
		return -1;

	int healthpack = CreateEntityByName("item_healthkit_small");
	float position[3];
	GetClientAbsOrigin(client, position);
	position[2] += 20.0;
	if(IsValidEntity(healthpack))
	{
		DispatchKeyValue(healthpack, "OnPlayerTouch", "!self,Kill,,0,-1");
		DispatchSpawn(healthpack);
		SetEntProp(healthpack, Prop_Send, "m_iTeamNum", team, 4);
		SetEntityMoveType(healthpack, MOVETYPE_VPHYSICS);
		float velocity[3];
		velocity[0] = float(GetRandomInt(-10, 10)), velocity[1]=float(GetRandomInt(-10, 10)), velocity[2]=50.0;  //I did this because setting it on the creation of the vel variable was creating a compiler error for me.
		TeleportEntity(healthpack, position, NULL_VECTOR, velocity);
		SetEntPropEnt(healthpack, Prop_Send, "m_hOwnerEntity", attacker);
		return healthpack;
	}
	return -1;
}

stock void IncrementHeadCount(int client)
{
	if(!TF2_IsPlayerInCondition(client, TFCond_DemoBuff))
		TF2_AddCondition(client, TFCond_DemoBuff, -1.0);

	int decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
	int health = GetClientHealth(client);
	SetEntProp(client, Prop_Send, "m_iDecapitations", decapitations+1);
	SetEntityHealth(client, health+15);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
}

stock int GetHealingTarget(int client, bool checkgun=false)
{
	int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(!checkgun)
	{
		if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");

		return -1;
	}

	if(IsValidEntity(medigun))
	{
		char classname[64];
		GetEntityClassname(medigun, classname, sizeof(classname));
		if(!strcmp(classname, "tf_weapon_medigun", false))
		{
			if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
				return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
		}
	}
	return -1;
}

stock bool RemoveCond(int client, TFCond cond)
{
	if(TF2_IsPlayerInCondition(client, cond))
	{
		TF2_RemoveCondition(client, cond);
		return true;
	}
	return false;
}

// Summon

public void Rage_Summon(int client, int boss, const char[] ability_name)
{
	float ratio = FF2_GetArgF(boss, this_plugin_name, ability_name, "ratio", 1);

	static char model[MAXMODELPATH];
	FF2_GetArgS(boss, this_plugin_name, ability_name, "model", 2, model, sizeof(model));

	TFClassType class = view_as<TFClassType>(FF2_GetArgI(boss, this_plugin_name, ability_name, "class", 3));

	static char voiceline[MAXBOSSSOUNDLENGTH];
	FF2_GetArgS(boss, this_plugin_name, ability_name, "voiceline", 4, voiceline, MAXBOSSSOUNDLENGTH);

	static char healthformula[MAXFORMULASLENGTH];
	FF2_GetArgS(boss, this_plugin_name, ability_name, "health", 5, healthformula, MAXFORMULASLENGTH);

	bool overheal = view_as<bool>(FF2_GetArgI(boss, this_plugin_name, ability_name, "overheal", 6));

	float invuln = FF2_GetArgF(boss, this_plugin_name, ability_name, "invuln", 7, 4.0);
	if(invuln > 0)
		invuln += GetEngineTime();

	float pushForce = FF2_GetArgF(boss, this_plugin_name, ability_name, "push", 8, 400.0);

	CloneDeath[client] = view_as<bool>(FF2_GetArgI(boss, this_plugin_name, ability_name, "die on boss death", 9, 1));

	bool cosmetics = view_as<bool>(FF2_GetArgI(boss, this_plugin_name, ability_name, "cosmetics", 10));

	TFTeam team = FF2_GetArgI(boss, this_plugin_name, ability_name, "rival", 11) ? TF2_GetClientTeam(client)==TFTeam_Blue ? TFTeam_Red : TFTeam_Blue : TF2_GetClientTeam(client);

	static float position[3], velocity[3];
	GetEntPropVector(GetClientOfUserId(FF2_GetBossUserId(boss)), Prop_Data, "m_vecOrigin", position);

	// Loadouts and Weapons
	static char temp[MAXABILITYLENGTH];
	static char classname[MAXLOADOUTS][MAXWEAPONS][MAXCLASSNAMELENGTH];
	static int index[MAXLOADOUTS][MAXWEAPONS];
	static char attributes[MAXLOADOUTS][MAXWEAPONS][MAXATTRIBUTELENGTH];
	static int ammo[MAXLOADOUTS][MAXWEAPONS];
	static int clip[MAXLOADOUTS][MAXWEAPONS];
	static char worldmodel[MAXLOADOUTS][MAXWEAPONS][MAXMODELPATH];
	int loadouts, weapons[MAXLOADOUTS];
	bool actionSlotUsed, noMoreWeapons;
	for(int i; i<MAXLOADOUTS; i++)
	{
		for(int ii; ii<MAXWEAPONS; ii++)
		{
			Format(temp, MAXABILITYLENGTH, "classname%i-%i", i+1, ii+1);
			if(!FF2_GetArgS(boss, this_plugin_name, ability_name, temp, (i*100)+(ii*10)+101, classname[i][ii], MAXABILITYLENGTH))
			{
				noMoreWeapons = ii==0;
				break;
			}

			if(!actionSlotUsed && (StrEqual(classname[i][ii], "tf_weapon_grapplinghook") || StrEqual(classname[i][ii], "tf_weapon_spellbook")))
				actionSlotUsed = true;

			weapons[i]++;
			Format(temp, MAXABILITYLENGTH, "index%i-%i", i+1, ii+1);
			index[i][ii] = FF2_GetArgI(boss, this_plugin_name, ability_name, temp, (i*100)+(ii*10)+102);
			Format(temp, MAXABILITYLENGTH, "attributes%i-%i", i+1, ii+1);
			FF2_GetArgS(boss, this_plugin_name, ability_name, temp, (i*100)+(ii*10)+103, attributes[i][ii], MAXATTRIBUTELENGTH);
			Format(temp, MAXABILITYLENGTH, "ammo%i-%i", i+1, ii+1);
			ammo[i][ii] = FF2_GetArgI(boss, this_plugin_name, ability_name, temp, (i*100)+(ii*10)+104, -1);
			Format(temp, MAXABILITYLENGTH, "clip%i-%i", i+1, ii+1);
			clip[i][ii] = FF2_GetArgI(boss, this_plugin_name, ability_name, temp, (i*100)+(ii*10)+105, -1);
			Format(temp, MAXABILITYLENGTH, "model%i-%i", i+1, ii+1);
			FF2_GetArgS(boss, this_plugin_name, ability_name, temp, (i*100)+(ii*10)+106, worldmodel[i][ii], MAXMODELPATH);
		}

		if(noMoreWeapons)
			break;

		loadouts++;
	}

	// Get Dead Targets
	int alive, dead;
	ArrayList players = new ArrayList();
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsValidClient(target))
		{
			if(GetClientTeam(target) > view_as<int>(TFTeam_Spectator))
			{
				if(IsPlayerAlive(target))
				{
					alive++;
				}
				else if(!IsBoss(target))
				{
					players.Push(target);
					dead++;
				}
			}
		}
	}

	// Loop, Spawn, Equip, Etc.
	int totalMinions = (ratio ? ratio>1 ? RoundFloat(ratio) : RoundToCeil(alive*ratio) : MaxClients);
	int health = ParseFormula(boss, healthformula, 125, alive);
	int clone, entity, var1, var2, var3;
	for(int i=1; i<=dead && i<=totalMinions; i++)
	{
		// Delete From Array
		var1 = GetRandomInt(0, players.Length-1);
		clone = players.Get(var1);
		players.Erase(var1);

		// Assign Global Vars
		CloneTeam[clone] = TF2_GetClientTeam(clone);
		CloneOwner[clone] = boss;
		strcopy(CloneVo[clone], MAXBOSSSOUNDLENGTH, voiceline);

		// Team, Flags, Spawn, Class
		FF2_SetFF2flags(clone, FF2_GetFF2flags(clone)|FF2FLAG_ALLOWSPAWNINBOSSTEAM|FF2FLAG_CLASSTIMERDISABLED);
		ChangeClientTeam(clone, view_as<int>(team));
		TF2_RespawnPlayer(clone);
		if(class != TFClass_Unknown)
			TF2_SetPlayerClass(clone, class, _, false);

		// Model
		if(StrEqual("1", model))
		{
			TF2_GetNameOfClass(TF2_GetPlayerClass(clone), temp, MAXNAMELENGTH);
			Format(temp, MAXMODELPATH, "models/bots/%s/bot_%s.mdl", temp, temp);
			ReplaceString(temp, MAXMODELPATH, "demoman", "demo", false);
		}
		else if(StrEqual("2", model))
		{
			strcopy(temp, MAXMODELPATH, RobotBosses[view_as<int>(TF2_GetPlayerClass(clone))]);
		}
		else
		{
			strcopy(temp, MAXMODELPATH, model);
		}

		if(strlen(model) && !StrEqual("0", model))
		{
			PrecacheModel(temp);
			SetVariantString(temp);
			AcceptEntityInput(clone, "SetCustomModel");
			SetEntProp(clone, Prop_Send, "m_bUseClassAnimations", 1);

			DataPack data;
			CreateDataTimer(0.2, Timer_EquipModel, data, TIMER_FLAG_NO_MAPCHANGE);
			data.WriteCell(GetClientUserId(clone));
			data.WriteString(temp);
		}

		// Weapons
		if(loadouts)
		{
			TF2_RemoveAllWeapons(clone);

			var1 = GetRandomInt(0, loadouts-1);
			for(int wep; wep<weapons[var1]; wep++)
			{
				if(!strlen(worldmodel[var1][wep]) || StrEqual("0", worldmodel[var1][wep]))
				{
					var2 = 0;
				}
				else if(StrEqual("1", worldmodel[var1][wep]))
				{
					var2 = 1;
				}
				else
				{
					var2 = 2;
				}

				var3 = FF2_SpawnWeapon(clone, classname[var1][wep], index[var1][wep], 101, GetRandomInt(0, 14), attributes[var1][wep], var2==1);
				if(StrEqual(classname[var1][wep], "tf_weapon_builder") && index[var1][wep]!=735 && index[var1][wep]!=736)  //PDA, normal sapper
				{
					SetEntProp(var3, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
					SetEntProp(var3, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
					SetEntProp(var3, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
					SetEntProp(var3, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
				}
				else if(StrEqual(classname[var1][wep], "tf_weapon_sapper") || index[var1][wep]==735 || index[var1][wep]==736)  //Sappers, normal sapper
				{
					SetEntProp(var3, Prop_Send, "m_iObjectType", 3);
					SetEntProp(var3, Prop_Data, "m_iSubType", 3);
					SetEntProp(var3, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
					SetEntProp(var3, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
					SetEntProp(var3, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
					SetEntProp(var3, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
				}

				FF2_SetAmmo(clone, var3, ammo[var1][wep], clip[var1][wep]);

				if(!wep) // Equip only if it's the first weapon
					SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", var3);

				if(var2 == 2) // Give model is has a model
					ConfigureWorldModelOverride(var3, worldmodel[var1][wep]);
			}
		}

		entity = -1;
		while((entity=FindEntityByClassname2(entity, "tf_wear*")) != -1)
		{
			if(clone == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))
			{
				switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
				{
					case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 928:  //Action slot items
					{
						if(actionSlotUsed)
							TF2_RemoveWearable(clone, entity);
					}
					case 131, 133, 405, 406, 444, 608, 1099, 1144:	// Wearable weapons
					{
						if(loadouts)
							TF2_RemoveWearable(clone, entity);
					}
					default:
					{
						if(!cosmetics)
							TF2_RemoveWearable(clone, entity);
					}
				}
			}
		}

		entity = -1;
		while((entity=FindEntityByClassname2(entity, "tf_powerup_bottle")) != -1)
		{
			if(clone==GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") && (actionSlotUsed || !cosmetics))
				TF2_RemoveWearable(clone, entity);
		}

		if(health > 0)
		{
			if(!overheal)
			{
				CloneHealth[clone] = health;
				CreateTimer(0.2, Timer_SetHealth, GetClientUserId(clone), TIMER_FLAG_NO_MAPCHANGE);
				SDKHook(clone, SDKHook_GetMaxHealth, OnGetMaxHealth);
			}

			SetEntProp(clone, Prop_Data, "m_iHealth", health);
			SetEntProp(clone, Prop_Send, "m_iHealth", health);
		}

		if(pushForce && team==TF2_GetClientTeam(client))
		{
			velocity[0] = GetRandomFloat(0.75, 1.25)*pushForce*(GetRandomInt(0, 1) ? 1:-1);
			velocity[1] = GetRandomFloat(0.75, 1.25)*pushForce*(GetRandomInt(0, 1) ? 1:-1);
			velocity[2] = GetRandomFloat(0.75, 1.25)*pushForce;
			TeleportEntity(clone, position, NULL_VECTOR, velocity);
		}

		if(invuln > 0)
		{
			SDKHook(clone, SDKHook_OnTakeDamage, OnSpawnDamage);
			CloneInvuln[clone] = invuln;
		}
	}
	delete players;
}

/*public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int index, Handle &item)
{
	if(CloneOwner[client]<0 || CloneTeam[client]==TF2_GetClientTeam(client) || CloneWear[client]>6)
		return Plugin_Continue;

	if(StrEqual(classname, "tf_wearable", false))
	{
		switch(index)
		{
			case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 928:  //Action slot items
			{
				if(CloneWear[client] > 3)
					return Plugin_Handled;
			}
			case 131, 133, 405, 406, 444, 608, 1099, 1144:	// Wearable weapons
			{
				if(CloneWear[client]==2 || CloneWear[client]==3 || CloneWear[client]>5)
					return Plugin_Handled;
			}
			default:
			{
				if(!CloneWear[client] || CloneWear[client]%2==0)
					return Plugin_Handled;
			}
		}
	}

	if(StrEqual(classname, "tf_powerup_bottle", false) && (!CloneWear[client] || CloneWear[client]==2 || CloneWear[client]>3))
		return Plugin_Handled;

	return Plugin_Continue;
}*/

public Action OnSpawnDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!IsValidClient(client))
		return Plugin_Continue;

	if(CloneOwner[client]<0 || CloneInvuln[client]<GetEngineTime())
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, OnSpawnDamage);
		return Plugin_Continue;
	}

	if(IsValidClient(attacker))
		return Plugin_Handled;

	int owner = GetClientOfUserId(FF2_GetBossUserId(CloneOwner[client]));
	if(!IsValidClient(owner) || !IsPlayerAlive(owner) || TF2_GetClientTeam(client)!=TF2_GetClientTeam(owner))
		return Plugin_Continue;

	static float position[3];
	GetEntPropVector(owner, Prop_Data, "m_vecOrigin", position);
	TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
	return Plugin_Handled;
}

public Action Timer_SetHealth(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsValidClient(client) || CloneOwner[client]<0)
		return Plugin_Continue;

	SetEntProp(client, Prop_Data, "m_iHealth", CloneHealth[client]);
	SetEntProp(client, Prop_Send, "m_iHealth", CloneHealth[client]);
	return Plugin_Continue;
}

public Action OnGetMaxHealth(int client, int &maxHealth)
{
	maxHealth = CloneHealth[client];
	return Plugin_Changed;
}

// Animation

#if defined _tf2attributes_included
public void AnimationThink(int client)
{
	float engineTime = GetEngineTime();
	if(NextAnimation[client]+6.0 < engineTime) // Give 6 secs to fall down, otherwise cancel the ability
	{
		NextAnimationId[client] = 0;
		NextAnimation[client] = 0.0;
	}

	if((GetEntPropEnt(client, Prop_Send, "m_hGroundEntity")==-1 || NextAnimation[client]>engineTime) && NextAnimation[client] && NextAnimationId[client])
		return;

	if(!tf2attributes || NextAnimationId[client]<=0 || hPlayTaunt==INVALID_HANDLE)
	{
		if(tf2attributes)
			TF2Attrib_RemoveByDefIndex(client, 201);

		TF2_RemoveCondition(client, TFCond_HalloweenKartNoTurn);
		TF2_RemoveCondition(client, TFCond_Taunting);
		SetEntityMoveType(client, MOVETYPE_WALK);
		SDKUnhook(client, SDKHook_PreThink, AnimationThink);
		return;
	}

	int boss = FF2_GetBossIndex(client);
	static char arg[MAXSOUNDPATH];

	Format(arg, MAXARGLENGTH, "taunt%i", NextAnimationId[client]);
	int tauntId = FF2_GetArgI(boss, this_plugin_name, CurrentAnimation[client], arg, (NextAnimationId[client]*10)+1, -1);
	if(tauntId < 0)
	{
		NextAnimationId[client] = 0;
		return;
	}

	Format(arg, MAXARGLENGTH, "speed%i", NextAnimationId[client]);
	TF2Attrib_SetByDefIndex(client, 201, FF2_GetArgF(boss, this_plugin_name, CurrentAnimation[client], arg, (NextAnimationId[client]*10)+2, 1.0));

	if(FF2_GetArgI(boss, this_plugin_name, CurrentAnimation[client], "freeze", 3, 1))
		SetEntityMoveType(client, MOVETYPE_NONE);

	switch(tauntId)
	{
		case 0:
		{
			
		}
		case 1:
		{
			FakeClientCommand(client, "taunt");
		}
		case 2:
		{
			FakeClientCommand(client, "voicemenu 0 2"); // Go Go Go!
		}
		case 3:
		{
			FakeClientCommand(client, "voicemenu 2 6"); // Nice Shot
		}
		case 4:
		{
			FakeClientCommand(client, "voicemenu 2 1"); // Battle Cry
		}
		case 5:
		{
			FakeClientCommand(client, "voicemenu 1 0"); // Incoming!
		}
		default:
		{
			if(ExcuteAnimation(client, tauntId))
			{
				NextAnimationId[client] = 0;
				return;
			}
		}
	}

	Format(arg, MAXARGLENGTH, "time%i", NextAnimationId[client]);
	NextAnimation[client] = engineTime+FF2_GetArgF(boss, this_plugin_name, CurrentAnimation[client], arg, (NextAnimationId[client]*10)+3);

	if(FF2_GetRoundState())
	{
		Format(arg, MAXBOSSSOUNDLENGTH, "%s%i", SOUNDANIMATION, NextAnimationId[client]);
		if(FF2_RandomSound(arg, arg, MAXSOUNDPATH, boss))
			EmitVoiceToAll(arg, client);
	}

	NextAnimationId[client]++;
}

public bool ExcuteAnimation(int client, int tauntId)
{
	int ent = MakeCEIVEnt(client, tauntId);
	if(!IsValidEntity(ent))
	{
		LogError2("[Plugin] Couldn't create entity for taunt for %s", this_plugin_name);
		return true;
	}

	int iCEIVOffset = GetEntSendPropOffs(ent, "m_Item", true);
	if(iCEIVOffset <= 0)
	{
		LogError2("[Plugin] Couldn't find m_Item for taunt item for %s", this_plugin_name);
		return true;
	}

	Address pEconItemView = GetEntityAddress(ent);
	if(pEconItemView == Address_Null)
	{
		LogError2("[Plugin] Couldn't find entity address for taunt item for %s", this_plugin_name);
		return true;
	}

	pEconItemView += view_as<Address>(iCEIVOffset);
	SDKCall(hPlayTaunt, client, pEconItemView);
	AcceptEntityInput(ent, "Kill");
	return false;
}
#endif

// Revive Markers

public bool DropReviveMarker(int client, int team)
{
	#if defined _revivemarkers_included_
	if(revivemarkers)
		return CheckMarkerConditions(client);
	#endif

	if(ReviveLimit[team]>0 && ReviveTimes[client][team]>=ReviveLimit[team])
	{
		if(ReviveSound[team] && ReviveTimes[client][team]==ReviveLimit[team])
		{
			ReviveTimes[client][team]++;
			EmitSoundToClient(client, GAMEOVER, _, _, _, _, GAMEOVER_VOL);
		}
		return false;
	}

	if(ReviveSound[team])
		EmitSoundToClient(client, DEATH, _, _, _, _, DEATH_VOL);

	ChangeClientTeam(client, team+2);
	return SpawnReviveMarker(client, team);
}

public bool SpawnReviveMarker(int client, int team)
{
	int reviveMarker = CreateEntityByName("entity_revive_marker");
	if(reviveMarker != -1)
	{
		SetEntPropEnt(reviveMarker, Prop_Send, "m_hOwner", client); // client index 
		SetEntProp(reviveMarker, Prop_Send, "m_nSolidType", 2); 
		SetEntProp(reviveMarker, Prop_Send, "m_usSolidFlags", 8); 
		SetEntProp(reviveMarker, Prop_Send, "m_fEffects", 16); 
		SetEntProp(reviveMarker, Prop_Send, "m_iTeamNum", team+2); // client team 
		SetEntProp(reviveMarker, Prop_Send, "m_CollisionGroup", 1); 
		SetEntProp(reviveMarker, Prop_Send, "m_bSimulatedEveryTick", 1);
		SetEntDataEnt2(client, FindSendPropInfo("CTFPlayer", "m_nForcedSkin")+4, reviveMarker);
		SetEntProp(reviveMarker, Prop_Send, "m_nBody", view_as<int>(TF2_GetPlayerClass(client)) - 1); // character hologram that is shown
		SetEntProp(reviveMarker, Prop_Send, "m_nSequence", 1); 
		SetEntPropFloat(reviveMarker, Prop_Send, "m_flPlaybackRate", 1.0);
		SetEntProp(reviveMarker, Prop_Data, "m_iInitialTeamNum", team+2);
		SDKHook(reviveMarker, SDKHook_SetTransmit, NoTransmit);

		if(team)
			SetEntityRenderColor(reviveMarker, 0, 0, 255); // make the BLU Revive Marker distinguishable from the red one

		DispatchSpawn(reviveMarker);
		ReviveIndex[client] = EntIndexToEntRef(reviveMarker);
		ReviveMoveAt[client] = GetEngineTime()+0.05;
		if(ReviveLife[team] > 0)
		{
			ReviveGoneAt[client] = GetEngineTime()+ReviveLife[team];
		}
		else
		{
			ReviveGoneAt[client] = FAR_FUTURE;
		}

		SDKHook(client, SDKHook_PreThink, MarkerThink);
		return true;
	}
	return false;
}

public void MarkerThink(int client)
{
	if(ReviveMoveAt[client] < GetEngineTime())
	{
		ReviveMoveAt[client] = FAR_FUTURE;
		if(!IsValidMarker(ReviveIndex[client])) // Oh fiddlesticks, what now..
		{
			SDKUnhook(client, SDKHook_PreThink, MarkerThink);
			return;
		}

		// get position to teleport the Marker to
		static float position[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		TeleportEntity(ReviveIndex[client], position, NULL_VECTOR, NULL_VECTOR);
		SDKHook(ReviveIndex[client], SDKHook_SetTransmit, MarkerTransmit);
		SDKUnhook(ReviveIndex[client], SDKHook_SetTransmit, NoTransmit);
	}
	else if(ReviveGoneAt[client] < GetEngineTime())
	{
		SDKUnhook(client, SDKHook_PreThink, MarkerThink);
		if(!IsValidMarker(ReviveIndex[client]))
			return;

		AcceptEntityInput(ReviveIndex[client], "Kill");
		ReviveIndex[client] = INVALID_ENT_REFERENCE;
	}
}

public Action MarkerTransmit(int entity, int client)
{
	int team = GetEntProp(entity, Prop_Send, "m_iTeamNum");
	if(!ReviveHide[team-2] || !IsPlayerAlive(client) || GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
		return Plugin_Continue;

	if(team != GetClientTeam(client))
		return Plugin_Handled;

	if(ReviveHide[team-2]==2 && TF2_GetPlayerClass(client)!=TFClass_Medic)
		return Plugin_Handled;

	return Plugin_Continue;
}

// Stocks

stock bool ShowGameText(int client, const char[] icon="ico_notify_flag_moving_alt", int color=0, const char[] buffer, any ...)
{
	Handle bf;
	if(!client)
	{
		bf = StartMessageAll("HudNotifyCustom");
	}
	else
	{
		bf = StartMessageOne("HudNotifyCustom", client);
	}

	if(bf == null)
		return false;

	char message[512];
	SetGlobalTransTarget(client);
	VFormat(message, sizeof(message), buffer, 5);
	ReplaceString(message, sizeof(message), "\n", "");

	BfWriteString(bf, message);
	BfWriteString(bf, icon);
	BfWriteByte(bf, color);
	EndMessage();
	return true;
}

stock int FindEntityByClassname2(int startEnt, const char[] classname)
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
	{
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
}

stock void SetCondition(int client, char[] cond)
{
	char conds[32][32];
	int count = ExplodeString(cond, " ; ", conds, sizeof(conds), sizeof(conds));
	if(count <= 0)
		return;

	for(int i=0; i<count; i+=2)
	{
		TF2_AddCondition(client, view_as<TFCond>(StringToInt(conds[i])), StringToFloat(conds[i+1]));
	}
}

stock void TF2_GetNameOfClass(TFClassType class, char[] name, int maxlen) // Retrieves player class name
{
	switch(class)
	{
		case TFClass_Scout: Format(name, maxlen, "scout");
		case TFClass_Soldier: Format(name, maxlen, "soldier");
		case TFClass_Pyro: Format(name, maxlen, "pyro");
		case TFClass_DemoMan: Format(name, maxlen, "demoman");
		case TFClass_Heavy: Format(name, maxlen, "heavy");
		case TFClass_Engineer: Format(name, maxlen, "engineer");
		case TFClass_Medic: Format(name, maxlen, "medic");
		case TFClass_Sniper: Format(name, maxlen, "sniper");
		case TFClass_Spy: Format(name, maxlen, "spy");
	}
}

stock int MakeCEIVEnt(int client, int itemdef, int particle=0)
{
	static Handle hItem;
	if(hItem == INVALID_HANDLE)
	{
		hItem = TF2Items_CreateItem(OVERRIDE_ALL|PRESERVE_ATTRIBUTES|FORCE_GENERATION);
		TF2Items_SetClassname(hItem, "tf_wearable_vm");
		TF2Items_SetQuality(hItem, 6);
		TF2Items_SetLevel(hItem, 1);
	}

	TF2Items_SetItemIndex(hItem, itemdef);
	TF2Items_SetNumAttributes(hItem, particle ? 1 : 0);
	if(particle)
		TF2Items_SetAttribute(hItem, 0, 2041, float(particle));

	return TF2Items_GiveNamedItem(client, hItem);
}

public Action Timer_EquipModel(Handle timer, any pack)
{
	ResetPack(pack);
	int client=GetClientOfUserId(ReadPackCell(pack));
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		char model[MAXMODELPATH];
		ReadPackString(pack, model, MAXMODELPATH);
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

stock void Operate(ArrayList sumArray, int &bracket, float value, ArrayList _operator)
{
	float sum = sumArray.Get(bracket);
	switch(_operator.Get(bracket))
	{
		case Operator_Add:
		{
			sumArray.Set(bracket, sum+value);
		}
		case Operator_Subtract:
		{
			sumArray.Set(bracket, sum-value);
		}
		case Operator_Multiply:
		{
			sumArray.Set(bracket, sum*value);
		}
		case Operator_Divide:
		{
			if(!value)
			{
				LogError2("[Boss] Detected a divide by 0!");
				bracket = 0;
				return; 
			}
			sumArray.Set(bracket, sum/value);
		}
		case Operator_Exponent:
		{
			sumArray.Set(bracket, Pow(sum, value));
		}
		default:
		{
			sumArray.Set(bracket, value);  //This means we're dealing with a constant
		}
	}
	_operator.Set(bracket, Operator_None);
}

stock void OperateString(ArrayList sumArray, int &bracket, char[] value, int size, ArrayList _operator)
{
	if(!StrEqual(value, ""))  //Make sure 'value' isn't blank
	{
		Operate(sumArray, bracket, StringToFloat(value), _operator);
		strcopy(value, size, "");
	}
}

public int ParseFormula(int boss, const char[] key, int defaultValue, int playing)
{
	char formula[MAXFORMULASLENGTH], bossName[64];
	GetBossName(boss, bossName, sizeof(bossName));
	strcopy(formula, sizeof(formula), key);
	int size=1;
	int matchingBrackets;
	for(int i; i<=strlen(formula); i++)  //Resize the arrays once so we don't have to worry about it later on
	{
		if(formula[i]=='(')
		{
			if(!matchingBrackets)
			{
				size++;
			}
			else
			{
				matchingBrackets--;
			}
		}
		else if(formula[i]==')')
		{
			matchingBrackets++;
		}
	}

	ArrayList sumArray=CreateArray(_, size), _operator=CreateArray(_, size);
	int bracket;  //Each bracket denotes a separate sum (within parentheses).  At the end, they're all added together to achieve the actual sum
	sumArray.Set(0, 0.0);
	_operator.Set(bracket, Operator_None);

	char character[2], value[16];
	for(int i; i<=strlen(formula); i++)
	{
		character[0]=formula[i];  //Find out what the next char in the formula is
		switch(character[0])
		{
			case ' ', '\t':  //Ignore whitespace
			{
				continue;
			}
			case '(':
			{
				bracket++;  //We've just entered a new parentheses so increment the bracket value
				sumArray.Set(bracket, 0.0);
				_operator.Set(bracket, Operator_None);
			}
			case ')':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				if(_operator.Get(bracket) != Operator_None)
				{
					LogError2("[Boss] %s's %s formula has an invalid operator at character %i", bossName, key, i+1);
					delete sumArray;
					delete _operator;
					return defaultValue;
				}

				if(--bracket<0)  //Something like (5))
				{
					LogError2("[Boss] %s's %s formula has an unbalanced parentheses at character %i", bossName, key, i+1);
					delete sumArray;
					delete _operator;
					return defaultValue;
				}

				Operate(sumArray, bracket, sumArray.Get(bracket+1), _operator);
			}
			case '\0':  //End of formula
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
			}
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.':
			{
				StrCat(value, sizeof(value), character);  //Constant?  Just add it to the current value
			}
			case 'n', 'x':  //n and x denote player variables
			{
				Operate(sumArray, bracket, float(playing), _operator);
			}
			case '+', '-', '*', '/', '^':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				switch(character[0])
				{
					case '+':
						_operator.Set(bracket, Operator_Add);

					case '-':
						_operator.Set(bracket, Operator_Subtract);

					case '*':
						_operator.Set(bracket, Operator_Multiply);

					case '/':
						_operator.Set(bracket, Operator_Divide);

					case '^':
						_operator.Set(bracket, Operator_Exponent);
				}
			}
		}
	}

	float result = sumArray.Get(0);
	delete sumArray;
	delete _operator;
	if(result <= 0)
	{
		LogError2("[Boss] %s has an invalid %s formula, using default health!", bossName, key);
		return defaultValue;
	}
	return RoundFloat(result);
}

stock bool ConfigureWorldModelOverride(int entity, const char[] model, bool wearable=false)
{
	if(!FileExists(model, true))
		return false;

	int modelIndex = PrecacheModel(model);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 0);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 1);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 2);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 3);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", (!wearable ? GetEntProp(entity, Prop_Send, "m_iWorldModelIndex") : GetEntProp(entity, Prop_Send, "m_nModelIndex")), _, 0);
	return true;
}

public Action NoTransmit(int entity, int client)
{
	return Plugin_Handled;
}

stock bool IsValidMarker(int marker)
{
	if(IsValidEntity(marker))
	{
		static char buffer[128];
		GetEntityClassname(marker, buffer, sizeof(buffer));
		if(!strcmp(buffer, "entity_revive_marker", false))
			return true;
	}
	return false;
}

stock bool IsInvuln(int client)
{
	if(!IsValidClient(client))	
		return true;

	return (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(client, TFCond_Bonked) ||
		TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode) ||
		!GetEntProp(client, Prop_Data, "m_takedamage"));
}

stock bool IsValidClient(int client, bool replaycheck=true)
{
	if(client<=0 || client>MaxClients)
		return false;

	if(!IsClientInGame(client))
		return false;

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck && (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;

	return true;
}

stock bool IsBoss(int client, bool replaycheck=true)
{
	if(!IsValidClient(client, replaycheck))
		return false;

	return FF2_GetBossIndex(client)>=0;
}

// Sarysa Stocks

stock int AttachParticle(int entity, const char[] particleType, float offset=0.0, bool attach=true)
{
	int particle = CreateEntityByName("info_particle_system");
	
	if(!IsValidEntity(particle))
		return -1;

	char targetName[128];
	float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2] += offset;
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

stock int AttachParticleToAttachment(int entity, const char[] particleType, const char[] attachmentPoint) // m_vecAbsOrigin. you're welcome.
{
	int particle = CreateEntityByName("info_particle_system");
	
	if(!IsValidEntity(particle))
		return -1;

	char targetName[128];
	float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	AcceptEntityInput(particle, "SetParent", particle, particle, 0);
	SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	
	SetVariantString(attachmentPoint);
	AcceptEntityInput(particle, "SetParentAttachment");

	if(strlen(particleType))
	{
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
	}
	return particle;
}

public Action Timer_RemoveEntity(Handle timer, any entid)
{
	int entity = EntRefToEntIndex(entid);
	if(IsValidEdict(entity) && entity>MaxClients)
	{
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR); // send it away first in case it feels like dying dramatically
		AcceptEntityInput(entity, "Kill");
	}
}

stock float GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	//tmpVec[0] = startPos[0] - endPos[0];
	//tmpVec[1] = startPos[1] - endPos[1];
	//tmpVec[2] = startPos[2] - endPos[2];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}

//	Backward Complability Stocks

stock bool GetBossName(int boss=0, char[] buffer, int bufferLength, int bossMeaning=0, int client=0)
{
	#if defined _FFBAT_included
	if(UnofficialFF2)
		return FF2_GetBossName(boss, buffer, bufferLength, bossMeaning, client);
	#endif
	return FF2_GetBossSpecial(boss, buffer, bufferLength, bossMeaning);
}

stock void LogError2(const char[] message, any ...)
{
	char buffer[MAX_BUFFER_LENGTH], buffer2[MAX_BUFFER_LENGTH];
	Format(buffer, sizeof(buffer), "%s", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 2);

	#if defined _FFBAT_included
	if(UnofficialFF2)
	{
		FF2_LogError(buffer2);
	}
	else
	{
		LogError(buffer2);
	}
	#else
	LogError(buffer2);
	#endif
}

stock void EmitVoiceToAll(const char[] sample, int entity=SOUND_FROM_PLAYER)
{
	#if defined _FFBAT_included
	if(UnofficialFF2)
	{
		FF2_EmitVoiceToAll(sample, entity);
	}
	else
	{
		EmitSoundToAll(sample, entity);
	}
	#else
	EmitSoundToAll(sample, entity);
	#endif
}

//#file "FF2 Subplugin: Bat's Public Pack"
