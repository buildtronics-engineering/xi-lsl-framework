/*
    object_rez.lsl
    Event Handler
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

    This snippet replaces the object_rez event handler with a version that calls
    maintenance functions required by Xi libraries, then optionally executes a user-
    defined function to handle event calls that are not intercepted by Xi libraries:

		#define XI_OBJECT_REZ
		Xi_object_rez( key id )
		{
            // code to run when event occurs that is not intercepted by Xi
		}
*/

#ifdef XI_OBJECT_REZ
	object_rez( key id )
	{
        // event unused, so the only reason to define it is to log it
        XiLog_TraceParams( "object_rez", [ "id" ], [
            XiObject_Elem( id ),
        ] );

        // event unused, so pass to user-defined function only
        Xi_object_rez( id );
	}
#endif
