#pragma semicolon               1
#pragma newdecls                required

#include <sourcemod>
#include <left4dhooks>


public Plugin myinfo = {
	name        = "TankClawIncapDelay",
	author      = "Confogl Team, Forgetest",
	description = "The tank sends the survivor flying before he is incapacitated",
	version     = "build0001",
	url         = "https://github.com/TouchMe-Inc/l4d2_tank_claw_incap_delay"
}


#define TEAM_SURVIVOR           2


/* sm_tank_flying_incap_anim_fix */
ConVar g_cvAnimFix = null;
bool g_bAnimFix = false;


float g_fIncapTime[MAXPLAYERS + 1] = {0.0, ...};

int g_iIncap[MAXPLAYERS + 1] = {0, ...};


public void OnPluginStart()
{
	g_cvAnimFix = CreateConVar("sm_tank_flying_incap_anim_fix", "0", "Remove the getting-up animation at the end of fly (NOTE: Survivors will be able to shoot as soon as they land)");

	g_bAnimFix = GetConVarBool(g_cvAnimFix);
	HookConVarChange(g_cvAnimFix, CvChange_AnimFix);

	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
}

public void OnMapStart()
{
    for (int i = 1; i <= MaxClients; ++i)
    {
        g_fIncapTime[i] = 0.0;
    }
}

void CvChange_AnimFix(ConVar cv, const char[] szOldValue, const char[] szValue) {
	g_bAnimFix = GetConVarBool(cv);
}

void Event_PlayerIncapacitated(Event event, const char[] sEventName, bool bDontBroadcast)
{
	char szWeapon[32];
	GetEventString(event, "weapon", szWeapon, sizeof(szWeapon));

	if (strcmp(szWeapon, "tank_claw") != 0) {
		return;
	}

	int iClientId = GetEventInt(event, "userid");
	int iClient = GetClientOfUserId(iClientId);

	if (!iClient || !IsClientInGame(iClient) || !IsClientSurvivor(iClient)) {
		return;
	}

	g_fIncapTime[iClient] = GetGameTime();

	if (g_bAnimFix) {
		RequestFrame(NextFrame_HookAnimation, iClientId);
	}
}

void NextFrame_HookAnimation(int iClientId)
{
    int iClient = GetClientOfUserId(iClientId);
    if (!iClient || !IsClientInGame(iClient) || !IsClientSurvivor(iClient)) {
        return;
	}

    if (!IsPlayerAlive(iClient)) {
        return;
	}

    if (!GetEntProp(iClient, Prop_Send, "m_isIncapacitated")) {
        return;
	}

    AnimHookEnable(iClient, AnimHook_PunchFly);
}

Action AnimHook_PunchFly(int client, int &activity)
{
    switch (activity)
    {
    	case L4D2_ACT_TERROR_HIT_BY_TANKPUNCH,
            L4D2_ACT_TERROR_IDLE_FALL_FROM_TANKPUNCH,
            L4D2_ACT_TERROR_JUMP_LANDING,
            L4D2_ACT_TERROR_JUMP_LANDING_HARD,
	        L4D2_ACT_DEPLOY_PISTOL:
        {
            return Plugin_Continue;
        }

    	// Skip the getting up from ground animation
    	case L4D2_ACT_TERROR_TANKPUNCH_LAND:
        {
            PlayerAnimState.FromPlayer(client).m_bIsPunchedByTank = false;  // no longer in punched animation

            activity = L4D2_ACT_DIESIMPLE;  // incap animation intro
        }
    }

    AnimHookDisable(client, AnimHook_PunchFly);
    return Plugin_Changed;
}

public Action L4D_TankClaw_OnPlayerHit_Pre(int tank, int claw, int player)
{
    g_iIncap[player] = GetEntProp(player, Prop_Send, "m_isIncapacitated");

    if (GetGameTime() == g_fIncapTime[player]) {
        SetEntProp(player, Prop_Send, "m_isIncapacitated", 0);
    }

    return Plugin_Continue;
}

public void L4D_TankClaw_OnPlayerHit_Post(int tank, int claw, int player) {
    SetEntProp(player, Prop_Send, "m_isIncapacitated", g_iIncap[player]);
}

public void L4D_TankClaw_OnPlayerHit_PostHandled(int tank, int claw, int player) {
    SetEntProp(player, Prop_Send, "m_isIncapacitated", g_iIncap[player]);
}

/**
 * Survivor team player?
 */
bool IsClientSurvivor(int iClient) {
	return (GetClientTeam(iClient) == TEAM_SURVIVOR);
}
