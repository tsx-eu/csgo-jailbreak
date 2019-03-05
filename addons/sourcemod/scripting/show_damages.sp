#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

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
	static char str_damage[12], str_size[12];
	
	if( attacker > 0 && attacker < MaxClients && damage > 0.0 ) {
		float ang[3], vel[3], pos[3], dir[3], origin[3];
		
		origin = damageOrigin;
		
		if(weapon == -1 && damagetype == DMG_BLAST ) // HE Grenade
			GetClientEyePosition(victim, origin);
		
		if(weapon == -1 && damagetype == DMG_BURN ) { // Molotov
			GetClientAbsOrigin(victim, origin);
			origin[2] += 16.0;
		}
		
		GetClientEyeAngles(attacker, ang);
		GetClientEyePosition(attacker, pos);
		
		float dist = GetVectorDistance(pos, origin);
		float r = Math_Min(1.0, dist / 256.0);

		Format(str_damage, sizeof(str_damage), "%d", RoundFloat(damage));
		Format(str_size, sizeof(str_size), "%.0f", Logarithm(damage) * 4.0 * r );
		
		int parent = CreateEntityByName("hegrenade_projectile");
		DispatchKeyValue(parent, "OnUser1", "!self,KillHierarchy,,1.0,-1");
		DispatchSpawn(parent);
		
		Entity_SetSolidType(parent, SOLID_VPHYSICS);
		Entity_SetCollisionGroup(parent, COLLISION_GROUP_DEBRIS_TRIGGER);	
		SetEntityRenderMode(parent, RENDER_NONE);
		
		int sub = CreateEntityByName("point_worldtext");
		DispatchKeyValue(sub, "message", str_damage);
		DispatchKeyValue(sub, "textsize", str_size);
		DispatchKeyValue(sub, "color", "255 0 0");
		DispatchSpawn(sub);
		
		SetVariantString("!activator");
		AcceptEntityInput(sub, "SetParent", parent);
		AcceptEntityInput(parent, "FireUser1");
		
		SubtractVectors(pos, origin, dir);
		NormalizeVector(dir, dir);
		ScaleVector(dir, 64.0);
		
		Entity_GetAbsVelocity(victim, vel);
		AddVectors(vel, dir, vel);
		vel[0] += GetRandomFloat(-32.0, 32.0);
		vel[1] += GetRandomFloat(-32.0, 32.0);
		vel[2] += 128.0;
		TeleportEntity(parent, origin, ang, vel);
		
		g_iOwner[parent] = g_iOwner[sub] = attacker;
		
		SDKHook(parent, SDKHook_Touch, OnTouch);
		SDKHook(parent, SDKHook_SetTransmit, OnSetTransmit);
		SDKHook(sub, SDKHook_SetTransmit, OnSetTransmit);
	}
	
	return Plugin_Continue;
}
public Action OnSetTransmit(int entity, int client) {
	if( g_iOwner[entity] == client )
		return Plugin_Continue;
	return Plugin_Handled;
}

public void OnTouch(int entity, int touched) {
	AcceptEntityInput(entity, "KillHierarchy");
}