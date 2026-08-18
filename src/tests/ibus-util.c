/* -*- mode: C; c-basic-offset: 4; indent-tabs-mode: nil; -*- */

#include <locale.h>

#include "ibus.h"

static void
test (void)
{
    gchar *name;
    g_assert_cmpstr (name = ibus_get_language_name ("eng"), ==, "English");
    g_free (name);
}

int
main (int argc, char *argv[])
{
    g_test_init (&argc, &argv, NULL);
    setlocale(LC_ALL, "C");
    g_test_add_func ("/ibus-util", test);
    return g_test_run ();
}
