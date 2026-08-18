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

#import "candidatewindow.h"
#import "glibrunloop.h"
#import "panel.h"

#import <AppKit/AppKit.h>
#import <ibus.h>

static IBusBus *_bus = NULL;
static IBusMacOSPanel *_panel = NULL;

static void
create_panel (void)
{
    GDBusConnection *connection;
    guint32 flags;

    if (_panel != NULL || _bus == NULL)
        return;
    if (!ibus_bus_is_connected (_bus))
        return;

    connection = ibus_bus_get_connection (_bus);
    if (connection == NULL)
        return;

    flags = IBUS_BUS_NAME_FLAG_ALLOW_REPLACEMENT |
            IBUS_BUS_NAME_FLAG_REPLACE_EXISTING;
    ibus_bus_request_name (_bus, IBUS_SERVICE_PANEL, flags);
    _panel = ibus_macos_panel_new (connection);
}

static void
_bus_disconnected_cb (IBusBus  *bus,
                      gpointer  user_data)
{
    g_debug ("Connection closed by ibus-daemon");
    if (_panel != NULL) {
        g_object_unref (_panel);
        _panel = NULL;
    }
    g_clear_object (&_bus);
    [NSApp terminate:nil];
}

static void
_bus_connected_cb (IBusBus  *bus,
                   gpointer  user_data)
{
    create_panel ();
}

int
main (int    argc,
      char **argv)
{
    ibus_init ();
    g_set_prgname ("ibus-ui-macos");
    ibus_macos_attach_glib_to_runloop ();

    macos_candidate_window_init ();

    _bus = ibus_bus_new ();
    g_signal_connect (_bus, "disconnected",
                      G_CALLBACK (_bus_disconnected_cb), NULL);
    g_signal_connect (_bus, "connected",
                      G_CALLBACK (_bus_connected_cb), NULL);
    if (ibus_bus_is_connected (_bus))
        create_panel ();

    @autoreleasepool {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [NSApp run];
    }

    if (_panel != NULL)
        g_object_unref (_panel);
    g_clear_object (&_bus);
    return EXIT_SUCCESS;
}
