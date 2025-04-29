//#if defined STANDALONE_BUILD

#define STANDALONE_BUILD "1"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <store>
#include <zephstocks>
#include <clientprefs> 
#include <sdkhooks>
#include <freak_fortress_2>
#include <tf2utils>

#pragma dynamic 131072

new GAME_TF2 = false;
new GAME_CSGO = false;
//#endif
//#include <worldtext>

#define EF_BONEMERGE            (1 << 0)
#define EF_NOSHADOW             (1 << 4)
#define EF_BONEMERGE_FASTCULL   (1 << 7)
#define EF_PARENT_ANIMATES      (1 << 9)
#define BLUE_sign "models/player/items/all_class/blue_sign.mdl"
#define RED_sign "models/player/items/all_class/red_sign.mdl"


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

//int playerText[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE , ... };

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

new g_Equipped[MAXPLAYERS+1][10];
//new Handle:g_SkinHatCookie = INVALID_HANDLE;
new bool:g_bTForcedSkin = false;
new bool:g_bCTForcedSkin = false;

int g_iPreviewEntity[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};
Handle g_hTimerPreview[MAXPLAYERS + 1];
char g_sChatPrefix[128];

//int Text_Owner[2049] = { -1 , ... };

//new Handle:g_hGetBonePosition;
//new Handle:g_hLookupBone;
//Handle g_hStudio_FindAttachment;
//Handle g_hFollowEntity;


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
//	HookEvent("player_death", PlayerSkins_PlayerDeath, EventHookMode_Pre);
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

public void Store_OnConfigExecuted(char[] prefix)
{
	strcopy(g_sChatPrefix, sizeof(g_sChatPrefix), prefix);
}

public PlayerSkins_OnMapStart()
{
	PrecacheModel(BLUE_sign);
	PrecacheModel(RED_sign);
	PrecacheModel("models/weapons/c_models/c_engineer_gunslinger.mdl");
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
		g_ePlayerSkins[i].nModelIndex = PrecacheModel2(g_ePlayerSkins[i].szModel, true);
		Downloader_AddFileToDownloadsTable(g_ePlayerSkins[i].szModel);

		if(strlen(g_ePlayerSkins[i].szArms) > 3)
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
		
		
//	StartPrepSDKCall(SDKCall_Entity);
//	PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN11CBaseEntity12FollowEntityEPS_b", 0);
//	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);	//entity to follow
//	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);			//bonemerge
//	g_hFollowEntity =  EndPrepSDKCall();
//	if(g_hFollowEntity == INVALID_HANDLE)
//		SetFailState("Failed to create SDKCall for CBaseEntity::FollowEntity signature!");
	
/*	StartPrepSDKCall(SDKCall_Entity);
//												 \x55\x8B\xEC\x56\x8B\xF1\x80\xBE\x69\x03\x00\x00\x00\x75\x28\x83\xBE\x98\x04\x00\x00\x00\x75\x10\xE8\x13\x2A\x02
	PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x56\x8B\xF1\x80\xBE\x69\x03\x00\x00\x00\x75\x28\x83\xBE\x98\x04\x00\x00\x00\x75\x10\xE8\x13\x2A\x02", 28);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hLookupBone = EndPrepSDKCall();
	if (g_hLookupBone == INVALID_HANDLE)
		SetFailState("Failed to create SDKCall for CBaseAnimating::LookupBone signature!");
		
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x83\xEC\x30\x56\x8B\xF1\x80\xBE\x69\x03\x00\x00\x00", 16);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	g_hGetBonePosition = EndPrepSDKCall();
	if (g_hGetBonePosition == INVALID_HANDLE)
		SetFailState("Failed to create SDKCall for CBaseAnimating::GetBonePosition signature!");*/
	
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
	for(new i=0;i<10;i++)
	{
		g_Equipped[client][i]=0;
	}
	
	HasArms[client] = 0;
}
#if defined STANDALONE_BUILD
public OnClientPutInServer(client)
#else
public PlayerSkins_OnClientPutInServer(client)
#endif
{

	SDKHook(client, SDKHook_WeaponSwitchPost, SDHook_OnWeaponSwitchPost);
//	SDKHook(client, SDKHook_WeaponEquipPost, SDHook_OnWeaponEquipPost);
	
//	playerText[client] = INVALID_ENT_REFERENCE;

}
public PlayerSkins_Reset()
{
	g_iPlayerSkins = 0;
}

public PlayerSkins_Config(&Handle:kv, itemid)
{
//	Handle kv;
//	CloneHandle(kvv, kv);
	Store_SetDataIndex(itemid, g_iPlayerSkins);
	
	KvGetString(kv, "model", g_ePlayerSkins[g_iPlayerSkins].szModel, PLATFORM_MAX_PATH);
	KvGetString(kv, "arms", g_ePlayerSkins[g_iPlayerSkins].szArms, PLATFORM_MAX_PATH);
	g_ePlayerSkins[g_iPlayerSkins].iSkin = KvGetNum(kv, "skin");
//	g_ePlayerSkins[g_iPlayerSkins].iTeam = KvGetNum(kv, "team");
	g_ePlayerSkins[g_iPlayerSkins].iClass = KvGetNum(kv, "class");
//	g_ePlayerSkins[g_iPlayerSkins][bTemporary] = (KvGetNum(kv, "temporary")?true:false);
	
	if(strlen(g_ePlayerSkins[g_iPlayerSkins].szModel) > 3 && FileExists(g_ePlayerSkins[g_iPlayerSkins].szModel, true))
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
	if(g_eCvars[g_cvarSkinChangeInstant].aCache && IsPlayerAlive(client) && (TF2_GetPlayerClassAsNumber(client)==g_ePlayerSkins[m_iData].iClass || g_ePlayerSkins[m_iData].iClass==10))
	{
		Store_SetClientModel(client, g_ePlayerSkins[m_iData].szModel, g_ePlayerSkins[m_iData].iSkin, g_ePlayerSkins[m_iData].szArms);
	}
	else
	{
		if(Store_IsClientLoaded(client))
			CPrintToChat(client, "%s%t", g_sChatPrefix, "PlayerSkins Settings Changed");

//		if(g_ePlayerSkins[m_iData][bTemporary])
//		{
//			g_iTempSkins[client] = m_iData;
//			return -1;
//		}
	}
	new class=g_ePlayerSkins[m_iData].iClass-1;
	if(class >= 0 && class <= 9)
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
		CPrintToChat(client, "%s%t", g_sChatPrefix, "PlayerSkins Settings Changed");
		return g_ePlayerSkins[Store_GetDataIndex(id)].iClass-1;
	}
	if(class >= 0 && class <= 9)
		g_Equipped[client][class]=0;
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	RemoveValveHat(client, true);
	
/*	if(playerText[client] != INVALID_ENT_REFERENCE)
	{
		new ent = EntRefToEntIndex(playerText[client]);
		if(IsValidEntity(ent))
		{
			PrintToChatAll("remove remove");
			WorldText_Detach(ent);
			RemoveEntity(ent);
			playerText[client] = INVALID_ENT_REFERENCE;
		}
	}*/
	
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
	if(!IsValidClient(client))
		return Plugin_Stop;

	//if(g_bZombieMode)
	//	if(ZR_IsClientZombie(client))
	//		return Plugin_Continue;
	
	new class=TF2_GetPlayerClassAsNumber(client)-1;
	
	if(RestoreHat[client])
	{
		if(class >= 0 && class <= 9)
			g_Equipped[client][class]=0;
		HasArms[client] = 0;
		TheArms[client] = "";
		RemoveValveHat(client ,true);
		RestoreHat[client] = false;
		
/*		if(playerText[client] != INVALID_ENT_REFERENCE)
		{
			new ent = EntRefToEntIndex(playerText[client]);
			if(IsValidEntity(ent))
			{
				PrintToChatAll("remove remove");
				WorldText_Detach(ent);
				RemoveEntity(ent);
				playerText[client] = INVALID_ENT_REFERENCE;
			}
		}
		*/
	}
	
	new m_iEquipped = Store_GetEquippedItem(client, "playerskin", class);
	if(m_iEquipped < 0)
		m_iEquipped = Store_GetEquippedItem(client, "playerskin", 9);
	if(m_iEquipped >= 0)
	{
		g_iPlayerBGroups[client] = GetEntProp(client, Prop_Send, "m_nBody");
		decl m_iData;
//		if(g_iTempSkins[client]>=0)
//			m_iData = g_iTempSkins[client];
//		else
		m_iData = Store_GetDataIndex(m_iEquipped);
		Store_SetClientModel(client, g_ePlayerSkins[m_iData].szModel, g_ePlayerSkins[m_iData].iSkin, g_ePlayerSkins[m_iData].szArms);
		if(class >= 0 && class <= 9)
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
			SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 0);
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
			SetEntProp(client, Prop_Send, "m_nBody", CalculateBodyGroups(client));
			RemoveValveHat(client);
			(GetClientTeam(client) == 2) ? EquipWearable(client, RED_sign) : EquipWearable(client, BLUE_sign);
/*			int textEnt;
//			float origin[3], angles[3];
//			int iBone = SDKCall(g_hLookupBone, client, "bip_head");
//			if(iBone != -1)
//			{
//				SDKCall(g_hGetBonePosition, client, iBone, origin, angles);
//				origin[2] += 20.0;
//			}

			switch(GetClientTeam(client))
			{
				case 2:
					textEnt = WorldText_Create(NULL_VECTOR, NULL_VECTOR, "RED", 10.0, _, _, FONT_TF2_BULKY, 255, 61, 41, 155, false, ORIENTATION_ALWAYS_FACE_PLAYER);
				case 3:
					textEnt = WorldText_Create(NULL_VECTOR, NULL_VECTOR, "BLUE", 10.0, _, _, FONT_TF2_BULKY, 41, 108, 255, 155, false, ORIENTATION_ALWAYS_FACE_PLAYER);
			}

			if(playerText[client] != INVALID_ENT_REFERENCE)
			{
				new ent = EntRefToEntIndex(playerText[client]);
				if(IsValidEntity(ent))
				{
					PrintToChatAll("equip equip");
					WorldText_Detach(ent);
					RemoveEntity(ent);
					playerText[client] = INVALID_ENT_REFERENCE;
				}
			}

			if (IsValidEntity(textEnt))
			{
				playerText[client] = EntIndexToEntRef(textEnt);
				WorldText_AttachToEntity(textEnt, client, "head", _, _, 20.0);
				Text_Owner[textEnt] = GetClientUserId(client);
				SDKHook(textEnt, SDKHook_SetTransmit, Text_Transmit);
			}*/

			
			if(strlen(arms) > 3)
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

/*public Action:PlayerSkins_PlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	int flags = GetEventInt(event, "death_flags");
	if(flags & TF_DEATHFLAG_DEADRINGER) // Because those damn subplugins
		return Plugin_Continue;
//	g_iTempSkins[client] = -1;
	if(playerText[client] != INVALID_ENT_REFERENCE)
	{
		new ent = EntRefToEntIndex(playerText[client]);
		if(IsValidEntity(ent))
		{
			PrintToChatAll("remove remove");
			WorldText_Detach(ent);
			RemoveEntity(ent);
			playerText[client] = INVALID_ENT_REFERENCE;
		}
	}

	return Plugin_Continue;
}*/

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
		if(m_iEquipped < 0)
			m_iEquipped = Store_GetEquippedItem(client, "playerskin", 9);
		if(m_iEquipped >= 0)
		{
			g_iPlayerBGroups[client] = GetEntProp(client, Prop_Send, "m_nBody");
			decl m_iData;
			m_iData = Store_GetDataIndex(m_iEquipped);
			Store_SetClientModel(client, g_ePlayerSkins[m_iData].szModel, g_ePlayerSkins[m_iData].iSkin, g_ePlayerSkins[m_iData].szArms);
			if(class >= 0 && class <= 9)
				g_Equipped[client][class]=1;
			if(HasArms[client] == class + 1)
			{
				new active_weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(active_weapon <= 0 || active_weapon > 2048)
					return Plugin_Continue;
				if(!IsValidEntity(active_weapon))
					return Plugin_Continue;

//				new DataPack:gPack = new DataPack();
//				gPack.WriteCell(EntIndexToEntRef(client));
//				gPack.WriteCell(EntIndexToEntRef(active_weapon));
//				RequestFrame(OnDrawWeapon, gPack);
				ChangeArm(client, active_weapon);
				
/*				new weapon = GetPlayerWeaponSlot(client, 4);
				if(IsValidEntity(weapon))
				{
					new String:classname[64];
					GetEntityClassname(weapon, classname, sizeof(classname));
					if(StrEqual(classname, "tf_weapon_invis", false))
					{
//						ChangeArm(client, weapon);
//						new viewmodel = GetEntPropEnt(client, Prop_Send, "m_hViewModel", 1);



//						new wearable1 = CreateEntityByName("tf_wearable_vm");
//						if(!IsValidEntity(wearable1))
//							return Plugin_Continue;
//						SetEntProp(wearable1, Prop_Send, "m_iItemDefinitionIndex", 65535);
//						SetEntProp(wearable1, Prop_Send, "m_nModelIndex", GetEntProp(weapon, Prop_Send, "m_iViewModelIndex"));
//						SetEntProp(wearable1, Prop_Send, "m_bValidatedAttachedEntity", 1);
//						DispatchSpawn(wearable1);
//						TF2Util_EquipPlayerWearable(client, wearable1);
//						SetEntityRenderMode(wearable1, RENDER_TRANSCOLOR);
//						SetEntityRenderColor(wearable1, 255, 255, 255, 0);

						new wearable2 = CreateEntityByName("tf_wearable_vm");
						if(!IsValidEntity(wearable2))
							return Plugin_Continue;
						SetEntProp(wearable2, Prop_Send, "m_nModelIndex", PrecacheModel(TheArms[client]));
						SetEntProp(wearable2, Prop_Send, "m_fEffects",  EF_BONEMERGE | EF_BONEMERGE_FASTCULL);
						SetEntProp(wearable2, Prop_Send, "m_iTeamNum", GetClientTeam(client));
						SetEntProp(wearable2, Prop_Send, "m_nSkin", GetClientTeam(client));
						SetEntProp(wearable2, Prop_Send, "m_usSolidFlags", 4);
						SetEntProp(wearable2, Prop_Send, "m_CollisionGroup", 11);
						SetEntProp(wearable2, Prop_Send, "m_iEntityQuality", 1);
						SetEntProp(wearable2, Prop_Send, "m_iEntityLevel", -1);
						SetEntProp(wearable2, Prop_Send, "m_iItemIDLow", 2048);
						SetEntProp(wearable2, Prop_Send, "m_iItemIDHigh", 0);
						SetEntProp(wearable2, Prop_Send, "m_bInitialized", 1);
						SetEntProp(wearable2, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
						SetEntProp(wearable2, Prop_Send, "m_bValidatedAttachedEntity", 1);

						DispatchSpawn(wearable2);
						SetVariantString("!activator");
						ActivateEntity(wearable2);
						
						TF2Util_EquipPlayerWearable(client, wearable2);


//						SetEntPropEnt(wearable1, Prop_Send, "m_hWeaponAssociatedWith", weapon);
						SetEntPropEnt(wearable2, Prop_Send, "m_hWeaponAssociatedWith", weapon);

					}
				}*/
			}
		}
	}
	return Plugin_Continue;
}


public void SDHook_OnWeaponSwitchPost(client, weapon)
{
//	PrintToChat(client, "fuckfuckfuck")
	new class = TF2_GetPlayerClassAsNumber(client) - 1;
	if(class >= 0 && class <= 9)
	{
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
		else
			ChangeArm(client, weapon, true);
	}
//	else if(!IsBoss(client) && !g_Equipped[client][class])
//	{
//		ChangeArm(client, weapon, true);
//	}
	return;
}

/*public void SDHook_OnWeaponEquipPost(client, weapon)
{
	new class = TF2_GetPlayerClassAsNumber(client) - 1;
	if(class >= 0 && class <= 9)
	{
		if((HasArms[client] == class+1) && g_Equipped[client][class] && !IsBoss(client))
			ChangeArm(client, weapon);
	}

	return;
}*/


public OnDrawWeapon(DataPack:hPack)
{
	hPack.Reset();
	new client = EntRefToEntIndex(hPack.ReadCell());
	new weapon = EntRefToEntIndex(hPack.ReadCell());
	delete hPack;

	if(client == -1 || weapon == -1)
		return;
		
//	new boss = GetClientOfUserId(FF2_GetBossUserId(0));

//	SDKCall(g_hFollowEntity, boss, client, true);

/*	new weapon1 = GetPlayerWeaponSlot(client, 4);
	if(IsValidEntity(weapon1))
	{
		new String:classname[64];
		GetEntityClassname(weapon1, classname, sizeof(classname));
		if(!StrEqual(classname, "tf_weapon_invis", false))
			weapon1 = 0;
	}

	new vm = -1;
	while( ( vm = FindEntityByClassname( vm, "tf_viewmodel" ) ) != -1 )	// hide the view model
	{ 
		if(client == GetEntPropEnt(vm, Prop_Send, "m_hOwner"))
		{
			new index = GetEntProp(vm, Prop_Send, "m_nViewModelIndex");
			new wep = GetEntPropEnt(vm, Prop_Send, "m_hWeapon");
			if(IsValidEntity(wep))
			{
				if(GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex") == 59)
					PrintToChatAll("%d, %d, %d", index, wep, weapon1);
				if(weapon1)
				{
					SetEntProp(vm, Prop_Send, "m_fEffects", GetEntProp(vm, Prop_Send, "m_fEffects") | 32);
					ChangeEdictState(vm, FindSendPropInfo("CBaseViewModel","m_fEffects"));
					
					new ent = CreateEntityByName("tf_wearable_vm");
					if (!IsValidEntity(ent)) 
						return;

					SetEntProp(ent, Prop_Send, "m_nModelIndex", PrecacheModel(TheArms[client]));
					SetEntProp(ent, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL);
					SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
					SetEntProp(ent, Prop_Send, "m_usSolidFlags", 4);
					SetEntProp(ent, Prop_Send, "m_CollisionGroup", 11);

					DispatchSpawn(ent);
					SetVariantString("!activator");
					ActivateEntity(ent);

					TF2Util_EquipPlayerWearable(client, ent);
					
					SetEntPropEnt(ent, Prop_Send, "m_hWeaponAssociatedWith", weapon);
					SetEntPropEnt(weapon, Prop_Send, "m_hExtraWearableViewModel", ent);
					
					SDKCall(g_hFollowEntity, ent, -1, true);
					SDKCall(g_hFollowEntity, ent, client, true);
				}
			}
		}
	}
*/

	ChangeArm(client, weapon);

	return;
}

ChangeArm(client, weapon, bool:stockArm = false)
{
	new ModelIndex;
	if(!stockArm)
	{
		ModelIndex = PrecacheModel(TheArms[client]);
//		PrecacheModel(TheArms[client]);
//		SetEntityModel(weapon, TheArms[client]);
	}
	else
	{
/*		new TFClassType:class = TF2_GetPlayerClass(client);
		char arms[PLATFORM_MAX_PATH];
		switch (class)
		{
			case TFClass_Scout: Format(arms, sizeof(arms), "models/weapons/c_models/c_scout_arms.mdl");
			case TFClass_Soldier: Format(arms, sizeof(arms), "models/weapons/c_models/c_soldier_arms.mdl");
			case TFClass_Pyro: Format(arms, sizeof(arms), "models/weapons/c_models/c_pyro_arms.mdl");
			case TFClass_DemoMan: Format(arms, sizeof(arms), "models/weapons/c_models/c_demo_arms.mdl");
			case TFClass_Heavy: Format(arms, sizeof(arms), "models/weapons/c_models/c_heavy_arms.mdl");
			case TFClass_Engineer: 
			{
				int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
				if(IsValidEntity(melee))
				{
					if(GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex") == 142)
						Format(arms, sizeof(arms), "models/weapons/c_models/c_engineer_gunslinger.mdl");
					else
						Format(arms, sizeof(arms), "models/weapons/c_models/c_engineer_arms.mdl");
				}
				else
					Format(arms, sizeof(arms), "models/weapons/c_models/c_engineer_arms.mdl");
			}
			case TFClass_Medic: Format(arms, sizeof(arms), "models/weapons/c_models/c_medic_arms.mdl");
			case TFClass_Sniper: Format(arms, sizeof(arms), "models/weapons/c_models/c_sniper_arms.mdl");
			case TFClass_Spy: Format(arms, sizeof(arms), "models/weapons/c_models/c_spy_arms.mdl");
		}
		SetEntityModel(weapon, arms);
*/
		ModelIndex = GetEntProp(weapon, Prop_Send, "m_nModelIndex");
	}
	if(ModelIndex)
	{
		SetEntProp(weapon, Prop_Send, "m_nCustomViewmodelModelIndex", ModelIndex);
		SetEntProp(weapon, Prop_Send, "m_iViewModelIndex", ModelIndex);
	}
//	SetEntProp(weapon, Prop_Send, "m_nCustomViewmodelModelIndex", GetEntProp(weapon, Prop_Send, "m_nModelIndex"));
//	SetEntProp(weapon, Prop_Send, "m_iViewModelIndex", GetEntProp(weapon, Prop_Send, "m_nModelIndex"));
}

public void Store_OnPreviewItem(int client, char[] type, int index)
{
	//if (!StrEqual(type, "playerskin"))
	//	return;
		
	if(g_hTimerPreview[client] != null) 
		TriggerTimer(g_hTimerPreview[client], false);

	if (StrEqual(type, "playerskin"))
	{
		int iPreview = CreateEntityByName("prop_dynamic_override"); //prop_physics_multiplayer
		
		if (g_hTimerPreview[client] != null) 
		{
			delete g_hTimerPreview[client];
			g_hTimerPreview[client] = null;
		} 

		DispatchKeyValue(iPreview, "spawnflags", "64");
//		if(StrEqual(type, "playerskin"))
		DispatchKeyValue(iPreview, "model", g_ePlayerSkins[index].szModel);
//		else if(StrEqual(type, "arms"))
//			DispatchKeyValue(iPreview, "model", g_ePlayerArms[index].szModel);
			
		DispatchSpawn(iPreview);

		SetEntProp(iPreview, Prop_Send, "m_CollisionGroup", 11);

		AcceptEntityInput(iPreview, "Enable");

		SetEntProp(iPreview, Prop_Send, "m_nSkin", g_ePlayerSkins[index].iSkin);
//		if (g_ePlayerSkins[index].iBody > 0)
//		{
//			SetEntProp(iPreview, Prop_Send, "m_nBody", g_ePlayerSkins[index].iBody);
//		}


		float fOrigin[3], fAngles[3], fRad[2], fPosition[3];

		GetClientAbsOrigin(client, fOrigin);
		GetClientAbsAngles(client, fAngles);

		fRad[0] = DegToRad(fAngles[0]);
		fRad[1] = DegToRad(fAngles[1]);

		fPosition[0] = fOrigin[0] + 64 * Cosine(fRad[0]) * Cosine(fRad[1]);
		fPosition[1] = fOrigin[1] + 64 * Cosine(fRad[0]) * Sine(fRad[1]);
		fPosition[2] = fOrigin[2] + 4 * Sine(fRad[0]);

		fAngles[0] *= -1.0;
		fAngles[1] *= -1.0;

//		if(StrEqual(type, "playerskin"))
		fPosition[2] += 5;
//		else if(StrEqual(type, "arms"))
//			fPosition[2] += 45;

		TeleportEntity(iPreview, fPosition, fAngles, NULL_VECTOR);

		g_iPreviewEntity[client] = EntIndexToEntRef(iPreview);

		int iRotator = CreateEntityByName("func_rotating");
		DispatchKeyValueVector(iRotator, "origin", fPosition);

		DispatchKeyValue(iRotator, "maxspeed", "20");
		DispatchKeyValue(iRotator, "spawnflags", "64");
		DispatchSpawn(iRotator);

		SetVariantString("!activator");
		AcceptEntityInput(iPreview, "SetParent", iRotator, iRotator);
		AcceptEntityInput(iRotator, "Start");

		SDKHook(iPreview, SDKHook_SetTransmit, Hook_SetTransmit_Preview);

		g_hTimerPreview[client] = CreateTimer(45.0, Timer_KillPreview, client);

		CPrintToChat(client, "%s%t", g_sChatPrefix, "Spawn Preview", client);
	}
}

public Action Hook_SetTransmit_Preview(int ent, int client)
{
	if (g_iPreviewEntity[client] == INVALID_ENT_REFERENCE)
		return Plugin_Handled;

	if (ent == EntRefToEntIndex(g_iPreviewEntity[client]))
		return Plugin_Continue;

	return Plugin_Handled;
}

public Action Timer_KillPreview(Handle timer, int client)
{
	g_hTimerPreview[client] = null;

	if (g_iPreviewEntity[client] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(g_iPreviewEntity[client]);

		if (entity > 0 && IsValidEdict(entity))
		{
			SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit_Preview);
			AcceptEntityInput(entity, "Kill");
		}
	}
	g_iPreviewEntity[client] = INVALID_ENT_REFERENCE;

	return Plugin_Stop;
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

/*public Action Text_Transmit(int entity, int client)
{
//	SetEdictFlags(entity, GetEdictFlags(entity)&(~FL_EDICT_ALWAYS));
	int owner = GetClientOfUserId(Text_Owner[entity]);
//	if (client == owner)
//	{
//		return Plugin_Handled;
//		return Plugin_Continue;
//	}
//	else

//	{
		if(TF2_IsPlayerInCondition(owner, TFCond_Disguised) || TF2_IsPlayerInCondition(owner, TFCond_Cloaked)
		|| TF2_IsPlayerInCondition(owner, TFCond_Stealthed) || TF2_IsPlayerInCondition(owner, TFCond_CloakFlicker)
		|| TF2_IsPlayerInCondition(owner, TFCond_DeadRingered))
		{
			return Plugin_Handled;
		}
//	}

	return Plugin_Continue;
}*/

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
	TF2Util_EquipPlayerWearable(client, ent); // urg
	return ent;
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