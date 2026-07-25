#include <errno.h>
#include <fcntl.h>
#include <launch.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int activated_socket(const char *name) {
  int *fds = NULL;
  size_t count = 0;
  int error = launch_activate_socket(name, &fds, &count);

  if (error != 0) {
    fprintf(stderr, "launch_activate_socket(%s): %s\n", name, strerror(error));
    exit(EXIT_FAILURE);
  }
  if (count != 1) {
    fprintf(stderr, "launch_activate_socket(%s): expected 1 socket, got %zu\n", name, count);
    free(fds);
    exit(EXIT_FAILURE);
  }

  int fd = fds[0];
  free(fds);
  return fd;
}

static int preserve_socket(int fd) {
  int preserved = fcntl(fd, F_DUPFD_CLOEXEC, 10);
  if (preserved == -1) {
    fprintf(stderr, "fcntl(F_DUPFD_CLOEXEC): %s\n", strerror(errno));
    exit(EXIT_FAILURE);
  }
  return preserved;
}

static void move_socket(int source, int destination) {
  if (dup2(source, destination) == -1) {
    fprintf(stderr, "dup2(%d, %d): %s\n", source, destination, strerror(errno));
    exit(EXIT_FAILURE);
  }
  close(source);
}

int main(int argc, char *argv[]) {
  if (argc < 2) {
    fprintf(stderr, "usage: caddy-launcher PROGRAM [ARG ...]\n");
    return EXIT_FAILURE;
  }

  int ipv4 = preserve_socket(activated_socket("HTTPSIPv4"));
  int ipv6 = preserve_socket(activated_socket("HTTPSIPv6"));

  move_socket(ipv4, 3);
  move_socket(ipv6, 4);

  execv(argv[1], &argv[1]);
  fprintf(stderr, "execv(%s): %s\n", argv[1], strerror(errno));
  return EXIT_FAILURE;
}
