# OSC Logger (zosc_logger)

## Overview
`zosc_logger` is a simple and efficient application in C++ for logging Open Sound Control (OSC) messages. Built using the `zosc` library, it facilitates easy monitoring of OSC traffic over UDP.

## Features
- Logs incoming OSC messages from a specified UDP port.
- Customizable port selection with warnings for reserved ranges.
- Handles SIGINT (Ctrl+C) for graceful shutdown.

## Requirements
- C++17 or later
- [zosc](https://github.com/PedroZappa/zosc) library
- A system with signal handling capabilities (e.g., Linux, macOS, or Windows Subsystem for Linux)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/zosc_logger.git
   cd zosc_logger
   ```

2. Build the application:
   ```bash
   make
   ```

3. Run the application:
   ```bash
   ./zosc_logger [PORT]
   ```

## Usage

- To start the logger with the default port (9000):
  ```bash
  ./zosc_logger
  ```

- To specify a custom port:
  ```bash
  ./zosc_logger 12345
  ```

  **Note:** Ports below 1024 are reserved and may require administrative privileges.

## Example Output

```
osc_logger 1.0.0
Using default port: 9000
listening on Port: 9000
Got msg from : /example/address
Got msg from : /another/address
Closing osc_logger 1.0.0
```

## Signals
- **SIGINT (Ctrl+C):** Stops the logger gracefully.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing
Contributions are welcome! Please submit issues or pull requests to improve the application.

## Acknowledgments
- Built using the ZOSC library for Open Sound Control.
- Inspired by the need for simple and effective OSC monitoring tools.
