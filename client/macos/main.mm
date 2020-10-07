
#include <ibus.h>

static IBusBus *_bus = NULL;

typedef struct _MACOS_ICONN    MACOS_ICONN;
struct _MACOS_ICONN {
    GList        *clients;
};

typedef struct _MACOS_IC    MACOS_IC;
struct _MACOS_IC {
    IBusInputContext *context;
    gint32           input_style;
    MACOS_ICONN        *conn;
    gint             icid;
    gint             connect_id;
    gchar           *lang;
    gboolean         has_preedit_area;
    // GdkRectangle     preedit_area;

    gchar           *preedit_string;
    IBusAttrList    *preedit_attrs;
    gint             preedit_cursor;
    gboolean         preedit_visible;
    gboolean         preedit_started;
    gint             onspot_preedit_length;
};

static void
_context_update_preedit_text_cb (IBusInputContext *context,
                                 IBusText         *text,
                                 gint              cursor_pos,
                                 gboolean          visible,
                                 MACOS_IC            *macosic)
{
    g_assert (macosic);

    g_printerr ("Update Preedit \"%s\" Length: %d\n", text->text, strlen (text->text));
}

static void
_context_show_preedit_text_cb (IBusInputContext *context,
                               MACOS_IC            *macosic)
{
    g_assert (macosic);

    g_printerr ("Preedit shown\n");
}

static void
_context_hide_preedit_text_cb (IBusInputContext *context,
                               MACOS_IC            *macosic)
{
    g_assert (macosic);

    g_printerr ("Preedit hidden\n");
}

static void
_context_commit_text_cb (IBusInputContext *context,
                         IBusText         *text,
                         MACOS_IC            *macosic)
{
    g_assert (macosic);

    g_printerr ("Text Committed\n");
}

static void
_context_forward_key_event_cb (IBusInputContext *context,
                               guint             keyval,
                               guint             keycode,
                               guint             state,
                               MACOS_IC            *macosic)
{
    g_assert (macosic);

    g_printerr ("Event %ud %ud %ud\n", keyval, keycode, state);
}

static void
_context_enabled_cb (IBusInputContext *context,
                    MACOS_IC            *macosic)
{
    g_assert (IBUS_IS_INPUT_CONTEXT (context));
    g_assert (macosic);

    g_printerr ("Enabled\n");
}

static void
_context_disabled_cb (IBusInputContext *context,
                    MACOS_IC            *macosic)
{
    g_assert (IBUS_IS_INPUT_CONTEXT (context));
    g_assert (macosic);

    g_printerr ("Disabled\n");
}

static void
_bus_disconnected_cb (IBusBus  *bus,
                      gpointer  user_data)
{
    g_debug ("Connection closed by ibus-daemon\n");
    g_printerr ("Connection closed by ibus-daemon\n");
    g_clear_object (&_bus);
    ibus_quit ();
}

static void
_macos_init_ibus (void)
{
    if (_bus != NULL)
        return;

    ibus_init ();

    _bus = ibus_bus_new ();

    // On disconnect
    g_signal_connect (_bus, "disconnected",
                        G_CALLBACK (_bus_disconnected_cb), NULL);
}

static void
_macos_init_IMKit ()
{
    _macos_init_ibus ();

    MACOS_IC *macosic;
    macosic = g_slice_new0 (MACOS_IC);

    macosic->context = ibus_bus_create_input_context (_bus, "macos");

    if (macosic->context == NULL) {
        g_slice_free (MACOS_IC, macosic);
        return;
    }

    g_signal_connect (macosic->context, "commit-text",
                        G_CALLBACK (_context_commit_text_cb), macosic);
    g_signal_connect (macosic->context, "forward-key-event",
                        G_CALLBACK (_context_forward_key_event_cb), macosic);

    g_signal_connect (macosic->context, "update-preedit-text",
                        G_CALLBACK (_context_update_preedit_text_cb), macosic);
    g_signal_connect (macosic->context, "show-preedit-text",
                        G_CALLBACK (_context_show_preedit_text_cb), macosic);
    g_signal_connect (macosic->context, "hide-preedit-text",
                        G_CALLBACK (_context_hide_preedit_text_cb), macosic);

    g_signal_connect (macosic->context, "enabled",
                        G_CALLBACK (_context_enabled_cb), macosic);
    g_signal_connect (macosic->context, "disabled",
                        G_CALLBACK (_context_disabled_cb), macosic);

    ibus_input_context_set_capabilities (macosic->context, IBUS_CAP_FOCUS | IBUS_CAP_PREEDIT_TEXT);

    int retval = ibus_input_context_process_key_event (
                                      macosic->context,
                                      IBUS_KEY_A,
                                      0x1E,     // ? A
                                      0);
    if (retval) {
        g_printerr ("Send event error\n");
        return;
    } else {
        g_printerr ("Send event ok\n");
    }
}

int
main (int    argc,
      char **argv)
{
    _macos_init_IMKit ();
    ibus_main ();

    return EXIT_SUCCESS;
}
