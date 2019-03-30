#if defined _smart_menu_included
#endinput
#define _smart_menu_included
#endif

typedef SmartMenuHandler = function int(SmartMenu menu, MenuAction action, int param1, int param2);

methodmap SmartMenu __nullable__ < Menu {
    public SmartMenu(SmartMenuHandler handler, MenuAction actions = MENU_ACTIONS_DEFAULT) {
        return view_as<SmartMenu>(new Menu(view_as<MenuHandler>(handler), actions));
    }

    public void SetCell(const char[] id, any data) {
        char buffer[64];
        IntToString(view_as<int>(data), buffer, sizeof(buffer));
        this.AddItem(id, buffer, ITEMDRAW_IGNORE);
    }

    public any GetCell(const char[] id, any def_value = 0) {
        char info[64], data[64];
        for(int i = 0; i < this.ItemCount; i++) {
            this.GetItem(i, info, sizeof(info), _, data, sizeof(data));

            if(StrEqual(id, info)) {
                return StringToInt(data);
            }
        }

        return def_value;
    }

    public void SetFloat(const char[] id, float data) {
    	char buffer[64];
    	FloatToString(data, buffer, sizeof(buffer));
    	this.AddItem(id, buffer, ITEMDRAW_IGNORE);
    }

    public float GetFloat(const char[] id, float def_value) {
    	char info[64], data[64];
    	for(int i = 0; i < this.ItemCount; i++) {
    		this.GetItem(i, info, sizeof(info), _, data, sizeof(data));

    		if(StrEqual(id, info)) {
    			return StringToFloat(data);
    		}
    	}

    	return def_value;
    }

    public void SetString(const char[] id, const char[] data) {
    	this.AddItem(id, data, ITEMDRAW_IGNORE);
    }

    public bool GetString(const char[] id, char[] buffer, int maxlen, const char[] def_value = NULL_STRING) {
    	char info[64], data[64];
    	for(int i = 0; i < this.ItemCount; i++) {
    		this.GetItem(i, info, sizeof(info), _, data, sizeof(data));

    		if(StrEqual(info, id)) {
    			strcopy(buffer, maxlen, data);
    			return true;
    		}
    	}

    	strcopy(buffer, maxlen, def_value);
    	return false;
    }

    public bool AddItemFormat(const char[] info, int style = ITEMDRAW_DEFAULT, const char[] format, any ...) {
    	char display[128];
    	VFormat(display, sizeof(display), format, 4);

    	return this.AddItem(info, display, style);
    }

    public void CopyAny(SmartMenu dest, const char[] id) {
    	char info[64], data[64];
    	for(int i = 0; i < this.ItemCount; i++) {
    		this.GetItem(i, info, sizeof(info), _, data, sizeof(data));

    		if(StrEqual(info, id)) {
    			dest.AddItem(id, data, ITEMDRAW_IGNORE);
    		}
    	}
    }
}
