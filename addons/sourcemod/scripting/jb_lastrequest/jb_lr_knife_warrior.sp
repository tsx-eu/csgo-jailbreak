#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

#include <jb_lastrequest>

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Combat de cut warrior", 	JB_RUN_UNTIL_DEAD|JB_BEACON, DV_CAN_Min3CT, DV_Start);
}
public void DV_Start(int client) {
	int cpt = 0;
	
	DV_StripWeapon(client);
	GivePlayerItem(client, "weapon_knife");
	
	for (int i = 1; i < MaxClients; i++) {
		if( !IsClientInGame(i) || !IsPlayerAlive(i) )
			continue;
		if( GetClientTeam(i) != CS_TEAM_CT )
			continue;
		
		SetEntityHealth(i, 100);
		DV_StripWeapon(i);
		GivePlayerItem(i, "weapon_knife");
		JB_AddClientInDV(i);
		cpt++;
	}
	
	SetEntityHealth(client, 100 + 75*cpt);
	
	JB_ShowHUDMessage("Vous av﻿ez un gran﻿d nombre d'hp et devez affronter au cut tous les ct encore en vie. (Astuce: essayez de prendre 1 par 1 tous les ct)", CS_TEAM_T);
	JB_ShowHUDMessage("Vous d﻿evez affronter le dernier terro, attention, il a un grand nombre d'hp. (Astuce: Rushez le à plusieurs)﻿", CS_TEAM_CT);
	
}
