#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <csgocolors>

#pragma newdecls required
#define MAX_ENTITIES 2048

int g_iOwner[MAX_ENTITIES+1];

public Plugin myinfo = {
	name = "Show damages",
	author = "KoSSoLaX",
	description = "A fun way to show damage with popup",
	version = "1.0.0",
	url = "zaretti.be"
};

public void OnPluginStart() {
	for (int i = 1; i <= MaxClients; i++)
		if( IsClientInGame(i) )
			OnClientPostAdminCheck(i);
}

public void OnClientPostAdminCheck(int client) {
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamage);
}
public void OnEntityCreated(int entity, const char[] classname) {
	if( entity >= 0 && entity < MAX_ENTITIES )
		g_iOwner[entity] = 0;
}
public void OnEntityDestroyed(int entity) {
	if( entity >= 0 && entity < MAX_ENTITIES )
		g_iOwner[entity] = 0;
}
public void OnTakeDamage( int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damageOrigin[3]) {
	if(!IsClientVip(attacker))
		return;

	static char str_damage[12], str_size[12];
	if( attacker > 0 && attacker < MaxClients && damage > 0.0 ) {
		float ang[3], vel[3], pos[3], dir[3], origin[3];
		
		origin = damageOrigin;
		
		if(weapon == -1 && damagetype == DMG_BLAST ) // HE Grenade
			GetClientEyePosition(victim, origin);
		if( damagetype & DMG_SLASH )				// CUT
			GetClientEyePosition(victim, origin);		
		if(weapon == -1 && damagetype == DMG_BURN ) { // Molotov
			GetClientAbsOrigin(victim, origin);
			origin[2] += 16.0;
		}
		
		GetClientEyeAngles(attacker, ang);
		GetClientEyePosition(attacker, pos);
		
		float dist = GetVectorDistance(pos, origin);
		float r = Math_Min(1.0, dist / 256.0);
		int health = GetClientHealth(victim);

		Format(str_damage, sizeof(str_damage), "%d", RoundFloat(damage));
		Format(str_size, sizeof(str_size), "%.0f", Logarithm(damage) * 4.0 * r );
		
		int sub = CreateEntityByName("point_worldtext");
		DispatchKeyValue(sub, "OnUser1", "!self,KillHierarchy,,1.0,-1");
		DispatchKeyValue(sub, "message", str_damage);
		DispatchKeyValue(sub, "textsize", str_size);
		
		if( health <= 25 )
			DispatchKeyValue(sub, "color", "255 0 0");
		else if( health <= 50 )
			DispatchKeyValue(sub, "color", "255 255 0");
		else
			DispatchKeyValue(sub, "color", "0 255 0");
		
		DispatchSpawn(sub);
		
		SubtractVectors(pos, origin, dir);
		GetVectorAngles(dir, ang);
		ang[0] = ang[2] = 0.0;
		dir[0] = 16.0;
		dir[1] = GetRandomFloat(-8.0, 8.0);
		dir[2] = GetRandomFloat(-8.0, 8.0);
		
		Math_RotateVector(dir, ang, vel);
		AddVectors(origin, vel, origin);	
		
		ang[1] += 180.0;
		TeleportEntity(sub, origin, ang, NULL_VECTOR);
		
		g_iOwner[sub] = attacker;
		
		AcceptEntityInput(sub, "FireUser1");
		SetFlags(sub);
		SDKHook(sub, SDKHook_SetTransmit, OnSetTransmit);
	}
	
	return;
}
public Action OnSetTransmit(int entity, int client) {
	SetFlags(entity);
	if( g_iOwner[entity] == client )
		return Plugin_Continue;
	return Plugin_Handled;
}
public void SetFlags(int entity) {
	if (GetEdictFlags(entity) & FL_EDICT_ALWAYS) 
		SetEdictFlags(entity, (GetEdictFlags(entity) ^ FL_EDICT_ALWAYS));
}

bool IsClientVip(int client) {
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
		return true;
	return false;
}