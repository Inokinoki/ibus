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

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include "panel.h"
#include "candidatewindow.h"

G_DEFINE_TYPE (IBusMacOSPanel, ibus_macos_panel, IBUS_TYPE_PANEL_SERVICE)

static void
candidate_clicked_cb (guint    index,
                      gpointer user_data)
{
    ibus_panel_service_candidate_clicked (IBUS_PANEL_SERVICE (user_data),
                                          index, 1, 0);
}

static void
ibus_macos_panel_set_cursor_location (IBusPanelService *panel,
                                      gint              x,
                                      gint              y,
                                      gint              w,
                                      gint              h)
{
    macos_candidate_window_set_cursor_location (x, y, w, h);
}

static void
ibus_macos_panel_update_preedit_text (IBusPanelService *panel,
                                      IBusText         *text,
                                      guint             cursor_pos,
                                      gboolean          visible)
{
    macos_candidate_window_update_preedit (text, cursor_pos, visible);
}

static void
ibus_macos_panel_hide_preedit_text (IBusPanelService *panel)
{
    macos_candidate_window_update_preedit (NULL, 0, FALSE);
}

static void
ibus_macos_panel_update_auxiliary_text (IBusPanelService *panel,
                                        IBusText         *text,
                                        gboolean          visible)
{
    macos_candidate_window_update_auxiliary (text, visible);
}

static void
ibus_macos_panel_hide_auxiliary_text (IBusPanelService *panel)
{
    macos_candidate_window_update_auxiliary (NULL, FALSE);
}

static void
ibus_macos_panel_update_lookup_table (IBusPanelService *panel,
                                      IBusLookupTable  *table,
                                      gboolean          visible)
{
    macos_candidate_window_update_lookup_table (table, visible);
}

static void
ibus_macos_panel_hide_lookup_table (IBusPanelService *panel)
{
    macos_candidate_window_hide ();
}

static void
ibus_macos_panel_show_lookup_table (IBusPanelService *panel)
{
}

static void
ibus_macos_panel_reset (IBusPanelService *panel)
{
    macos_candidate_window_hide ();
}

static void
ibus_macos_panel_focus_out (IBusPanelService *panel,
                            const gchar      *input_context_path)
{
    macos_candidate_window_hide ();
}

static void
ibus_macos_panel_class_init (IBusMacOSPanelClass *class)
{
    IBusPanelServiceClass *panel_class = IBUS_PANEL_SERVICE_CLASS (class);

    panel_class->set_cursor_location = ibus_macos_panel_set_cursor_location;
    panel_class->update_preedit_text = ibus_macos_panel_update_preedit_text;
    panel_class->hide_preedit_text = ibus_macos_panel_hide_preedit_text;
    panel_class->update_auxiliary_text = ibus_macos_panel_update_auxiliary_text;
    panel_class->hide_auxiliary_text = ibus_macos_panel_hide_auxiliary_text;
    panel_class->update_lookup_table = ibus_macos_panel_update_lookup_table;
    panel_class->hide_lookup_table = ibus_macos_panel_hide_lookup_table;
    panel_class->show_lookup_table = ibus_macos_panel_show_lookup_table;
    panel_class->reset = ibus_macos_panel_reset;
    panel_class->focus_out = ibus_macos_panel_focus_out;
}

static void
ibus_macos_panel_init (IBusMacOSPanel *panel)
{
    macos_candidate_window_init ();
    macos_candidate_window_set_click_cb (candidate_clicked_cb, panel);
}

IBusMacOSPanel *
ibus_macos_panel_new (GDBusConnection *connection)
{
    g_return_val_if_fail (G_IS_DBUS_CONNECTION (connection), NULL);

    return g_object_new (IBUS_TYPE_MACOS_PANEL,
                         "object-path", IBUS_PATH_PANEL,
                         "connection", connection,
                         NULL);
}
