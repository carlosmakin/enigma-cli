import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:enigma/enigma.dart' as enigma;
import 'package:path/path.dart' as path;

const String name = 'enigma-cli';
const String description = 'A simple command-line interface for encrypting and decrypting data.';

class KeygenCommand extends Command<String> {
  KeygenCommand() {
    argParser
      ..addOption('passphrase', abbr: 'p', mandatory: true, help: 'Passphrase seed.')
      ..addOption('salt', abbr: 's', defaultsTo: '', help: 'Cryptographic salt.')
      ..addOption('iterations', abbr: 'i', defaultsTo: '10000', help: 'Hash iterations.')
      ..addOption(
        'strength',
        abbr: 'S',
        defaultsTo: '256',
        allowed: <String>['128', '192', '256'],
        allowedHelp: <String, String>{
          '128': 'Offers a good balance of strong security and high performance.',
          '192': 'Provides enhanced security over AES-128, balancing security and performance',
          '256': 'Delivers the highest security level among standard AES keys.',
        },
        help: 'Encryption strength.',
      )
      ..addFlag('random', abbr: 'r', negatable: false, help: 'Generate random key.');
  }

  @override
  String get name => 'keygen';

  @override
  String get description => 'Generate an AES key from a passphrase or randomly.';

  @override
  String run() {
    final enigma.AESKeyStrength strength = <String, enigma.AESKeyStrength>{
      '128': enigma.AESKeyStrength.aes128,
      '192': enigma.AESKeyStrength.aes192,
      '256': enigma.AESKeyStrength.aes256,
    }[argResults!['strength']]!;

    if (argResults!['random']) return base64.encode(enigma.generateRandomKey(strength));

    return base64.encode(
      enigma.deriveKeyFromPassphrase(
        argResults!['passphrase'],
        salt: argResults!['salt'],
        iterations: int.tryParse(argResults!['iterations']) ?? 10000,
        strength: strength,
      ),
    );
  }
}

class EncryptTextCommand extends Command<String> {
  EncryptTextCommand() {
    argParser
      ..addOption('input', abbr: 'i', mandatory: true, help: 'Input text.')
      ..addOption('key', abbr: 'k', mandatory: true, help: 'Base64 AES key.');
  }

  @override
  String get name => 'encrypt-text';

  @override
  String get description => 'Encrypt text using a base64 AES key.';

  @override
  String run() => enigma.encryptTextWithEmbeddedIV(
        key: base64.decode(argResults!['key']),
        iv: enigma.generateRandomIV(),
        text: argResults!['input'],
      );
}

class DecryptTextCommand extends Command<String> {
  DecryptTextCommand() {
    argParser
      ..addOption('input', abbr: 'i', mandatory: true, help: 'Input cipher.')
      ..addOption('key', abbr: 'k', mandatory: true, help: 'Base64 AES key.');
  }

  @override
  String get name => 'decrypt-text';

  @override
  String get description => 'Decrypt text using a base64 AES key.';

  @override
  String run() => enigma.decryptTextWithEmbeddedIV(
        key: base64.decode(argResults!['key']),
        text: argResults!['input'],
      );
}

class EncryptFileCommand extends Command<String> {
  EncryptFileCommand() {
    argParser
      ..addOption('input', abbr: 'i', mandatory: true, help: 'Input file path.')
      ..addOption('key', abbr: 'k', mandatory: true, help: 'Base64 AES key.');
  }

  @override
  String get name => 'encrypt-file';

  @override
  String get description => 'Encrypt a file using a base64 AES key.';

  @override
  Future<String> run() async {
    final Uint8List key;

    try {
      key = base64.decode(argResults!['key']);
    } on FormatException {
      throw ArgumentError('Invalid base64 AES key encoding.');
    }

    if (!<int>[16, 24, 32].contains(key.length)) {
      throw ArgumentError('Invalid AES key length.');
    }

    final File inputFile = File(argResults!['input']);
    final File outputFile = File(
      path.join(path.dirname(inputFile.path), '${inputFile.path}.aes${key.length * 8}'),
    );

    final Stopwatch stopwatch = Stopwatch()..start();

    final Uint8List data = await inputFile.readAsBytes();
    final Uint8List output = await enigma.encryptBytesWithEmbeddedIVFast(
        key: key, iv: enigma.generateRandomIV(), data: data);
    await outputFile.writeAsBytes(output);

    return 'File encrypted in ${(stopwatch..stop()).elapsedMilliseconds} ms.';
  }
}

class DecryptFileCommand extends Command<String> {
  DecryptFileCommand() {
    argParser
      ..addOption('input', abbr: 'i', mandatory: true, help: 'Input file path.')
      ..addOption('key', abbr: 'k', mandatory: true, help: 'Base64 AES key.');
  }

  @override
  String get name => 'decrypt-file';

  @override
  String get description => 'Decrypt a file using a base64 AES key.';

  @override
  Future<String> run() async {
    final Uint8List key;

    try {
      key = base64.decode(argResults!['key']);
    } on FormatException {
      throw ArgumentError('Invalid base64 AES key encoding.');
    }

    if (!<int>[16, 24, 32].contains(key.length)) {
      throw ArgumentError('Invalid AES key length.');
    }

    final File inputFile = File(argResults!['input']);
    final String outputFileName = inputFile.path.replaceFirst('.aes${key.length * 8}', '');
    final File outputFile = File(
      path.join(path.dirname(inputFile.path), outputFileName),
    );

    final Stopwatch stopwatch = Stopwatch()..start();

    final Uint8List data = await inputFile.readAsBytes();
    final Uint8List decryptedBytes =
        await enigma.decryptBytesWithEmbeddedIVFast(key: key, data: data);
    await outputFile.writeAsBytes(decryptedBytes);

    return 'File decrypted in ${(stopwatch..stop()).elapsedMilliseconds} ms.';
  }
}
