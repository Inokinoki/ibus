/* -*- mode: ObjC; c-basic-offset: 4; indent-tabs-mode: nil; -*- */
/* vim:set et sts=4: */
/* ibus - The Input Bus
 * Copyright (C) 2020-2026 Weixuan XIAO <veyx.shaw@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301 USA.
 */

#import "glibrunloop.h"

#import <CoreFoundation/CoreFoundation.h>

static void
ibus_macos_pump_glib (CFRunLoopTimerRef timer,
                      void             *info)
{
    GMainContext *context = g_main_context_default ();
    while (g_main_context_pending (context))
        g_main_context_iteration (context, FALSE);
}

void
ibus_macos_attach_glib_to_runloop (void)
{
    static gboolean attached = FALSE;
    CFRunLoopTimerRef timer;
    CFRunLoopTimerContext ctx = { 0, NULL, NULL, NULL, NULL };

    if (attached)
        return;
    attached = TRUE;

    /* Iterate GLib on the main CFRunLoop so GDBus/IBus stay on the
     * Cocoa UI thread. A short timer is used because GLib's kqueue
     * sources do not automatically wake CFRunLoop. */
    timer = CFRunLoopTimerCreate (kCFAllocatorDefault,
                                  CFAbsoluteTimeGetCurrent (),
                                  0.016,
                                  0,
                                  0,
                                  ibus_macos_pump_glib,
                                  &ctx);
    CFRunLoopAddTimer (CFRunLoopGetMain (), timer, kCFRunLoopCommonModes);
    CFRelease (timer);
}
