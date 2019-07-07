#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>

#pragma newdecls required

#include <jb_lastrequest>

public void JB_OnPluginReady() {
	int id = JB_CreateLastRequest("Brochette", 			JB_SELECT_CT_UNTIL_DEAD|JB_BEACON, 				DV_CAN_Min4CT, DV_Start);
	JB_SetTeamCount(id, CS_TEAM_CT, 3);
}
public void DV_Start(int client, int[] targets, int targetCount) {
	DV_StripWeapon(client);
	GivePlayerItem(client, "weapon_knife");
	
	int wpnId = GivePlayerItem(client, "weapon_awp");
	SetEntProp(wpnId, Prop_Send, "m_iClip1", 1);
	SetEntProp(wpnId, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
	
	for (int i = 0; i < targetCount; i++) {
		DV_StripWeapon(targets[i]);
		GivePlayerItem(targets[i], "weapon_knife");
	}
	
	JB_ShowHUDMessage("Les ct choisis devront se placer dans le coin que vous définissez, s'accroupir ou non. Votre but est d'éliminer le maximum de ct avec votre balle d'awp puis de tuer les derniers au cut.", CS_TEAM_T);
	JB_ShowHUDMessage("Placez vous dans le coin défini par le terro et faites ce qu'il vous dit Votre but est de survivre à sa balle et de l'éliminer ensuite au cut.", CS_TEAM_CT);
}