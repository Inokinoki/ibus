#include <ibus.h>

static void
test (void)
{
    IBusRegistry *registry = ibus_registry_new ();
    g_object_unref (registry);
}

int
main(int argc, char *argv[])
{
    g_test_init (&argc, &argv, NULL);
    ibus_init ();
    g_test_add_func ("/ibus-registry", test);
    return g_test_run ();
}
