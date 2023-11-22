# Enigma Command-Line Interface

A command-line interface for encrypting and decrypting data.

## Installation

1. Clone or download the repository.
2. Navigate to the directory containing the source code.

For users who want to run the tool directly using the compiled `.exe` file:

- Run `enigma_cli.exe` from the command line.

For users who wish to run the Dart source code:

1. Ensure Dart SDK is installed.
2. Run `dart pub get` to fetch dependencies.

## Usage

### Generate Key

Generate an AES key from a passphrase or randomly.

- Using the compiled `.exe`:
  ```
  enigma_cli.exe keygen --passphrase <PASSPHRASE> [--salt <SALT>] [--iterations <COUNT>] [--strength <128|192|256>] [--random]
  ```

- Using Dart source:
  ```
  dart enigma_cli.dart keygen --passphrase <PASSPHRASE> [--salt <SALT>] [--iterations <COUNT>] [--strength <128|192|256>] [--random]
  ```

Options:
- `--passphrase, -p`: The passphrase seed for key derivation. Mandatory unless `--random` is used.
- `--salt, -s`: Optional cryptographic salt. This option is ignored if `--random` flag is used.
- `--iterations, -i`: Number of hash iterations for key derivation. Default is 10000.
- `--strength, -S`: Encryption strength (key length in bits: 128, 192, or 256). Default is 256.
- `--random, -r`: Generate a random key. If used, passphrase and salt options are ignored.

### Encrypt Text

Encrypt text using a Base64 AES key.

- Using the compiled `.exe`:
  ```
  enigma_cli.exe encrypt-text --input <TEXT> --key <KEY>
  ```

- Using Dart source:
  ```
  dart enigma_cli.dart encrypt-text --input <TEXT> --key <KEY>
  ```

Options:
- `--input, -i`: Input text to encrypt.
- `--key, -k`: Base64 encoded AES key.

### Decrypt Text

Decrypt text using a Base64 AES key.

- Using the compiled `.exe`:
  ```
  enigma_cli.exe decrypt-text --input <CIPHER_TEXT> --key <KEY>
  ```

- Using Dart source:
  ```
  dart enigma_cli.dart decrypt-text --input <CIPHER_TEXT> --key <KEY>
  ```

Options:
- `--input, -i`: Encrypted text to decrypt.
- `--key, -k`: Base64 encoded AES key.

### Encrypt File

Encrypt a file using a Base64 AES key.

- Using the compiled `.exe`:
  ```
  enigma_cli.exe encrypt-file --input <FILE_PATH> --key <KEY>
  ```

- Using Dart source:
  ```
  dart enigma_cli.dart encrypt-file --input <FILE_PATH> --key <KEY>
  ```

Options:
- `--input, -i`: Input file path to encrypt.
- `--key, -k`: Base64 encoded AES key.

### Decrypt File

Decrypt a file using a Base64 AES key.

- Using the compiled `.exe`:
  ```
  enigma_cli.exe decrypt-file --input <ENCRYPTED_FILE_PATH> --key <KEY>
  ```

- Using Dart source:
  ```
  dart enigma_cli.dart decrypt-file --input <ENCRYPTED_FILE_PATH> --key <KEY>
  ```

Options:
- `--input, -i`: Input encrypted file path to decrypt.
- `--key, -k`: Base64 encoded AES key.

## Error Handling

The tool provides descriptive error messages for any issues with commands or arguments.

## Dependencies

- [`args`](https://pub.dev/packages/args) - For parsing command-line arguments.
- [`enigma`](https://github.com/carlosmakin/enigma.git) - For simplified cryptographic operations.

## Contributing

Contributions are welcome. For major changes, please open an issue first to discuss what you would like to change.
