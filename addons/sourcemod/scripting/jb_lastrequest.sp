#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <csgocolors>
#include <emitsoundany>
#include <cstrike>

#pragma newdecls required

#include <jb_lastrequest>


public Plugin myinfo = {
	name = "Last Request",
	author = "KoSSoLaX",
	description = "Système de DV",
	version = "1.0.0",
	url = "zaretti.be"
};

#define MAX_PLAYERS 65
int g_iStackCount = 0;

char g_cStackName[MAX_LR][128];
Function g_fStackCondition[MAX_LR], g_fStackStart[MAX_LR], g_fStackEnd[MAX_LR];
Handle g_hStackPlugin[MAX_LR];
int g_iStackFlag[MAX_LR], g_iStackTeam[MAX_LR][4]; // CS_TEAM_T == 2 CS_TEAM_CT == 3 
Handle g_hPluginReady = INVALID_HANDLE;
bool g_bDoingDV, g_bDoingUntilDead;


int g_iClients[MAX_PLAYERS], g_iClientCount, g_iTargets[MAX_PLAYERS], g_iTargetCount;

public void OnPluginStart() {
	RegConsoleCmd("sm_dv", 			cmd_DV);
	RegConsoleCmd("sm_lr", 			cmd_DV);
	RegConsoleCmd("sm_lastrequest", cmd_DV);
	
	g_iStackCount = 0;

	Call_StartForward(g_hPluginReady);
	Call_Finish();
}
public void OnMapStart() {
	g_iStackCount = 0;
	
	Call_StartForward(g_hPluginReady);
	Call_Finish();
}
// -------------------------------------------------------------------------------------------------------------------------------
public Action cmd_DV(int client, int args) {
	if( GetClientTeam(client) != CS_TEAM_T || !IsPlayerAlive(client) || DV_CAN() == -1 ) {
		CPrintToChat(client, MOD_TAG ... "Vous n'avez {red}pas{default} le droit d'utiliser le " ... MOD_TAG_START ... "!dv" ... MOD_TAG_END ... " maintenant.");
		return Plugin_Handled;
	}
	
	displayDV(client);
	return Plugin_Handled;
}
void displayDV(int client) {
	static char tmp[8];
	
	Menu menu = new Menu(menuDV);
	menu.SetTitle("Choisissez votre dernière volonté\n");
	
	g_iClients[0] = client;
	g_iClientCount = 1;
	g_iTargetCount = 0;
	
	int targetCount = DV_CountTeam(CS_TEAM_CT);
	
	for (int i = 0; i < g_iStackCount; i++) {
		Format(tmp, sizeof(tmp), "%d", i);
		
		bool can;
		
		if( g_iStackTeam[i][CS_TEAM_CT] > targetCount ) {
			can = false;
		}
		else if( g_fStackCondition[i] == INVALID_FUNCTION ) {
			can = true;
		}
		else {
			
			Call_StartFunction(g_hStackPlugin[i], g_fStackCondition[i]);
			if( g_iStackTeam[i][CS_TEAM_T] > 1 ) {
				Call_PushArray(g_iClients, g_iClientCount);
				Call_PushCell(g_iClientCount);
			}
			else
				Call_PushCell(g_iClients[0]);
			Call_Finish(can);
			
		}
		
		menu.AddItem(tmp, g_cStackName[i], can ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	
	PrintHintTextToAll("%N\nchoisis sa dernière volonté", client);
	EmitSoundToAllAny("ui/bonus_alert_start.wav");
}
void displayDV_SelectCT(int id, int client) {
	static char tmp[2][64];
	
	Menu menu = new Menu(menuDVchooseCT);
	menu.SetTitle("Choisissez un CT\n");
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsClientInGame(i) )
			continue;
		if( !IsPlayerAlive(i) )
			continue;
		if( GetClientTeam(i) != CS_TEAM_CT)
			continue;
			
		int skip = false;
		for (int j = 0; j < g_iStackTeam[id][CS_TEAM_CT]; j++) {
			if( g_iTargets[j] == i ) {
				skip = true;
				break;
			}
		}
		
		if( skip )
			continue;
		
		Format(tmp[0], sizeof(tmp[]), "%d %d", id, i);
		Format(tmp[1], sizeof(tmp[]), "%N", i);
		
		menu.AddItem(tmp[0], tmp[1]);
	}
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}
public int menuDV(Handle menu, MenuAction action, int client, int params) {
	static char options[64];
	if( action == MenuAction_Select ) {
		GetMenuItem(menu, params, options, sizeof(options));
		int id = StringToInt(options);
		
		if( g_iStackFlag[id] & JB_SHOULD_SELECT_CT ) {
			displayDV_SelectCT(id, client);
		}
		else {
			DV_Start(id);
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}
public int menuDVchooseCT(Handle menu, MenuAction action, int client, int params) {
	static char options[64], data[2][16];
	if( action == MenuAction_Select ) {
		GetMenuItem(menu, params, options, sizeof(options));
		ExplodeString(options, " ", data, sizeof(data), sizeof(data[]));
		
		int id = StringToInt(data[0]);
		g_iTargets[g_iTargetCount] = StringToInt(data[1]);
		g_iTargetCount++;
		
		if( g_iTargetCount >= g_iStackTeam[id][CS_TEAM_CT] )
			DV_Start(id);
		else
			displayDV_SelectCT(id, client);
		
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
// -------------------------------------------------------------------------------------------------------------------------------
int DV_CAN() {
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
int DV_CountTeam(int team) {
	int t = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsClientInGame(i) || !IsPlayerAlive(i) )
			continue;
		if( GetClientTeam(i) == team )
			t++;
	}
	return t;
}
int DV_Start(int id) {
	PrintHintTextToAll("Dernière volonté:\n%s", g_cStackName[id]);
		
	if( g_iTargetCount > 0 )
		CPrintToChatAll(MOD_TAG ... "{teamcolor}%N{default} a choisis de faire sa DV " ... MOD_TAG_START ... "%s" ... MOD_TAG_END ... " contre " ... MOD_TAG_START ... "%N" ... MOD_TAG_END ... ".", g_iClients[0], g_cStackName[id], g_iTargets[0]);
	else
		CPrintToChatAll(MOD_TAG ... "{blue}%N{default} a choisis sa dernière volontée: " ... MOD_TAG_START ... "%s" ... MOD_TAG_END ... ".", g_iClients[0],  g_cStackName[id]);
	
	g_bDoingDV = true;
	g_bDoingUntilDead = view_as<bool>(g_iStackFlag[id] & JB_RUN_UNTIL_DEAD);
	
	if( g_fStackStart[id] != INVALID_FUNCTION )
		DV_Call(id, g_fStackStart[id]);
}
int DV_Stop(int id) {
	
	CPrintToChatAll("%s La {blue}DV{default} est terminée.", MOD_TAG);
	
	g_bDoingDV = false;
	g_bDoingUntilDead = false;
	
	if( g_fStackStop[id] != INVALID_FUNCTION )
		DV_Call(id, g_fStackStop[id]);
}
void DV_Call(int id, Function func) {
	Call_StartFunction(g_hStackPlugin[id], func);
	if( g_iStackTeam[id][CS_TEAM_T] > 1 ) {
		Call_PushArray(g_iClients, g_iClientCount);
		Call_PushCell(g_iClientCount);
	}
	else
		Call_PushCell(g_iClients[0]);
	
	if( g_iStackTeam[id][CS_TEAM_CT] > 1 ) {
		Call_PushArray(g_iTargets, g_iTargetCount);
		Call_PushCell(g_iTargetCount);
	}
	else
		Call_PushCell(g_iTargets[0]);
	Call_Finish();
}
// -------------------------------------------------------------------------------------------------------------------------------
public APLRes AskPluginLoad2(Handle hPlugin, bool isAfterMapLoaded, char[] error, int err_max) {
	RegPluginLibrary("JB_LastRequest");
	
	CreateNative("JB_CreateLastRequest", Native_JB_CreateLastRequest);
	CreateNative("JB_SetTeamCount", Native_JB_SetTeamCount);
	
	g_hPluginReady = CreateGlobalForward("JB_OnPluginReady", ET_Ignore);
}
public int Native_JB_CreateLastRequest(Handle plugin, int numParams) {

	g_hStackPlugin[g_iStackCount] = plugin;
	GetNativeString(1, g_cStackName[g_iStackCount], sizeof(g_cStackName[]));
	g_iStackFlag[g_iStackCount] = GetNativeCell(2);
	g_fStackCondition[g_iStackCount] = GetNativeFunction(3);
	g_fStackStart[g_iStackCount] = GetNativeFunction(4);
	g_fStackEnd[g_iStackCount] = GetNativeFunction(5);
	
	g_iStackTeam[g_iStackCount][CS_TEAM_T] = 1;
	g_iStackTeam[g_iStackCount][CS_TEAM_CT] = 1;
	
	return g_iStackCount++;
}
public int Native_JB_SetTeamCount(Handle plugin, int numParams) {	
	g_iStackTeam[GetNativeCell(1)][GetNativeCell(2)] = GetNativeCell(3);	
}