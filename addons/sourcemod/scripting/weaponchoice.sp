#include <sourcemod>
#include <rsc_utils>
#include <cstrike>
#include <menustock>
#include <clientprefs>
#include <rsc_utils>

#define MAX_WEAPON 20
#define CAT_CHOICE 0
#define CAT_PRIMARY 1
#define CAT_SECONDARY 2

enum WeaponStruct {
    String:Name[65],
    String:ClassName[65],
    Cat
}

Handle cookie_PGuns;
Handle cookie_SGuns;

int g_Weapon[MAX_WEAPON][WeaponStruct];
int g_numbWeapon;

char g_szPGuns[MAXPLAYERS + 1][32];
char g_szSGuns[MAXPLAYERS + 1][32];

public void OnPluginStart() {
	RegAdminCmd("sm_guns", Command_Guns, ADMFLAG_CUSTOM1);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	cookie_PGuns = RegClientCookie("t_primary_guns", "", CookieAccess_Private);
	cookie_SGuns = RegClientCookie("t_secondary_guns", "", CookieAccess_Private);
	
	WeaponList();
}

public void OnClientCookiesCached(int client) {
	GetClientCookie(client, cookie_PGuns, g_szPGuns[client], 32);
	GetClientCookie(client, cookie_SGuns, g_szSGuns[client], 32);
	
	if(StrEqual(g_szPGuns[client], "")) {
		strcopy(g_szPGuns[client], 32, "weapon_m4a1");
	}
	if(StrEqual(g_szSGuns[client], "")) {
		strcopy(g_szSGuns[client], 32, "weapon_deagle");
	}	
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(GetClientTeam(client) > CS_TEAM_SPECTATOR) {
		ClientDisarm(client);
		GivePlayerItem(client, "weapon_knife");
		
		if(GetClientTeam(client) == CS_TEAM_CT) {
			GivePlayerItem(client, g_szPGuns[client]);
			GivePlayerItem(client, g_szSGuns[client]);
		}
	}
}

public Action Command_Guns(int client, int args) {
	if(!IsClientValid(client, true) || GetClientTeam(client) != CS_TEAM_CT) {
		return Plugin_Handled;
	}
	
	GunsMenu(client, CAT_CHOICE);
	
	return Plugin_Handled;
}

public void WeaponList() {
	
	CreateWeapon("AK47", "weapon_ak47", CAT_PRIMARY);
	CreateWeapon("M4A1", "weapon_m4a1", CAT_PRIMARY);
	
	CreateWeapon("Deagle", "weapon_deagle", CAT_SECONDARY);
	CreateWeapon("Glock", "weapon_glock", CAT_SECONDARY);
	CreateWeapon("P228", "weapon_p228", CAT_SECONDARY);
}

public void CreateWeapon(char[] name, char[] classname, int cat) {
	g_numbWeapon++;
	
	strcopy(g_Weapon[g_numbWeapon][Name], 32, name);
	strcopy(g_Weapon[g_numbWeapon][ClassName], 32, classname);
	g_Weapon[g_numbWeapon][Cat] = cat;
}

public void GunsMenu(int client, int cat) {
	Menu menu = new Menu(MenuHandler_Guns);
	
	if(cat == CAT_CHOICE) {
		menu.SetTitle("Catégorie");
		menu.AddItem("1", "Arme primaire");
		menu.AddItem("2", "Arme secondaire");
	}
	
	if(cat > CAT_CHOICE) {
		menu.SetTitle(cat == CAT_PRIMARY ? "Arme primaire:":"Arme secondaire:");
		
		for (int i = 0; i <= g_numbWeapon; i++) {
			if(g_Weapon[i][Cat] != cat) {
				continue;
			}
			
			menu.AddItem(g_Weapon[i][ClassName], g_Weapon[i][Name], StrEqual(g_szPGuns[client], g_Weapon[i][ClassName]) || StrEqual(g_szSGuns[client], g_Weapon[i][ClassName]) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		}
	}
	
	PushMenuCell(menu, "cat", cat);
	
	menu.Display(client, 15);
	menu.ExitButton = true;
}

public int MenuHandler_Guns(Menu menu, MenuAction action, int client, int param) {
	if(action == MenuAction_Select) {
		char szParam[32];
		GetMenuItem(menu, param, szParam, sizeof(szParam));
		
		int cat = GetMenuCell(menu, "cat");
		
		if(cat == CAT_PRIMARY) {
			strcopy(g_szPGuns[client], 32, szParam);
			SetClientCookie(client, cookie_PGuns, szParam);
		}
		if(cat == CAT_SECONDARY) {
			strcopy(g_szSGuns[client], 32, szParam);			
			SetClientCookie(client, cookie_SGuns, szParam);
		}
		
		if(cat == CAT_CHOICE) {
			GunsMenu(client, StringToInt(szParam));
		}
		else {
			GunsMenu(client, cat);
		}
	}
	if(action == MenuAction_End) {
		delete menu;
	}
}