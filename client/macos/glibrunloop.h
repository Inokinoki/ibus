/* -*- mode: C; c-basic-offset: 4; indent-tabs-mode: nil; -*- */
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

#ifndef __IBUS_MACOS_GLIB_RUNLOOP_H_
#define __IBUS_MACOS_GLIB_RUNLOOP_H_

#include <glib.h>

G_BEGIN_DECLS

/**
 * ibus_macos_attach_glib_to_runloop:
 *
 * Pump the default #GMainContext from the Cocoa CFRunLoop so D-Bus
 * replies and IBus signals are dispatched on the UI thread.
 */
void ibus_macos_attach_glib_to_runloop (void);

G_END_DECLS

#endif
