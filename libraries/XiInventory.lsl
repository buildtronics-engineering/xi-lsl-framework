/*
    XiInventory.lsl
    Library
    Xi LSL Framework
    Copyright (C) 2024  BuildTronics
    https://docs.buildtronics.net/xi-lsl-framework

    ╒══════════════════════════════════════════════════════════════════════════════╕
    │ LICENSE                                                                      │
    └──────────────────────────────────────────────────────────────────────────────┘

    This script is free software: you can redistribute it and/or modify it under the
    terms of the GNU Lesser General Public License as published by the Free Software
    Foundation, either version 3 of the License, or (at your option) any later
    version.

    This script is distributed in the hope that it will be useful, but WITHOUT ANY
    WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
    PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License along
    with this script.  If not, see <https://www.gnu.org/licenses/>.

    ╒══════════════════════════════════════════════════════════════════════════════╕
    │ INSTRUCTIONS                                                                 │
    └──────────────────────────────────────────────────────────────────────────────┘

    TBD
*/

// ==
// == preprocessor options
// ==

#ifdef XIALL_ENABLE_XILOG_TRACE
#define XIINVENTORY_ENABLE_XILOG_TRACE
#endif

// ==
// == globals
// ==

string XIINVENTORY_NC_N;
string XIINVENTORY_NC_K;
integer XIINVENTORY_NC_L;
string XIINVENTORY_NC_H;

list XIINVENTORY_REMOTE; // start_param, script_name, running
#define XIINVENTORY_REMOTE_STRIDE 3

// ==
// == functions
// ==

#define XiInventory$List(...) _XiInventory_List( __VA_ARGS__ )
list XiInventory$List(
    integer t
    )
{
    list x;
    integer i;
    integer l = llGetInventoryNumber(t);
    for (i = 0; i < l; i++)
    {
        x += llGetInventoryName(t, i);
    }
    return x;
}

#define XiInventory$Copy(...) _XiInventory_Copy( __VA_ARGS__ )
integer XiInventory$Copy( // copies an inventory item to another object
    string prim,
    string name,
    integer type,
    integer pin,
    integer run,
    integer param
    )
{
    #ifdef XIINVENTORY_ENABLE_XILOG_TRACE
        XiLog$TraceParams("XiInventory$Copy", ["prim", "name", "type", "pin", "run", "param"], [
            XiObject$Elem(prim),
            XiString$Elem(name),
            type,
            pin,
            run,
            param
            ]);
    #endif
    integer t = llGetInventoryType(name);
    if (type != INVENTORY_ALL && type != t) return 0; // type check failed
    if (t == INVENTORY_NONE) return 0; // can't push anything
    integer p = llGetInventoryPermMask(name, MASK_OWNER);
    if (!(p & PERM_COPY)) return 0; // can't push a no-copy inventory item
    if (t == INVENTORY_SCRIPT && pin) llRemoteLoadScriptPin(prim, name, pin, run, param);
    else llGiveInventory(prim, name);
    return 1;
}

#define XiInventory$OwnedByCreator(...) _XiInventory_OwnedByCreator( __VA_ARGS__ )
integer XiInventory$OwnedByCreator(
    string name
)
{
    return llGetInventoryCreator( name ) == llGetOwner();
}

#define XiInventory$RezRemote(...) _XiInventory_RezRemote( __VA_ARGS__ )
integer XiInventory$RezRemote( // rezzes a remote object with Remote.lsl
    string name,
    vector pos,
    vector vel,
    rotation rot,
    integer param,
    list scripts,
    list runs
    )
{
    #ifdef XIINVENTORY_ENABLE_XILOG_TRACE
        XiLog$TraceParams( "XiInventory$RezRemote", [ "name", "pos", "vel", "rot", "param", "scripts", "runs" ], [
            XiString$Elem( name ),
            (string)pos,
            (string)vel,
            (string)rot,
            (string)param,
            XiList$Elem( scripts ),
            XiList$Elem( runs )
            ] );
    #endif
    XiLog( DEBUG, "Rezzing remote object with loglevel " + XiLog$LevelToString( (integer)llLinksetDataRead( "loglevel" ) ) + "." );
    llRezAtRoot( name, pos, vel, rot, (integer)llLinksetDataRead( "loglevel" ) );
    XIINVENTORY_REMOTE += [ param, XiList$ToString( scripts ), XiList$ToString( runs ) ];
    // TODO: somehow timeout XIINVENTORY_REMOTE
    return 1;
}

#define XiInventory$NCOpen(...) _XiInventory_NCOpen( __VA_ARGS__ )
integer XiInventory$NCOpen( // opens a notecard for XiInventory$NC* operations
    string name
    )
{
    #ifdef XIINVENTORY_ENABLE_XILOG_TRACE
        XiLog$TraceParams("XiInventory$NCOpen", ["name"], [
            XiString$Elem(name)
            ]);
    #endif
    #ifndef XIINVENTORY_ENABLE_NC
        XiLog(DEBUG, "XIINVENTORY_ENABLE_NC not defined.");
        return;
    #endif
    XIINVENTORY_NC_N = name;
    key new_NC_K = llGetInventoryKey(XIINVENTORY_NC_N);
    if (new_NC_K == NULL_KEY) return 0; // notecard doesn't eXist
    if (new_NC_K == XIINVENTORY_NC_K) return 0x1; // notecard opened, no changes since last opened
    XIINVENTORY_NC_K = new_NC_K;
    return 0x3; // notecard opened, changes since last opened
}

#define XiInventory$NCRead(...) _XiInventory_NCRead( __VA_ARGS__ )
XiInventory$NCRead( // reads a line from the open notecard
    integer i // line number, starting from 0
    )
{
    #ifdef XIINVENTORY_ENABLE_XILOG_TRACE
        XiLog$TraceParams("XiInventory$NCRead", ["i"], [
            i
            ]);
    #endif
    #ifndef XIINVENTORY_ENABLE_NC
        XiLog(DEBUG, "XIINVENTORY_ENABLE_NC not defined.");
        return;
    #endif
    string s = NAK;
    if (llGetFreeMemory() > 4096) s = llGetNotecardLineSync(XIINVENTORY_NC_N, i); // attempt sync read if at least 2k of memory free
    if (s == NAK) XIINVENTORY_NC_H = llGetNotecardLine(XIINVENTORY_NC_N, i); // sync read failed, do dataserver read
    else Xi$nc_line(XIINVENTORY_NC_N, XIINVENTORY_NC_L, s);
}

#define XiInventory$TypeToString(...) _XiInventory_TypeToString( __VA_ARGS__ )
string XiInventory$TypeToString( // converts an INVENTORY_* flag into a string (use "INVENTORY_" + llToUpper(XiInventory$TypeToString(...)) to get actual flag name)
    integer f // INVENTORY_* flag
    )
{
    if (f == -1) return ""; // return empty string for INVENTORY_NONE and INVENTORY_ALL
    integer i = llListFindList([
        INVENTORY_TEXTURE,
        INVENTORY_SOUND,
        INVENTORY_LANDMARK,
        INVENTORY_CLOTHING,
        INVENTORY_OBJECT,
        INVENTORY_NOTECARD,
        INVENTORY_SCRIPT,
        INVENTORY_BODYPART,
        INVENTORY_ANIMATION,
        INVENTORY_GESTURE,
        INVENTORY_SETTING,
        INVENTORY_MATERIAL
        ], [f]);
    if (i == -1) return "Unknown"; // return "Unknown" for a flag that is not known by XiInventory at compile time
    return llList2String([
        "Texture",
        "Sound",
        "Landmark",
        "Clothing",
        "Object",
        "Notecard",
        "Script",
        "BodyPart",
        "Animation",
        "Gesture",
        "Setting",
        "Material"
        ], i);
}

#define XiInventory$Push(...) _XiInventory_Push( __VA_ARGS__ )
XiInventory$Push( // pushes an inventory item via XiChat
    string prim,
    string domain,
    string name,
    integer type,
    integer pin,
    integer run,
    integer param
    )
{
    #ifdef XIINVENTORY_ENABLE_XILOG_TRACE
        XiLog$TraceParams("XiInventory$Push", ["prim", "domain", "name", "type", "pin", "run", "param"], [
            XiObject$Elem(prim),
            XiString$Elem(domain),
            XiString$Elem(name),
            type,
            pin,
            run,
            param
            ]);
    #endif
    // TODO
}

#define XiInventory$Pull(...) _XiInventory_Pull( __VA_ARGS__ )
XiInventory$Pull( // pulls an inventory item via XiChat
    string prim,
    string domain,
    string name,
    integer type,
    integer pin,
    integer run,
    integer param
    )
{
    #ifdef XIINVENTORY_ENABLE_XILOG_TRACE
        XiLog$TraceParams("XiInventory$Pull", ["prim", "domain", "name", "type", "pin", "run", "param"], [
            XiObject$Elem(prim),
            XiString$Elem(domain),
            XiString$Elem(name),
            type,
            pin,
            run,
            param
            ]);
    #endif
    // TODO
}
