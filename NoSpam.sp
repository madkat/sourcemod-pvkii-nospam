#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "0.01"
#define SERVER_TAG "nospam"

public Plugin:myinfo = {
    name        = "NoSpam",
    author      = "MadKat",
    description = "Allows a server operator to throttle jump and shield spam.",
    version     = PL_VERSION,
    url         = "http://www.github.com/madkat"
}

new cvar_enabled;
new cvar_debug;
new float:cvar_jump;
new float:cvar_shield;

#define NS_TIMERS	1
#define NS_JUMP		0
#define NS_SHIELD	1

new Handle:clientTimers[MAXPLAYERS + 1][NS_TIMERS];
new jumpState[MAXPLAYERS + 1];

public OnPluginStart()
{
    /*
	Cvars
    */
    CreateConVar("pvkii_nospam_version", PL_VERSION, "NoSpam for PVKII.", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_PLUGIN);
    
    new Handle:cv_enabled 	= CreateConVar("ns_enabled", "1", "Enables/disables PVKII Randomizer.", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, true, 1.0);
    new Handle:cv_debug 	= CreateConVar("ns_debug", "0", "Debug mode.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    new Handle:cv_jump 		= CreateConVar("ns_jump", "1.0", "Set how often a player may jump.", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, true, 10.0);
    new Handle:cv_shield 	= CreateConVar("ns_shield", "1.0", "Set how often a player may shield smash.", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, true, 10.0);
    
    HookEvent("player_spawn", player_spawn);
    HookEvent("round_end", round_end);
    HookEvent("gamemode_roundrestart", gamemode_roundrestart);

    HookConVarChange(cv_enabled, 	cvHookEnabled);
    HookConVarChange(cv_debug,  	cvHookDebug);
    HookConVarChange(cv_jump,	  	cvHookJump);
    HookConVarChange(cv_shield,  	cvHookShield);
    
    cvar_enabled 	= GetConVarBool(cv_enabled);
    cvar_debug 		= GetConVarBool(cv_debug);
    cvar_jump 		= GetConVarFloat(cv_jump);
    cvar_shield 	= GetConVarFloat(cv_shield);
    
    /*
	Event Hooks
    */

    AddServerTag(SERVER_TAG);
}

public cvHookEnabled(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
    cvar_enabled = GetConVarBool(cvar);
    if (!cvar_enabled)
    {
	RemoveServerTag(SERVER_TAG);
    }
    else
    {
	AddServerTag(SERVER_TAG);
    }
}
public cvHookDebug(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_debug = GetConVarBool(cvar); }
public cvHookJump(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_jump = GetConVarFloat(cvar); }
public cvHookShield(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_shield = GetConVarFloat(cvar); }

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (cvar_enabled)
    {
	if(IsValidEntity(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
	    if (buttons & IN_JUMP)
	    {
		new GroundEntity = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
		if (jumpState[client] == 0 && GroundEntity != -1)
		{
		    if (clientTimers[client][NS_JUMP] == INVALID_HANDLE)
		    {
			clientTimers[client][NS_JUMP] = CreateTimer(cvar_jump, ResetJumpTimer, client);
			return Plugin_Continue;
		    }
		    else
		    {
			buttons ^= IN_JUMP;
			return Plugin_Continue;
		    }
		}
		jumpState[client] = 1;
	    }
	    else
	    {
		jumpState[client] = 0;
	    }
	}
    }
    
    return Plugin_Continue;
}

public Action:ResetJumpTimer(Handle:timer, any:client)
{
    clientTimers[client][NS_JUMP] = INVALID_HANDLE;
}

public ResetClient(client)
{
    for (new i = 0; i < NS_TIMERS; i++) clientTimers[client][i] = INVALID_HANDLE;
    jumpState[client] = 0;
}

public OnMapStart()
{
    for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) ResetClient(i);
}

public player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    ResetClient(client);
}
public round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) ResetClient(i);
}
public gamemode_roundrestart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) ResetClient(i);
}

