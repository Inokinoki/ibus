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

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include <stdlib.h>

#import "glibrunloop.h"
#import "ibusimcontroller.h"

#import <AppKit/AppKit.h>
#import <InputMethodKit/InputMethodKit.h>
#import <ibus.h>

static IMKServer *_imk_server = nil;

static void
_bus_disconnected_cb (IBusBus  *bus,
                      gpointer  user_data)
{
    g_debug ("Connection closed by ibus-daemon");
}

static void
_bus_connected_cb (IBusBus  *bus,
                   gpointer  user_data)
{
    g_debug ("Connected to ibus-daemon");
}

int
main (int    argc,
      char **argv)
{
    NSString *connection_name;
    NSString *bundle_id;
    NSBundle *bundle;
    IBusBus *bus;

    ibus_init ();
    g_set_prgname ("ibus-macos");
    ibus_macos_attach_glib_to_runloop ();

    bus = ibus_bus_new ();
    ibus_macos_set_bus (bus);
    g_signal_connect (bus, "disconnected",
                      G_CALLBACK (_bus_disconnected_cb), NULL);
    g_signal_connect (bus, "connected",
                      G_CALLBACK (_bus_connected_cb), NULL);

    @autoreleasepool {
        bundle = [NSBundle mainBundle];
        connection_name = [bundle objectForInfoDictionaryKey:
                           @"InputMethodConnectionName"];
        bundle_id = [bundle bundleIdentifier];
        if (connection_name == nil)
            connection_name = @"IBus_1_Connection";
        if (bundle_id == nil)
            bundle_id = @"org.freedesktop.IBus.inputmethod";

        _imk_server = [[IMKServer alloc] initWithName:connection_name
                                     bundleIdentifier:bundle_id];
        if (_imk_server == nil)
            g_warning ("Failed to create IMKServer; is this running as an "
                       "Input Method bundle?");

        [NSApplication sharedApplication];
        [[NSApplication sharedApplication] run];
    }

    ibus_macos_set_bus (NULL);
    g_object_unref (bus);
    return EXIT_SUCCESS;
}
