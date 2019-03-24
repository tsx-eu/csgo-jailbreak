#include <cstrike>

#define MOD_TAG				"{lightgreen}[ {default}WARMUP {lightgreen}]"
#define MOD_TAG_START		"{default}"
#define MOD_TAG_END			"{lightgreen}"

#define MAX_LR				32

#define JB_DEFAULT			0
#define JB_SHOULD_SELECT_CT	(1<<0)
#define JB_RUN_UNTIL_END	(1<<1)
#define JB_FUTUR_FLAG		(1<<2)

forward void JB_OnPluginReady();
native int JB_CreateLastRequest(const char name[128], int flags = JB_DEFAULT, JB_Condition condition = INVALID_FUNCTION, JB_Event start = INVALID_FUNCTION, JB_Event end = INVALID_FUNCTION);

typeset JB_Condition {
	function bool(int client);
}
typeset JB_Event { // TODO: Checker comment gérer deux types différents de retour, sinon tempis :'(
	function void(int client, int target);
	function void(int client, int[] targets, int targetCount);
}

stock bool DV_CAN_Always(int client) {
	return true;
}
stock bool DV_CAN_Min3CT(int client) {
	int cpt = 0;
	for (int i = 1; i <= MaxClients; i++)
		if( IsClientInGame(i) &&  IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT )
			cpt++;
	
	return (cpt>=3);
}
stock void DV_StripWeapon(int client, bool drop = false) {
	int wepIdx = -1;
	for( int i = 0; i < 5; i++ ) {
		while( ( wepIdx = GetPlayerWeaponSlot( client, i ) ) != -1 ) {
			if( i == CS_SLOT_KNIFE || i == CS_SLOT_GRENADE || !drop ) {
				RemovePlayerItem( client, wepIdx );
				RemoveEdict( wepIdx );
			}
			else {
				CS_DropWeapon(client, wepIdx, true);
			}
		}
	}
}