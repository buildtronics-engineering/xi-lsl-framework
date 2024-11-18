/*
    XiFloat.lsl
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
// == functions
// ==

string XiFloat$ToString( // rounds a float to a specified number of digits after the decimal
    float f,
    integer digits
    )
{
    if (!digits) return (string)llRound(f); // no digits after decimal, so just round and return
    // we need to manually return only a certain positive number of digits after the decimal
    string s = (string)f;
    integer i = llSubStringIndex(s, "."); // there are more efficient ways to do this, but whatever
    return llGetSubString(s, 0, i + digits); // return string-cast float, but only up to the number of digits requested
}

float XiFloat$Clamp(
    float i,
    float m,
    float x
    )
{
    if (i < m) i = m; // clamp to minimum
    if (i > x) i = x; // clamp to maXimum
    return i;
}

integer XiFloat$FlipCoin(
    float chance // values that are not BETWEEN 0.0 and 1.0, EXCLUSIVE, are treated as 50/50
    )
{
    if ( chance <= 0.0 ) return 0;
    if ( chance >= 1.0 ) return 1;
    if ( llFrand( 1.0 ) < chance ) return 0;
    return 1;
}

float XiFloat$RandRange(
    float min,
    float max
    )
{
    return min + llFrand( max - min );
}
