#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <emitsoundany>

#pragma newdecls required

#include <jb_lastrequest>

int g_iClient, g_iTarget;
int g_cLaser;

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Pikachu", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON|JB_NODAMAGE, DV_CAN_Always, DV_Start, DV_Stop);
}
public void OnMapStart() {
	g_cLaser = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	PrecacheSoundAny("rsc/jailbreak/pika.mp3");
	
	HookEvent("weapon_fire",		EventShoot,			EventHookMode_Post);
}

public void DV_Start(int client, int target) {
	g_iClient = client;
	g_iTarget = target;
	
	SetEntityHealth(client, 100);
	SetEntityHealth(target, 100);
	
	DV_StripWeapon(client);
	DV_StripWeapon(target);
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(target, "weapon_knife");
}
public Action EventShoot(Handle ev, const char[] name, bool broadcast) {
	int client = GetClientOfUserId(GetEventInt(ev, "userid"));
	char wepname[32];
	GetEventString(ev, "weapon", wepname, sizeof(wepname));
	
	if( (client == g_iTarget || client == g_iClient) ) {
		if( StrContains(wepname, "knife") >= 0 ) {
			float src[3], ang[3], dst[3];
			GetClientEyePosition(client, src);
			src[2] -= 8.0;
			GetClientEyeAngles(client, ang);
			
			Handle tr = TR_TraceRayFilterEx(src, ang, MASK_SHOT, RayType_Infinite, TR_FilterSelf, client);
			if( TR_DidHit(tr) ) {
				TR_GetEndPosition(dst, tr);
				int target = TR_GetEntityIndex(tr);
				
				TE_SetupBeamPoints(src, dst, g_cLaser, g_cLaser, 0, 0, 1.0, 2.0, 2.0, 0, 8.0, { 240, 230, 170, 200 }, 0);
				TE_SendToAll();
				
				for (int i = 0; i < 8; i++) {
					TE_SetupBeamPoints(src, dst, g_cLaser, g_cLaser, 0, 0, 1.0, 2.0, 2.0, 0, 64.0, { 255, 255, 0, 200 }, 0);
					TE_SendToAll();
				}
				
				if(target == g_iTarget || target == g_iClient) {
					Entity_SetHealth(target, GetClientHealth(target) - 25);
					SlapPlayer(target, 0);
					
					EmitSoundToAllAny("rsc/jailbreak/pika.mp3", client);
				}
			}
			else {
				PrintToChatAll("no hit");
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