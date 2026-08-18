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

#ifndef __IBUS_MACOS_PANEL_H_
#define __IBUS_MACOS_PANEL_H_

#include <ibus.h>

G_BEGIN_DECLS

#define IBUS_TYPE_MACOS_PANEL (ibus_macos_panel_get_type ())
#define IBUS_MACOS_PANEL(obj) \
    (G_TYPE_CHECK_INSTANCE_CAST ((obj), IBUS_TYPE_MACOS_PANEL, IBusMacOSPanel))
#define IBUS_MACOS_PANEL_CLASS(klass) \
    (G_TYPE_CHECK_CLASS_CAST ((klass), IBUS_TYPE_MACOS_PANEL, IBusMacOSPanelClass))
#define IBUS_IS_MACOS_PANEL(obj) \
    (G_TYPE_CHECK_INSTANCE_TYPE ((obj), IBUS_TYPE_MACOS_PANEL))

typedef struct _IBusMacOSPanel IBusMacOSPanel;
typedef struct _IBusMacOSPanelClass IBusMacOSPanelClass;

struct _IBusMacOSPanel {
    IBusPanelService parent;
};

struct _IBusMacOSPanelClass {
    IBusPanelServiceClass parent_class;
};

GType            ibus_macos_panel_get_type (void);
IBusMacOSPanel  *ibus_macos_panel_new      (GDBusConnection *connection);

G_END_DECLS

#endif
