/*
Development plugin that allows walking through a kv structure
using SourceMod commands.

Author: Wliu
*/

#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

KeyValues kv;

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
	name="KeyValue Tester",
	author="Wliu",
	description="Walk through kv structures",
	version=PLUGIN_VERSION,
};

public void OnPluginStart()
{
	CreateConVar("kv_version", PLUGIN_VERSION, "KVTester version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);

	RegAdminCmd("sm_kv_importfromfile", Command_ImportFromFile, ADMFLAG_GENERIC, "Usage: sm_kv_importfromfile <file>");
	RegAdminCmd("sm_kv_getcolor", Command_GetColor, ADMFLAG_GENERIC, "Usage: sm_kv_getcolor <key>");
	RegAdminCmd("sm_kv_getcolor4", Command_GetColor4, ADMFLAG_GENERIC, "Usage: sm_kv_getcolor4 <key>");
	RegAdminCmd("sm_kv_getfloat", Command_GetFloat, ADMFLAG_GENERIC, "Usage: sm_kv_getfloat <key> [default value]");
	RegAdminCmd("sm_kv_getnum", Command_GetNum, ADMFLAG_GENERIC, "Usage: sm_kv_getnum <key> [default value]");
	RegAdminCmd("sm_kv_getsectionname", Command_GetSectionName, ADMFLAG_GENERIC, "Usage: sm_kv_getsectionname");
	RegAdminCmd("sm_kv_getstring", Command_GetString, ADMFLAG_GENERIC, "Usage: sm_kv_getstring <key> [default value]");
	RegAdminCmd("sm_kv_getvector", Command_GetVector, ADMFLAG_GENERIC, "Usage: sm_kv_getvector <key> [default first component] [default second component] [default third component]");
	RegAdminCmd("sm_kv_goback", Command_GoBack, ADMFLAG_GENERIC, "Usage: sm_kv_goback");
	RegAdminCmd("sm_kv_gotofirstsubkey", Command_GotoFirstSubKey, ADMFLAG_GENERIC, "Usage: sm_kv_gotofirstsubkey [true|false]");
	RegAdminCmd("sm_kv_gotonextkey", Command_GotoNextKey, ADMFLAG_GENERIC, "Usage: sm_kv_gotonextkey [true|false]");
	RegAdminCmd("sm_kv_jumptokey", Command_JumpToKey, ADMFLAG_GENERIC, "Usage: sm_kv_jumptokey <key>");
	RegAdminCmd("sm_kv_nodesinstack", Command_NodesInStack, ADMFLAG_GENERIC, "Usage: sm_kv_nodesinstack");
	RegAdminCmd("sm_kv_rewind", Command_Rewind, ADMFLAG_GENERIC, "Usage: sm_kv_rewind");
	RegAdminCmd("sm_kv_saveposition", Command_SavePosition, ADMFLAG_GENERIC, "Usage: sm_kv_saveposition");
}

public Action Command_ImportFromFile(int client, int args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "[KVTester] Usage: sm_kv_importfromfile <file>");
		return Plugin_Handled;
	}

	char file[PLATFORM_MAX_PATH];
	GetCmdArg(1, file, sizeof(file));
	kv = CreateKeyValues(file);
	BuildPath(Path_SM, file, sizeof(file), "%s", file);
	if(kv.ImportFromFile(file))
	{
		ReplyToCommand(client, "[KVTester] %s imported successfully", file);
	}
	else
	{
		delete kv;
		ReplyToCommand(client, "[KVTester] File %s does not exist!", file);
	}
	return Plugin_Handled;
}

public Action Command_GetColor(int client, int args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "[KVTester] Usage: sm_kv_getcolor <key>");
		return Plugin_Handled;
	}

	char key[64];
	GetCmdArg(1, key, sizeof(key));

	int r, g, b, a;
	if(StrEqual(key, "NULL_STRING"))
	{
		kv.GetColor(NULL_STRING, r, g, b, a);
	}
	else
	{
		kv.GetColor(key, r, g, b, a);
	}

	ReplyToCommand(client, "[KVTester] %s: %i %i %i %i", key, r, g, b, a);
	return Plugin_Handled;
}

public Action Command_GetColor4(int client, int args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "[KVTester] Usage: sm_kv_getcolor4 <key>");
		return Plugin_Handled;
	}

	char key[64];
	GetCmdArg(1, key, sizeof(key));

	int color[4];
	if(StrEqual(key, "NULL_STRING"))
	{
		kv.GetColor4(NULL_STRING, color);
	}
	else
	{
		kv.GetColor4(key, color);
	}

	ReplyToCommand(client, "[KVTester] %s: %i %i %i %i", key, color[0], color[1], color[2], color[3]);
	return Plugin_Handled;
}

public Action Command_GetFloat(int client, int args)
{
	if(args < 1 || args > 2)
	{
		ReplyToCommand(client, "[KVTester] Usage: sm_kv_getfloat <key> [default value]");
		return Plugin_Handled;
	}

	if(kv == null)
	{
		ReplyToCommand(client, "[KVTester] Call sm_kv_importfromfile first");
		return Plugin_Handled;
	}

	char key[64];
	GetCmdArg(1, key, sizeof(key));

	float defaultValue;
	if(args == 2)
	{
		char temp[8];
		GetCmdArg(2, temp, sizeof(temp));
		defaultValue = StringToFloat(temp);
	}

	float value;
	if(StrEqual(key, "NULL_STRING"))
	{
		value = kv.GetFloat(NULL_STRING, defaultValue);
	}
	else
	{
		value = kv.GetFloat(key, defaultValue);
	}

	ReplyToCommand(client, "[KVTester] %s: %f", key, value);
	return Plugin_Handled;
}

public Action Command_GetNum(int client, int args)
{
	if(args < 1 || args > 2)
	{
		ReplyToCommand(client, "[KVTester] Usage: sm_kv_getnum <key> [default value]");
		return Plugin_Handled;
	}

	if(kv == null)
	{
		ReplyToCommand(client, "[KVTester] Call sm_kv_importfromfile first");
		return Plugin_Handled;
	}

	char key[64];
	GetCmdArg(1, key, sizeof(key));

	int defaultValue;
	if(args == 2)
	{
		char temp[8];
		GetCmdArg(2, temp, sizeof(temp));
		defaultValue = StringToInt(temp);
	}

	int value;
	if(StrEqual(key, "NULL_STRING"))
	{
		value = kv.GetNum(NULL_STRING, defaultValue);
	}
	else
	{
		value = kv.GetNum(key, defaultValue);
	}

	ReplyToCommand(client, "[KVTester] %s: %i", key, value);
	return Plugin_Handled;
}

public Action Command_GetSectionName(int client, int args)
{
	if(args)
	{
		ReplyToCommand(client, "[KVTester] Usage: sm_kv_getsectionname");
		return Plugin_Handled;
	}

	if(kv == null)
	{
		ReplyToCommand(client, "[KVTester] Call sm_kv_importfromfile first");
		return Plugin_Handled;
	}

	char sectionName[64];
	kv.GetSectionName(sectionName, sizeof(sectionName));

	ReplyToCommand(client, "[KVTester] %s", sectionName);
	return Plugin_Handled;
}

public Action Command_GetString(int client, int args)
{
	if(args < 1 || args > 2)
	{
		ReplyToCommand(client, "[KVTester] Usage: sm_kv_getstring <key> [default value]");
		return Plugin_Handled;
	}

	if(kv == null)
	{
		ReplyToCommand(client, "[KVTester] Call sm_kv_importfromfile first");
		return Plugin_Handled;
	}

	char key[64];
	GetCmdArg(1, key, sizeof(key));

	char defaultValue[64];
	if(args == 2)
	{
		GetCmdArg(2, defaultValue, sizeof(defaultValue));
	}

	char value[64];
	if(StrEqual(key, "NULL_STRING"))
	{
		kv.GetString(NULL_STRING, value, sizeof(value), defaultValue);
	}
	else
	{
		kv.GetString(key, value, sizeof(value), defaultValue);
	}

	ReplyToCommand(client, "[KVTester] %s: %s", key, value);
	return Plugin_Handled;
}

public Action Command_GetVector(int client, int args)
{
	if(args < 1 || args > 4)
	{
		ReplyToCommand(client, "[KVTester] Usage: sm_kv_getvector <key> [default first component] [default second component] [default third component]");
		return Plugin_Handled;
	}

	if(kv == null)
	{
		ReplyToCommand(client, "[KVTester] Call sm_kv_importfromfile first");
		return Plugin_Handled;
	}

	char key[64];
	GetCmdArg(1, key, sizeof(key));

	float defaultValue[3];
	if(args >= 2)
	{
		char temp[8];
		GetCmdArg(2, temp, sizeof(temp));
		defaultValue[0] = StringToFloat(temp);

		if(args >= 3)
		{
			GetCmdArg(3, temp, sizeof(temp));
			defaultValue[1] = StringToFloat(temp);

			if(args == 4)
			{
				GetCmdArg(4, temp, sizeof(temp));
				defaultValue[2] = StringToFloat(temp);
			}
		}
	}

	float value[3];
	if(StrEqual(key, "NULL_STRING"))
	{
		kv.GetVector(NULL_STRING, value, defaultValue);
	}
	else
	{
		kv.GetVector(key, value, defaultValue);
	}

	ReplyToCommand(client, "[KVTester] %s: %f %f %f", key, value[0], value[1], value[2]);
	return Plugin_Handled;
}

public Action Command_GoBack(int client, int args)
{
	if(args)
	{
		ReplyToCommand(client, "[KVTester] Usage: sm_kv_goback");
		return Plugin_Handled;
	}

	if(kv == null)
	{
		ReplyToCommand(client, "[KVTester] Call sm_kv_importfromfile first");
		return Plugin_Handled;
	}

	kv.GoBack();

	char sectionName[64];
	kv.GetSectionName(sectionName, sizeof(sectionName));

	ReplyToCommand(client, "[KVTester] Now at section %s", sectionName);
	return Plugin_Handled;
}

public Action Command_GotoFirstSubKey(int client, int args)
{
	if(args > 1)
	{
		ReplyToCommand(client, "[KVTester] Usage: sm_kv_gotofirstsubkey [true|false]");
		return Plugin_Handled;
	}

	if(kv == null)
	{
		ReplyToCommand(client, "[KVTester] Call sm_kv_importfromfile first");
		return Plugin_Handled;
	}

	bool keyExists;
	if(args == 1)
	{
		char keyOnly[8];
		GetCmdArg(1, keyOnly, sizeof(keyOnly));
		if(StrEqual(keyOnly, "true"))
		{
			keyExists = kv.GotoFirstSubKey(true);
		}
		else if(StrEqual(keyOnly, "false"))
		{
			keyExists = kv.GotoFirstSubKey(false);
		}
		else
		{
			ReplyToCommand(client, "[KVTester] Usage: sm_kv_gotofirstsubkey [true|false]");
			return Plugin_Handled;
		}
	}
	else
	{
		keyExists = kv.GotoFirstSubKey();
	}

	char sectionName[64];
	kv.GetSectionName(sectionName, sizeof(sectionName));
	if(keyExists)
	{
		ReplyToCommand(client, "[KVTester] Now at section %s", sectionName);
	}
	else
	{
		ReplyToCommand(client, "[KVTester] No sub key exists under section %s!", sectionName);
	}
	return Plugin_Handled;
}

public Action Command_GotoNextKey(int client, int args)
{
	if(args > 1)
	{
		ReplyToCommand(client, "[KVTester] Usage: sm_kv_gotonextkey [true|false]");
		return Plugin_Handled;
	}

	if(kv == null)
	{
		ReplyToCommand(client, "[KVTester] Call sm_kv_importfromfile first");
		return Plugin_Handled;
	}

	bool keyExists;
	if(args == 1)
	{
		char keyOnly[8];
		GetCmdArg(1, keyOnly, sizeof(keyOnly));
		if(StrEqual(keyOnly, "true"))
		{
			keyExists = kv.GotoNextKey(true);
		}
		else if(StrEqual(keyOnly, "false"))
		{
			keyExists = kv.GotoNextKey(false);
		}
		else
		{
			ReplyToCommand(client, "[KVTester] Usage: sm_kv_gotonextkey [true|false]");
			return Plugin_Handled;
		}
	}
	else
	{
		keyExists = kv.GotoNextKey();
	}

	char sectionName[64];
	kv.GetSectionName(sectionName, sizeof(sectionName));
	if(keyExists)
	{
		ReplyToCommand(client, "[KVTester] Now at section %s", sectionName);
	}
	else
	{
		ReplyToCommand(client, "[KVTester] Already at the last section %s!", sectionName);
	}
	return Plugin_Handled;
}

public Action Command_JumpToKey(int client, int args)
{
	if(args > 1)
	{
		ReplyToCommand(client, "[KVTester] Usage: sm_kv_jumptokey <key>");
		return Plugin_Handled;
	}

	if(kv == null)
	{
		ReplyToCommand(client, "[KVTester] Call sm_kv_importfromfile first");
		return Plugin_Handled;
	}

	char key[64];
	GetCmdArg(1, key, sizeof(key));

	if(kv.JumpToKey(key))
	{
		char sectionName[64];
		kv.GetSectionName(sectionName, sizeof(sectionName));

		ReplyToCommand(client, "[KVTester] Now at section %s", sectionName);
	}
	else
	{
		ReplyToCommand(client, "[KVTester] Key %s does not exist!", key);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_NodesInStack(int client, int args)
{
	if(args)
	{
		ReplyToCommand(client, "[KVTester] Usage: sm_kv_nodesinstack");
		return Plugin_Handled;
	}

	if(kv == null)
	{
		ReplyToCommand(client, "[KVTester] Call sm_kv_importfromfile first");
		return Plugin_Handled;
	}

	ReplyToCommand(client, "[KVTester] %i", kv.NodesInStack());
	return Plugin_Handled;
}

public Action Command_Rewind(int client, int args)
{
	if(args)
	{
		ReplyToCommand(client, "[KVTester] Usage: sm_kv_rewind");
		return Plugin_Handled;
	}

	if(kv == null)
	{
		ReplyToCommand(client, "[KVTester] Call sm_kv_importfromfile first");
		return Plugin_Handled;
	}

	kv.Rewind();

	char sectionName[64];
	kv.GetSectionName(sectionName, sizeof(sectionName));

	ReplyToCommand(client, "[KVTester] Now at section %s", sectionName);
	return Plugin_Handled;
}

public Action Command_SavePosition(int client, int args)
{
	if(args)
	{
		ReplyToCommand(client, "[KVTester] Usage: sm_kv_rewind");
		return Plugin_Handled;
	}

	if(kv == null)
	{
		ReplyToCommand(client, "[KVTester] Call sm_kv_importfromfile first");
		return Plugin_Handled;
	}

	kv.SavePosition();

	char sectionName[64];
	kv.GetSectionName(sectionName, sizeof(sectionName));

	ReplyToCommand(client, "[KVTester] Position saved at section %s", sectionName);
	return Plugin_Handled;
}
