#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <emitsoundany>
#include <rsc_utils>

#pragma newdecls required

#include <jb_lastrequest>

int g_iClient, g_iTarget;
int g_cLaser;

public void OnPluginStart() {
	HookEvent("weapon_fire",		EventShoot,			EventHookMode_Post);
}
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
	
	Client_SetArmor(client, 0);
	Client_SetArmor(target, 0);
	
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
		if (KnifeWeapon(wepname) ) {
			float src[3], ang[3];
			GetClientEyePosition(client, src);
			GetClientEyeAngles(client, ang);
			
			int target = -1;
			Effect(client, src, ang, view_as<float>({ -16.0, 0.0,  -7.0 }), {255, 128, 40, 128}, 2.0, 128.0, target);
			Effect(client, src, ang, view_as<float>({   0.0, 0.0,  -3.0 }), {255, 128, 40, 128}, 2.0, 128.0, target);
			Effect(client, src, ang, view_as<float>({  16.0, 0.0,  -7.0 }), {255, 128, 40, 128}, 2.0, 128.0, target);
			Effect(client, src, ang, view_as<float>({   0.0, 0.0, -11.0 }), {255, 128, 40, 128}, 2.0, 128.0, target);
			
			Effect(client, src, ang, view_as<float>({  -8.0, 0.0,  -3.0 }), {255, 255, 0, 128}, 1.0, 256.0, target);
			Effect(client, src, ang, view_as<float>({   0.0, 0.0,  -3.0 }), {255, 255, 0, 128}, 1.0, 256.0, target);
			Effect(client, src, ang, view_as<float>({   8.0, 0.0,  -3.0 }), {255, 255, 0, 128}, 1.0, 256.0, target);
			
			Effect(client, src, ang, view_as<float>({  -8.0, 0.0,  -7.0 }), {255, 255, 0, 128}, 	1.0, 256.0, target);
			Effect(client, src, ang, view_as<float>({   0.0, 0.0,  -7.0 }), {255, 255, 128, 128},	4.0,  32.0, target);
			Effect(client, src, ang, view_as<float>({   8.0, 0.0,  -7.0 }), {255, 255, 0, 128}, 	1.0, 256.0, target);
			
			Effect(client, src, ang, view_as<float>({  -8.0, 0.0, -11.0 }), {255, 255, 0, 128}, 1.0, 256.0, target);
			Effect(client, src, ang, view_as<float>({   0.0, 0.0, -11.0 }), {255, 255, 0, 128}, 1.0, 256.0, target);
			Effect(client, src, ang, view_as<float>({   8.0, 0.0, -11.0 }), {255, 255, 0, 128}, 1.0, 256.0, target);
			
			if( target == g_iTarget || target == g_iClient ) {
				Entity_SetHealth(target, GetClientHealth(target) - 25);
				SlapPlayer(target, 0);
				
				EmitSoundToAllAny("rsc/jailbreak/pika.mp3", client);
			}
		}
	}
}
public bool TR_FilterSelf(int entity, int mask, any client) {
	if (entity == client)
		return false;
	return true;
}

int Effect(int client, float origin[3], float angle[3], float offset[3], int color[4], float size, float amplitude, int& target) {
	float src[3], dst[3];
	dst[0] = angle[0];
	dst[1] = 0.0;
	dst[2] = 0.0;
	 
	Math_RotateVector(offset, angle, src);
	AddVectors(src, origin, src);
	
	
	Handle tr = TR_TraceRayFilterEx(src, angle, MASK_SHOT, RayType_Infinite, TR_FilterSelf, client);
	if( TR_DidHit(tr) ) {
		TR_GetEndPosition(dst, tr);
		
		TE_SetupBeamPoints(src, dst, g_cLaser, g_cLaser, 0, 0, 1.0, size, size, 0, amplitude, color, 0);
		TE_SendToAll();
		
		int tmp = TR_GetEntityIndex(tr);
		if( tmp > 0 && tmp < MaxClients )
			target = tmp;
	}
	CloseHandle(tr);
	return target;
}


public void DV_Stop(int client, int target) {
	g_iClient = g_iTarget = -1;
}
