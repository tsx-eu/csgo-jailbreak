#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

#pragma newdecls required

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

public void OnTakeDamage( int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3]) {
	static char str_damage[12], str_size[12];
	
	if( attacker > 0 && attacker < MaxClients ) {
		float ang[3], vel[3], pos[3];
		
		GetClientEyeAngles(attacker, ang);
		GetClientEyePosition(attacker, pos);
		
		float dist = GetVectorDistance(pos, damagePosition);

		Format(str_damage, sizeof(str_damage), "%d", RoundFloat(damage));
		Format(str_size, sizeof(str_size), "%.0f", Logarithm(damage) * 4.0 * Math_Max(1.0, dist/256.0) );
		
		int parent = CreateEntityByName("hegrenade_projectile");
		DispatchKeyValue(parent, "OnUser1", "!self,KillHierarchy,,1.0,-1");
		DispatchSpawn(parent);
		
		Entity_SetSolidType(parent, SOLID_VPHYSICS);
		Entity_SetCollisionGroup(parent, COLLISION_GROUP_DEBRIS);	
		Entity_SetSolidFlags(parent, FSOLID_TRIGGER);
		SetEntityRenderMode(parent, RENDER_NONE);
		
		int sub = CreateEntityByName("point_worldtext");
		DispatchKeyValue(sub, "message", str_damage);
		DispatchKeyValue(sub, "textsize", str_size);
		DispatchKeyValue(sub, "color", "255 0 0");
		DispatchSpawn(sub);
		
		SetVariantString("!activator");
		AcceptEntityInput(sub, "SetParent", parent);
		AcceptEntityInput(parent, "FireUser1");
		
		
		Entity_GetAbsVelocity(victim, vel);
		vel[0] += Math_GetRandomFloat(-64.0, 64.0);
		vel[1] += Math_GetRandomFloat(-64.0, 64.0);
		vel[2] += 128.0;
		TeleportEntity(parent, damagePosition, ang, vel);
		
		SetEntityHealth(victim, 1000);
		
		SDKHook(parent, SDKHook_Touch, OnTouch);
	}
}
public void OnTouch(int entity, int touched) {
	AcceptEntityInput(entity, "KillHierarchy");
}