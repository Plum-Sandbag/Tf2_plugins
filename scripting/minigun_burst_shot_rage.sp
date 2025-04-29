#pragma semicolon 1
#include <sourcemod>

#include <dhooks>
#include <sdkhooks>
#include <tf2attributes>
#include <tf2>

#pragma newdecls required

#include <stocksoup/math>
#include <stocksoup/tf/entity_prop_stocks>
#include <stocksoup/var_strings>
#include <stocksoup/memory>
//#include <custom_status_hud>
#include <sourcescramble>


enum BoostState {
	Boost_None,
	Boost_Prestart,
	Boost_Starting,
	Boost_Active,
	Boost_ResetState
}

#define TALOS_BOOST_ACTIVATE_DELAY 1.5



BoostState g_BoostState[MAXPLAYERS + 1];
float g_flStateTransitionTime[MAXPLAYERS + 1];
float g_flNextAllowedBoostTime[MAXPLAYERS + 1];

float g_flBoostActivateTime[MAXPLAYERS + 1];
float g_flBoostPenaltyExpired[MAXPLAYERS + 1];
float g_flBoostPenaltyDecayRate[MAXPLAYERS + 1];

// minigun weapon states
enum eMinigunState {
	AC_STATE_IDLE = 0,
	AC_STATE_STARTFIRING,
	AC_STATE_FIRING,
	AC_STATE_SPINNING,
	AC_STATE_DRYFIRE
};

MemoryPatch g_PatchDisableHeavyRageKnockback;
MemoryPatch g_PatchDisableSlownessFromHeavyRage;

Handle g_DHookRemoveAmmo;
//Handle dtMinigunActivatePushBack;

public void OnPluginStart() {
	Handle hGameConf = LoadGameConfigFile("tf2.cattr_starterpack");
	if (!hGameConf) {
		SetFailState("Failed to load gamedata (tf2.cattr_starterpack).");
	}

	g_PatchDisableHeavyRageKnockback = MemoryPatch.CreateFromConf(hGameConf,
			"CTFPlayer::ApplyPushFromDamage()::NoHeavyKnockbackRage");
	if (!g_PatchDisableHeavyRageKnockback.Validate()) {
		SetFailState("Could not verify patch for "
				... "CTFPlayer::ApplyPushFromDamage()::NoHeavyKnockbackRage");
	}

	g_PatchDisableSlownessFromHeavyRage = MemoryPatch.CreateFromConf(hGameConf,
			"CTFWeaponBase::ApplyOnHitAttributes()::RemoveSlowness");
	if (!g_PatchDisableSlownessFromHeavyRage.Validate()) {
		SetFailState("Could not verify patch for "
				... "CTFWeaponBase::ApplyOnHitAttributes()::RemoveSlowness");
	}

	Handle dtApplyPushFromDamage = DHookCreateFromConf(hGameConf,
			"CTFPlayer::ApplyPushFromDamage()");
	DHookEnableDetour(dtApplyPushFromDamage, false, OnApplyPushFromDamagePre);

	g_DHookRemoveAmmo = DHookCreateFromConf(hGameConf, "CTFPlayer::RemoveAmmo()");
	
//	dtMinigunActivatePushBack = DHookCreateFromConf(hGameConf,
//			"CTFMinigun::ActivatePushBackAttackMode()");
//	DHookEnableDetour(dtMinigunActivatePushBack, false, OnMinigunActivatePushBackPre);
	GameData gamedata = new GameData("tf2.cattr_starterpack");
	DHook_CreateDetour(gamedata, "CTFMinigun::ActivatePushBackAttackMode()", OnMinigunActivatePushBackPre, _);
	delete hGameConf;
	
	HookEvent("player_spawn", OnPlayerSpawn);
}


public void OnMapStart() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
	
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_flBoostPenaltyDecayRate[client] = 0.0;
}

public void OnClientPutInServer(int client) {
	g_flNextAllowedBoostTime[client] = 0.0;
	g_flStateTransitionTime[client] = 0.0;
	
	SDKHook(client, SDKHook_PostThinkPost, OnClientPostThinkPost);

	DHookEntity(g_DHookRemoveAmmo, false, client, .callback = OnPlayerRemoveAmmo);
}

public MRESReturn OnApplyPushFromDamagePre(int client, Handle hParams) {
	g_PatchDisableHeavyRageKnockback.Disable();
	
	Address pTakeDamageInfo = DHookGetParam(hParams, 1);
	int weapon = LoadEntityHandleFromAddress(pTakeDamageInfo + view_as<Address>(0x2C));
	
	if(!HasGenerateRageOnDamage(weapon)) {
		return MRES_Ignored;
	}

	if(TF2Attrib_HookValueFloat(1.0, "minigun_burst_shot_rage", weapon) != 1.0) {
		return MRES_Ignored;
	}
	
	g_PatchDisableHeavyRageKnockback.Enable();
	g_PatchDisableSlownessFromHeavyRage.Enable();
	return MRES_Ignored;
}

public MRESReturn OnMinigunActivatePushBackPre(int minigun) {
	int owner = TF2_GetEntityOwner(minigun);
	if (!IsValidEntity(owner)) {
		return MRES_Ignored;
	}
	
	if(TF2Attrib_HookValueFloat(1.0, "minigun_burst_shot_rage", minigun) != 1.0) {
		float numaa = TF2Attrib_HookValueFloat(1.0, "minigun_burst_shot_rage", minigun);
		PrintToChat(owner, "%f",numaa);
		return MRES_Ignored;
	}
	
	
//	char buffer[128];
//	if (!TF2CustAttr_GetString(minigun, "minigun burst shot rage", buffer, sizeof(buffer))) {
//		return MRES_Ignored;
//	}
	
	ActivateBurstMode(owner);
	return MRES_Supercede;
}


public void OnPlayerRunCmdPost(int client, int buttons) {
	if (buttons & IN_RELOAD == 0) {
		return;
	}
	
	int weapon = TF2_GetClientActiveWeapon(client);
	if (!IsValidEntity(weapon)) {
		return;
	}

	if(TF2Attrib_HookValueFloat(1.0, "minigun_burst_shot_rage", weapon) != 1.0) {
		PrintToChat(client, "fuck2");
		return;
	}

//	char buffer[16];
//	if (!TF2CustAttr_GetString(weapon, "minigun burst shot rage", buffer, sizeof(buffer))) {
//		return;
//	}
	
	ActivateBurstMode(client);
}

void ActivateBurstMode(int client) {
	float flRageMeter = GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
	if (flRageMeter < 100.0 || g_BoostState[client]) {
		return;
	}
	
	g_BoostState[client] = Boost_Prestart;
}

public void OnClientPostThinkPost(int client) {
	int primaryWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(!IsValidEntity(primaryWeapon)) return;
	static char classname[32];
	if(!GetEntityClassname(primaryWeapon, classname, sizeof(classname)) || StrContains(classname, "tf_weapon_minigun", false)) return;
//	char attr[128];
	if (g_BoostState[client] != Boost_None) {
//		TF2CustAttr_GetString(primaryWeapon, "minigun burst shot rage", attr, sizeof(attr));
	}
	
	float flRageMeter = GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
	bool bRageDraining = !!GetEntProp(client, Prop_Send, "m_bRageDraining");
	
	if (!bRageDraining && flRageMeter < 100.0) {
		for (int i; i < 3 && flRageMeter < 100.0; i++) {
			int weapon = GetPlayerWeaponSlot(client, i);
			if (!IsValidEntity(weapon)) {
				continue;
			}
			
			// rage is to 100
			flRageMeter += (GetGameFrameTime() / 200) * 100.0;
		}
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", flRageMeter);
	}
	
	// I don't even know
	// trying to maintain boost states is awkward
	
	switch (g_BoostState[client]) {
		case Boost_None: {
			// not in boosted state
			// TODO properly deal with fire rate penalties
			if (g_flBoostPenaltyDecayRate[client]) {
				// we have a penalty being applied
				Address pAttr = TF2Attrib_GetByName(primaryWeapon, "fire rate bonus HIDDEN");
				if (pAttr) {
					float flNewRate = TF2Attrib_GetValue(pAttr)
						- (g_flBoostPenaltyDecayRate[client] * GetGameFrameTime());
					TF2Attrib_SetValue(pAttr, flNewRate);
					TF2Attrib_ClearCache(primaryWeapon);
					
					if (GetGameTime() > g_flBoostPenaltyExpired[client]) {
						TF2Attrib_RemoveByName(primaryWeapon, "fire rate bonus HIDDEN");
						UpdateWeaponResetParity(primaryWeapon);
						g_flBoostPenaltyDecayRate[client] = 0.0;
					}
				}
			}
		}
		case Boost_Prestart: {
			// player activated boost, begin charging, transition to starting state

			
			g_flBoostActivateTime[client] = GetGameTime() + TALOS_BOOST_ACTIVATE_DELAY;
			
			// disable next attack if it's sooner than our activation time
			float flNextAttack =
					GetEntPropFloat(primaryWeapon, Prop_Data, "m_flNextPrimaryAttack");
			if (g_flBoostActivateTime[client] > flNextAttack) {
				SetEntPropFloat(primaryWeapon, Prop_Data, "m_flNextPrimaryAttack",
						g_flBoostActivateTime[client]);
			}
			
			// roll it back to startfiring to disable the weapon temporarily while "charging"
			if (GetEntProp(primaryWeapon, Prop_Send, "m_iWeaponState") > AC_STATE_STARTFIRING) {
				SetEntProp(primaryWeapon, Prop_Send, "m_iWeaponState", AC_STATE_STARTFIRING);
			}
			g_BoostState[client]++;
		}
		case Boost_Starting: {
			// disable next attack if it's sooner than our activation time
			float flNextAttack =
					GetEntPropFloat(primaryWeapon, Prop_Data, "m_flNextPrimaryAttack");
			if (g_flBoostActivateTime[client] > flNextAttack) {
				SetEntPropFloat(primaryWeapon, Prop_Data, "m_flNextPrimaryAttack",
						g_flBoostActivateTime[client]);
			}
			
			// transition to active boost if we're activated
			if (g_flBoostActivateTime[client] && GetGameTime() > g_flBoostActivateTime[client]
					&& !bRageDraining) {

				SetEntProp(client, Prop_Send, "m_bRageDraining", true);
				
				UpdateWeaponResetParity(primaryWeapon);
				
//				float flFireBonus = ReadFloatVar(attr, "mult_postfiredelay", 1.0);
				float flFireBonus = 0.5;
				TF2Attrib_SetByName(primaryWeapon, "fire rate bonus HIDDEN", flFireBonus);
				
//				float flSpreadScale = ReadFloatVar(attr, "mult_spread", 1.0);
				float flSpreadScale = 0.35; 
				TF2Attrib_SetByName(primaryWeapon, "spread penalty", flSpreadScale);
//				TF2Attrib_SetByName(primaryWeapon, "apply look velocity on damage", 100.0);
//				TF2Attrib_SetByDefIndex(primaryWeapon, 4367, 600.0);
//				TF2Attrib_SetByDefIndex(primaryWeapon, 4370, 600.0);
				TF2Attrib_SetByName(primaryWeapon, "dmg penalty vs players", 2.15);
				g_BoostState[client]++;
			}
		}
		case Boost_Active: {
			// transition to boost disabled if rage isn't draining
			if (!bRageDraining) {

				TF2Attrib_RemoveByName(primaryWeapon, "fire rate bonus HIDDEN");
				TF2Attrib_RemoveByName(primaryWeapon, "spread penalty");
//				TF2Attrib_RemoveByName(primaryWeapon, "apply look velocity on damage");
//				TF2Attrib_RemoveByDefIndex(primaryWeapon, 4367);
//				TF2Attrib_RemoveByDefIndex(primaryWeapon, 4370);
				TF2Attrib_RemoveByName(primaryWeapon, "dmg penalty vs players");
				// fix sound breakage after fire rate bonus attribute is cleared
				UpdateWeaponResetParity(primaryWeapon);
				
				g_flBoostActivateTime[client] = 0.0;
				
//				float flRechargeTime = ReadFloatVar(attr, "recharge_period", 0.0);
				float flRechargeTime = 3.5;
				if (flRechargeTime > 0.0) {
					
//					float flFirePenalty = ReadFloatVar(attr, "fire_delay_recharge", 1.0);
					float flFirePenalty = 1.5;
					TF2Attrib_SetByName(primaryWeapon, "fire rate bonus HIDDEN", flFirePenalty);
					
					float flDecayAmount = (flFirePenalty - 1.0); // 0.25 -> 1.0 = -0.75
					// subtract -0.75 * GetGameFrameTime() until expired ??
					
					g_flBoostPenaltyDecayRate[client] = flDecayAmount / flRechargeTime;
					g_flBoostPenaltyExpired[client] = GetGameTime() + flRechargeTime;
				}
				
				g_BoostState[client] = Boost_None;
			}
		}
	}
}

public MRESReturn OnPlayerRemoveAmmo(int client, Handle hReturn, Handle hParams) {
	if (g_BoostState[client] != Boost_Active) {
		return MRES_Ignored;
	}
	
	int primaryWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if (!IsValidEntity(primaryWeapon)) {
		return MRES_Ignored;
	}
	
	int ammoType = DHookGetParam(hParams, 2);
	if (ammoType != GetEntProp(primaryWeapon, Prop_Send, "m_iPrimaryAmmoType")) {
		return MRES_Ignored;
	}
	
	if(TF2Attrib_HookValueFloat(1.0, "minigun_burst_shot_rage", primaryWeapon) != 1.0) {
		PrintToChat(client,"fuck3");
		return MRES_Ignored;
	}
	
//	char attr[64];
//	if (!TF2CustAttr_GetString(primaryWeapon, "minigun burst shot rage", attr, sizeof(attr))) {
//		return MRES_Ignored;
//	}
//	int ammoPerShot = ReadIntVar(attr, "ammo_per_shot", 1);
	int ammoPerShot = 2;
	DHookSetParam(hParams, 1, ammoPerShot);
	return MRES_ChangedHandled;
}

void UpdateWeaponResetParity(int weapon) {
	SetEntProp(weapon, Prop_Send, "m_bResetParity",
			!GetEntProp(weapon, Prop_Send, "m_bResetParity"));
}



static void DHook_CreateDetour(GameData gamedata, const char[] name, DHookCallback preCallback = INVALID_FUNCTION, DHookCallback postCallback = INVALID_FUNCTION)
{
	Handle detour = DHookCreateFromConf(gamedata, name);
	if (!detour)
	{
		LogError("Failed to create detour: %s", name);
	}
	else
	{
		if (preCallback != INVALID_FUNCTION)
			if (!DHookEnableDetour(detour, false, preCallback))
				LogError("Failed to enable pre detour: %s", name);
		
		if (postCallback != INVALID_FUNCTION)
			if (!DHookEnableDetour(detour, true, postCallback))
				LogError("Failed to enable post detour: %s", name);
		
		delete detour;
	}
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;

	return IsClientInGame(client);
}

stock bool HasGenerateRageOnDamage(int weapon) {
	// going to assume this is applied on runtime
	if(IsValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_AttributeList"))
		return !!TF2Attrib_GetByName(weapon, "generate rage on damage");
	else
		return false;
}