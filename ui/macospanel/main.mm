/* -*- mode: C; c-basic-offset: 4; indent-tabs-mode: nil; -*- */
/* vim:set et sts=4: */
/* ibus - The Input Bus
 * Copyright (C) 2020 Weixuan XIAO <veyx.shaw@gmail.com>
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

#include <ibus.h>

static IBusBus *_bus = NULL;

static void
_bus_disconnected_cb (IBusBus  *bus,
                      gpointer  user_data)
{
    g_debug ("Connection closed by ibus-daemon\n");
    g_printerr ("Connection closed by ibus-daemon\n");
    g_clear_object (&_bus);
    ibus_quit ();
}

int
main (int    argc,
      char **argv)
{
    if (_bus != NULL)
        return 0;

    ibus_init ();

    _bus = ibus_bus_new ();

    // On disconnect
    g_signal_connect (_bus, "disconnected",
                        G_CALLBACK (_bus_disconnected_cb), NULL);

    ibus_main ();

    return EXIT_SUCCESS;
}
