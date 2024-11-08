/*
    XiTimer.lsl
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

    TODO
*/

// ==
// == preprocessor options
// ==

#ifdef XIALL_ENABLE_XILOG_TRACE
#define XITIMER_ENABLE_XILOG_TRACE
#endif

#ifndef XITIMER_MINIMUM_INTERVAL
#define XITIMER_MINIMUM_INTERVAL 0.1
#endif

// ==
// == globals
// ==


#ifdef XITIMER_DISABLE_MULTIPLE
    list _XITIMER_QUEUE; // id, callback, length
    #define _XITIMER_QUEUE_STRIDE 3
#else
    list _XITIMER_QUEUE; // id, callback, length, trigger
    #define _XITIMER_QUEUE_STRIDE 4
#endif

// ==
// == functions
// ==

#define XiTimer$Start(...) _XiTimer_Start( __VA_ARGS__ )
string XiTimer$Start( // adds a timer
    float interval,
    integer periodic,
    string callback
    )
{
    #ifdef XITIMER_ENABLE_XILOG_TRACE
        XiLog$TraceParams("XiTimer$Start", [ "interval", "periodic", "callback" ], [
            interval,
            periodic,
            XiString$Elem( callback )
            ]);
    #endif

    // check inputs
    if ( interval < 0.00001 ) return NULL_KEY; // invalid interval
    if ( interval < XITIMER_MINIMUM_INTERVAL ) interval = XITIMER_MINIMUM_INTERVAL; // clamp to minimum interval
    string id = llGenerateKey();
    #ifdef XITIMER_DISABLE_MULTIPLE
        _XITIMER_QUEUE = [ // multiple timers not enabled, so set queue
            id,
            callback,
            (integer)( interval * 1000 ) * !!periodic
        ];
        llSetTimerEvent( interval ); // then start single timer
    #else
        _XITIMER_QUEUE += [ // multiple timers enabled, so add to queue
            id,
            callback,
            (integer)( interval * 1000 ) * !!periodic,
            XiDate$MSAdd( XiDate$MSNow(), (integer)( interval * 1000 ) ) // convert to ms
        ];
        _XITimer_Check(); // then reprocess queue
    #endif
    return id;
}

#define XiTimer$Cancel(...) _XiTimer_Cancel( __VA_ARGS__ )
integer XiTimer$Cancel( // removes a timer
    string id // required unless XITIMER_DISABLE_MULTIPLE is set
    )
{
    #ifdef XITIMER_ENABLE_XILOG_TRACE
        XiLog$TraceParams("XiTimer$Cancel", [ "id" ], [
            XiString$Elem( id )
            ]);
    #endif
    #ifdef XITIMER_DISABLE_MULTIPLE
        _XITIMER_QUEUE = []; // we only have one timer, so cancel it
        llSetTimerEvent( 0.0 );
    #else
        // find timer by id
        integer i = llListFindList( llList2ListSlice( XIMIT_TIMERS, 0, -1, XIMIT_TIMERS_STRIDE, 0 ), [ id ] );
        if ( i == -1 ) return 0; // not found
        // found, delete it
        XIMIT_TIMERS = llDeleteSubList( XIMIT_TIMERS, i, i + XIMIT_TIMERS_STRIDE - 1 );
        _XiMIT_Check();
    #endif
    return 1;
}

#define XiTimer$Find(...) _XiTimer_Find( __VA_ARGS__ )
string XiTimer$Find( // finds a timer by callback
    string callback
    )
{
    #ifdef XITIMER_ENABLE_XILOG_TRACE
        XiLog$TraceParams("XiTimer$Find", [ "callback" ], [
            XiString$Elem( callback )
            ]);
    #endif
    integer i = llListFindList( llList2ListSlice( XIMIT_TIMERS, 0, -1, XIMIT_TIMERS_STRIDE, 1 ), [ callback ] );
    if ( i == -1 ) return "";
    return llList2String( XIMIT_TIMERS, i * XIMIT_TIMERS_STRIDE );
}

#define _XiTimer$Check(...) _XiTimer_Check( __VA_ARGS__ )
_XiTimer$Check() // checks the MIT timers to see if any are triggered
{
    #ifdef XITIMER_ENABLE_XILOG_TRACE
        XiLog$TraceParams("_XiTimer$Check", [], []);
    #endif
    llSetTimerEvent(0.0);
    if ( _XITIMER_QUEUE != [] ) return; // no timer to check
    #ifdef XIMIT_DISABLE_MULTIPLE
        xi_xitimer(
            llList2String( _XITIMER_QUEUE, 0 ),
            llList2String( _XITIMER_QUEUE, 1 )
        );
        if ( (integer)llList2String( _XITIMER_QUEUE, 3 ) ) llSetTimerEvent( (integer)llList2String( _XITIMER_QUEUE, 3 ) * 0.001 ); // periodic
        else _XITIMER_QUEUE = []; // one-shot
    #else
        integer now = XiDate$MSNow();
        integer i;
        integer l = llGetListLength( _XITIMER_QUEUE ) / _XITIMER_QUEUE_STRIDE;
        integer lowest = 0x7FFFFFFF;
        for (i = 0; i < l; i++)
        {
            string t_id = llList2String( _XITIMER_QUEUE, i * _XITIMER_QUEUE_STRIDE );
            string t_callback = llList2String( _XITIMER_QUEUE, i * _XITIMER_QUEUE_STRIDE + 1 );
            integer t_length = (integer)llList2String( _XITIMER_QUEUE, i * _XITIMER_QUEUE_STRIDE + 2 );
            integer t_trigger = (integer)llList2String( _XITIMER_QUEUE, i * _XITIMER_QUEUE_STRIDE + 3 );
            integer remain = XiDate$MSAdd( t_trigger, -now );
            if ( remain * 0.001 < XITIMER_MINIMUM_INTERVAL )
            { // timer triggered
                if ( !t_length )
                { // one-shot, so drop it from the queue
                    _XITIMER_QUEUE = llDeleteSubList( _XITIMER_QUEUE, i * _XITIMER_QUEUE_STRIDE, ( i + 1 ) * _XITIMER_QUEUE_STRIDE - 1 );
                    i--; l--; // shift for loop to account for lost queue stride
                }
                else if ( t_length < lowest ) lowest = t_length; // periodic, and it is currently the next timer to trigger
                xi_xitimer( // fire function
                    t_id,
                    t_callback
                    );
            }
            else if ( remain < lowest ) lowest = remain; // timer not triggered, but it is currently the next timer to trigger
        }
        if ( lowest != 0x7FFFFFFF )
        { // a timer is still in the queue
            llSetTimerEvent( lowest * 0.001 );
        }
    #endif
}
