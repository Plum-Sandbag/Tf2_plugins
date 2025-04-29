#pragma semicolon 1
#pragma newdecls required

// ====[ INCLUDES ]=============================================================
#include <tf2_stocks>

#undef REQUIRE_EXTENSIONS
#include <smffmpeg>

// ====[ DEFINES ]==============================================================
#define PLUGIN_NAME    "Rociar"
#define PLUGIN_VERSION "1.1.6"

#define MAX_FILEPATH 1024

// ====[ HANDLES | CVARS ]======================================================
ConVar g_hCvarEnabled;
ConVar g_hCvarSpraycanNoiseFrequency;
ConVar g_hCvarSprayDistanceLimit;
ConVar g_hCvarSpraySoundToggleTime;
ConVar g_hCvarInformPlayer;
ConVar g_hCvarFallbackMode;
ConVar g_hCvarFallbackFile;
ConVar g_hCvarDecalfrequency;  // Stock CVAR

QueryCookie g_qcCustomsounds[MAXPLAYERS + 1];

// ====[ CVAR VARIABLES ]=======================================================
bool g_bEnabled;                    // Is the plugin enabled
int g_iSpraycanNoiseFrequency;      // Time between making spray noises
float g_fSprayDistanceLimit;        // Minimum allowed distance between two sprays
int g_iSpraySoundToggleTime;        // Time in which meleeing a spray will toggle or restart, requires SMFFMPEG for correct length
int g_iInformPlayer;                // Inform the player about cl_customsounds?
int g_iFallbackMode;                // What to do if the player has cl_customsounds 0
char g_sFallbackFile[MAX_FILEPATH]; // Sound to play if the player has cl_customsounds 0

// ====[ VARIABLES ]============================================================
float g_vSprayLocation     [MAXPLAYERS + 1][3];               // XYZ location of every player's spray
int g_iLastSprayed         [MAXPLAYERS + 1];                  // Last time the player sprayed, to compare with decalfrequency
int g_iLastNoise           [MAXPLAYERS + 1];                  // Last time the player sprayed and the sound played, to compare with g_iSpraySoundToggleTime
bool g_bCustomsoundEnabled [MAXPLAYERS + 1];                  // Tracking which players have cl_customsounds 1
int g_iLastChatMessage     [MAXPLAYERS + 1];                  // Tracking the last message we sent to the player to avoid spamming
bool g_bSMFFMPEG = false;                                     // Is optional dependency SMFFMPEG installed?
int g_iChatspamTime = 0;                                      // Time between chat messages to the player
int g_iSpraySoundToggleTimes[MAXPLAYERS + 1][MAXPLAYERS + 1]; // Tracking which sounds are currently playing for which clients

// ====[ PLUGIN ]===============================================================
public Plugin myinfo =
{
  name = PLUGIN_NAME,
  author = "Hartmann",
  description = "Enhances sprays. Credits: shavit, ReFlexPoison, Nanochip, FlaminSarge",
  version = PLUGIN_VERSION,
  url = "https://www.scg.wtf/"
}

// ====[ EVENTS ]===============================================================
public void OnPluginStart()
{
  CreateConVar("sm_Rociar_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

  g_hCvarEnabled = CreateConVar(
    "sm_Rociar_enabled",
    "1",
    "Enable Plugin\n" ...
      "0 = Disabled\n" ...
      "1 = Enabled",
    _,
    true,
    0.0,
    true,
    1.0
  );
  g_hCvarSpraycanNoiseFrequency = CreateConVar(
    "sm_Rociar_SpraycanNoiseFrequency",
    "10",
    "Spraycan Noise Frequency\n" ...
      "0 = Disable noise entirely\n" ...
      ">0 = Wait N seconds between spraycan noise",
    _,
    true,
    0.0,
    true,
    60.0
  );
  g_hCvarSprayDistanceLimit = CreateConVar(
    "sm_Rociar_SprayDistanceLimit",
    "75.0",
    "Minimum allowed distance between sprays. Note: Sphere, not a square/cube!\n" ...
      "0 = Allow overlapping\n" ...
      ">0 = Prevent sprays being closer than N hammer units",
    _,
    true,
    0.0,
    true,
    1024.0
  );
  g_hCvarSpraySoundToggleTime = CreateConVar(
    "sm_Rociar_SpraySoundToggleTime",
    "5",
    "Without smffmpeg:\n" ...
      "Time in seconds that meleeing a spray will toggle off/on rather than replay the sound\n" ...
    "With smffmpeg:\n" ...
      "0 = Disable toggle\n" ...
      ">0 = Enable toggle for the duration of the sound file",
    _,
    true,
    1.0,
    true,
    60.0
  );
  g_hCvarInformPlayer = CreateConVar(
    "sm_Rociar_CustomsoundsDisabled_Inform",
    "1",
    "Inform the player if cl_customsounds is disabled when meleeing a spray\n" ...
      "0 = Do nothing\n" ...
      "1 = Tell them to use cl_customsounds 1, and the !sprays command to update",
    _,
    true,
    0.0,
    true,
    1.0
  );
  g_hCvarFallbackMode = CreateConVar(
    "sm_Rociar_CustomsoundsDisabled_Mode",
    "1",
    "What to do if the player has cl_customsounds 0 and melees a spray\n" ...
      "0 = Nothing\n" ...
      "1 = Play the fallback sound\n" ...
      "2 = Attempt to play the customsound anyway\n" ...
      "3 = Play the fallback sound and attempt to play the customsound",
    _,
    true,
    0.0,
    true,
    3.0
  );
  g_hCvarFallbackFile = CreateConVar(
    "sm_Rociar_CustomsoundsDisabled_FallbackFile",
    "ui/hitsound_retro2.wav",
    "Which file to play if the player has cl_customsounds 0",
    _,
    _,
    _,
    _,
    _
  );

  g_hCvarDecalfrequency = FindConVar("decalfrequency");

  HookConVarChange(g_hCvarEnabled, OnConVarChange);
  HookConVarChange(g_hCvarSpraycanNoiseFrequency, OnConVarChange);
  HookConVarChange(g_hCvarSprayDistanceLimit, OnConVarChange);
  HookConVarChange(g_hCvarSpraySoundToggleTime, OnConVarChange);
  HookConVarChange(g_hCvarInformPlayer, OnConVarChange);
  HookConVarChange(g_hCvarFallbackMode, OnConVarChange);
  HookConVarChange(g_hCvarFallbackFile, OnConVarChange);

  OnConVarChange(g_hCvarEnabled, "", "");
  OnConVarChange(g_hCvarSpraycanNoiseFrequency, "", "");
  OnConVarChange(g_hCvarSprayDistanceLimit, "", "");
  OnConVarChange(g_hCvarSpraySoundToggleTime, "", "");
  OnConVarChange(g_hCvarInformPlayer, "", "");
  OnConVarChange(g_hCvarFallbackMode, "", "");
  OnConVarChange(g_hCvarFallbackFile, "", "");

  RegConsoleCmd("sprays", Command_Sprays, "Respray all sprays, and recheck client cl_customsounds value");

  for (int i = 1; i <= MaxClients; i++)
  {
    if (IsValidClient(i))
      OnClientPutInServer(i);
  }
}

public void OnAllPluginsLoaded()
{
  if (LibraryExists("smffmpeg"))
    g_bSMFFMPEG = true;
}

public void OnLibraryAdded(const char[] name)
{
  if (strcmp(name, "smffmpeg") == 0)
    g_bSMFFMPEG = true;
}

public void OnLibraryRemoved(const char[] name)
{
  if (strcmp(name, "smffmpeg") == 0)
    g_bSMFFMPEG = false;
}

public void OnMapStart()
{
  for (int i = 1; i <= MAXPLAYERS; i++)
  {
    InitClientValues(i);
  }
}

public void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
  if(convar == g_hCvarEnabled)
    g_bEnabled                = GetConVarBool(g_hCvarEnabled);
  else if(convar == g_hCvarSpraycanNoiseFrequency)
    g_iSpraycanNoiseFrequency = GetConVarInt(g_hCvarSpraycanNoiseFrequency);
  else if(convar == g_hCvarSprayDistanceLimit)
    g_fSprayDistanceLimit     = GetConVarFloat(g_hCvarSprayDistanceLimit);
  else if(convar == g_hCvarSpraySoundToggleTime)
    g_iSpraySoundToggleTime   = GetConVarInt(g_hCvarSpraySoundToggleTime);
  else if(convar == g_hCvarInformPlayer)
    g_iInformPlayer           = GetConVarInt(g_hCvarInformPlayer);
  else if (convar == g_hCvarFallbackMode)
    g_iFallbackMode           = GetConVarInt(g_hCvarFallbackMode);
  else if (convar == g_hCvarFallbackFile)
    GetConVarString(g_hCvarFallbackFile, g_sFallbackFile, MAX_FILEPATH);
}

public void OnClientPutInServer(int iClient)
{
  InitClientValues(iClient);
}

public Action OnPlayerRunCmd(int iClient, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
  if (!g_bEnabled || impulse != 201 || !IsPlayerAlive(iClient))
    return Plugin_Continue;

  // Override the spray function so it doesn't play the sound every time
  impulse = 0;

  float vLookPoint[3];
  float vEyeLocation[3];
  if (!GetClientEyeEndLocation(iClient, vLookPoint))
    return Plugin_Continue;
  GetClientEyePosition(iClient, vEyeLocation);

  // Limit spray distance
  if (GetVectorDistance(vLookPoint, vEyeLocation) > 128)
    return Plugin_Continue;

  int time = GetTime();

  if (time - g_iLastSprayed[iClient] >= GetConVarInt(g_hCvarDecalfrequency))
  {
    for(int i = 1; i <= MaxClients; i++)
    {
      // Don't check overlapping for the player's own spray
      if(i == iClient)
        continue;

      // If the spray is too close to another, don't allow it
      if(GetVectorDistance(vLookPoint, g_vSprayLocation[i]) <= g_fSprayDistanceLimit)
        return Plugin_Continue;
    }

    g_iLastSprayed[iClient] = time;
    g_vSprayLocation[iClient] = vLookPoint;
    DoSpray(iClient, vLookPoint, iClient, true);

    if (time - g_iLastNoise[iClient] >= g_iSpraycanNoiseFrequency)
    {
      g_iLastNoise[iClient] = time;
      PrecacheSound("player/sprayer.wav", true);
      EmitSoundToAll("player/sprayer.wav", iClient, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.6);
    }
  }

  return Plugin_Continue;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
  MarkNativeAsOptional("SMFFMPEG_GetSoundDuration");
  MarkNativeAsOptional("SMFFMPEG_FlushSoundDurationCache"); // You probably don't want to use this anyway

  return APLRes_Success;
}

public Action TF2_CalcIsAttackCritical(int iClient, int weapon, char[] weaponname, bool &result)
{
  if (!g_bEnabled)
    return Plugin_Continue;

  if (!IsValidEntity(weapon))
    return Plugin_Continue;

  if (weapon != GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee))
    return Plugin_Continue;

  if (!g_bCustomsoundEnabled[iClient] && g_iFallbackMode == 0)
    return Plugin_Continue;

  float vLookPoint[3];
  float vEyeLocation[3];
  if(!GetClientEyeEndLocation(iClient, vLookPoint))
    return Plugin_Continue;
  GetClientEyePosition(iClient, vEyeLocation);

  for(int i = 1; i <= MaxClients; i++)
  {
    // Sprays of players who have left the game and not been replaced can still
    // function, but let's not assume
    if(!IsValidClient(i))
      continue;

    // Player must be near enough to the spray, and be looking close to the
    // center of the spray
    if(GetVectorDistance(vEyeLocation, g_vSprayLocation[i]) > 64 ||
      GetVectorDistance(vLookPoint, g_vSprayLocation[i]) > 32)
      continue;

    if (!g_bCustomsoundEnabled[iClient] && g_iInformPlayer == 1)
      PrintToChatEx(iClient, "[Rociar]你的自定义音效处于关闭状态,控制台输入 "cl_customsounds 1" 然后在对话框输入 !sprays .");

    int time = GetTime();

    char jingleFile[MAX_FILEPATH];
    char jingleServerFile[MAX_FILEPATH];
    int targetPlayerHasJingle = GetPlayerJingleTempPath(i, jingleFile);

    if (!targetPlayerHasJingle)
      jingleFile = g_sFallbackFile;

    GetPlayerJingleUserCustomPath(i, jingleServerFile);

    if (targetPlayerHasJingle)
      PrecacheSound(jingleFile, true);
    PrecacheSound(g_sFallbackFile, true);
    EmitSoundToClient(iClient, jingleFile, 0, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_STOPLOOPING);

    // If spray sound toggling is enabled, and we've actually got one playing,
    // and the elapsed time is within the sound's range, don't play the sound
    if (g_iSpraySoundToggleTime > 0 &&
      g_iSpraySoundToggleTimes[iClient][i] != 0 &&
      time < g_iSpraySoundToggleTimes[iClient][i])
    {
      g_iSpraySoundToggleTimes[iClient][i] = 0;
      return Plugin_Continue;
    }

    // If the target does or doesn't have a jingle, and acting player has
    // jingles enabled, inform player of what happens
    if (g_bCustomsoundEnabled[iClient] && g_iInformPlayer == 1)
    {
      char msg[128];

      if (targetPlayerHasJingle)
        msg = "[Rociar]正在播放%N的音频文件,再次近战打击喷漆来停止";
      else if (i == iClient)
        msg = "[Rociar]根据https://tieba.baidu.com/p/2566271887 自定义你的音频文件!";
      else
        msg = "[Rociar] %N 没有自定义音频! :(";

      PrintToChatEx1(iClient, msg, i);
    }

    int toggleTime = time;
    if (g_bSMFFMPEG)
      toggleTime = time + SMFFMPEG_GetSoundDuration(jingleServerFile);

    // SMFFMPEG will return 0 if a file does not exist
    if (!g_bSMFFMPEG || toggleTime == time)
      toggleTime = time + g_iSpraySoundToggleTime;

    // If player has customsounds enabled, target spray has a jingle, or if
    // customsounds disabled and fallback selected
    if ((g_bCustomsoundEnabled[iClient] && targetPlayerHasJingle) ||
      (g_iFallbackMode == 2 || g_iFallbackMode == 3))
    {
      g_iSpraySoundToggleTimes[iClient][i] = toggleTime;
      EmitSoundToClient(iClient, jingleFile, 0, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vEyeLocation);
    }

    // If player has customsounds disabled and fallback selected
    if (!g_bCustomsoundEnabled[iClient] && (g_iFallbackMode == 1 || g_iFallbackMode == 3))
      EmitSoundToClient(iClient, g_sFallbackFile, 0, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vEyeLocation);
  }

  return Plugin_Continue;
}

// ====[ COMMANDS ]=============================================================
public Action Command_Sprays(int iClient, int args)
{
  if (!IsValidClient(iClient))
    return Plugin_Handled;

  bool bGlobal = false;

  GetPlayerCustomsoundsEnabled(iClient);

  if (args > 0 && GetUserAdmin(iClient) != INVALID_ADMIN_ID)
  {
    char arg[32];
    GetCmdArg(1, arg, sizeof(arg));

    if (strcmp(arg, "global") == 0)
      bGlobal = true;
  }

  for(int i = 1; i <= MaxClients; i++)
  {
    if(!IsValidClient(i))
      continue;

    if(g_iLastSprayed[i] == 0)
      continue;

    DoSpray(i, g_vSprayLocation[i], iClient, bGlobal);
  }

  return Plugin_Handled;
}

// ====[ FUNCTIONS | CALLBACKS ]================================================
public void GetPlayerCustomsoundsEnabled(int iClient)
{
  if (g_qcCustomsounds[iClient] == QUERYCOOKIE_FAILED)
    g_qcCustomsounds[iClient] = QueryClientConVar(iClient, "cl_customsounds", GetPlayerCustomsoundsEnabledCallback);
}

public void GetPlayerCustomsoundsEnabledCallback(QueryCookie cookie, int iClient, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
  g_qcCustomsounds[iClient] = QUERYCOOKIE_FAILED;
  if (result != ConVarQuery_Okay)
  {
    // If for some reason can't determine, assume disabled
    g_bCustomsoundEnabled[iClient] = false;
    return;
  }

  g_bCustomsoundEnabled[iClient] = StringToInt(cvarValue) == 1;
}

public void InitClientValues(int iClient)
{
  g_vSprayLocation[iClient][0] = 0.0;
  g_vSprayLocation[iClient][1] = 0.0;
  g_vSprayLocation[iClient][2] = 0.0;

  g_iLastSprayed[iClient] = 0;
  g_iLastNoise[iClient] = 0;
  g_bCustomsoundEnabled[iClient] = false;
  g_qcCustomsounds[iClient] = QUERYCOOKIE_FAILED;
  if (IsValidClient(iClient))
    GetPlayerCustomsoundsEnabled(iClient);

  for (int i = 1; i <= MAXPLAYERS; i++)
  {
    g_iSpraySoundToggleTimes[iClient][i] = 0;
  }
}

// ====[ STOCKS ]===============================================================
stock void PrintToChatEx(int iClient, const char[] format)
{
  int time = GetTime();
  if (time - g_iLastChatMessage[iClient] > g_iChatspamTime)
  {
    g_iLastChatMessage[iClient] = time;
    PrintToChat(iClient, format);
  }
}

stock void PrintToChatEx1(int iClient, const char[] format, any a)
{
  int time = GetTime();
  if (time - g_iLastChatMessage[iClient] > g_iChatspamTime)
  {
    g_iLastChatMessage[iClient] = time;
    PrintToChat(iClient, format, a);
  }
}

stock bool GetPlayerJingleTempPath(int iClient, char[] jingleFile)
{
  char hex[16];
  GetPlayerJingleFile(iClient, hex, 16);

  if (!hex[0])
    return false;

  Format(jingleFile, 24, "temp/%s.wav", hex);
  return true;
}

stock bool GetPlayerJingleUserCustomPath(int iClient, char[] jingleFile)
{
  char hexchunk[4];
  char hex[16];

  GetPlayerJingleFile(iClient, hexchunk, 3); // Actually 2
  GetPlayerJingleFile(iClient, hex, 16);

  if (!hex[0])
    return false;

  Format(jingleFile, 64, "tf/download/user_custom/%s/%s.dat", hexchunk, hex);
  return true;
}

stock void DoSpray(int iClient, float vSprayLocation[3], int iSenderClient, bool bGlobal)
{
  TE_Start("Player Decal");
  TE_WriteVector("m_vecOrigin", vSprayLocation);
  TE_WriteNum("m_nPlayer", iClient);

  if (bGlobal)
    TE_SendToAll();
  else
    TE_SendToClient(iSenderClient);
}

stock bool IsValidClient(int iClient, bool bReplay = true)
{
  if (iClient <= 0 || iClient > MaxClients || !IsClientConnected(iClient) || !IsClientInGame(iClient))
    return false;
  if (bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
    return false;
  return true;
}

stock bool GetClientEyeEndLocation(int iClient, float vector[3])
{
  if (!IsValidClient(iClient))
    return false;

  float vOrigin[3];
  float vAngles[3];

  GetClientEyePosition(iClient, vOrigin);
  GetClientEyeAngles(iClient, vAngles);

  Handle hTraceRay = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, ValidSpray);

  if (TR_DidHit(hTraceRay))
  {
    TR_GetEndPosition(vector, hTraceRay);
    CloseHandle(hTraceRay);

    return true;
  }

  CloseHandle(hTraceRay);

  return false;
}

stock bool ValidSpray(int entity, int contentsmask)
{
  return entity > MaxClients;
}
