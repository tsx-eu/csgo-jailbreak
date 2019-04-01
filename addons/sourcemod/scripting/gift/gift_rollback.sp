#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <gift>
#include <csgocolors>

#pragma newdecls required

int g_iGift = -1;
int g_iRollback[65];
float g_flPositions[65][3];

public Plugin myinfo = {
	name = "Gift: ROLLBACK",
	author = "KoSSoLaX",
	description = "Retourne en arrière",
	version = "1.0.0",
	url = "zaretti.be"
};

public void Gift_OnGiftStart() {
	g_iGift = Gift_RegisterNewGift("Rollback", "Rollback", true, false, 25.0, -1, ADMFLAG_CUSTOM1|ADMFLAG_ROOT);
}
public void OnPluginStart() {
	HookEvent("round_start", 		OnRoundStart, 			EventHookMode_Post);
	
	RegConsoleCmd("sm_rollback", Cmd_Rollback);
}
public Action OnRoundStart(Handle ev, const char[] name, bool dontBroadcast) {
	for (int i = 0; i < MaxClients; i++)
		g_iRollback[i] = 0;
}

public Action Gift_OnRandomGift(int client, int gift) {
	if(gift != g_iGift)
		return Plugin_Handled;
	
	CPrintToChat(client, "{lightgreen}%s {green} Vous pouvez retourner dans le temps!", PREFIX);
	CPrintToChat(client, "{lightgreen}%s {green} Tapez !rollback pour sauvegarder votre position.", PREFIX);
	
	g_iRollback[client] = 1;
	
	return Plugin_Handled;
}
public Action Cmd_Rollback(int client, int args) {
	
	if( g_iRollback[client] == 1 ) {
		
		CPrintToChat(client, "{lightgreen}%s {green} Vous avez sauvegardé votre position.", PREFIX);
		CPrintToChat(client, "{lightgreen}%s {green} Tapez !rollback pour retourner à votre position.", PREFIX);
		GetClientAbsOrigin(client, g_flPositions[client]);
		
		g_iRollback[client] = 2;
	}
	else if( g_iRollback[client] == 2 ) {
		TeleportEntity(client, g_flPositions[client], NULL_VECTOR, NULL_VECTOR);
		
		g_iRollback[client] = 0;
	}
	
}