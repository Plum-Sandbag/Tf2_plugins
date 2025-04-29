//#if defined STANDALONE_BUILD
//#include <sourcemod>
//#include <sdktools>
//#include <tf2>
//#include <tf2_stocks>
//#include <store>
//#include <zephstocks>
//#include <clientprefs> 

//new GAME_TF2 = false;
//#endif
#include <worldtext>

#define EF_BONEMERGE            (1 << 0)
#define EF_NOSHADOW             (1 << 4)
#define EF_BONEMERGE_FASTCULL   (1 << 7)
#define EF_PARENT_ANIMATES      (1 << 9)

#define BODYGROUP_SCOUT_HAT				(1 << 0)
#define BODYGROUP_SCOUT_HEADPHONES		(1 << 1)
#define BODYGROUP_SCOUT_SHOESSOCKS		(1 << 2)
#define BODYGROUP_SCOUT_DOGTAGS			(1 << 3)

#define BODYGROUP_SOLDIER_ROCKET		(1 << 0)
#define BODYGROUP_SOLDIER_HELMET		(1 << 1)
#define BODYGROUP_SOLDIER_MEDAL			(1 << 2)
#define BODYGROUP_SOLDIER_GRENADES		(1 << 3)

#define BODYGROUP_PYRO_HEAD				(1 << 0)
#define BODYGROUP_PYRO_GRENADES			(1 << 1)

#define BODYGROUP_DEMO_SMILE			(1 << 0)
#define BODYGROUP_DEMO_SHOES			(1 << 1)

#define BODYGROUP_HEAVY_HANDS			(1 << 0)

#define BODYGROUP_ENGINEER_HELMET		(1 << 0)
#define BODYGROUP_ENGINEER_ARM			(1 << 1)

#define BODYGROUP_MEDIC_BACKPACK		(1 << 0)

#define BODYGROUP_SNIPER_ARROWS			(1 << 0)
#define BODYGROUP_SNIPER_HAT			(1 << 1)
#define BODYGROUP_SNIPER_BULLETS		(1 << 2)

#define BODYGROUP_SPY_MASK				(1 << 0)

native bool:ZR_IsClientZombie(client);
//new bool:g_bZombieMode = false;
new bool:RestoreHat[MAXPLAYERS+1];
new HasArms[MAXPLAYERS+1];
new String:TheArms[MAXPLAYERS+1][PLATFORM_MAX_PATH];

int playerText[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE , ... };

enum struct PlayerSkin
{
	char szModel[PLATFORM_MAX_PATH];
	char szArms[PLATFORM_MAX_PATH];
	int iSkin;
//	bool bTemporary;
	int iClass
//	int iTeam;
	int nModelIndex;
}

new g_iPlayerBGroups[MAXPLAYERS+1];
PlayerSkin g_ePlayerSkins[STORE_MAX_ITEMS];

new g_iPlayerSkins = 0;
//new g_iTempSkins[MAXPLAYERS+1];

new g_cvarSkinChangeInstant = -1;
new g_cvarSkinForceChange = -1;
new g_cvarSkinForceChangeCT = -1;
new g_cvarSkinForceChangeT = -1;
new g_cvarSkinDelay = -1;

new g_Equipped[MAXPLAYERS+1][9];
//new Handle:g_SkinHatCookie = INVALID_HANDLE;
new bool:g_bTForcedSkin = false;
new bool:g_bCTForcedSkin = false;

int Text_Owner[2049] = { -1 , ... };

Handle g_hGetBonePosition;
Handle g_hLookupBone;
//Handle g_hStudio_FindAttachment;

#if defined STANDALONE_BUILD
public OnPluginStart()
#else
public PlayerSkins_OnPluginStart()
#endif
{
//#if defined STANDALONE_BUILD
	new String:m_szGameDir[32];
	GetGameFolderName(m_szGameDir, sizeof(m_szGameDir));
	
	if(strcmp(m_szGameDir, "tf")==0)
		GAME_TF2 = true;
		
	LoadTranslations("store.phrases");
//#endif
	
	Store_RegisterHandler("playerskin", "model", PlayerSkins_OnMapStart, PlayerSkins_Reset, PlayerSkins_Config, PlayerSkins_Equip, PlayerSkins_Remove, true);
	Store_RegisterHandler("playerskin_temp", "model", PlayerSkins_OnMapStart, PlayerSkins_Reset, PlayerSkins_Config, PlayerSkins_Equip, PlayerSkins_Remove, false);

	g_cvarSkinChangeInstant = RegisterConVar("sm_store_playerskin_instant", "0", "Defines whether the skin should be changed instantly or on next spawn.", TYPE_INT);
	g_cvarSkinForceChange = RegisterConVar("sm_store_playerskin_force_default", "0", "If it's set to 1, default skins will be enforced.", TYPE_INT);
	g_cvarSkinForceChangeCT = RegisterConVar("sm_store_playerskin_default_ct", "", "Path of the default CT skin.", TYPE_STRING);
	g_cvarSkinForceChangeT = RegisterConVar("sm_store_playerskin_default_t", "", "Path of the default T skin.", TYPE_STRING);
	g_cvarSkinDelay = RegisterConVar("sm_store_playerskin_delay", "2.0", "Delay after spawn before applying the skin. -1 means no delay", TYPE_FLOAT);
	
//	g_SkinHatCookie = RegClientCookie("sm_store_playerskinhat", "Player Skin's Hat", CookieAccess_Protected);

	HookEvent("player_spawn", PlayerSkins_PlayerSpawn);
	HookEvent("player_death", PlayerSkins_PlayerDeath);
	HookEvent("post_inventory_application", Event_EquipItem, EventHookMode_Post);

	//g_bZombieMode = (FindPluginByFile("zombiereloaded")==INVALID_HANDLE?false:true);
}

#if defined STANDALONE_BUILD
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("ZR_IsClientZombie");
	return APLRes_Success;
} 
#endif

public PlayerSkins_OnMapStart()
{
	for(new i=0;i<g_iPlayerSkins;++i)
	{
		g_ePlayerSkins[i].nModelIndex = PrecacheModel2(g_ePlayerSkins[i].szModel, true);
		Downloader_AddFileToDownloadsTable(g_ePlayerSkins[i].szModel);

		if(g_ePlayerSkins[i].szArms[0]!=0)
		{
			PrecacheModel2(g_ePlayerSkins[i].szArms, true);
			Downloader_AddFileToDownloadsTable(g_ePlayerSkins[i].szArms);
		}
	}

	if(g_eCvars[g_cvarSkinForceChangeT].sCache[0] != 0 && (FileExists(g_eCvars[g_cvarSkinForceChangeT].sCache) || FileExists(g_eCvars[g_cvarSkinForceChangeT].sCache, true)))
	{
		g_bTForcedSkin = true;
		PrecacheModel2(g_eCvars[g_cvarSkinForceChangeT].sCache, true);
		Downloader_AddFileToDownloadsTable(g_eCvars[g_cvarSkinForceChangeT].sCache);
	}
	else
		g_bTForcedSkin = false;
		
	if(g_eCvars[g_cvarSkinForceChangeCT].sCache[0] != 0 && (FileExists(g_eCvars[g_cvarSkinForceChangeCT].sCache) || FileExists(g_eCvars[g_cvarSkinForceChangeCT].sCache, true)))
	{
		g_bCTForcedSkin = true;
		PrecacheModel2(g_eCvars[g_cvarSkinForceChangeCT].sCache, true);
		Downloader_AddFileToDownloadsTable(g_eCvars[g_cvarSkinForceChangeCT].sCache);
	}
	else
		g_bCTForcedSkin = false;
		
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x56\x8B\xF1\x80\xBE\x41\x03\x00\x00\x00\x75\x2A\x83\xBE\x6C\x04\x00\x00\x00\x75\x2A\xE8\x2A\x2A\x2A\x2A\x85\xC0\x74\x2A\x8B\xCE\xE8\x2A\x2A\x2A\x2A\x8B\x86\x6C\x04\x00\x00\x85\xC0\x74\x2A\x83\x38\x00\x74\x2A\xFF\x75\x08\x50\xE8\x2A\x2A\x2A\x2A\x83\xC4\x08\x5E", 68);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	if ((g_hLookupBone = EndPrepSDKCall()) == INVALID_HANDLE) SetFailState("Failed to create SDKCall for CBaseAnimating::LookupBone signature!");
		
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x83\xEC\x30\x56\x8B\xF1\x80\xBE\x69\x03\x00\x00\x00", 16);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	if ((g_hGetBonePosition = EndPrepSDKCall()) == INVALID_HANDLE) SetFailState("Failed to create SDKCall for CBaseAnimating::GetBonePosition signature!");
	
//	StartPrepSDKCall(SDKCall_Static);
//	PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x53\x56\x57\x8B\x7D\x08\x85\xFF");
//	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	//pStudioHdr
//	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);		//pAttachmentName
//	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);	//return index
//	if((g_hStudio_FindAttachment = EndPrepSDKCall()) == INVALID_HANDLE) SetFailState("Failed to create Call for Studio_FindAttachment");

}

#if defined STANDALONE_BUILD
public OnLibraryAdded(const String:name[])
#else
public PlayerSkins_OnLibraryAdded(const String:name[])
#endif
{
	//if(strcmp(name, "zombiereloaded")==0)
		//g_bZombieMode = true;
}

#if defined STANDALONE_BUILD
public OnClientConnected(client)
#else
public PlayerSkins_OnClientConnected(client)
#endif
{
	RestoreHat[client] = false;
//	g_iTempSkins[client] = -1;
	for(new i=0;i<9;i++)
	{
		g_Equipped[client][i]=0;
	}
	
	HasArms[client] = 0;
}

public PlayerSkins_OnClientPutInServer(client)
{

	SDKHook(client, SDKHook_WeaponSwitchPost, SDHook_OnWeaponSwitchPost);
	
	playerText[client] = INVALID_ENT_REFERENCE;

}
public PlayerSkins_Reset()
{
	g_iPlayerSkins = 0;
}

public PlayerSkins_Config(&Handle:kv, itemid)
{
	Store_SetDataIndex(itemid, g_iPlayerSkins);
	
	KvGetString(kv, "model", g_ePlayerSkins[g_iPlayerSkins].szModel, PLATFORM_MAX_PATH);
	KvGetString(kv, "arms", g_ePlayerSkins[g_iPlayerSkins].szArms, PLATFORM_MAX_PATH);
	g_ePlayerSkins[g_iPlayerSkins].iSkin = KvGetNum(kv, "skin");
//	g_ePlayerSkins[g_iPlayerSkins].iTeam = KvGetNum(kv, "team");
	g_ePlayerSkins[g_iPlayerSkins].iClass = KvGetNum(kv, "class");
//	g_ePlayerSkins[g_iPlayerSkins][bTemporary] = (KvGetNum(kv, "temporary")?true:false);
	
	if(FileExists(g_ePlayerSkins[g_iPlayerSkins].szModel, true))
	{
		++g_iPlayerSkins;
		return true;
	}
	
	return false;
}

public PlayerSkins_Equip(client, id)
{
	new m_iData = Store_GetDataIndex(id);
//	if(g_eCvars[g_cvarSkinChangeInstant].aCache && IsPlayerAlive(client) && GetClientTeam(client)==g_ePlayerSkins[m_iData].iTeam)
	if(g_eCvars[g_cvarSkinChangeInstant].aCache && IsPlayerAlive(client) && GetClientTeam(client)==g_ePlayerSkins[m_iData].iClass)
	{
		Store_SetClientModel(client, g_ePlayerSkins[m_iData].szModel, g_ePlayerSkins[m_iData].iSkin, g_ePlayerSkins[m_iData].szArms);
	}
	else
	{
		if(Store_IsClientLoaded(client))
			Chat(client, "%t", "PlayerSkins Settings Changed");

//		if(g_ePlayerSkins[m_iData][bTemporary])
//		{
//			g_iTempSkins[client] = m_iData;
//			return -1;
//		}
	}
	new class=g_ePlayerSkins[m_iData].iClass-1;
	g_Equipped[client][class]=1;
	RestoreHat[client] = false;
	return g_ePlayerSkins[Store_GetDataIndex(id)].iClass-1;
//	return g_ePlayerSkins[Store_GetDataIndex(id)].iTeam-2;
}

public PlayerSkins_Remove(client, id)
{
	new class = g_ePlayerSkins[Store_GetDataIndex(id)].iClass - 1;
	if(Store_IsClientLoaded(client) && g_eCvars[g_cvarSkinChangeInstant].aCache)
	{
		RestoreHat[client] = true;
		Chat(client, "%t", "PlayerSkins Settings Changed");
		return g_ePlayerSkins[Store_GetDataIndex(id)].iClass-1;
	}
	g_Equipped[client][class]=0;
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	RemoveValveHat(client, true);
	
	new ent = EntRefToEntIndex(playerText[client]);
	if(IsValidEntity(ent))
	{
		char classname[128];
		GetEntityClassname(ent, classname, 128);
		if(!strcmp(classname, "point_worldtext"))
		{
			RemoveEntity(ent);
		}
	}
	playerText[client] = INVALID_ENT_REFERENCE;
	
	HasArms[client] = 0;
	TheArms[client] = "";
	RestoreHat[client] = false;
//	return g_ePlayerSkins[Store_GetDataIndex(id)].iTeam-2;
	return g_ePlayerSkins[Store_GetDataIndex(id)].iClass-1;
}

public Action:PlayerSkins_PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || !(2<=GetClientTeam(client)<=3))
		return Plugin_Continue;
			
	float Delay = view_as<float>(g_eCvars[g_cvarSkinDelay].aCache);

	//if(Delay < 0 && g_bZombieMode)
		//Delay = 2.0;

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

	//if(g_bZombieMode)
	//	if(ZR_IsClientZombie(client))
	//		return Plugin_Continue;
	
	new class=TF2_GetPlayerClassAsNumber(client)-1;
	
	if(RestoreHat[client])
	{
		g_Equipped[client][class]=0;
		HasArms[client] = 0;
		TheArms[client] = "";
		RemoveValveHat(client ,true);
		RestoreHat[client] = false;
		
		new ent = EntRefToEntIndex(playerText[client]);
		if(IsValidEntity(ent))
		{
			char classname[128];
			GetEntityClassname(ent, classname, 128);
			if(!strcmp(classname, "point_worldtext"))
			{
				RemoveEntity(ent);
			}
		}
		playerText[client] = INVALID_ENT_REFERENCE;
		
	}
	
	new m_iEquipped = Store_GetEquippedItem(client, "playerskin", class);
//	if(m_iEquipped < 0)
//		m_iEquipped = Store_GetEquippedItem(client, "playerskin", GetClientTeam(client)-2);
	if(m_iEquipped >= 0)
	{
		g_iPlayerBGroups[client] = GetEntProp(client, Prop_Send, "m_nBody");
		decl m_iData;
//		if(g_iTempSkins[client]>=0)
//			m_iData = g_iTempSkins[client];
//		else
		m_iData = Store_GetDataIndex(m_iEquipped);
		Store_SetClientModel(client, g_ePlayerSkins[m_iData].szModel, g_ePlayerSkins[m_iData].iSkin, g_ePlayerSkins[m_iData].szArms);
		g_Equipped[client][class]=1;
	}
	else if(g_eCvars[g_cvarSkinForceChange].aCache)
	{
		new m_iTeam = GetClientTeam(client);
		if(m_iTeam == 2 && g_bTForcedSkin)
			Store_SetClientModel(client, g_eCvars[g_cvarSkinForceChangeT].sCache);
		else if(m_iTeam == 3 && g_bCTForcedSkin)
			Store_SetClientModel(client, g_eCvars[g_cvarSkinForceChangeCT].sCache);
	}
	return Plugin_Stop;
}

Store_SetClientModel(client, const String:model[], const skin=0, const String:arms[]="")
{
	if(GAME_TF2)
	{
		if(!IsBoss(client))
		{
			SetVariantString(model);
			AcceptEntityInput(client, "SetCustomModel");
//			SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 0);
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
			SetEntProp(client, Prop_Send, "m_nBody", CalculateBodyGroups(client));
			RemoveValveHat(client);
			
			int textEnt;
			float origin[3], angles[3];
			int iBone = SDKCall(g_hLookupBone, client, "bip_head");
			if(iBone != -1)
			{
				SDKCall(g_hGetBonePosition, client, iBone, origin, angles);
				origin[2] += 20.0;
			}

			switch(GetClientTeam(client))
			{
				case 2:
					textEnt = WorldText_Create(origin, NULL_VECTOR, "RED", 10.0, _, _, FONT_TF2_BULKY, 255, 61, 41, 155, false, ORIENTATION_ALWAYS_FACE_PLAYER);
				case 3:
					textEnt = WorldText_Create(origin, NULL_VECTOR, "BLUE", 10.0, _, _, FONT_TF2_BULKY, 41, 108, 255, 155, false, ORIENTATION_ALWAYS_FACE_PLAYER);
			}

			if (IsValidEntity(textEnt))
			{
				playerText[client] = EntIndexToEntRef(textEnt);
				WorldText_AttachToEntity(textEnt, client, "head", _, _, _);
				Text_Owner[textEnt] = GetClientUserId(client);
				SDKHook(textEnt, SDKHook_SetTransmit, Text_Transmit);
			}

			
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

	if(GAME_CSGO && arms[0]!=0)
	{
		SetEntPropString(client, Prop_Send, "m_szArmsModel", arms);
	}
}

public Action:PlayerSkins_PlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
//	g_iTempSkins[client] = -1;
	new ent = EntRefToEntIndex(playerText[client]);
	if(IsValidEntity(ent))
	{
		char classname[128];
		GetEntityClassname(ent, classname, 128);
		if(!strcmp(classname, "point_worldtext"))
		{
			RemoveEntity(ent);
		}
	}
	playerText[client] = INVALID_ENT_REFERENCE;
	return Plugin_Continue;
}

public Action:Event_EquipItem(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	new userid = GetEventInt(hEvent, "userid");
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
//		if(!client)
//			return Plugin_Stop;
			
		new class=TF2_GetPlayerClassAsNumber(client)-1;
		new m_iEquipped = Store_GetEquippedItem(client, "playerskin", class);
		if(m_iEquipped >= 0)
		{
			g_iPlayerBGroups[client] = GetEntProp(client, Prop_Send, "m_nBody");
			decl m_iData;
			m_iData = Store_GetDataIndex(m_iEquipped);
			Store_SetClientModel(client, g_ePlayerSkins[m_iData].szModel, g_ePlayerSkins[m_iData].iSkin, g_ePlayerSkins[m_iData].szArms);
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
	}
	return Plugin_Continue;
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

public Action Text_Transmit(int entity, int client)
{
	SetEdictFlags(entity, GetEdictFlags(entity)&(~FL_EDICT_ALWAYS));
	if (client == GetClientOfUserId(Text_Owner[entity]))
	{
		return Plugin_Handled;
	}
	else
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Disguised) || TF2_IsPlayerInCondition(client, TFCond_Cloaked)
		|| TF2_IsPlayerInCondition(client, TFCond_Stealthed) || TF2_IsPlayerInCondition(client, TFCond_CloakFlicker)
		|| TF2_IsPlayerInCondition(client, TFCond_DeadRingered))
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

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