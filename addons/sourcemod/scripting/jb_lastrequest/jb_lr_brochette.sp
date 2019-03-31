#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>

#pragma newdecls required

#include <jb_lastrequest>

public void JB_OnPluginReady() {
	int id = JB_CreateLastRequest("Brochette", 			JB_SELECT_CT_UNTIL_DEAD|JB_BEACON, 				DV_CAN_Min3CT, DV_Start);
	JB_SetTeamCount(id, CS_TEAM_CT, 3);
}
public void DV_Start(int client, int[] targets, int targetCount) {
	DV_StripWeapon(client);
	
	GivePlayerItem(client, "weapon_knife");
	Client_GiveWeaponAndAmmo(client, "weapon_awp", true, 1, 0, 0, 0);
	
	for (int i = 0; i < targetCount; i++) {
		DV_StripWeapon(targets[i]);
		GivePlayerItem(targets[i], "weapon_knife");
	}
	
}