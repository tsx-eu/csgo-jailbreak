#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <gift>
#include <csgocolors>
#include <cstrike>

#pragma newdecls required

#define MODEL "models/weapons/w_knife_flip_dropped.mdl"

int g_iClient[MAXPLAYERS];
int g_cLaser;
int g_iGift;

public void OnPluginStart() {
	HookEvent("weapon_fire",		EventShoot,			EventHookMode_Post);
}
public void JB_OnPluginReady() {
	g_iGift = Gift_RegisterNewGift("Lancé de couteau", "knifethrow", true, false, 100.0, -1, ADMFLAG_CUSTOM1|ADMFLAG_ROOT);
}
public void OnMapStart() {
	g_cLaser = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	PrecacheModel(MODEL);
}
public Action Gift_OnRandomGift(int client, int gift) {
	if(gift != g_iGift)
		return Plugin_Handled;
	
	
	CPrintToChat(client, "{lightgreen}%s {green} Vous pouvez lancer deux couteaux!", PREFIX);
	g_iClient[client] = 2;
	return Plugin_Continue;
}
public Action EventShoot(Handle ev, const char[] name, bool broadcast) {
	int client = GetClientOfUserId(GetEventInt(ev, "userid"));
	char wepname[32];
	GetEventString(ev, "weapon", wepname, sizeof(wepname));
	
	if( g_iClient[client] > 0 ) {
		if( StrContains(wepname, "knife") >= 0 ) {
			g_iClient[client]--;
			
			float src[3], ang[3];
			GetClientEyePosition(client, src);
			GetClientEyeAngles(client, ang);
			
			Effect(client, src, ang, view_as<float>({ 0.0, 24.0, -8.0 }), GetClientTeam(client) == CS_TEAM_T ? {255, 0, 0, 150} : {0, 0, 255, 150});
		}
	}
}
public bool TR_FilterSelf(int entity, int mask, any client) {
	if (entity == client)
		return false;
	return true;
}

int Effect(int client, float origin[3], float angle[3], float offset[3], int color[4]) {
	float src[3], dst[3], fVel[3], fPVel[3];
	dst[0] = angle[0];
	dst[1] = 0.0;
	dst[2] = 0.0;
	 
	Math_RotateVector(offset, angle, src);
	AddVectors(src, origin, src);
	
	GetAngleVectors(angle, fVel, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fVel, 2000.0);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fPVel);
	AddVectors(fVel, fPVel, fVel);
	
	int ent = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(ent, "model", MODEL);
	DispatchKeyValue(ent, "OnUser1", "!self,Kill,,10.0,-1");
	DispatchSpawn( ent );
	
	AcceptEntityInput(ent, "FireUser1");	
	TeleportEntity(ent, origin, angle, fVel);
	Entity_SetCollisionGroup(ent, COLLISION_GROUP_PLAYER);
	Entity_SetSolidFlags(ent, FSOLID_TRIGGER);
	Entity_SetSolidType(ent, SOLID_VPHYSICS);
	Entity_SetOwner(ent, client);
	
	SDKHook(ent, SDKHook_Touch, OnTouch);	
	
	SetEntPropFloat(ent, Prop_Send, "m_flElasticity", 0.01);
	SetEntPropVector(ent, Prop_Data, "m_vecAngVelocity", view_as<float>({20000.0, 0.0, 0.0}));
	
	TE_SetupBeamFollow(ent, g_cLaser, 0, 0.5, 2.0, 0.1, 1, color);
	TE_SendToAll();
}
public void OnTouch(int entity, int client) {
	if( Entity_GetOwner(entity) == client )
		return;
	
	if( client > 0 ) {
		AcceptEntityInput(entity, "Kill");
		Entity_SetHealth(client, GetClientHealth(client) - 25);
		SlapPlayer(client, 0);
	}
}
