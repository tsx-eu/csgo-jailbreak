#if defined _shopcustom_included
	#endinput
#endif
#define _shopcustom_included

#include <advanced_precache.inc>
#define MAX_ITEMS	10
#define MAX_WEIGHT	50
#define WORLDNAME	"sc_item_"
#define	TAG			"[SHOP]"

#define SC_XXXXX	(1<<0)

typeset SC_OnItemUse {
	function Action(int itemId, int client);
	function Action(SC_Item item, int client);
}
typeset SC_OnItemDrop {
	function void(int itemId, int client);
	function void(SC_Item item, int client);
}

forward void SC_OnPluginReady();

native int SC_Create(const char[] name, SC_OnItemUse onUse = INVALID_FUNCTION, SC_OnItemDrop onDrop = INVALID_FUNCTION);

native void SC_SetItemPrice(int id, int price);
native int SC_GetItemPrice(int id);

native void SC_SetItemMaxStack(int id, int price);
native int SC_GetItemMaxStack(int id);

native void SC_SetItemWeight(int id, int price);
native int SC_GetItemWeight(int id);

native void SC_SetItemFlags(int id, int price);
native int SC_GetItemFlags(int id);

native void SC_SetItemModel(int id, const char[] model, float scale=1.0);
native float SC_GetItemModel(int id, char[] model, int maxLength);

native void SC_GivePlayerItem(int client, int itemId);
native int SC_SpawnItem(int id, float pos[3], float vel[3] =  { 0.0, 0.0, 0.0 } );

methodmap SC_Item {
	public SC_Item(const char[] name, SC_OnItemUse onUse = INVALID_FUNCTION, SC_OnItemDrop onDrop = INVALID_FUNCTION) {
		return view_as<SC_Item>(SC_Create(name, onUse, onDrop));
	}
	property int Id {
        public get() {
            return view_as<int>(this);
        }
	}
	property int Money {
        public get() {
            return SC_GetItemPrice(this.Id);
        }
        public set(int value) {
            SC_SetItemPrice(this.Id, value);
        }
    }
    property int Stack {
        public get() {
            return SC_GetItemMaxStack(this.Id);
        }
        public set(int value) {
            SC_SetItemMaxStack(this.Id, value);
        }
    }
    property int Weight {
        public get() {
            return SC_GetItemWeight(this.Id);
        }
        public set(int value) {
            SC_SetItemWeight(this.Id, value);
        }
    }
    property int Flag {
        public get() {
            return SC_GetItemFlags(this.Id);
        }
        public set(int value) {
            SC_SetItemFlags(this.Id, value);
        }
    }
	public float GetModel(char[] model, int length) {
		return SC_GetItemModel(this.Id, model, length);
	}
	public void SetModel(const char[] model, float scale=1.0) {
		ModelsPrecacheStatic(model);
		SC_SetItemModel(this.Id, model, scale);
	}
}