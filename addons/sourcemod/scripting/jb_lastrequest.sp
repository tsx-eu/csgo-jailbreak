#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <csgocolors>
#include <emitsoundany>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = {
	name = "Last Request",
	author = "KoSSoLaX",
	description = "Système de DV",
	version = "1.0.0",
	url = "zaretti.be"
};

#define MOD_TAG				"[REBEL-CORP]"
#define MAX_LR				32
#define JB_SHOULD_SELECT_CT	(1<<0)
#define JB_RUN_UNTIL_END	(2<<0)

int g_iStackCount = 0;

char g_cStackName[MAX_LR][128];
Function g_fStackCondition[MAX_LR], g_fStackStart[MAX_LR], g_fStackEnd[MAX_LR];
int g_bStackFlag[MAX_LR];

bool g_bDoingDV, g_bDoingUntilRoundEnd;


public void OnPluginStart() {
	RegConsoleCmd("sm_dv", 			cmd_DV);
	RegConsoleCmd("sm_lr", 			cmd_DV);
	RegConsoleCmd("sm_lastrequest", cmd_DV);
}
public Action cmd_DV(int client, int args) {
	if( GetClientTeam(client) != CS_TEAM_T || !IsPlayerAlive(client) || DV_CAN() == -1 ) {
		CPrintToChat(client, "%s Vous n'avez {red}pas{default} le droit d'utiliser le !dv maintenant.", MOD_TAG);
		return Plugin_Handled;
	}
	
	displayDV(client);
	return Plugin_Handled;
}
public void displayDV(int client) {
	static char tmp[8];
	
	Handle menu = CreateMenu(menuDV);
	SetMenuTitle(menu, "Choisissez votre dernière volonté");
	
	
	for (int i = 0; i < g_iStackCount; i++) {
		
		Format(tmp, sizeof(tmp), "%d", i);
		
		bool can;
		Call_StartFunction(INVALID_HANDLE, g_fStackCondition[i]);
		Call_PushCell(client);
		Call_Finish(can);
		
		AddMenuItem(menu, tmp, g_cStackName[i], can ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	PrintHintTextToAll("%N\nchoisis sa dernière volonté", client);
	
	EmitSoundToAllAny("ui/bonus_alert_start.wav");
}
public int menuDV(Handle menu, MenuAction action, int client, int params) {
	if( action == MenuAction_Select ) {
		char options[64];
		GetMenuItem(menu, params, options, sizeof(options));
		int id = StringToInt(options);
		
		g_bDoingDV = true;
		g_bDoingUntilRoundEnd = view_as<bool>(g_bStackFlag[id] & JB_RUN_UNTIL_END);
		
		PrintHintTextToAll("Dernière volonté:\n%s", g_cStackName[id]);
		CPrintToChat(client, "%s {blue}%N{default} a choisis sa dernière volontée: {green}%s{default}.", MOD_TAG, client,  g_cStackName[id]);
		
		if( g_bStackFlag[id] & JB_SHOULD_SELECT_CT ) {
			Handle menu2 = CreateMenu(menuDVchoose);
			SetMenuTitle(menu2, "Choisissez un CT");
			
			char tmp[2][64];
			
			for (int i = 1; i <= MaxClients; i++) {
				if( IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT ) {
					
					Format(tmp[0], sizeof(tmp[]), "%d %d", id, i);
					Format(tmp[1], sizeof(tmp[]), "%N", i);
					
					AddMenuItem(menu2, tmp[0], tmp[1]);
				}
			}
			
			SetMenuExitButton(menu2, false);
			DisplayMenu(menu2, client, MENU_TIME_FOREVER);
		}
		else {			
			Call_StartFunction(INVALID_HANDLE, g_fStackStart[id]);
			Call_PushCell(client);
			Call_PushCell(-1);
			Call_Finish();
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}
public int menuDVchoose(Handle menu, MenuAction action, int client, int params) {
	if( action == MenuAction_Select ) {
		char options[64], data[2][16];
		GetMenuItem(menu, params, options, sizeof(options));
		ExplodeString(options, " ", data, sizeof(data), sizeof(data[]));
		
		int id = StringToInt(data[0]);
		int target = StringToInt(data[1]);
		
		CPrintToChatAllEx(client, "%s {teamcolor}%N{default} a choisis de faire sa DV {green}%s{default} contre {lightblue}%N{default}.", MOD_TAG, client, options, target);
		g_bDoingDV = true;
		g_bDoingUntilRoundEnd = view_as<bool>(g_bStackFlag[id] & JB_RUN_UNTIL_END);
		
		
		Call_StartFunction(INVALID_HANDLE, g_fStackStart[id]);
		Call_PushCell(client);
		Call_PushCell(target);
		Call_Finish();
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public int DV_CAN() {
	if( g_bDoingDV )
		return -1;
	
	int ct, t, found;
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsClientInGame(i) || !IsPlayerAlive(i) )
			continue;
			
		if( GetClientTeam(i) == CS_TEAM_CT )
			ct++;
		else if( GetClientTeam(i) == CS_TEAM_T ) {
			t++;
			found = i;
		}
	}
			
	if( t > 1 || ct == 0 ) 
		return -1;
	
	return found;
}
public APLRes AskPluginLoad2(Handle hPlugin, bool isAfterMapLoaded, char[] error, int err_max) {
	RegPluginLibrary("JB_LastRequest");
	
	CreateNative("JB_CreateLastRequest", Native_JB_CreateLastRequest);
}
public int Native_JB_CreateLastRequest(Handle plugin, int numParams) {

	GetNativeString(1, g_cStackName[g_iStackCount], sizeof(g_cStackName[]));
	g_fStackCondition[g_iStackCount] = GetNativeFunction(2);
	g_fStackStart[g_iStackCount] = GetNativeFunction(3);
	g_fStackEnd[g_iStackCount] = GetNativeFunction(4);
	g_bStackFlag[g_iStackCount] = GetNativeCell(5);
	
	return g_iStackCount++;
}


// JB_CreateLastRequest("Roulette",			DV_Condition,	DV_Debut,	DV_Fin, FLAG);
// JB_CreateLastRequest("Roulette",			DV_Condition,	DV_Debut,	DV_Fin, JB_SHOULD_SELECT_CT);
// JB_CreateLastRequest("Roulette",			DV_Condition,	DV_Debut,	DV_Fin, JB_RUN_UNTIL_END);
// JB_CreateLastRequest("Roulette",			DV_Condition,	DV_Debut,	DV_Fin, JB_SHOULD_SELECT_CT|JB_RUN_UNTIL_END);
