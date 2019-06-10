#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <csgocolors>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = {
	name = "WARMUP",
	author = "KoSSoLaX",
	description = "un peu plus de fun quand il y'a peu de joueur",
	version = "1.0.0",
	url = "zaretti.be"
};

bool g_bEnable = false, g_bPlayerWantedDisable = false;
Handle g_hCvarPlayerCount, g_hCvarPlayerRatio, g_hCvarBunnyHop, g_hCvarAdvertTime;
bool g_bFirstSpawner[65];
bool g_bInPassive[65];

public void OnPluginStart() {
	g_hCvarPlayerCount = CreateConVar("sm_warmup_playercount", "5");
	g_hCvarBunnyHop = CreateConVar("sm_warmup_bunnyhop", "1");
	g_hCvarPlayerRatio = CreateConVar("sm_warmup_ratio", "0.6");
	g_hCvarAdvertTime = CreateConVar("sm_warmup_advert_time", "120");
	
	HookConVarChange(g_hCvarBunnyHop, OnConVarChange);
	HookEvent("player_spawn", 		EventSpawn, 		EventHookMode_Post);
	
	RegConsoleCmd("sm_warmup", 	Cmd_Warmup);
	RegConsoleCmd("sm_passif", Cmd_Passive);
	
	AutoExecConfig();
}
public Action Cmd_Passive(int client, int args) {
	g_bInPassive[client] = !g_bInPassive[client];
	
	if( g_bInPassive[client] )
		ReplyToCommand(client, "Le GODMOD est activé.");
	else
		ReplyToCommand(client, "Le GODMOD est déactivé.");
	
}
public void OnConVarChange(Handle cvar, const char[] oldVal, const char[] newVal) {
	if( g_hCvarBunnyHop == cvar && StringToInt(oldVal) == 1 && StringToInt(newVal) == 0 && g_bEnable ) {
		ServerCommand("sv_autobunnyhopping 0; sv_enablebunnyhopping 0");
	}
}
public void OnMapStart() {
	g_bEnable = false;
	g_bPlayerWantedDisable = false;
	if( WARMUP_CanBeEnabled() )
		WARMUP_Enable();
	
	CreateTimer(GetConVarFloat(g_hCvarAdvertTime), TIMER_Advert, 0, TIMER_FLAG_NO_MAPCHANGE);
}
public Action TIMER_Advert(Handle timer, any none) {
	if( g_bEnable == true ) {
		CPrintToChatAll("{lightgreen}[ {default}WARMUP {lightgreen}] Le warmup est {default}actif{lightgreen}, tapez {default}!warmup{lightgreen} pour le désactiver.");
		CPrintToChatAll("{lightgreen}[ {default}WARMUP {lightgreen}] Tapez !passif pour ne plus subir de dégat des autres joueurs.");
	}
	
	CreateTimer(GetConVarFloat(g_hCvarAdvertTime), TIMER_Advert, 0, TIMER_FLAG_NO_MAPCHANGE);
}
public void OnClientPostAdminCheck(int client) {
	if( !WARMUP_CanBeEnabled() )
		WARMUP_Disable();
}
public void OnClientPutInServer(int client) {
	g_bFirstSpawner[client] = true;
	g_bInPassive[client] = false;
	SDKHook(client, SDKHook_OnTakeDamage, EventTakeDamage);
}
public void OnClientDisconnect(int client) {
	g_bFirstSpawner[client] = false;
}
public Action EventSpawn(Handle ev, const char[] name, bool broadcast) {
	int client = GetClientOfUserId(GetEventInt(ev, "userid"));
	int team = GetClientTeam(client);
	
	if( g_bFirstSpawner[client] && (team == CS_TEAM_CT || team == CS_TEAM_T) ) {
		g_bFirstSpawner[client] = false;
		
		if( g_bEnable == true ) {
			CPrintToChat(client, "{lightgreen}[ {default}WARMUP {lightgreen}] Le warmup est {default}actif{lightgreen}!");
			CPrintToChat(client, "{lightgreen}[ {default}WARMUP {lightgreen}] Tapez !passif pour ne plus subir de dégat des autres joueurs.");
		}
	}
}
public Action Cmd_Warmup(int client, int args) {
	if( IsVoteInProgress() || !IsNewVoteAllowed() )
		return Plugin_Handled;
	
	Menu menu = null;
	
	if( g_bEnable == true ) {
		menu = new Menu(Handle_VoteMenu);
		menu.SetTitle("Voulez-vous désactiver le warmup?");
		menu.VoteResultCallback = Handle_VoteResults_DISABLE;
	}
	else if( g_bEnable == false && WARMUP_CanBeEnabled() ) {
		menu = new Menu(Handle_VoteMenu);
		menu.SetTitle("Voulez-vous activer le warmup?");
		menu.VoteResultCallback = Handle_VoteResults_ENABLE;
	}
	
	if( menu != null ) {
		menu.AddItem("0", "Non");
		menu.AddItem("1", "Oui");
		
		menu.ExitButton = false;
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
		g_bPlayerWantedDisable = false;
		WARMUP_Enable();
	}
	else {
		CPrintToChatAll("{lightgreen}[ {default}WARMUP {lightgreen}] Le vote a échoué!");
	}
}
public void Handle_VoteResults_DISABLE(Menu menu, int num_votes, int num_clients, const int[][] client_info,  int num_items, const int[][] item_info) {
	float ratio = item_info[0][VOTEINFO_ITEM_VOTES] / float(item_info[1][VOTEINFO_ITEM_VOTES]);
	
	if( item_info[0][VOTEINFO_ITEM_INDEX] == 1 && ratio >= GetConVarFloat(g_hCvarPlayerRatio) ) {
		WARMUP_Disable();
		g_bPlayerWantedDisable = true;
	}
	else {
		CPrintToChatAll("{lightgreen}[ {default}WARMUP {lightgreen}] Le vote a échoué!");
	}
}

public Action EventTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]) {
	if( g_bEnable == false )
		return Plugin_Continue;
	
	
	if( attacker > MaxClients && HasEntProp(attacker, Prop_Data, "m_hOwnerEntity") )
		attacker = GetEntProp(attacker, Prop_Data, "m_hOwnerEntity");
	if( attacker > 0 && attacker < MaxClients ) {
		if( g_bInPassive[victim] || g_bInPassive[attacker] )
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
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
	
	ServerCommand("sm_stoplr");
	ServerCommand("sm_hosties_lr 0");
	ServerCommand("mp_ignore_round_win_conditions 1");
	ServerCommand("mp_respawn_on_death_ct 1; mp_respawn_on_death_t 1"); 
	ServerCommand("mp_respawnwavetime_ct 1; mp_respawnwavetime_t 1");
	if( GetConVarBool(g_hCvarBunnyHop) )
		ServerCommand("sv_autobunnyhopping 1; sv_enablebunnyhopping 1");
	
	CS_TerminateRound(1.0, CSRoundEnd_Draw);
	
	g_bEnable = true;
}
void WARMUP_Disable() {
	if( g_bEnable != true )
		return;
	
	CPrintToChatAll("{lightgreen}[ {default}WARMUP {lightgreen}]========================================");
	CPrintToChatAll("{lightgreen}[ {default}WARMUP {lightgreen}]           {default}Fin{lightgreen} du WARMUP !");
	CPrintToChatAll("{lightgreen}[ {default}WARMUP {lightgreen}]========================================");
	
	ServerCommand("sm_stoplr");
	ServerCommand("sm_hosties_lr 1");
	ServerCommand("mp_ignore_round_win_conditions 0");
	ServerCommand("mp_respawn_on_death_ct 0; mp_respawn_on_death_t 0");
	if( GetConVarBool(g_hCvarBunnyHop) )
		ServerCommand("sv_autobunnyhopping 0; sv_enablebunnyhopping 0");
	
	CS_TerminateRound(1.0, CSRoundEnd_Draw);
	
	g_bEnable = false;
}
