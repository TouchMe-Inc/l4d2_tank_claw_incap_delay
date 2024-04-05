#pragma semicolon               1
#pragma newdecls                required

#include <sourcemod>


public Plugin myinfo = {
	name = "TankClawIncapDelay",
	author = "Confogl Team",
	description = "The tank sends the survivor flying before he is incapacitated",
	version = "build0000",
	url = "https://github.com/TouchMe-Inc/l4d2_tank_claw_incap_delay"
}


#define TEAM_SURVIVOR           2


ConVar g_cvSurvivorIncapHealth = null;


public void OnPluginStart()
{
	g_cvSurvivorIncapHealth = FindConVar("survivor_incap_health");

	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
}

void Event_PlayerIncapacitated(Event event, const char[] sEventName, bool bDontBroadcast)
{
	char sWeapon[32];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));

	if (strcmp(sWeapon, "tank_claw") != 0) {
		return;
	}

	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!iClient || !IsClientInGame(iClient) || !IsClientSurvivor(iClient)) {
		return;
	}

	SetEntProp(iClient, Prop_Send, "m_isIncapacitated", 0, 1);
	SetEntityHealth(iClient, 1);

	CreateTimer(0.3, Timer_PlayerIncapacitated, iClient, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_PlayerIncapacitated(Handle hTimer, int iClient)
{
	if (!IsClientInGame(iClient) || !IsClientSurvivor(iClient)) {
		return Plugin_Stop;
	}

	SetEntProp(iClient, Prop_Send, "m_isIncapacitated", 1, 1);
	SetEntityHealth(iClient, GetConVarInt(g_cvSurvivorIncapHealth));

	return Plugin_Stop;
}

/**
 * Survivor team player?
 */
bool IsClientSurvivor(int iClient) {
	return (GetClientTeam(iClient) == TEAM_SURVIVOR);
}
