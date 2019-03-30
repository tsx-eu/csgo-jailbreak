#define PLUGIN_VERSION "2.6.8"
#define PLUGIN_NAME "Gang - "

#define JSON_ITEM_PATH "addons/sourcemod/data/gangs/items/"

#define EXP_UP_GRADE 100

#define PREFIX_CONNECT "gang"
#define MAX_QUERY_SIZES 8064

#define MAX_ITEM 300
#define MAX_CATEGORIE 32
#define MAX_SELL 5000
#define MAX_LAYOUT 64
#define MAX_GANG 10
#define MAX_TERRITORY 100

#define MAX_JSON_SIZE 4094
#define MAX_ITEM_NAME_SIZE 32
#define MAX_ITEM_CATEGORIE_SIZE 32
#define MAX_CATEGORIE_DESCRIPTION 64

#define EXPIRE 86400 * 31 // 1 jours * nb

enum GangList {
	GangNothing, // 0
	Gang1, // 1
	Gang2, // 2
	Gang3, // 3
	Gang4, // 4
	Gang5, // 5
	Gang6, // 6
	Gang7, // 7

	gang_list_size, // 9
}

enum GradeList {
	GradeNothing,
	Chief, 
	Lieutenant, 
	Honor, 
	Aged3, 
	Aged2, 
	Aged, 
	Member, 
	Recruit, 
	
	grade_list_size
}

enum TypeCash {
	WhiteCash,
	BlackCash,
	InvestCash, // Argent investis dans le gang
}

enum ShopAction {
	Shop_Sell,
	Shop_Send,
	Shop_Delete,
	Shop_Use,
	Shop_Buy,
	Shop_CancelSell
}

forward void Gang_OnDatabaseConnected();
forward void Gang_OnInitItemCategorie();
forward void Gang_OnInitTerritory();
forward void Gang_OnInitAttribus();

forward void Gang_OnInitClientGang(int client);
forward void Gang_OnInitClientItem(int client);
forward void Gang_OnInitClientLayout(int client);
	
forward Action Gang_OnUseItem(int client, int databaseId, char[] sqlname, char[] name, char[] categorie);
forward void Gang_OnBuyItem(int client, char[] name, int price, char[] sqlname);
forward void Gang_OnSendItem(int sender, int recever, char[] name, char[] sqlname);
forward void Gang_OnSellItem(int client, char[] name, int price, char[] sqlname);
forward void Gang_OnOfflineSellItem(char[] client, char[] name, int price, char[] sqlname);
forward void Gang_OnSellInventoryItem(int client, char[] name, int price, char[] sqlname);
forward void Gang_OnUseShopCategorie(int client, Menu &menu, ShopAction action, char[] categorie);
forward void Gang_OnClientGetCash(int client, TypeCash cash, int amount, char[] msg);

forward void Gang_OnLayoutAdd(int client, char[] categorie, int item);
forward void Gang_OnLayoutDeleted(int client, char[] categorie, int item);
forward void Gang_OnLayoutChanged(int client, char[] categorie, int olditem, int newitem);
	
forward void Gang_OnGangChange(int client, GangList oldgang, GangList gang);
forward void Gang_OnGradeChange(int client, GradeList oldgrad, GradeList grade);
forward void Gang_OnExpChange(int client, int old, int exp);

/* ---------------------------------------------------------------------- */

native GangList Gang_TerritoryGetGang(char[] map);
native void Gang_TerritorySetGang(char[] map, GangList gang);
native bool Gang_TerritoryDefault(char[] map);

/* ---------------------------------------------------------------------- */

native int Gang_GetDatabase();

native void Gang_CreateEvent(GangList gang, char[] msg, any ...);

native void Gang_GetName(GangList gang, char[] name, int maxlen);
native void Gang_GetGradeName(GangList gang, GradeList grade, char[] name, int maxlen);

native int Gang_GetCash(GangList gang, TypeCash cash);
native void Gang_SetCash(GangList gang, TypeCash cash, int amount);

/* ---------------------------------------------------------------------- */

native int Gang_GetTotalItemCategorie();
native void Gang_RegisterItemCategorie(char[] sqlname, char[] name);
native void Gang_GetItemCategorieName(int cat, char[] buffer, int maxlen); // Cat étant la colonne du tableau
native void Gang_GetItemCategorieSqlName(int cat, char[] buffer, int maxlen); // Cat étant la colonne du tableau
native void Gang_GetItemCategorieDescription(int cat, char[] buffer, int maxlen); // Cat étant la colonne du tableau
native bool Gang_IsItemCategorieEnabled(int cat); // Cat étant la colonne du tableau

/* --- */

native int Gang_GetTotalAttribus();
native void Gang_GetAttribusType(int attribus, char[] buffer, int maxlen); // Attribus étant la colone du tableau
native void Gang_GetAttribusSqlName(int attribus, char[] buffer, int maxlen); // Attribus étant la colone du tableau
native void Gang_GetAttribusJson(int attribus, char[] buffer, int maxlen); // Attribus étant la colone du tableau

/* --- */

native int Gang_GetTotalItemSell();
native void Gang_GetItemSellAuthor(int databaseId, char[] buffer, int maxlen);
native void Gang_GetItemSellName(int databaseId, char[] buffer, int maxlen);
native void Gang_GetItemSellSqlName(int databaseId, char[] buffer, int maxlen);
native void Gang_GetItemSellCategorie(int databaseId, char[] buffer, int maxlen);
native int Gang_GetItemSellPrice(int databaseId);
native void Gang_RemoveSellItem(int databaseId);
native int Gang_GetItemSellExpire(int databaseId);
native int Gang_GetItemSellAttribus(int databaseId);

native int Gang_GetItemSellDatabaseId(int item); // Item étant la colonne du tableau

/* ---------------------------------------------------------------------- */

// databaseId = ID UNIQUE dans la table gangs_items
native void Gang_CreateSellItem(int client, char[] type, char[] sqlname, char[] name, int price, bool deleted, bool cansell, bool cansend, char[] attribus);
native void Gang_CreateInventoryItem(int client, char[] type, char[] sqlname, char[] name, bool deleted, bool cansell, bool cansend, char[] attribus);
native void Gang_SellInventoryItem(int client, int databaseId, int price);
native void Gang_BuyItem(int client, int databaseId);
native void Gang_GiveSellItem(int client, int databaseId);
native void Gang_RemoveInventoryItem(int client, int databaseId);
native void Gang_CopyInventoryItem(int client, int databaseId);

native void Gang_ClientUseItem(int client, int databaseId);
native void Gang_ClientSendItem(int sender, int recever, int databaseId);
native int Gang_GetClientNumbItem(int client);
native void Gang_GetClientItemName(int client, int databaseId, char[] buffer, int maxlen);
native void Gang_GetClientItemSqlName(int client, int databaseId, char[] buffer, int maxlen);
native void Gang_GetClientItemCategorie(int client, int databaseId, char[] buffer, int maxlen);

native bool Gang_ClientItemCanSell(int client, int databaseId);
native bool Gang_ClientItemCanSend(int client, int databaseId);

native int Gang_GetClientItemDatabaseId(int client, int item); // Item étant la colonne du tableau

native void Gang_UseShopCategorie(int client, Menu &menu, ShopAction action, char[] categorie);

native int Gang_GetTotalLayout(int client);
native int Gang_LayoutGetNumbItem(int client, char[] cat); 
native bool Gang_LayoutExistItem(int client, char[] cat, int databaseId); 
native void Gang_LayoutAddItem(int client, char[] cat, int databaseId, bool replace = false); 
native void Gang_LayoutDeleteItem(int client, char[] cat, int databaseId); 
native int Gang_LayoutGetItem(int client, int item); // Item étant la colonne du tableau 
native void Gang_LayoutChange(int client, char[] categorie, int databaseId, int newDatabaseId); // newDatabaseId <= 0 -> Changement automatique

native int Gang_GetClientItemAttribus(int client, int databaseId);

/* -------- */

native GangList Gang_GetClientGang(int client);
native void Gang_ChangeClientGang(int client, GangList gang);

native GradeList Gang_GetClientGrade(int client);
native void Gang_ChangeClientGrade(int client, GradeList grade);

native int Gang_GetClientCash(int client, TypeCash cash);
native void Gang_SetClientCash(int client, TypeCash cash, int amount, char[] msg);

native int Gang_GetClientExp(int client);
native void Gang_SetClientExp(int client, int amount);

native int Gang_GetClientOfflineSell(int client);

/* ---------------------------------------------------------------------- */

/* Fonction qui permet de volé l'argent d'un joueur */
public void StealCash(int victim, int attacker, int amount, bool chatvictim, bool chatattacker) {
	int Cash = Gang_GetClientCash(victim, WhiteCash);

	if(Cash < amount) {
		amount = Cash;
	}
	if(Cash <= 0) {
		amount = 0;
	}
	
	if(amount > 0) {
		char msg[128];
		Format(msg, sizeof(msg), "victim %N - attacker %N - amount %i", victim, attacker, amount);
		Gang_SetClientCash(victim, WhiteCash, Cash - amount, msg);

		Cash = Gang_GetClientCash(attacker, WhiteCash);
		Gang_SetClientCash(attacker, WhiteCash, Cash + amount, msg);
		
		if(chatvictim ) {
			CPrintToChat(victim, "{lightgreen}%N {green}vous a volé {lightgreen}%i$", attacker, amount);
		}
		if(chatattacker) {
			CPrintToChat(attacker, "{green}Vous avez volé {lightgreen}%i$ {green}à {lightgreen}%N", amount, victim);
		}
	}
}

/* ---------------------------------------------------------------------- */

/* On reprend le nom d'un item par son nom sql */
stock int GetItemName_BySqlName(char[] sqlname, char[] name, int maxlen) {
	int numb = Gang_GetTotalItemSell();
	int databaseid;
	char szSqlName[32];
	
	for (int i = 1; i <= numb; i++) {
		databaseid = Gang_GetItemSellDatabaseId(i);
		Gang_GetItemSellSqlName(databaseid, szSqlName, sizeof(szSqlName));
		
		if(StrEqual(sqlname, szSqlName)) {
			Gang_GetItemSellName(databaseid, name, maxlen);
			break;
		}
	}
}

/* On reprend le databaseid d'un item par son nom sql */
stock int GetItemDatabaseId_BySqlName(char[] sqlname) {
	int numb = Gang_GetTotalItemSell();
	int databaseid;
	char szSqlName[32];
	
	for (int i = 1; i <= numb; i++) {
		databaseid = Gang_GetItemSellDatabaseId(i);
		Gang_GetItemSellSqlName(databaseid, szSqlName, sizeof(szSqlName));
		
		if(StrEqual(sqlname, szSqlName)) {
			break;
		}
	}
	
	return databaseid;
}

/* On reprend le databaseid d'un item client par son nom sql */
stock int GetClientItemDatabaseId_BySqlName(int client, char[] sqlname) {
	int numb = Gang_GetClientNumbItem(client);
	int databaseid;
	char szSqlName[32];
	
	for (int i = 1; i <= numb; i++) {
		databaseid =  Gang_GetClientItemDatabaseId(client, i);
		Gang_GetClientItemSqlName(client, databaseid, szSqlName, sizeof(szSqlName));
		
		if(StrEqual(sqlname, szSqlName)) {
			break;
		}
	}
	
	return databaseid;
}

/* L'item n'expire jamais */
stock int IsUnlimitedSell(int item) {
	return Gang_GetItemSellExpire(item) > 0 ? false:true;
}

/* L'item est toujours en vente */
stock bool IsAlreadyInsell(int item) {
	int numb = Gang_GetTotalItemSell();
	int id;
	
	for (int i = 1; i <= numb; i++) {
		id = Gang_GetItemSellDatabaseId(i);
		
		if(id == item) {
			return true;
		}
	}
	
	return false;
}

/* Le client possède déjà l'item */
stock bool AsAlreadyInInventory(int client, int databaseId) {
	int numb = Gang_GetClientNumbItem(client);
	
	if(numb == 0) {
		return false;
	}
	
	int id;
	
	for (int i = 1; i <= numb; i++) {
		id = Gang_GetClientItemDatabaseId(client, i);
		
		if(databaseId == id) {
			return true;
		}
	}
	
	return false;
}

/* Le client possède déjà l'item */
stock bool AsAlreadyInInventory_BySqlName(int client, char[] name) {
	int numb = Gang_GetClientNumbItem(client);
	
	if(numb <= 0) {
		return false;
	}
	
	bool already = false;
	char szName[MAX_ITEM_NAME_SIZE];
	int id;
	
	for (int i = 1; i <= numb; i++) {
		id = Gang_GetClientItemDatabaseId(client, i);
		Gang_GetClientItemSqlName(client, id, szName, MAX_ITEM_NAME_SIZE);
		
		if(StrEqual(szName, name)) {
			already = true;
			break;
		}
	}
	
	return already;
}

/* Retourne le nombre d'item qu'un client possède */
stock int GetNumbItem(int client, char[] sqlname) {
	int numb = Gang_GetClientNumbItem(client);
	
	if(numb <= 0) {
		return 0;
	}
	
	int amount, id;
	char szSqlName[32];
	
	for (int i = 1; i <= numb; i++) {
		id = Gang_GetClientItemDatabaseId(client, i);
		Gang_GetClientItemSqlName(client, id, szSqlName, sizeof(szSqlName));
	
		if(StrEqual(sqlname, szSqlName)) {
			amount++;
		}
	}
	 
	return amount;
}

/* Retourne le nombre d'item qu'un client possède en vente */
stock int GetNumbItemSell(int client, char[] sqlname) {
	int numb = Gang_GetTotalItemSell();
	
	if(numb <= 0) {
		return 0;
	}
	
	int amount, id;
	char szSqlName[32], szAuthor[32], szSteamID[32];
	
	GetClientAuthId(client, AuthId_SteamID64, szSteamID, sizeof(szSteamID));
	
	for (int i = 1; i <= numb; i++) {
		id = Gang_GetItemSellDatabaseId(i);
		
		Gang_GetItemSellAuthor(id, szAuthor, sizeof(szAuthor));
		
		if(!StrEqual(szAuthor, szSteamID)) {
			continue;
		}
		
		Gang_GetClientItemSqlName(client, id, szSqlName, sizeof(szSqlName));
	
		if(StrEqual(sqlname, szSqlName)) {
			amount++;
		}
	}
	 
	return amount;
}

/* ---------------------------------------------------------------------- */

/* Vérification qu'un item existe dans un layout */
stock bool asItemLayoutExist(int client, char[] categorie, int databaseId) {
	int numb = Gang_LayoutGetNumbItem(client, categorie);
	
	if(numb == 0) {
		return false;
	}
	
	numb = Gang_GetTotalLayout(client);
	
	bool exist = false;
	
	int item;
	
	for (int i = 1; i <= numb; i++) {
		item = Gang_LayoutGetItem(client, i);
		
		if(item != databaseId) {
			continue;
		}
		
		exist = true;
	}
	
	return exist;
}

/* Fonction qui vérifie qu'un item existe dans une catégorie */
stock bool LayoutItemExist_ByCategorie(int client, char[] categorie) {
	int numb = Gang_LayoutGetNumbItem(client, categorie);
	
	if(numb <= 0) {
		return false;
	}
	
	numb = Gang_GetTotalLayout(client);

	int databaseId;
	char szCategorie[64];
	bool exist = false;
	
	for (int i = 1; i <= numb; i++) {
		databaseId = Gang_LayoutGetItem(client, i);

		Gang_GetClientItemCategorie(client, databaseId, szCategorie, sizeof(szCategorie));

		if(StrEqual(szCategorie, categorie)) {
			exist = true;
			break;
		}
	}
	
	return exist;
}

/* Fonction qui vérifie qu'un item existe dans le layout */
stock bool LayoutItemExist_BySqlName(int client, char[] categorie, char[] sqlname) {
	int numb = Gang_LayoutGetNumbItem(client, categorie);
	
	if(numb <= 0) {
		return false;
	}
	
	numb = Gang_GetTotalLayout(client);

	int databaseId;
	char szSqlName[64];
	char szCategorie[64];
	bool exist = false;
	
	for (int i = 1; i <= numb; i++) {
		databaseId = Gang_LayoutGetItem(client, i);

		Gang_GetClientItemCategorie(client, databaseId, szCategorie, sizeof(szCategorie));

		if(!StrEqual(szCategorie, categorie)) {
			continue;
		}
			
		Gang_GetClientItemSqlName(client, databaseId, szSqlName, sizeof(szSqlName));
		
		if(StrEqual(szSqlName, sqlname)) {
			exist = true;
			break;
		} 
	}
	
	return exist;
}

/* Suppression d'un item via son nom */
stock void LayoutDeleteItem_BySqlName(int client, char[] cat, char[] sqlname) {
	int numb = Gang_LayoutGetNumbItem(client, cat);
	
	if(numb == 0) {
		return;
	}
	
	numb = Gang_GetTotalLayout(client);
	
	int databaseId;
	char szCategorie[32];
	char szSqlName[32];
	
	for (int i = 1; i <= numb; i++) {
		databaseId = Gang_LayoutGetItem(client, i);

		Gang_GetClientItemCategorie(client, databaseId, szCategorie, sizeof(szCategorie));
		
		if(!StrEqual(szCategorie, cat)) {
			continue;
		}
		
		Gang_GetClientItemSqlName(client, databaseId, szSqlName, sizeof(szSqlName));

		if(!StrEqual(szSqlName, sqlname)) {
			continue;
		}
		
		Gang_LayoutDeleteItem(client, cat, databaseId);
	}
}

/* Suppression d'un loyout total */
stock void LayoutDeleteAllItem(int client, char[] cat) {
	int numb = Gang_LayoutGetNumbItem(client, cat);
	
	if(numb == 0) {
		return;
	}
	
	numb = Gang_GetTotalLayout(client);
	
	int databaseId;
	char szCategorie[32];
	
	for (int i = 1; i <= numb; i++) {
		databaseId = Gang_LayoutGetItem(client, i);
		Gang_GetClientItemCategorie(client, databaseId, szCategorie, sizeof(szCategorie));
		
		if(!StrEqual(szCategorie, cat)) {
			continue;
		}
		
		Gang_LayoutDeleteItem(client, cat, databaseId);
	}
}

/* Suppression d'un loyout total par nom */
stock void LayoutDeleteAllItem_bySqlName(int client, char[] cat, char[] sqlname) {
	int numb = Gang_LayoutGetNumbItem(client, cat);
	
	if(numb == 0) {
		return;
	}
	
	numb = Gang_GetTotalLayout(client);
	
	int databaseId;
	char szSqlName[MAX_ITEM_NAME_SIZE];
	char szCategorie[32];

	for (int i = 1; i <= numb; i++) {
		databaseId = Gang_LayoutGetItem(client, i);
		
		Gang_GetClientItemCategorie(client, databaseId, szCategorie, sizeof(szCategorie));
		
		if(!StrEqual(szCategorie, cat)) {
			continue;
		}
		
		Gang_GetClientItemSqlName(client, databaseId, szSqlName, sizeof(szSqlName));
		
		if(!StrEqual(szSqlName, sqlname)) {
			continue;
		}

		Gang_LayoutDeleteItem(client, cat, databaseId);
	}
}

/* ---------------------------------------------------------------------- */

/* Fonction qui envoie un message au membre du gang */
stock void PrintToGrade(GangList togang, GradeList tograde, char[] buffer, any ...) {
	int len = strlen(buffer) + 255;
	char[] szMessage = new char[len];
	VFormat(szMessage, len, buffer, 4);
	
	GangList gang;
	GradeList grade;
			
	for (int i = 1; i <= MaxClients; i++) {
		if(!IsClientValid(i)) {
			continue;
		}
		if(GetClientTeam(i) != 2) {
			continue;
		}
		
		gang = Gang_GetClientGang(i);
		
		if(gang != togang) {
			continue;
		}
		
		grade = Gang_GetClientGrade(i);
		
		if(grade != tograde) {
			continue;
		}
		
		CPrintToChat(i, szMessage);
	}
}

/* ---------------------------------------------------------------------- */

/* Fonction qui change le style d'un item */
stock void ChangeMenuItemStyle(Menu menu, int item, int style) {
	
	int count = menu.ItemCount;
	
	char szItem[32];
	char szDisplay[32];
	int itemdraw;
	
	for (int i = 0; i < count; i++) {
		
		menu.GetItem(i, szItem, sizeof(szItem), itemdraw, szDisplay, sizeof(szDisplay));
		
		if(item != i || itemdraw == ITEMDRAW_IGNORE) {
			continue;
		}
		
		menu.GetItem(i, szItem, sizeof(szItem), itemdraw, szDisplay, sizeof(szDisplay));
		
		menu.InsertItem(i, szItem, szDisplay, style);
		menu.RemoveItem(i+1);
	}
}

/* Fonction qui rename un item du menu */
stock void ChangeMenuItemDisplay(Menu menu, int item, char[] display, any ...) {
	
	int count = menu.ItemCount;
	
	char szDisplay[32];
	VFormat(szDisplay, sizeof(szDisplay), display, 4);
	
	char szItem[32];
	int style;
	
	for (int i = 0; i < count; i++) {

		if(item != i) {
			continue;
		}

		menu.GetItem(i, szItem, sizeof(szItem), style);
		
		menu.InsertItem(i, szItem, szDisplay, style);
		menu.RemoveItem(i+1);
	}
}

/* ---------------------------------------------------------------------- */

/* Fonction qui supprime un timer */
stock void DeleteTimer(Handle &timer) {
	if(timer != null) {
		delete timer;
	}
	
	timer = null;
}

/* Fonction qui transforme un temps en progressbar */
stock void TimeToProgressBar(int time, int maxtime, int bartime, char[] buffer, int maxlen, char[] load, char[] notload)
{
	float convert = float(bartime) * (float(time) / float(maxtime));

	for (int i = 1; i <= bartime; i++)
		Format(buffer, maxlen, "%s%s", buffer, convert >= i ? load:notload);
}

stock void FakePrecacheSound(const char[] path) {
	AddToStringTable(FindStringTable("soundprecache"), path);
}

/* Fonction qui convertis les secondes en temps */
stock void TimeToMinuts(int time, char[] buffer, int size)
{
	int minutes = time / 60;
	int seconds = time - 60 * minutes;
	
	Format(buffer, size, "%s%i'%s%i", (minutes < 10 ? "0":""), minutes, (seconds < 10 ? "0":""), seconds);
}

/* Precache d'effect */
stock void PrecacheParticleEffect(char[] sEffectName) {
	/*int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE) {
		table = FindStringTable("ParticleEffectNames");
	}*/
	
	int table = FindStringTable("ParticleEffectNames");
	bool save = LockStringTables(false);
	AddToStringTable(table, sEffectName);
	LockStringTables(save);
}

/* ---------------------------------------------------------------------- */

/* Fonction qui trouve un client via son steamid */
stock int FindPlayerByAuthid(char[] buffer, AuthIdType authid) {
	char szAuthId[32];
	
	for (int i = 1; i <= MaxClients; i++) {
		if(!IsClientValid(i)) {
			continue;
		}
		
		GetClientAuthId(i, authid, szAuthId, sizeof(szAuthId));
		
		if(StrEqual(buffer, szAuthId)) {
			return i;
		}
	}
	
	return 0;
}

/* Fonction qui vérifie la validité du client */
stock bool IsClientValid(int client, bool alive = false)
{
	if(client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		if(alive && !IsPlayerAlive(client))
			return false;
		
		return true;
	}
	return false;
}

/* Fonction qui reprend le nombre de joueur pas en spec (je sais plus pourquoi) */
stock int GetNumbPlayer() {
	int amount;
	
	for (int i = 1; i <= MaxClients; i++) {
		if(IsClientValid(i)) {
			if(GetClientTeam(i) > 1) {
				amount++;
			}
		}
	}
	
	return amount;
}