#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <csgocolors>
#include <gang>

#pragma newdecls required

char g_szTeamsName[] =  { "rouge", "bleu" };
int g_szTeamColor[][] = { { 255, 0, 0, 255 }, { 0, 0, 255, 0 } };
int g_iTeamBets[] =  { 0, 0 };

int g_iClientBet[65][2];
bool g_bCanBet = false;
StringMap g_hClienTeam;


public void OnPluginStart() {
	g_hClienTeam = new StringMap();
	
	RegConsoleCmd("sm_bet", 		cmd_Bet);
	RegAdminCmd("sm_event", 		cmd_Event,			ADMFLAG_ROOT);
	HookEvent("player_spawn", 		EventSpawn, 		EventHookMode_Post);
	
	for (int i = 1; i <= MaxClients; i++) {
		if( IsClientInGame(i) )
			OnClientPostAdminCheck(i);
	}
}
public void OnClientPostAdminCheck(int client) {
	g_iClientBet[client][0] = -1;
	Colorize(client);
}
public void Colorize(int client) {
	int team;
	char tmp[64];
	GetClientAuthId(client, AuthId_Engine, tmp, sizeof(tmp));
	
	if( g_hClienTeam.GetValue(tmp, team) ) {
		
		SetEntityRenderMode(client, RENDER_TRANSALPHA);
		SetEntityRenderColor(client, g_szTeamColor[team][0], g_szTeamColor[team][1], g_szTeamColor[team][2], g_szTeamColor[team][3]);
	}
	
}
public void OnMapStart() {
	g_hClienTeam.Clear();
}
public Action EventSpawn(Handle ev, const char[] name, bool broadcast) {
	int client = GetClientOfUserId(GetEventInt(ev, "userid"));
	Colorize(client);
}
public Action cmd_Bet(int client, int args) {
	char tmp[64], tmp2[64];
	GetCmdArg(1, tmp, sizeof(tmp));
	GetCmdArg(2, tmp2, sizeof(tmp2));
	
	int team = -1;
	for (int i = 0; i < sizeof(g_szTeamsName); i++) {
		if( StrEqual(tmp, g_szTeamsName[i]) ) {
			team = i;
			break;
		}
	}
	
	if( team == -1 ) {
		ReplyToCommand(client, "équipe: %s introuvable", tmp);
		return Plugin_Handled;
	}
	
	int money = StringToInt(tmp2);
	if( money < 50 ) {
		ReplyToCommand(client, "Vous devez pariez 50$ ou plus.");
		return Plugin_Handled;
	}
	
	if( g_iClientBet[client][0] != -1 ) {
		ReplyToCommand(client, "Vous avez déjà un paris d'actif.");
		return Plugin_Handled;
	}
	
	if( g_bCanBet == false ) {
		ReplyToCommand(client, "Il n'est pas possible de parier maintenant.");
		return Plugin_Handled;
	}
	
	if( Gang_GetClientCash(client, WhiteCash) < money ) {
		ReplyToCommand(client, "Vous n'avez pas assez d'argent");
		return Plugin_Handled;
	}
	
	g_iClientBet[client][0] = team;
	g_iClientBet[client][1] = money;
	g_iTeamBets[team] += money;
	
	Gang_SetClientCash(client, WhiteCash, Gang_GetClientCash(client, WhiteCash)-money, "bet");
	
	PrintToChatAll("%N a parié %d$ sur l'équipe %s!", client, money);
	
	return Plugin_Handled;
}
public Action cmd_Event(int client, int args) {
	char tmp[64], tmp2[64], tmp3[MAX_TARGET_LENGTH];
	GetCmdArg(1, tmp, sizeof(tmp));
	
	if( StrEqual(tmp, "team") ) {
		GetCmdArg(2, tmp2, sizeof(tmp2));
		GetCmdArg(3, tmp3, sizeof(tmp3));
		
		int team = -1;
		for (int i = 0; i < sizeof(g_szTeamsName); i++) {
			if( StrEqual(tmp2, g_szTeamsName[i]) ) {
				team = i;
				break;
			}
		}
		
		if( team == -1 ) {
			ReplyToCommand(client, "équipe: %s introuvable", tmp2);
			return Plugin_Handled;
		}
		
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count; bool tn_is_ml;
		if ((target_count = ProcessTargetString(tmp3, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_DEAD, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		for (int i = 0; i < target_count; i++) {
			int target = target_list[i];
			
			GetClientAuthId(target, AuthId_Engine, tmp, sizeof(tmp));
			g_hClienTeam.SetValue(tmp, team, true);
			
			Colorize(target);
		}
	}
	else if( StrEqual(tmp, "random") ) {
		int j = 0;
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsClientInGame(i) )
				continue;
			
			GetClientAuthId(i, AuthId_Engine, tmp2, sizeof(tmp2));
			g_hClienTeam.SetValue(tmp2, j % sizeof(g_szTeamsName), true);
			Colorize(i);
			j++;
		}
	}
	else if( StrEqual(tmp, "start") ) {
		g_bCanBet = true;
		CreateTimer(30.0, Task_BetStop);
		PrintToChatAll("Les parris sont ouvert pour 30 secondes!");
	}
	else if( StrEqual(tmp, "stop") ) {
		GetCmdArg(2, tmp2, sizeof(tmp2));
		
		int team = -1;
		for (int i = 0; i < sizeof(g_szTeamsName); i++) {
			if( StrEqual(tmp2, g_szTeamsName[i]) ) {
				team = i;
				break;
			}
		}
		
		if( team == -1 ) {
			ReplyToCommand(client, "équipe: %s introuvable", tmp2);
			return Plugin_Handled;
		}
		
		int sum = 0;
		for (int i = 0; i < sizeof(g_szTeamsName); i++)
			sum += g_iTeamBets[i];
		
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsClientInGame(i) )
				continue;
			
			if( g_iClientBet[client][0] == team && g_iClientBet[client][1] > 0 ) {
				int money = RoundToCeil(float(g_iClientBet[client][1]) * float(sum) / float(g_iTeamBets[team]));
				Gang_SetClientCash(client, WhiteCash, Gang_GetClientCash(client, WhiteCash)+money, "bet-win");
				
				PrintToChat(client, "Vous avez gagné %d$!", money);
			}
			
			g_iClientBet[client][0] = -1;
		}
		
		
		for (int i = 0; i < sizeof(g_szTeamsName); i++)
			g_iTeamBets[i] = 0;
		g_bCanBet = false;
	}
	else if( StrEqual(tmp, "clear") ) {
		g_hClienTeam.Clear();
	}
	else {
		ReplyToCommand(client, "erreur d'argument.");
	}
	return Plugin_Handled;
}
public Action Task_BetStop(Handle timer, any none) {
	g_bCanBet = false;
	PrintToChatAll("Les parris sont terminés!");
}