#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <cstrike>
#include <emitsoundany>

#pragma newdecls required

#include <jb_lastrequest>

public void JB_OnPluginReady() {
	int id = JB_CreateLastRequest("2 CT TEST", 	JB_SELECT_CT_UNTIL_DEAD, DV_CAN_Always, DV_Start, DV_Stop);
	JB_SetTeamCount(id, CS_TEAM_CT, 2);
}
public void DV_Start(int client, int[] targets, int targetCount) {
	PrintToChatAll("START - T - %N", client);
	
	for (int i = 0; i < targetCount; i++ )
		PrintToChatAll("START - CT - %N", targets[i]);
}

public void DV_Stop(int client, int[] targets, int targetCount) {
	PrintToChatAll("STOP - T - %N", client);
	
	for (int i = 0; i < targetCount; i++ )
		PrintToChatAll("STOP - CT - %N", targets[i]);
}