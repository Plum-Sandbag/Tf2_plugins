#include <sourcemod>

public OnPluginStart() {
    new Handle:file = OpenFile("console.txt", "w");
    decl String:name[256], bool:isCommand, flags, String:description[512];
    new Handle:iterator = FindFirstConCommand(name, sizeof(name), isCommand, flags, description, sizeof(description));
    do {
        if(flags & FCVAR_LAUNCHER != FCVAR_LAUNCHER) {
            continue;
        }
        
        WriteFileLine(file, "Locked %s: %s - %s", isCommand ? "command" : "cvar", name, description);
        if(isCommand) {
            SetCommandFlags(name, GetCommandFlags(name) & ~FCVAR_LAUNCHER);
        } else {
            new Handle:convar = FindConVar(name);
            SetConVarFlags(convar, GetConVarFlags(convar) & ~FCVAR_LAUNCHER);
        }
    } while(FindNextConCommand(iterator, name, sizeof(name), isCommand, flags, description, sizeof(description)));
    CloseHandle(iterator);
    CloseHandle(file);
}  