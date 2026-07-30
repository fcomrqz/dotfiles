#include <ApplicationServices/ApplicationServices.h>
#include <errno.h>
#include <stdlib.h>

static int parse_coordinate(const char *value, double *coordinate)
{
    char *end = NULL;

    errno = 0;
    *coordinate = strtod(value, &end);
    return errno == 0 && end != value && *end == '\0';
}

int main(int argc, char **argv)
{
    double x;
    double y;

    if (argc != 3 ||
        !parse_coordinate(argv[1], &x) ||
        !parse_coordinate(argv[2], &y)) {
        return 64;
    }

    return CGWarpMouseCursorPosition(CGPointMake(x, y)) == kCGErrorSuccess
               ? 0
               : 1;
}
