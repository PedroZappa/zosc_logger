#include "../inc/zosc_logger.hpp"
#include "../lib/zosc/inc/Zosc.hpp"

#define VERSION "0.0.1"
#define NAME "osc_logger"
#define BUF_SIZE 2048
#define MAX_PORTS 65535
#define PORT 9000

int main(int argc, char **argv) {
	char buf[BUF_SIZE]; // Buffer to read packet data
	int port = PORT;

	(void)buf;
	(void)argc;
	(void)argv;
	std::cout << BGRN << NAME << " " NC << VERSION << std::endl;
	ZoscReceiver receiver(port);
	return (EXIT_SUCCESS);
}
