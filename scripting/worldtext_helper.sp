#include <sourcemod>
#include <tf2_stocks>
#include <worldtext>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "World Text Helper",
	author = "Spookmaster",
	description = "Provides several natives which help developers make easy use of the point_worldtext entity.",
	version = PLUGIN_VERSION,
	url = "https://github.com/SupremeSpookmaster/TF2-World-Text-Helper"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion version = GetEngineVersion();
	if (version != Engine_TF2)
	{
		SetFailState("This plugin is only compatible with Team Fortress 2.");
		return APLRes_Failure;
	}
	
	CreateNative("WorldText_Create", Native_WorldText_Create);
	CreateNative("WorldText_SetMessage", Native_WorldText_SetMessage);
	CreateNative("WorldText_SetSize", Native_WorldText_SetSize);
	CreateNative("WorldText_SetSpacing", Native_WorldText_SetSpacing);
	CreateNative("WorldText_SetFont", Native_WorldText_SetFont);
	CreateNative("WorldText_SetColor", Native_WorldText_SetColor);
	CreateNative("WorldText_SetRainbow", Native_WorldText_SetRainbow);
	CreateNative("WorldText_SetOrientation", Native_WorldText_SetOrientation);
	CreateNative("WorldText_AttachToEntity", Native_WorldText_AttachToEntity);
	CreateNative("WorldText_Detach", Native_WorldText_Detach);
	CreateNative("WorldText_MimicHitNumbers", Native_WorldText_MimicHitNumbers);
	
	return APLRes_Success;
}

int WorldText_Color[2049][4];

public int Native_WorldText_Create(Handle plugin, int numParams)
{
	float pos[3], ang[3];
	GetNativeArray(1, pos, sizeof(pos));
	GetNativeArray(2, ang, sizeof(ang));
	char message[255];
	GetNativeString(3, message, sizeof(message));
	float size = GetNativeCell(4);
	float xSpacing = GetNativeCell(5);
	float ySpacing = GetNativeCell(6);
	WorldText_Font font = GetNativeCell(7);
	int r = GetNativeCell(8);
	int g = GetNativeCell(9);
	int b = GetNativeCell(10);
	int a = GetNativeCell(11);
	bool rainbow = GetNativeCell(12);
	WorldText_Orientation orientation = GetNativeCell(13);
	
	int text = CreateEntityByName("point_worldtext");
	if (IsValidEntity(text))
	{
		WorldText_SetMessage(text, message);
		WorldText_SetSize(text, size);
		WorldText_SetSpacing(text, xSpacing, true, ySpacing, true);
		WorldText_SetFont(text, font);
		WorldText_SetColor(text, r, g, b, a);
		WorldText_SetRainbow(text, rainbow);
		WorldText_SetOrientation(text, orientation);
		
		DispatchSpawn(text);
		ActivateEntity(text);
		AcceptEntityInput(text, "Start");
		TeleportEntity(text, pos, ang);
		
		return text;
	}
	
	return -1;
}

public any Native_WorldText_SetMessage(Handle plugin, int numParams)
{
	int text = GetNativeCell(1);
	char message[255];
	GetNativeString(2, message, sizeof(message));
	
	DispatchKeyValue(text, "message", message);
	
	return 0;
}

public any Native_WorldText_SetSize(Handle plugin, int numParams)
{
	int text = GetNativeCell(1);
	float size = GetNativeCell(2);
	
	DispatchKeyValueFloat(text, "textsize", size);
	
	return 0;
}

public any Native_WorldText_SetSpacing(Handle plugin, int numParams)
{
	int text = GetNativeCell(1);
	float Spacing = GetNativeCell(2);
	bool UseSpacing = view_as<bool>(GetNativeCell(3));
	if (UseSpacing)
	{
		DispatchKeyValueFloat(text, "textspacingx", Spacing);
	}
		
	Spacing = GetNativeCell(4);
	UseSpacing = view_as<bool>(GetNativeCell(5));
	if (UseSpacing)
	{
		DispatchKeyValueFloat(text, "textspacingy", Spacing);
	}
	
	return 0;
}

public any Native_WorldText_SetFont(Handle plugin, int numParams)
{
	int text = GetNativeCell(1);
	int font = GetNativeCell(2);
	
	DispatchKeyValueInt(text, "font", font);
	
	return 0;
}

public any Native_WorldText_SetColor(Handle plugin, int numParams)
{
	int text = GetNativeCell(1);
	int r = GetNativeCell(2);
	int g = GetNativeCell(3);
	int b = GetNativeCell(4);
	int a = GetNativeCell(5);
	
	char color[32];
	Format(color, sizeof(color), "%i %i %i %i", r, g, b, a);
	DispatchKeyValue(text, "color", color);
	
	WorldText_Color[text][0] = r;
	WorldText_Color[text][1] = g;
	WorldText_Color[text][2] = b;
	WorldText_Color[text][3] = a;
	
	return 0;
}

public any Native_WorldText_SetRainbow(Handle plugin, int numParams)
{
	int text = GetNativeCell(1);
	int rainbow = GetNativeCell(2);
	
	DispatchKeyValueInt(text, "rainbow", rainbow);
	
	return 0;
}

public any Native_WorldText_SetOrientation(Handle plugin, int numParams)
{
	int text = GetNativeCell(1);
	int orientation = GetNativeCell(2);
	
	DispatchKeyValueInt(text, "orientation", orientation);
	
	return 0;
}

public any Native_WorldText_AttachToEntity(Handle plugin, int numParams)
{
	int text = GetNativeCell(1);
	int target = GetNativeCell(2);
	char attachment[255];
	GetNativeString(3, attachment, sizeof(attachment));
	float xOff = GetNativeCell(4);
	float yOff = GetNativeCell(5);
	float zOff = GetNativeCell(6);
	
	float pos[3];
	if (HasEntProp(target, Prop_Data, "m_vecAbsOrigin"))
	{
		GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", pos);
	}
	else if (HasEntProp(target, Prop_Send, "m_vecOrigin"))
	{
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
	}
			
	pos[0] += xOff;
	pos[1] += yOff;
	pos[2] += zOff;
	
	TeleportEntity(text, pos, NULL_VECTOR, NULL_VECTOR);
	
	SetVariantString("!activator");
	AcceptEntityInput(text, "SetParent", target, text);
	SetVariantString(attachment);
	AcceptEntityInput(text, "SetParentAttachmentMaintainOffset", text, text);
	
	return 0;
}

public any Native_WorldText_Detach(Handle plugin, int numParams)
{
	int text = GetNativeCell(1);
	
	SetVariantString("!activator");
	AcceptEntityInput(text, "SetParent", text, text);
	
	return 0;
}

public any Native_WorldText_MimicHitNumbers(Handle plugin, int numParams)
{
	int text = GetNativeCell(1);
	float fadeTime = GetGameTime() + GetNativeCell(2);
	float fadeRate = GetNativeCell(3);
	float upRate = GetNativeCell(4);
	
	DataPack pack = new DataPack();
	RequestFrame(WorldText_MimicHitNumbers_Effect, pack);
	WritePackCell(pack, EntIndexToEntRef(text));
	WritePackFloat(pack, fadeTime);
	WritePackFloat(pack, fadeRate);
	WritePackFloat(pack, upRate);
	
	return 0;
}

public void WorldText_MimicHitNumbers_Effect(DataPack pack)
{
	ResetPack(pack);
	
	int text = EntRefToEntIndex(ReadPackCell(pack));
	float fadeTime = ReadPackFloat(pack);
	float fadeRate = ReadPackFloat(pack);
	float upRate = ReadPackFloat(pack);
	
	if (!IsValidEntity(text))
	{
		delete pack;
		return;
	}
	
	float pos[3];
	GetEntPropVector(text, Prop_Send, "m_vecOrigin", pos);
	pos[2] += upRate;
	TeleportEntity(text, pos);
	
	if (GetGameTime() >= fadeTime)
	{
		float a = float(WorldText_Color[text][3]);
		if (a <= 0.0)
		{
			RemoveEntity(text);
			delete pack;
			return;
		}
		
		a -= fadeRate;
		if (a < 0.0)
			a = 0.0;
			
		WorldText_SetColor(text, WorldText_Color[text][0], WorldText_Color[text][1], WorldText_Color[text][2], RoundToFloor(a));
	}
	
	RequestFrame(WorldText_MimicHitNumbers_Effect, pack);
}

public void OnEntityDestroyed(int entity)
{
	if (entity >= 0 && entity <= 2048)
	{
		for (int i = 0; i < 4; i++)
			WorldText_Color[entity][i] = 0;
	}
}
