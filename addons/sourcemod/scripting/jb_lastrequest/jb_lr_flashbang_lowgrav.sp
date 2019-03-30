#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <smart-menu>

#pragma newdecls required

#include <jb_lastrequest>

int g_iAirAccelerate, g_iGravity;
Handle g_hMain = INVALID_HANDLE;

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Combat de flashbang en faible gravité", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON, DV_CAN_Always, DV_Start, DV_Stop);
}
public void DV_Start(int client, int target) {
	g_iAirAccelerate = GetConVarInt(FindConVar("sv_airaccelerate"));
	g_iGravity = GetConVarInt(FindConVar("sv_gravity"));
	ServerCommand("sv_airaccelerate 1000;sv_gravity 200");
	
	SetEntityHealth(client, 1);
	SetEntityHealth(target, 1);
	
	DV_StripWeapon(client);
	DV_StripWeapon(target);
	
	GivePlayerItem(client, "weapon_flashbang");
	GivePlayerItem(target, "weapon_flashbang");	
	
	Handle dp;
	g_hMain = CreateDataTimer(1.0, EventSecondElapsed, dp, TIMER_REPEAT);
	WritePackCell(dp, client);
	WritePackCell(dp, target);
}
public Action EventSecondElapsed(Handle timer, Handle dp) {
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int target = ReadPackCell(dp);
	
	if( Client_GetWeapon(client, "weapon_flashbang") == -1 )
		GivePlayerItem(client, "weapon_flashbang");
	if( Client_GetWeapon(target, "weapon_flashbang") == -1 )
		GivePlayerItem(target, "weapon_flashbang");
}

public void DV_Stop(int client, int target) {
	ServerCommand("sv_airaccelerate %d;sv_gravity %d", g_iAirAccelerate, g_iGravity);
	
	KillTimer(g_hMain);
	g_hMain = null;
}