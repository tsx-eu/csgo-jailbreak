#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <csgocolors>
#include <gang>

#pragma newdecls required

#define TAXE 0.95

float g_flCoolDown[65];


public void OnPluginStart() {
	RegConsoleCmd("sm_coinflip", Cmd_CoinFlip);
}
public void OnClientPutInServer(int client) {
	g_flCoolDown[client] = GetGameTime();
}
public Action Cmd_CoinFlip(int client, int args) {
	char tmp[128], tmp2[128];

	if( IsPlayerAlive(client) ) {
		ReplyToCommand(client, "Cette commande est réservée aux morts.");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, tmp, sizeof(tmp));
	int money = StringToInt(tmp);
	if( money <= 0)
		money = 100;
	
	if( Gang_GetClientCash(client, WhiteCash) < money ) {
		ReplyToCommand(client, "Vous n'avez pas assez d'argent");
		return Plugin_Handled;
	}
	
	Menu menu = new Menu(menu_CoinFLip);
	menu.SetTitle("Avec qui voulez-vous faire un coin flip de %d$?\n", money);
	
	for (int i = 1; i < MaxClients; i++) {
		if( !IsClientInGame(i) )
			continue;
		if( i == client )
			continue;
		if( IsClientSourceTV(i) || IsFakeClient(i) )
			continue;
		if( IsPlayerAlive(i) )
			continue;
		if( Gang_GetClientCash(i, WhiteCash) < money )
			continue;
		if( g_flCoolDown[i] > GetGameTime() )
			continue;
		
		Format(tmp, sizeof(tmp), "%d %d %d", money, client, i);
		Format(tmp2, sizeof(tmp2), "%N", i);
		
		menu.AddItem(tmp, tmp2);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
	g_flCoolDown[client] = GetGameTime();
	
	return Plugin_Handled;
}
public int menu_CoinFLip(Menu menu, MenuAction action, int owner, int params) {
	char options[64];
	char buffer[3][8];
	if( action == MenuAction_Select ) {
		GetMenuItem(menu, params, options, sizeof(options));

		ExplodeString(options, " ", buffer, sizeof(buffer), sizeof(buffer[]));
		
		int money = StringToInt(buffer[0]);
		int client = StringToInt(buffer[1]);
		int target = StringToInt(buffer[2]);
		
		Menu submenu = new Menu(menu_CoinFLip_Complete);
		submenu.SetTitle("%N veut faire un coin flip de %d$\nAcceptez-vous?", client, money);
		
		Format(options, sizeof(options), "%d %d %d", money, client, target);
		submenu.AddItem(options, "Oui");

		submenu.AddItem("no", "Non");
		submenu.AddItem("never", "Ne plus me demander");
		
		submenu.Display(target, 15);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}

public int menu_CoinFLip_Complete(Menu menu, MenuAction action, int owner, int params) {
	char options[64];
	char buffer[3][8];
			
	if( action == MenuAction_Select ) {
		GetMenuItem(menu, params, options, sizeof(options));		
	
		if( !StrEqual(options, "no") && !StrEqual(options, "never") ) {
			ExplodeString(options, " ", buffer, sizeof(buffer), sizeof(buffer[]));
			int money = StringToInt(buffer[0]);
			int client = StringToInt(buffer[1]);
			int target = StringToInt(buffer[2]);
			
			Menu submenu = new Menu(menu_CoinFLip_Confirm);
			submenu.SetTitle("%N veut faire un coin flip de %d$\nÊtes vous sure?", client, money);
			
			Format(options, sizeof(options), "%d %d %d", money, client, target);

			submenu.AddItem("no", "Non");
			submenu.AddItem(options, "Oui");
			
			submenu.Display(target, 15);
		}
		else if(  StrEqual(options, "never") ) {
			g_flCoolDown[owner] = GetGameTime() + 30.0 * 60.0;
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}

public int menu_CoinFLip_Confirm(Menu menu, MenuAction action, int owner, int params) {
	char options[64];
	char buffer[3][8];
	if( action == MenuAction_Select ) {
		GetMenuItem(menu, params, options, sizeof(options));
		
		if( !StrEqual(options, "no") ) {
			ExplodeString(options, " ", buffer, sizeof(buffer), sizeof(buffer[]));
			int money = StringToInt(buffer[0]);
			int client = StringToInt(buffer[1]);
			int target = StringToInt(buffer[2]);	

			if( Gang_GetClientCash(client, WhiteCash) < money ) {
				PrintToChat(client, "%N n'a plus assez d'argent.", client);
				PrintToChat(target, "%N n'a plus assez d'argent.", client);
				return;
			}
			if( Gang_GetClientCash(target, WhiteCash) < money ) {
				PrintToChat(client, "%N n'a plus assez d'argent.", target);
				PrintToChat(target, "%N n'a plus assez d'argent.", target);
				return;
			}
			
			Gang_SetClientCash(client, WhiteCash, Gang_GetClientCash(client, WhiteCash)-money, "coin flip");
			Gang_SetClientCash(target, WhiteCash, Gang_GetClientCash(target, WhiteCash)-money, "coin flip");
			
			int winner = Math_GetRandomInt(0, 1) ? client : target;
			int loser = client == winner ? target : client;
			
			CPrintToChatAll("{green}%N{default} a gagné un coin flip contre {green}%N{default} de {red}%d${default}!", winner, loser, money);
			
			Gang_SetClientCash(winner, WhiteCash, Gang_GetClientCash(winner, WhiteCash) + RoundToCeil( (float(money)*2.0)*TAXE ), "coin flip");
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}