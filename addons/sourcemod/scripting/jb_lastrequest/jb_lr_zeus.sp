#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

#pragma newdecls required

#include <jb_lastrequest>

Handle g_hMain;

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Combat de zeus", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON, DV_CAN_Always, DV_Start, DV_Stop);
}
public void DV_Start(int client, int target) {
	SetEntityHealth(client, 100);
	SetEntityHealth(target, 100);
	
	Client_SetArmor(client, 0);
	Client_SetArmor(target, 0);
	
	DV_StripWeapon(client);
	DV_StripWeapon(target);
	
	GivePlayerItem(client, "weapon_taser");
	GivePlayerItem(target, "weapon_taser");
	
	Handle dp;
	g_hMain = CreateDataTimer(1.0, EventSecondElapsed, dp, TIMER_REPEAT);
	WritePackCell(dp, client);
	WritePackCell(dp, target);
}
public Action EventSecondElapsed(Handle timer, Handle dp) {
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int target = ReadPackCell(dp);
	
	if(Client_GetWeapon(client, "weapon_taser") == -1)
		GivePlayerItem(client, "weapon_taser");
	if(Client_GetWeapon(target, "weapon_taser") == -1)
		GivePlayerItem(target, "weapon_taser");
}

public void DV_Stop(int client, int target) {
	KillTimer(g_hMain);
	g_hMain = null;
}
