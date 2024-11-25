/*
    XiList.lsl
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
// == globals
// ==

// ==
// == macros
// ==

#define XiList$FindStrideByElem( list_haystack, stride_length, index_in_stride, string_needle ) \
    llListFindList( llList2ListSlice( list_haystack, 0, -1, stride_length, index_in_stride ), [ string_needle ] )

// ==
// == functions
// ==

string XiList$Elem(list var)
{
    if (var == []) return "[]";
    return "[\"" + llDumpList2String(var, "\", \"") + "\"]";
}

list XiList$Empty( // if a list only has one element that is a blank string, convert it to an empty list
    list in
    )
{
    if (llGetListLength(in) == 1)
    {
        if (llList2String(in, 0) == "") in = [];
    }
    return in;
}

list XiList$Json( // returns a string with each element converted to an escaped JSON string
    list in
)
{
    list out;
    integer i;
    integer l = llGetListLength(in);
    for (i = 0; i < l; i++)
    {
        out += ["\"" + XiString$Escape(XISTRING$ESCAPE_FILTER_JSON, llList2String(in, i)) + "\""];
    }
}

list XiList$Reverse(
    list l
)
{
    integer n = (l != []);
    while (n)
    {
        l += llList2List(l, (n = ~-n), n);
    }
    return llList2List(l, (l != []) >> 1, -1);
}

list XiList$Collate(
    list a,
    list b
    )
{
    list out;
    integer i;
    integer l = llGetListLength(a);
    if (llGetListLength(b) > l) l = llGetListLength(b);
    for (i = 0; i < l; i++) out += llList2List(a, i, i) + llList2List(b, i, i);
    return out;
}

list XiList$Concatenate(
    string start,
    list a,
    string mid,
    list b,
    string end
    )
{
    list out;
    integer i;
    integer l = llGetListLength(a);
    if (llGetListLength(b) > l) l = llGetListLength(b);
    for (i = 0; i < l; i++) out += [start + llList2String(a, i) + mid + llList2String(b, i) + end];
    return out;
}

string XiList$ToString( // converts a list into a string without worrying about separators or JSON
    list in
    )
{
    string out;
    integer i;
    integer l = llGetListLength( in );
    string elem;
    for ( i = 0; i < l; i++ )
    {
        elem = llList2String( in, i );
        out += XiInteger$ToHex( llStringLength( elem ), 1 ) + " " + elem;
    }
    return XiInteger$ToHex( l, 1 ) + " " + out + " ";
}

list XiList$FromStr( // converts a string generated by XiList$ToString(...) back into a list
    string in
    )
{
    integer length = llStringLength( in ); // count length once for speed
    integer space = llSubStringIndex( in, " " ); // find header delineator - hex before this is number of elements
    if ( space > 7 ) return []; // impossible to have an XiInteger$ToHex result longer than 8 chars - signals non-XiList string
    integer count;
    integer expect = (integer)( "0x" + llGetSubString( in, 0, space - 1 ) );
    in = llDeleteSubString( in, 0, space ); // trim elem_expect header off
    length -= space + 1; // reduce length counter
    integer elem_length;
    string elem;
    list out;
    while ( length > 1 )
    { // for each element
        space = llSubStringIndex( in, " " ); // find header delineator - hex before this is length of element body
        if ( space > 7 ) return []; // impossible to have an XiInteger$ToHex result longer than 8 chars - signals non-XiList string
        elem_length = (integer)( "0x" + llGetSubString( in, 0, space - 1 ) );
        if ( !elem_length ) elem = ""; // llGetSubString can't return an empty string
        else elem = llGetSubString( in, space + 1, space + elem_length );
        out += [ elem ]; // we can add it right to the output, since missing data will always be detected by the end-of-list check
        in = llDeleteSubString( in, 0, space + elem_length ); // trim elem_expect header off
        length -= space + elem_length + 1; // reduce length counter
    }
    if ( in != " " ) return []; // all that should be left is the end-of-list space
    return out;
}

integer XiList$FindPartial( // llListFindList but needle can be only part of the element instead of the entire element
    list x,
    string s
    )
{
    integer i;
    integer l = llGetListLength(x);
    for (i = 0; i < l; i++)
    {
        if (llSubStringIndex(llList2String(x, i), s) != -1) return i;
    }
    return -1;
}

list XiList$DeleteStrideByMatch(
    list haystack,
    integer stride,
    integer index,
    string needle
    )
{
    integer i = llListFindList(llList2ListSlice(haystack, 0, -1, stride, index), [needle]);
    if (i != -1) return llDeleteSubList(haystack, i * stride, (i + 1) * stride - 1); // delete existing stride because we'll be re-adding it
    return haystack;
}
