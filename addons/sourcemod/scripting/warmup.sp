#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <csgocolors>

#pragma newdecls required

public Plugin myinfo = {
	name = "WARMUP",
	author = "KoSSoLaX",
	description = "un peu plus de fun quand il y'a peu de joueur",
	version = "1.0.0",
	url = "zaretti.be"
};

bool g_bEnable = false, g_bPlayerWantedDisable = false;
Handle g_hCvarPlayerCount, g_hCvarPlayerRatio, g_hCvarBunnyHop;

public void OnPluginStart() {
	g_hCvarPlayerCount = CreateConVar("sm_warmup_playercount", "5");
	g_hCvarBunnyHop = CreateConVar("sm_warmup_bunnyhop", "1");
	g_hCvarPlayerRatio = CreateConVar("sm_warmup_ratio", "0.6");
	
	RegConsoleCmd("sm_warmup", 	Cmd_Warmup);
}
public void OnMapStart() {
	g_bEnable = false;
	g_bPlayerWantedDisable = false;
	if( WARMUP_CanBeEnabled() )
		WARMUP_Enable();
}
public void OnClientPostAdminCheck(int client) {
	if( !WARMUP_CanBeEnabled() )
		WARMUP_Disable();
}
public Action Cmd_Warmup(int client, int args) {
	if( IsVoteInProgress() || !IsNewVoteAllowed() )
		return Plugin_Handled;
	
	if( g_bEnable == true ) {
		Menu menu = new Menu(Handle_VoteMenu);
		menu.SetTitle("Voulez-vous désactiver le warmup?");
		
		menu.AddItem("0", "Non");
		menu.AddItem("1", "Oui");
		
		menu.ExitButton = false;
		menu.VoteResultCallback = Handle_VoteResults_DISABLE;
		VoteMenuToAll(menu, 25);
	}
	else if( g_bEnable == false && WARMUP_CanBeEnabled() ) {
		Menu menu = new Menu(Handle_VoteMenu);
		menu.SetTitle("Voulez-vous activer le warmup?");
		
		menu.AddItem("0", "Non");
		menu.AddItem("1", "Oui");
		
		menu.ExitButton = false;
		menu.VoteResultCallback = Handle_VoteResults_ENABLE;
		VoteMenuToAll(menu, 25);
	}
	
	
	return Plugin_Handled;
}
public int Handle_VoteMenu(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_End) {
		delete menu;
	}
}
public void Handle_VoteResults_ENABLE(Menu menu, int num_votes, int num_clients, const int[][] client_info,  int num_items, const int[][] item_info) {
	float ratio = item_info[0][VOTEINFO_ITEM_VOTES] / float(item_info[1][VOTEINFO_ITEM_VOTES]);
	
	if( item_info[0][VOTEINFO_ITEM_INDEX] == 1 && ratio >= GetConVarFloat(g_hCvarPlayerRatio) && WARMUP_CanBeEnabled() ) {
		WARMUP_Enable();
	}
}
public void Handle_VoteResults_DISABLE(Menu menu, int num_votes, int num_clients, const int[][] client_info,  int num_items, const int[][] item_info) {
	float ratio = item_info[0][VOTEINFO_ITEM_VOTES] / float(item_info[1][VOTEINFO_ITEM_VOTES]);
	
	if( item_info[0][VOTEINFO_ITEM_INDEX] == 1 && ratio >= GetConVarFloat(g_hCvarPlayerRatio) ) {
		WARMUP_Disable();
		g_bPlayerWantedDisable = true;
	}
}

// ------------------------------------------------------
bool WARMUP_CanBeEnabled() {
	return GetClientCount() <= GetConVarInt(g_hCvarPlayerCount);
}
void WARMUP_Enable() {
	if( g_bEnable != false )
		return;
	if( g_bPlayerWantedDisable == true )
		return;

	CPrintToChatAll("{lightgreen}[ {default}WARMUP {lightgreen}]========================================");
	CPrintToChatAll("{lightgreen}[ {default}WARMUP {lightgreen}]           {default}Début{lightgreen} du WARMUP !");
	CPrintToChatAll("{lightgreen}[ {default}WARMUP {lightgreen}]========================================");
	
	ServerCommand("sm_hosties_lr 1");
	ServerCommand("mp_ignore_round_win_conditions 1");
	ServerCommand("mp_respawn_on_death_ct 1; mp_respawn_on_death_t 1"); 
	ServerCommand("mp_respawnwavetime_ct 1; mp_respawnwavetime_t 1");
	if( GetConVarBool(g_hCvarBunnyHop) )
		ServerCommand("sv_autobunnyhopping 1; sv_enablebunnyhopping 1");
	
	ServerCommand("mp_restartgame 1");
	
	g_bEnable = true;
}
void WARMUP_Disable() {
	if( g_bEnable != true )
		return;
	
	CPrintToChatAll("{lightgreen}[ {default}WARMUP {lightgreen}]========================================");
	CPrintToChatAll("{lightgreen}[ {default}WARMUP {lightgreen}]           {default}Fin{lightgreen} du WARMUP !");
	CPrintToChatAll("{lightgreen}[ {default}WARMUP {lightgreen}]========================================");
	
	ServerCommand("sm_hosties_lr 0");
	ServerCommand("mp_ignore_round_win_conditions 0");
	ServerCommand("mp_respawn_on_death_ct 0; mp_respawn_on_death_t 0");
	if( GetConVarBool(g_hCvarBunnyHop) ) // TODO: Pose un problème. Quid si un admin change la valeur pendant un warmup ? Ca va laisser le bunny activer.
		ServerCommand("sv_autobunnyhopping 0; sv_enablebunnyhopping 0");
	
	ServerCommand("mp_restartgame 1");
	
	g_bEnable = false;
}
