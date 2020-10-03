
#include <ibus.h>

static IBusBus *_bus = NULL;

int
main (int    argc,
      char **argv)
{
    ibus_init ();

    _bus = ibus_bus_new ();
    if (!ibus_bus_is_connected (_bus)) {
        g_printerr ("Cannot connect to ibus-daemon\n");
        return EXIT_FAILURE;
    }
    ibus_main ();

    return EXIT_SUCCESS;
}
