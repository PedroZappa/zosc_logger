/**
 * @defgroup zosc_logger OSC Logger
 * @brief OSC Logger Application
 * @details This application is a simple logger for OSC messages.
 * @{
 */

#include "../inc/zosc_logger.hpp"
#include "../lib/zosc/inc/Zosc.hpp"

#ifdef __linux__
#include <asm-generic/socket.h>
#elif defined(__APPLE__)
#include <sys/socket.h> // macOS-specific headers
#endif

#include <sys/select.h>
#include <sys/socket.h>

#define VERSION "0.0.1"
#define NAME "osc_logger"
#define BUF_SIZE 2048
#define MAX_PORTS 65535
#define PORT 9000

// Volatile allows for external modification
static volatile bool _listening = true;

static void SIGINT_handler(int sig);

int main(int argc, char **argv) {
	int port = PORT;

	// Greet me baby one more time!
	printf(BGRN "%s " NC "%s\n", NAME, VERSION);

	// Process Port parameter
	try {
		if (argc > 1) { // Process Port
			std::cout << "Setting port to: " BYEL << argv[1] << NC << std::endl;

			long portLong = strtol(argv[1], nullptr, 10);
			char *endptr = nullptr;
			// Check if port is a valid int
			if (argv[1] == endptr) // if empty
				throw std::runtime_error("Invalid port: not an int");
			// Check if port is within valid range
			if ((portLong < 0) || (portLong > MAX_PORTS))
				throw std::runtime_error("Invalid port: out of range");
			// Warn about reserved ranges
			if (portLong < 1024)
				printf("Warning: Port %ld is within a reserved range "
					   "(0-1023)\n",
					   portLong);
			port = static_cast<int>(portLong);
		} else if (argc > 2) {
			throw std::runtime_error("Too many arguments");
		} else // Use default port
			printf("Using default port: %d\n", port);

		std::cout << "listening on Port: " BGRN << port << NC << std::endl;
	} catch (std::exception &e) { // Handle Error
		fprintf(stderr, "Error: " RED "%s\n" NC, e.what());
		return (EXIT_FAILURE);
	}

	// SIGINT handler
	signal(SIGINT, &SIGINT_handler);

	// Setup UDP Listeing
	ZoscReceiver receiver(port);
	receiver.setMessageCallback([](const ZoscMessage &message) {
		printf("Got msg from :" YEL " %s\n" NC, message.getAddress().c_str());
	});
	while (_listening) {
		receiver.start();
	}
	receiver.stop();
	printf("Closing " BGRN "%s " NC "%s\n", NAME, VERSION);

	return (EXIT_SUCCESS);
}

/// @brief SIGINT handler
/// @param sig Signal number
static void SIGINT_handler(int sig) {
	(void)sig;
	_listening = false;
}

/** @} */
