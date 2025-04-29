#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <freak_fortress_2>

//#pragma semicolon 1;
#define MAX_BUTTONS 26
#define VERSION "1.0"
public Plugin:myinfo = 
{
	name = "Projectile Spycam",
	author = "GovTonyBaretta",
	description = "",
	version = "VERSION",
	url = ""
};
#define IN_ATTACK      (1 << 0)
#define IN_JUMP   (1 << 1)
#define IN_DUCK   (1 << 2)
#define IN_FORWARD    (1 << 3)
#define IN_BACK   (1 << 4)
#define IN_USE      (1 << 5)
#define IN_CANCEL      (1 << 6)
#define IN_LEFT   (1 << 7)
#define IN_RIGHT        (1 << 8)
#define IN_MOVELEFT  (1 << 9)
#define IN_MOVERIGHT        (1 << 10)
#define IN_ATTACK2    (1 << 11)
#define IN_RUN      (1 << 12)
#define IN_RELOAD      (1 << 13)
#define IN_ALT1   (1 << 14)
#define IN_ALT2   (1 << 15)
#define IN_SCORE        (1 << 16)       // Used by client.dll for when scoreboard is held down
#define IN_SPEED        (1 << 17)   // Player is holding the speed key
#define IN_WALK   (1 << 18)    // Player holding walk key
#define IN_ZOOM   (1 << 19)    // Zoom key for HUD zoom
#define IN_WEAPON1    (1 << 20) // weapon defines these bits
#define IN_WEAPON2    (1 << 21) // weapon defines these bits
#define IN_BULLRUSH  (1 << 22)
#define IN_GRENADE1  (1 << 23)    // grenade 1
#define IN_GRENADE2  (1 << 24)    // grenade 2 

#define EF_NODRAW 0x020		// don't draw entity

// solid types
#define SOLID_NONE 0 // no solid model
#define SOLID_BSP 1 // a BSP tree
#define SOLID_BBOX 2 // an AABB
#define SOLID_OBB 3 // an OBB (not implemented yet)
#define SOLID_OBB_YAW 4 // an OBB, constrained so that it can only yaw
#define SOLID_CUSTOM 5 // Always call into the entity for tests
#define SOLID_VPHYSICS 6 // solid vphysics object, get vcollide from the model and collide with that

#define FSOLID_CUSTOMRAYTEST 0x0001 // Ignore solid type + always call into the entity for ray tests
#define FSOLID_CUSTOMBOXTEST 0x0002 // Ignore solid type + always call into the entity for swept box tests
#define FSOLID_NOT_SOLID 0x0004 // Are we currently not solid?
#define FSOLID_TRIGGER 0x0008 // This is something may be collideable but fires touch functions
#define FSOLID_NOT_STANDABLE 0x0010 // You can't stand on this
#define FSOLID_VOLUME_CONTENTS 0x0020 // Contains volumetric contents (like water)
#define FSOLID_FORCE_WORLD_ALIGNED 0x0040 // Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
#define FSOLID_USE_TRIGGER_BOUNDS 0x0080 // Uses a special trigger bounds separate from the normal OBB
#define FSOLID_ROOT_PARENT_ALIGNED 0x0100 // Collisions are defined in root parent's local coordinate space
#define FSOLID_TRIGGER_TOUCH_DEBRIS 0x0200 // This trigger will touch debris objects

enum // Collision_Group_t in const.h
{
	COLLISION_GROUP_NONE  = 0,
	COLLISION_GROUP_DEBRIS,			// Collides with nothing but world and static stuff
	COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
	COLLISION_GROUP_INTERACTIVE_DEBRIS,	// Collides with everything except other interactive debris or debris
	COLLISION_GROUP_INTERACTIVE,	// Collides with everything except interactive debris or debris
	COLLISION_GROUP_PLAYER,
	COLLISION_GROUP_BREAKABLE_GLASS,
	COLLISION_GROUP_VEHICLE,
	COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player, for
										// TF2, this filters out other players and CBaseObjects
	COLLISION_GROUP_NPC,			// Generic NPC group
	COLLISION_GROUP_IN_VEHICLE,		// for any entity inside a vehicle
	COLLISION_GROUP_WEAPON,			// for any weapons that need collision detection
	COLLISION_GROUP_VEHICLE_CLIP,	// vehicle clip brush to restrict vehicle movement
	COLLISION_GROUP_PROJECTILE,		// Projectiles!
	COLLISION_GROUP_DOOR_BLOCKER,	// Blocks entities not permitted to get near moving doors
	COLLISION_GROUP_PASSABLE_DOOR,	// ** sarysa TF2 note: Must be scripted, not passable on physics prop (Doors that the player shouldn't collide with)
	COLLISION_GROUP_DISSOLVING,		// Things that are dissolving are in this group
	COLLISION_GROUP_PUSHAWAY,		// ** sarysa TF2 note: I could swear the collision detection is better for this than NONE. (Nonsolid on client and server, pushaway in player code)

	COLLISION_GROUP_NPC_ACTOR,		// Used so NPCs in scripts ignore the player.
	COLLISION_GROUP_NPC_SCRIPTED,	// USed for NPCs in scripts that should not collide with each other

	LAST_SHARED_COLLISION_GROUP
};

#define EF_BONEMERGE                (1 << 0)
#define EF_NOSHADOW                 (1 << 4)
#define EF_NORECEIVESHADOW          (1 << 6)
#define EF_PARENT_ANIMATES          (1 << 9)

//#define Camera_mdl "models/props_spytech/security_camera.mdl"
bool ClientCanUse[MAXPLAYERS+1] = false;
bool FPView[MAXPLAYERS+1] = false;
ConVar CvarFlyView;
ConVar CvarEnable;
ConVar CvarHideCam;
ConVar CvarProjType;
ConVar CvarProjOwner;
ConVar CvarCaneraModel;
float ClientAngles[MAXPLAYERS+1][3];
float ClientOrigins[MAXPLAYERS+1][3];

float SpycamPos[MAXPLAYERS+1][3];

int iFakeEnt;
int g_iPlayerLastButtons[MAXPLAYERS + 1];
public void OnMapStart() {
	char ModelCamera[512];
	GetConVarString(CvarCaneraModel, ModelCamera, sizeof(ModelCamera));
	PrecacheModel(ModelCamera, true);
}
public OnPluginStart()
{
	CreateConVar("spycam_version", VERSION, "spycam version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	CvarEnable = CreateConVar("spycam_enable", "1", "spycam_enable?", FCVAR_NONE, true, 0.0, true, 1.0);
	CvarFlyView = CreateConVar("flyview_enabled", "1", "Enable Fly View", FCVAR_NONE, true, 0.0, true, 1.0);
	CvarHideCam = CreateConVar("hide_cam", "1", "hide cam model", FCVAR_NONE, true, 0.0, true, 1.0);
	CvarProjType = CreateConVar("proj_type", "tf_projectile_stun_ball", "projectile type", FCVAR_NONE);
	CvarProjOwner = CreateConVar("detect_owner", "0", "0 to m_hOwnerEntity, 1 to m_hThrower", FCVAR_NONE, true, 0.0, true, 1.0);
	CvarCaneraModel = CreateConVar("cam_model", "models/props_spytech/security_camera.mdl", "camera model ", FCVAR_NONE);
	RegConsoleCmd("sm_fw", cmd_flyview,"use fly view");
	RegConsoleCmd("sm_camhelp", cmd_camhelp,"help");
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	AutoExecConfig(true, "proj_camera_cfg");
}
	
public Action cmd_flyview(int client, int args)
{
	if(CvarFlyView.BoolValue && CvarEnable.BoolValue){
		if (!FPView[client])
		{
			FPView[client] = true;
			PrintToChat(client, "\x04 [Spycam]\x01 Fly view camera On");
		}
		else{
			FPView[client] = false;
			PrintToChat(client, "\x04 [Spycam]\x01 Fly view camera Off");
		}
	}
}
public Action cmd_camhelp(int client, int args)
{
	if(CvarEnable.BoolValue){
		ShowHelpMenu(client);
	}
}
public ShowHelpMenu(client)
{
	new Handle:menu = CreateMenu(MenuHelp);
	SetMenuTitle(menu, "SpyCam Help");
	AddMenuItem(menu, "", "COMMANDS");
	AddMenuItem(menu, "", "!fw , enable first person view on baseball(1 time only)");
	AddMenuItem(menu, "", "!camhelp , enable this menu");
	AddMenuItem(menu, "", "INSTRUCTIONS");
	AddMenuItem(menu, "", "After beating the ball, holding RELOAD will enable the spycam ,releasing the button return to the player ");		
	SetMenuExitButton(menu,true);
	DisplayMenu(menu,client,20);
}
public MenuHelp(Handle:menu,MenuAction:action,param1,param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(CvarEnable.BoolValue){
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		BackTolayer(client);
	}
}
public OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(CvarEnable.BoolValue){
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		BackTolayer(client);
	}
}
public SavePlayerPos(int client)
{
	GetClientEyeAngles(client, ClientAngles[client]);
	CPrintToChatAll("0 %f",ClientAngles[client][0]);
	CPrintToChatAll("1 %f",ClientAngles[client][1]);
	CPrintToChatAll("2 %f",ClientAngles[client][2]);
	GetClientAbsOrigin(client, ClientOrigins[client]);
}
public Action OnPlayerRunCmd(int iClient,int &buttons,int &impulse, float vel[3], float angles[3],int &weapon,int &subtype,int &cmdnum,int &tickcount,int &seed,int mouse[2])
{
	if(CvarEnable.BoolValue){
		for (int i = 0; i < MAX_BUTTONS; i++)
		{
			int button = (1 << i);

			if ((buttons & button))
			{
				if (!(g_iPlayerLastButtons[iClient] & button))
				{
					ClientOnButtonPress(iClient, button);
				}
			}
			else if ((g_iPlayerLastButtons[iClient] & button))
			{
				ClientOnButtonRelease(iClient, button);
			}
		}
		g_iPlayerLastButtons[iClient] = buttons;
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public void ClientOnButtonPress(int iClient,int button)
{
	if (button == IN_RELOAD)
	{
		if(!ClientCanUse[iClient])
		CreateTimer(0.1, saveposAction, iClient);
	}
}
public void ClientOnButtonRelease(int iClient,int button)
{
	if (button == IN_RELOAD)
	{
		if(ClientCanUse[iClient])
		BackTolayer(iClient);
	}

}
int OwnerCheck(int iEntity){
	int iOwner;
	if(!CvarProjOwner.BoolValue){
		iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	}
	if(CvarProjOwner.BoolValue){
		iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hThrower");
	}
	return iOwner;
}
public void OnGameFrame()
{
	if(CvarEnable.BoolValue){
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && ClientCanUse[i])
			{	int owner = OwnerCheck(iFakeEnt);
				if(owner == i){
					new bossindex = GetClientOfUserId(FF2_GetBossUserId(0));
//					GetClientEyeAngles(i, ClientAngles[i]);
					decl Float:angle[3],Float:pos[3];
					GetClientEyeAngles(bossindex, angle);
					GetClientEyePosition(bossindex, pos);
//					ClientAngles[bossindex][2] = 0.0;

					angle[2]=0.0;
					
//					TeleportEntity(iFakeEnt, pos, angle, NULL_VECTOR);
				}
			}
		}
	}
}
public int SaveCamPos(int client)
{
	int ent = -1;
	char buffer[512];
	GetConVarString(CvarProjType, buffer, sizeof(buffer));
	while ((ent = FindEntityByClassname(ent, buffer)) != -1){
		int owner = OwnerCheck(ent);
		SetEntPropString(ent, Prop_Data, "m_iName", "spycam_ball");
		if(owner == client && !ClientCanUse[client]){
			FPView[client] = false;
			ClientCanUse[client] = true;
			float position[3];
			GetEntityAbsOrigin(ent, position);
			SpycamPos[client] = position;
			iFakeEnt = CreateEntityByName("prop_dynamic");
			if(IsValidEntity(iFakeEnt)){
				char ModelCamera[512];
				GetConVarString(CvarCaneraModel, ModelCamera, sizeof(ModelCamera));
				DispatchKeyValue(iFakeEnt, "model", ModelCamera);
				DispatchKeyValue(iFakeEnt,"skin", "0");
				DispatchKeyValue(iFakeEnt, "targetname", "spycam");
				SetEntProp(iFakeEnt, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID); // not solid
				SetEntProp(iFakeEnt, Prop_Send, "m_nSolidType", SOLID_NONE); // not solid
				SetEntProp(iFakeEnt, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_NONE);
				SetEntPropEnt(iFakeEnt, Prop_Send, "m_hOwnerEntity", client);
				SetEntPropFloat(iFakeEnt, Prop_Send, "m_flModelScale", 0.001);
//				SetEntProp(iFakeEnt, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_NORECEIVESHADOW|EF_PARENT_ANIMATES);
				DispatchSpawn(iFakeEnt);
				SpycamPos[client][2] +=50.0;
				
				
				new bossindex = GetClientOfUserId(FF2_GetBossUserId(0));
				decl Float:angle[3],Float:pos[3];
				GetClientEyeAngles(bossindex, angle);
				GetClientEyePosition(bossindex, pos);
//				ClientAngles[bossindex][2] = 0.0;
				
				angle[2]=0.0;
				
				TeleportEntity(iFakeEnt, pos, angle, NULL_VECTOR);
				SetParent(bossindex, iFakeEnt ,"eyes");
				
//				TeleportEntity(iFakeEnt, SpycamPos[client], ClientAngles[client], NULL_VECTOR);
				SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
				if(CvarHideCam.BoolValue){
					SetEntityRenderColor(iFakeEnt, 255, 255, 255, 0);
				}

//				SetClientViewEntity(client, bossindex);
				SetEntPropEnt(client,Prop_Data, "m_hViewEntity", bossindex);
				// hide the player's viewmodel
				new viewModel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
				if (IsValidEntity(viewModel))
					SetEntProp(viewModel, Prop_Send, "m_fEffects", GetEntProp(viewModel, Prop_Send, "m_fEffects") | EF_NODRAW);
				SetClientViewEntity(client, iFakeEnt);
				SetEntityMoveType(client, MOVETYPE_OBSERVER);
			}
		}
	}
}

public int BackTolayer(int client)
{
	if(ClientCanUse[client])
	{
		if(IsValidClient(client))
		{
			SetClientViewEntity(client, client);
			SetEntPropEnt(client,Prop_Data, "m_hViewEntity", client);
			// show the player's viewmodel
			new viewModel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
			if (IsValidEntity(viewModel))
				SetEntProp(viewModel, Prop_Send, "m_fEffects", GetEntProp(viewModel, Prop_Send, "m_fEffects") & ~EF_NODRAW);

			SetEntityMoveType(client, MOVETYPE_WALK);
			SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		}
		ClientCanUse[client] = false;
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1){
			int owner = OwnerCheck(entity);
			char strName[50];
			GetEntPropString(entity, Prop_Data, "m_iName", strName, sizeof(strName));

			if(strcmp(strName, "spycam") == 0 && owner == client)
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
		int entity2 = -1;
		char buffer[512];
		GetConVarString(CvarProjType, buffer, sizeof(buffer));
		while ((entity2 = FindEntityByClassname(entity2, buffer)) != -1){
			int owner = OwnerCheck(entity2);
			char strName[50];
			GetEntPropString(entity2, Prop_Data, "m_iName", strName, sizeof(strName));

			if(strcmp(strName, "spycam_ball") == 0 && owner == client)
			{
				AcceptEntityInput(entity2, "Kill");
			}
		}
	}
}


public void OnClientDisconnect(int client)
{
	if(CvarEnable.BoolValue){
		BackTolayer(client);
	}
}


public void OnEntityCreated(int iEntity, const char[] classname) 
{
	if(CvarEnable.BoolValue){
		char buffer[512];
		GetConVarString(CvarProjType, buffer, sizeof(buffer));
		if(StrEqual(classname, buffer)) SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
	}
}

public int OnEntitySpawned(int iGrenade)
{
	int client = OwnerCheck(iGrenade);
	SetEntPropString(iGrenade, Prop_Data, "m_iName", "spycam_ball");
	SavePlayerPos(client);
	if(FPView[client]){
		new bossindex = GetClientOfUserId(FF2_GetBossUserId(0));
		new viewModels = GetEntPropEnt(bossindex, Prop_Send, "m_hViewModel");
		SetClientViewEntity(client, viewModels);
//		SetClientViewEntity(client, bossindex);
//		SetClientViewEntity(client, iGrenade);
	}
	CreateTimer(6.0, KillBall, client);
	//CreateTimer(4.6, BackTolayerAction, client);
}
public Action KillBall(Handle timer, any client)
{
	int entity2 = -1;
	char buffer[512];
	GetConVarString(CvarProjType, buffer, sizeof(buffer));
	while ((entity2 = FindEntityByClassname(entity2, buffer)) != -1){
		int owner = OwnerCheck(entity2);
		if(owner == client){
			char strName[50];
			GetEntPropString(entity2, Prop_Data, "m_iName", strName, sizeof(strName));

			if(strcmp(strName, "spycam_ball") == 0 && owner == client)
			{
				AcceptEntityInput(entity2, "Kill");
			}
		}
	}
}
public Action saveposAction(Handle timer, any client)
{
	SaveCamPos(client);
}

public Action BackTolayerAction(Handle timer, any client)
{
	BackTolayer(client);
}

GetEntityAbsOrigin(int entity,float origin[3]) {
    float mins[3]; float maxs[3];

    GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
    GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
    GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);

    origin[0] += (mins[0] + maxs[0]) * 0.5;
    origin[1] += (mins[1] + maxs[1]) * 0.5;
    origin[2] += (mins[2] + maxs[2]) * 0.5;
}
stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

stock SetParent(iParent, iChild, const String:szAttachment[] = "", Float:vOffsets[3] = {0.0,0.0,0.0}) 
{ 
    SetVariantString("!activator"); 
    AcceptEntityInput(iChild, "SetParent", iParent, iChild); 

    if (szAttachment[0] != '\0') // Use at least a 0.01 second delay between SetParent and SetParentAttachment inputs. 
    { 
        SetVariantString(szAttachment); // "head" 

        if (!AreVectorsEqual(vOffsets, Float:{0.0,0.0,0.0})) // NULL_VECTOR 
        { 
            decl Float:vPos[3]; 
            GetEntPropVector(iParent, Prop_Send, "m_vecOrigin", vPos); 
            AddVectors(vPos, vOffsets, vPos); 
            TeleportEntity(iChild, vPos, NULL_VECTOR, NULL_VECTOR); 
            AcceptEntityInput(iChild, "SetParentAttachmentMaintainOffset", iParent, iChild); 
        } 
        else 
        { 
            AcceptEntityInput(iChild, "SetParentAttachment", iParent, iChild); 
        } 
    } 
}

stock bool:AreVectorsEqual(Float:vVec1[3], Float:vVec2[3]) 
{ 
    return (vVec1[0] == vVec2[0] && vVec1[1] == vVec2[1] && vVec1[2] == vVec2[2]); 
}  