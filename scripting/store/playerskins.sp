#if defined STANDALONE_BUILD
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <store>
#include <zephstocks>
#include <freak_fortress_2>
#include <clientprefs>
//#include <datapack>


new GAME_TF2 = false;
#endif


bool g_bSdkStarted = false;
Handle g_hSdkEquipWearable;

#define EF_BONEMERGE            (1 << 0)
#define EF_NOSHADOW             (1 << 4)
#define EF_BONEMERGE_FASTCULL   (1 << 7)
#define EF_PARENT_ANIMATES      (1 << 9)
#define BLUE_sign "models/player/items/all_class/blue_sign.mdl"
#define RED_sign "models/player/items/all_class/red_sign.mdl"


native bool:ZR_IsClientZombie(client);
new bool:g_bZombieMode = false;
new bool:RestoreHat[MAXPLAYERS+1];
new HasArms[MAXPLAYERS+1];
new String:TheArms[MAXPLAYERS+1][PLATFORM_MAX_PATH];
//new Weapondata[MAXPLAYERS+1];

enum PlayerSkin
{
	String:szModel[PLATFORM_MAX_PATH],
	String:szArms[PLATFORM_MAX_PATH],
	iSkin,
	bool:bTemporary,
	iClass,
//	iTeam,
	nModelIndex

}

new g_iPlayerBGroups[MAXPLAYERS+1];

new g_ePlayerSkins[STORE_MAX_ITEMS][PlayerSkin];

new g_iPlayerSkins = 0;
new g_iTempSkins[MAXPLAYERS+1];

new g_cvarSkinChangeInstant = -1;
new g_cvarSkinForceChange = -1;
new g_cvarSkinForceChangeCT = -1;
new g_cvarSkinForceChangeT = -1;
new g_cvarSkinDelay = -1;

new g_Equipped[MAXPLAYERS+1][9];

//new Handle:g_SkinHatCookie = INVALID_HANDLE;

new bool:g_bTForcedSkin = false;
new bool:g_bCTForcedSkin = false;

#if defined STANDALONE_BUILD
public OnPluginStart()
#else
public PlayerSkins_OnPluginStart()
#endif
{
#if defined STANDALONE_BUILD
	new String:m_szGameDir[32];
	GetGameFolderName(m_szGameDir, sizeof(m_szGameDir));
	
	if(strcmp(m_szGameDir, "tf")==0)
		GAME_TF2 = true;
		
	LoadTranslations("store.phrases");
#endif
	
	Store_RegisterHandler("playerskin", "model", PlayerSkins_OnMapStart, PlayerSkins_Reset, PlayerSkins_Config, PlayerSkins_Equip, PlayerSkins_Remove, true);
	Store_RegisterHandler("playerskin_temp", "model", PlayerSkins_OnMapStart, PlayerSkins_Reset, PlayerSkins_Config, PlayerSkins_Equip, PlayerSkins_Remove, false);

	g_cvarSkinChangeInstant = RegisterConVar("sm_store_playerskin_instant", "0", "Defines whether the skin should be changed instantly or on next spawn.", TYPE_INT);
	g_cvarSkinForceChange = RegisterConVar("sm_store_playerskin_force_default", "0", "If it's set to 1, default skins will be enforced.", TYPE_INT);
	g_cvarSkinForceChangeCT = RegisterConVar("sm_store_playerskin_default_ct", "", "Path of the default CT skin.", TYPE_STRING);
	g_cvarSkinForceChangeT = RegisterConVar("sm_store_playerskin_default_t", "", "Path of the default T skin.", TYPE_STRING);
	g_cvarSkinDelay = RegisterConVar("sm_store_playerskin_delay", "-1", "Delay after spawn before applying the skin. -1 means no delay", TYPE_FLOAT);
	
//	g_SkinHatCookie = RegClientCookie("sm_store_skinhat", "Player Skin's Hat", CookieAccess_Protected);
	
	HookEvent("player_spawn", PlayerSkins_PlayerSpawn);
	HookEvent("player_death", PlayerSkins_PlayerDeath);
	HookEvent("post_inventory_application", Event_EquipItem, EventHookMode_Post);
//	HookEvent("teamplay_round_win", OnRoundEnd);

//	TF2_SdkStartup();

	g_bZombieMode = (FindPluginByFile("zombiereloaded")==INVALID_HANDLE?false:true);
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
			PlayerSkins_OnClientPutInServer(i);
	}
	
}

#if defined STANDALONE_BUILD
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("ZR_IsClientZombie");
	return APLRes_Success;
} 
#endif

/*public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(RestoreHat[i])
			{
				HasArms[i] = 0;
				TheArms[i] = "";
				RemoveValveHat(i ,true);
				RestoreHat[i] = false;
			}
		}
	}
}*/

public PlayerSkins_OnMapStart()
{
	PrecacheModel(BLUE_sign, true);
	PrecacheModel(RED_sign, true);
	AddFileToDownloadsTable(BLUE_sign);
	AddFileToDownloadsTable("models/player/items/all_class/blue_sign.dx80.vtx");
	AddFileToDownloadsTable("models/player/items/all_class/blue_sign.dx90.vtx");
	AddFileToDownloadsTable("models/player/items/all_class/blue_sign.sw.vtx");
	AddFileToDownloadsTable("models/player/items/all_class/blue_sign.vvd");
	AddFileToDownloadsTable(RED_sign);
	AddFileToDownloadsTable("models/player/items/all_class/red_sign.dx80.vtx");
	AddFileToDownloadsTable("models/player/items/all_class/red_sign.dx90.vtx");
	AddFileToDownloadsTable("models/player/items/all_class/red_sign.sw.vtx");
	AddFileToDownloadsTable("models/player/items/all_class/red_sign.vvd");
	AddFileToDownloadsTable("materials/models/player/items/all_class/BLACK.vmt");
	AddFileToDownloadsTable("materials/models/player/items/all_class/BLUE.vmt");
	AddFileToDownloadsTable("materials/models/player/items/all_class/RED.vmt");
	for(new i=0;i<g_iPlayerSkins;++i)
	{
		g_ePlayerSkins[i][nModelIndex] = PrecacheModel2(g_ePlayerSkins[i][szModel], true);
		Downloader_AddFileToDownloadsTable(g_ePlayerSkins[i][szModel]);

		if(g_ePlayerSkins[i][szArms][0]!=0)
		{
			PrecacheModel2(g_ePlayerSkins[i][szArms], true);
			Downloader_AddFileToDownloadsTable(g_ePlayerSkins[i][szArms]);
		}
	}

	if(g_eCvars[g_cvarSkinForceChangeT][sCache][0] != 0 && (FileExists(g_eCvars[g_cvarSkinForceChangeT][sCache]) || FileExists(g_eCvars[g_cvarSkinForceChangeT][sCache], true)))
	{
		g_bTForcedSkin = true;
		PrecacheModel2(g_eCvars[g_cvarSkinForceChangeT][sCache], true);
		Downloader_AddFileToDownloadsTable(g_eCvars[g_cvarSkinForceChangeT][sCache]);
	}
	else
		g_bTForcedSkin = false;
		
	if(g_eCvars[g_cvarSkinForceChangeCT][sCache][0] != 0 && (FileExists(g_eCvars[g_cvarSkinForceChangeCT][sCache]) || FileExists(g_eCvars[g_cvarSkinForceChangeCT][sCache], true)))
	{
		g_bCTForcedSkin = true;
		PrecacheModel2(g_eCvars[g_cvarSkinForceChangeCT][sCache], true);
		Downloader_AddFileToDownloadsTable(g_eCvars[g_cvarSkinForceChangeCT][sCache]);
	}
	else
		g_bCTForcedSkin = false;
}

#if defined STANDALONE_BUILD
public OnLibraryAdded(const String:name[])
#else
public PlayerSkins_OnLibraryAdded(const String:name[])
#endif
{
	if(strcmp(name, "zombiereloaded")==0)
		g_bZombieMode = true;
}

#if defined STANDALONE_BUILD
public OnClientConnected(client)
#else
public PlayerSkins_OnClientConnected(client)
#endif
{
	RestoreHat[client] = false;
	g_iTempSkins[client] = -1;
	for(new i=0;i<9;i++)
	{
		g_Equipped[client][i]=0;
	}
	
	HasArms[client] = 0;


}

public PlayerSkins_OnClientPutInServer(client)
{
//	PrintToChat(client, "HOOKED");
	SDKHook(client, SDKHook_WeaponSwitchPost, SDHook_OnWeaponSwitchPost);
//	SDKHook(client, SDKHook_WeaponEquipPost, SDHook_OnWeaponEquipPost);
}

public PlayerSkins_Reset()
{
	g_iPlayerSkins = 0;
}

public PlayerSkins_Config(&Handle:kv, itemid)
{
	Store_SetDataIndex(itemid, g_iPlayerSkins);
	
	KvGetString(kv, "model", g_ePlayerSkins[g_iPlayerSkins][szModel], PLATFORM_MAX_PATH);
	KvGetString(kv, "arms", g_ePlayerSkins[g_iPlayerSkins][szArms], PLATFORM_MAX_PATH);
	g_ePlayerSkins[g_iPlayerSkins][iSkin] = KvGetNum(kv, "skin");
//	g_ePlayerSkins[g_iPlayerSkins][iTeam] = KvGetNum(kv, "team");
	g_ePlayerSkins[g_iPlayerSkins][iClass] = KvGetNum(kv, "class");
	g_ePlayerSkins[g_iPlayerSkins][bTemporary] = (KvGetNum(kv, "temporary")?true:false);
	
	if(FileExists(g_ePlayerSkins[g_iPlayerSkins][szModel], true))
	{
		++g_iPlayerSkins;
		return true;
	}
	
	return false;
}

public PlayerSkins_Equip(client, id)
{
	new m_iData = Store_GetDataIndex(id);
//	if(g_eCvars[g_cvarSkinChangeInstant][aCache] && IsPlayerAlive(client) && GetClientTeam(client)==g_ePlayerSkins[m_iData][iTeam] && TF2_GetPlayerClassAsNumber(client)==g_ePlayerSkins[m_iData][iClass])
	if(g_eCvars[g_cvarSkinChangeInstant][aCache] && IsPlayerAlive(client) && TF2_GetPlayerClassAsNumber(client)==g_ePlayerSkins[m_iData][iClass])
	{
		Store_SetClientModel(client, g_ePlayerSkins[m_iData][szModel], g_ePlayerSkins[m_iData][iSkin], g_ePlayerSkins[m_iData][szArms]);
	}
	else
	{
		if(Store_IsClientLoaded(client))
		{
			Chat(client, "%t", "PlayerSkins Settings Changed");
		}

		if(g_ePlayerSkins[m_iData][bTemporary])
		{
			g_iTempSkins[client] = m_iData;
			return -1;
		}
	}
	new class=g_ePlayerSkins[m_iData][iClass]-1;
	g_Equipped[client][class]=1;
	RestoreHat[client] = false;
//	return g_ePlayerSkins[Store_GetDataIndex(id)][iTeam]-2;
	return g_ePlayerSkins[Store_GetDataIndex(id)][iClass]-1;
}

public PlayerSkins_Remove(client, id)
{
	new class = g_ePlayerSkins[Store_GetDataIndex(id)][iClass] - 1;


	if(Store_IsClientLoaded(client) && !g_eCvars[g_cvarSkinChangeInstant][aCache])
	{
		RestoreHat[client] = true;
//		HasArms[client] = false;

		Chat(client, "%t", "PlayerSkins Settings Changed");
		return g_ePlayerSkins[Store_GetDataIndex(id)][iClass]-1;
	}
	g_Equipped[client][class]=0;
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	RemoveValveHat(client, true);
	
	HasArms[client] = 0;
	TheArms[client] = "";
	RestoreHat[client] = false;

//	return g_ePlayerSkins[Store_GetDataIndex(id)][iTeam]-2;
	return g_ePlayerSkins[Store_GetDataIndex(id)][iClass]-1;
}

public Action:PlayerSkins_PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || !(2<=GetClientTeam(client)<=3))
		return Plugin_Continue;
	new Float:Delay = Float:g_eCvars[g_cvarSkinDelay][aCache];

	if(Delay < 0 && g_bZombieMode)
		Delay = 2.0;

	if(Delay < 0)
		PlayerSkins_PlayerSpawnPost(INVALID_HANDLE, GetClientUserId(client));
	else
		CreateTimer(Delay, PlayerSkins_PlayerSpawnPost, GetClientUserId(client));

	return Plugin_Continue;
}

public Action:PlayerSkins_PlayerSpawnPost(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;
		
	new class=TF2_GetPlayerClassAsNumber(client)-1;
	if(RestoreHat[client])
	{
		g_Equipped[client][class]=0;
		HasArms[client] = 0;
		TheArms[client] = "";
		RemoveValveHat(client ,true);
		RestoreHat[client] = false;
	}

	new m_iEquipped = Store_GetEquippedItem(client, "playerskin", class);
//	if(m_iEquipped < 0)
//		m_iEquipped = Store_GetEquippedItem(client, "playerskin", class);
//	if(m_iEquipped >= 0 ||  g_iTempSkins[client] >= 0)
	if(m_iEquipped >= 0)
	{
		g_iPlayerBGroups[client] = GetEntProp(client, Prop_Send, "m_nBody");
		decl m_iData;
//		if(g_iTempSkins[client]>=0)
//			m_iData = g_iTempSkins[client];
//		else
		m_iData = Store_GetDataIndex(m_iEquipped);
		Store_SetClientModel(client, g_ePlayerSkins[m_iData][szModel], g_ePlayerSkins[m_iData][iSkin], g_ePlayerSkins[m_iData][szArms]);
		g_Equipped[client][class]=1;
//		SetVariantString(g_ePlayerSkins[m_iData][szModel]);
//			AcceptEntityInput(client, "SetCustomModel");
//			SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 0);
//			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
//			SetEntProp(client, Prop_Send, "m_nBody", CalculateBodyGroups(client));
//			RemoveValveHat(client);
	}
	else if(g_eCvars[g_cvarSkinForceChange][aCache])
	{
		new m_iTeam = GetClientTeam(client);
		if(m_iTeam == 2 && g_bTForcedSkin)
			Store_SetClientModel(client, g_eCvars[g_cvarSkinForceChangeT][sCache]);
		else if(m_iTeam == 3 && g_bCTForcedSkin)
			Store_SetClientModel(client, g_eCvars[g_cvarSkinForceChangeCT][sCache]);
	}
	
	return Plugin_Stop;
}

Store_SetClientModel(client, const String:model[], const skin=0, const String:arms[]="")
{
	if(g_bZombieMode)
		if(ZR_IsClientZombie(client))
			return;

	if(GAME_TF2)
	{
		if(!IsBoss(client))
		{
			SetVariantString(model);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 0);
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
			SetEntProp(client, Prop_Send, "m_nBody", CalculateBodyGroups(client));
			RemoveValveHat(client);
			(GetClientTeam(client) == 2) ? EquipWearable(client, RED_sign) : EquipWearable(client, BLUE_sign);
			if(arms[0])
			{
				HasArms[client] = TF2_GetPlayerClassAsNumber(client);
				new String:str[PLATFORM_MAX_PATH];
				strcopy(str, sizeof(str), arms);
				TheArms[client] = str;
			}
		}
		else
		{
			HasArms[client] = 0;
			TheArms[client] = "";
		}
	}
	else
	{
		SetEntityModel(client, model);
	}

	SetEntProp(client, Prop_Send, "m_nSkin", skin);

	if(GAME_CSGO & arms[0]!=0)
	{
		SetEntPropString(client, Prop_Send, "m_szArmsModel", arms);
	}
}

public Action:PlayerSkins_PlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	g_iTempSkins[client] = -1;
	return Plugin_Continue;
}

public Event_EquipItem(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	new userid = GetEventInt(hEvent, "userid");
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		new client = GetClientOfUserId(userid);
		if(!client)
			return Plugin_Stop;
			
/*		new weapon = GetPlayerWeaponSlot(client, 4);
		if(IsValidEntity(weapon))
		{
			new String:classname[64];
			GetEntityClassname(weapon, classname, sizeof(classname));
			if(StrEqual(classname, "tf_weapon_invis", false))
			{
				ChangeArm(client, weapon, true);
			}
		}*/

//		new TFClassType:class = TF2_GetPlayerClass(client);
//		if (class != TFClass_Unknown && class != g_iPlayerSpawnClass[client])
//		{
//			PlayerSkins_Remove(client);
//		}
//		g_iPlayerSpawnClass[client] = class;
//		CreateTimer(0.1, Timer_EquipItem, userid, TIMER_FLAG_NO_MAPCHANGE);
		new class=TF2_GetPlayerClassAsNumber(client)-1;
		new m_iEquipped = Store_GetEquippedItem(client, "playerskin", class);
		if(m_iEquipped >= 0)
		{
			g_iPlayerBGroups[client] = GetEntProp(client, Prop_Send, "m_nBody");
			decl m_iData;
			m_iData = Store_GetDataIndex(m_iEquipped);
			Store_SetClientModel(client, g_ePlayerSkins[m_iData][szModel], g_ePlayerSkins[m_iData][iSkin], g_ePlayerSkins[m_iData][szArms]);
			g_Equipped[client][class]=1;
			if(HasArms[client] == class + 1)
			{
				new active_weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(active_weapon <= 0 || active_weapon > 2048)
					return Plugin_Continue;
				if(!IsValidEntity(active_weapon))
					return Plugin_Continue;

				new DataPack:gPack = new DataPack();
				gPack.WriteCell(EntIndexToEntRef(client));
				gPack.WriteCell(EntIndexToEntRef(active_weapon));
				RequestFrame(OnDrawWeapon, gPack);
				
				new weapon = GetPlayerWeaponSlot(client, 4);
				if(IsValidEntity(weapon))
				{
					new String:classname[64];
					GetEntityClassname(weapon, classname, sizeof(classname));
					if(StrEqual(classname, "tf_weapon_invis", false))
					{
						ChangeArm(client, weapon);
					}
				}
			}
		}

/*		if(class>=0 && class<=8)
		{
			if(g_Equipped[client][class])
			{
//				CreateTimer(0.1, Remove_HAT, userid, TIMER_FLAG_NO_MAPCHANGE);
				RemoveValveHat(client);
			}
		}*/
	}
}


public SDHook_OnWeaponSwitchPost(client, weapon)
{

	new class = TF2_GetPlayerClassAsNumber(client) - 1;
	if((HasArms[client] == class+1) && g_Equipped[client][class] && !IsBoss(client))
	{
		new DataPack:hPack = new DataPack();
		hPack.WriteCell(EntIndexToEntRef(client));
		hPack.WriteCell(EntIndexToEntRef(weapon));
//		Weapondata[client] = EntIndexToEntRef(weapon);

//		new clientIdx = GetClientUserId(client);
		RequestFrame(OnDrawWeapon, hPack);
		return;
	}
//	else if(!IsBoss(client) && !g_Equipped[client][class])
//	{
//		ChangeArm(client, weapon, true);
//	}
	return;
}

public OnDrawWeapon(DataPack:hPack)
{
	hPack.Reset();
	new client = EntRefToEntIndex(hPack.ReadCell());
	new weapon = EntRefToEntIndex(hPack.ReadCell());
	delete hPack;

	if(client == -1 || weapon == -1)
		return;

	ChangeArm(client, weapon);

	return;
}

ChangeArm(client, weapon, bool:stockArm = false)
{
	new ModelIndex;
	if(!stockArm)
	{
		ModelIndex = PrecacheModel(TheArms[client] ,true);
//			SetEntityModel(weapon, TheArms[client]);
	}
	else
	{
		new TFClassType:class = TF2_GetPlayerClass(client);
		char arms[PLATFORM_MAX_PATH];
		switch (class)
		{
			case TFClass_Scout: Format(arms, sizeof(arms), "models/weapons/c_models/c_scout_arms.mdl");
			case TFClass_Soldier: Format(arms, sizeof(arms), "models/weapons/c_models/c_soldier_arms.mdl");
			case TFClass_Pyro: Format(arms, sizeof(arms), "models/weapons/c_models/c_pyro_arms.mdl");
			case TFClass_DemoMan: Format(arms, sizeof(arms), "models/weapons/c_models/c_demo_arms.mdl");
			case TFClass_Heavy: Format(arms, sizeof(arms), "models/weapons/c_models/c_heavy_arms.mdl");
			case TFClass_Engineer: Format(arms, sizeof(arms), "models/weapons/c_models/c_engineer_arms.mdl");
			case TFClass_Medic: Format(arms, sizeof(arms), "models/weapons/c_models/c_medic_arms.mdl");
			case TFClass_Sniper: Format(arms, sizeof(arms), "models/weapons/c_models/c_sniper_arms.mdl");
			case TFClass_Spy: Format(arms, sizeof(arms), "models/weapons/c_models/c_spy_arms.mdl");
		}
//		SetEntityModel(weapon, arms);
		ModelIndex = PrecacheModel(arms ,true);
	}

	SetEntProp(weapon, Prop_Send, "m_iViewModelIndex", ModelIndex);
	SetEntProp(weapon, Prop_Send, "m_nCustomViewmodelModelIndex", ModelIndex);
//	SetEntProp(weapon, Prop_Send, "m_nCustomViewmodelModelIndex", GetEntProp(weapon, Prop_Send, "m_nModelIndex"));
//	SetEntProp(weapon, Prop_Send, "m_iViewModelIndex", GetEntProp(weapon, Prop_Send, "m_nModelIndex"));
}

//public Action:Remove_HAT(Handle:hTimer, any:userid)
//{
//	new client = GetClientOfUserId(userid);
//	if (!IsValidClient(client)) return Plugin_Continue;
//	if (!IsPlayerAlive(client)) return Plugin_Continue;
//	SetEntProp(client, Prop_Send, "m_nBody", CalculateBodyGroups(client));
//	RemoveValveHat(client);
//	return Plugin_Continue;
//}

stock RemoveValveHat(client, bool:unhide = false)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassnameSafe(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && strcmp(netclass, "CTFWearable") == 0)
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (idx != 57 && idx != 133 && idx != 231 && idx != 444 && idx != 405 && idx != 608 && idx != 642 && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityRenderMode(edict, (unhide ? RENDER_NORMAL : RENDER_TRANSCOLOR));
				SetEntityRenderColor(edict, 255, 255, 255, (unhide ? 255 : 0));
			}
		}
	}
	edict = MaxClients+1;
	while((edict = FindEntityByClassnameSafe(edict, "tf_powerup_bottle")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && strcmp(netclass, "CTFPowerupBottle") == 0)
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (idx != 57 && idx != 133 && idx != 231 && idx != 444 && idx != 405 && idx != 608 && idx != 642 && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityRenderMode(edict, (unhide ? RENDER_NORMAL : RENDER_TRANSCOLOR));
				SetEntityRenderColor(edict, 255, 255, 255, (unhide ? 255 : 0));
			}
		}
	}
}

stock FindEntityByClassnameSafe(iStart, const String:strClassname[])
{
	while (iStart > -1 && !IsValidEntity(iStart)) iStart--;
	return FindEntityByClassname(iStart, strClassname);
}

stock TF2_GetPlayerClassAsNumber(client)
{
	new Num;
	new TFClassType:class = TF2_GetPlayerClass(client);
	switch(class)
	{
		case TFClass_Scout:
		{
			Num=1;
		}
		case TFClass_Soldier:
		{
			Num=2;
		}
		case TFClass_Pyro:
		{
			Num=3;
		}
		case TFClass_DemoMan:
		{
			Num=4;
		}
		case TFClass_Heavy:
		{
			Num=5;
		}
		case TFClass_Engineer:
		{
			Num=6;
		}
		case TFClass_Medic:
		{
			Num=7;
		}
		case TFClass_Sniper:
		{
			Num=8;
		}
		case TFClass_Spy:
		{
			Num=9;
		}
	}
	return Num;
}

CalculateBodyGroups(client)
{
	new iBodyGroups = g_iPlayerBGroups[client];
//	new iItemGroups = 0;

	new TFClassType:class = TF2_GetPlayerClass(client);
	switch(class)
	{
		case TFClass_Scout:
		{
			iBodyGroups |= BODYGROUP_SCOUT_HAT;
			iBodyGroups |= BODYGROUP_SCOUT_HEADPHONES;
			iBodyGroups |= BODYGROUP_SCOUT_SHOESSOCKS;
			iBodyGroups |= BODYGROUP_SCOUT_DOGTAGS;
		}
		case TFClass_Soldier:
		{
			iBodyGroups |= BODYGROUP_SOLDIER_ROCKET;
			iBodyGroups |= BODYGROUP_SOLDIER_HELMET;
			iBodyGroups |= BODYGROUP_SOLDIER_GRENADES;
		}
		case TFClass_Pyro:
		{
			iBodyGroups |= BODYGROUP_PYRO_HEAD;
			iBodyGroups |= BODYGROUP_PYRO_GRENADES;
		}
		case TFClass_DemoMan:
		{
			iBodyGroups |= BODYGROUP_DEMO_SMILE;
			iBodyGroups |= BODYGROUP_DEMO_SHOES;
		}
		case TFClass_Heavy:
		{
			iBodyGroups = BODYGROUP_HEAVY_HANDS;
		}
		case TFClass_Engineer:
		{
			iBodyGroups |= BODYGROUP_ENGINEER_HELMET;
			iBodyGroups |= BODYGROUP_ENGINEER_ARM;
		}
		case TFClass_Medic:
		{
			iBodyGroups |= BODYGROUP_MEDIC_BACKPACK;
		}
		case TFClass_Sniper:
		{
			iBodyGroups |= BODYGROUP_SNIPER_ARROWS;
			iBodyGroups |= BODYGROUP_SNIPER_HAT;
			iBodyGroups |= BODYGROUP_SNIPER_BULLETS;
		}
		case TFClass_Spy:
		{
			iBodyGroups |= BODYGROUP_SPY_MASK;
		}
	}

	return iBodyGroups;
}

stock EquipWearable(client, String:Mdl[])
{ // ^ bad name probably
	int wearable = CreateWearable(client, Mdl);
	if (wearable == -1)
		return -1;
	return wearable;
}

stock CreateWearable(client, String:model[]) // Randomizer code :3
{
	int ent = CreateEntityByName("tf_wearable");
	if (!IsValidEntity(ent)) return -1;
	SetEntProp(ent, Prop_Send, "m_nModelIndex", PrecacheModel(model));
	SetEntProp(ent, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_PARENT_ANIMATES);
	SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
	SetEntProp(ent, Prop_Send, "m_usSolidFlags", 4);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 11);
	SetEntProp(ent, Prop_Send, "m_bValidatedAttachedEntity", 1);
	DispatchSpawn(ent);
	SetVariantString("!activator");
	ActivateEntity(ent);
	TF2_EquipWearable(client, ent); // urg
	return ent;
}

// *sigh*
stock TF2_EquipWearable(int client,int Ent)
{
	if (g_bSdkStarted == false || g_hSdkEquipWearable == INVALID_HANDLE)
	{
		TF2_SdkStartup();
		LogMessage("Error: Can't call EquipWearable, SDK functions not loaded! If it continues to fail, reload plugin or restart server. Make sure your gamedata is intact!");
	}
	else
	{
		SDKCall(g_hSdkEquipWearable, client, Ent);
	}
}
stock bool TF2_SdkStartup()
{
	new Handle:hGameConf = LoadGameConfigFile("tf2items.randomizer");
	if (hGameConf == INVALID_HANDLE)
	{
		LogMessage("Couldn't load SDK functions (GiveWeapon). Make sure tf2items.randomizer.txt is in your gamedata folder! Restart server if you want wearable weapons.");
		return false;
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTFPlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSdkEquipWearable = EndPrepSDKCall();

	CloseHandle(hGameConf);
	g_bSdkStarted = true;
	return true;
}


bool:IsBoss(client)
{
	return (FF2_GetBossIndex(client)!=-1) ? true : false;
}

stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
//	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}