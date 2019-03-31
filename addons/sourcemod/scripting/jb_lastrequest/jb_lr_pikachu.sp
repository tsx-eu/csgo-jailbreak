#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <emitsoundany>

#pragma newdecls required

#include <jb_lastrequest>

int g_iClient, g_iTarget, g_iWpnClient, g_iWpnTarget;
int g_cLaser;

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Pikachu", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON|JB_NODAMAGE, DV_CAN_Always, DV_Start, DV_Stop);
}
public void OnMapStart() {
	g_cLaser = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	PrecacheSoundAny("rsc/jailbreak/pika.mp3");
}

public void DV_Start(int client, int target) {
	g_iClient = client;
	g_iTarget = target;
	
	SetEntityHealth(client, 100);
	SetEntityHealth(target, 100);
	
	DV_StripWeapon(client);
	DV_StripWeapon(target);
	
	g_iWpnClient = GivePlayerItem(client, "weapon_knife");
	g_iWpnTarget = GivePlayerItem(target, "weapon_knife");
}
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) {
	if( (client == g_iTarget || client == g_iClient) && (weapon == g_iWpnClient || weapon == g_iWpnTarget) ) {
		float time = GetGameTime();
		
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", time + 1.0);
		
		if( buttons & IN_ATTACK2 && time >= GetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack") ) {
			float src[3], ang[3], dst[3];
			GetClientEyePosition(client, src);
			GetClientEyeAngles(client, ang);
			
			Handle tr = TR_TraceRayFilterEx(src, ang, MASK_SHOT, RayType_EndPoint, TR_FilterSelf, client);
			if( TR_DidHit(tr) ) {
				TR_GetEndPosition(dst, tr);
				int target = TR_GetEntityIndex(tr);
				
				if(target == g_iTarget || target == g_iClient) {
					Entity_SetHealth(target, GetClientHealth(target) - 25);
					SlapPlayer(target, 0);
					
					TE_SetupBeamPoints(src, dst, g_cLaser, g_cLaser, 0, 0, 1.0, 8.0, 8.0, 0, 1.0, { 240, 230, 170, 200 }, 0);
					TE_SendToAll();
					
					for (int i = 0; i < 8; i++) {
						TE_SetupBeamPoints(src, dst, g_cLaser, g_cLaser, 0, 0, 1.0, 2.0, 2.0, 0, 8.0, { 255, 255, 0, 200 }, 0);
						TE_SendToAll();
					}
					
					EmitSoundToAllAny("rsc/jailbreak/pika.mp3", client);
				}
			}
			
			CloseHandle(tr);
		}
	}
}
public bool TR_FilterSelf(int entity, int mask, any client) {
	if (entity == client)
		return false;
	return true;
}


public void DV_Stop(int client, int target) {
	g_iClient = g_iTarget = -1;
}