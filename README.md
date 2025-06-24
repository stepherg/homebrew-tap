# stepherg/homebrew-tap

This is a Homebrew tap providing formulae for installing software maintained by [stepherg](https://github.com/stepherg). The tap currently includes the `rbus` formula, which installs the RDK-Bus (RBUS) messaging framework, a lightweight IPC framework for embedded systems.

## Installation

To use this tap, add it to your Homebrew installation with the following command:

```bash
brew tap stepherg/tap
```

This clones the repository from `https://github.com/stepherg/homebrew-tap` into `$(brew --repository)/Library/Taps/stepherg/homebrew-tap`. Once tapped, formulae in this repository are available for installation and will be updated automatically when you run `brew update`.

## Available Formulae

### rbus

**Description**: RDK-Bus (RBUS) is an IPC framework for communication between processes in embedded systems.

**Installation**:

```bash
brew install rbus
```

**Usage**:

- Start the `rtrouted` daemon as a background service:

  ```bash
  rtrouted-start
  ```

- Stop the service:

  ```bash
  rtrouted-stop
  ```

**Notes**:

## License

 Individual formulae may have their own licenses; for example, the `rbus` formula is licensed under the Apache-2.0 License.

## Contact

For issues or questions, please open an issue on the [GitHub repository](https://github.com/stepherg/homebrew-tap/issues) or contact [stepherg](https://github.com/stepherg).