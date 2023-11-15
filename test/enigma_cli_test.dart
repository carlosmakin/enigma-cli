import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:enigma_cli/enigma_cli.dart';
import 'package:test/test.dart';
import 'package:enigma/enigma.dart' as enigma;

void main() {
  final CommandRunner<String> runner = CommandRunner<String>(name, description);

  group('enigma-cli keygen command', () {
    final KeygenCommand command = KeygenCommand();
    runner.addCommand(command);

    test('generates random key', () async {
      final String? aes128Key = await runner.run(
        <String>['keygen', '-r', '-e', '128'],
      );
      expect(base64.decode(aes128Key!).length, 16);

      final String? aes192Key = await runner.run(
        <String>['keygen', '-r', '-e', '192'],
      );
      expect(base64.decode(aes192Key!).length, 24);

      final String? aes256Key = await runner.run(
        <String>['keygen', '-r', '-e', '256'],
      );
      expect(base64.decode(aes256Key!).length, 32);
    });

    test('derives key from passphrase without salt', () async {
      final String? aes128Key = await runner.run(
        <String>['keygen', '-p', 'test', '-e', '128', '-i', '1'],
      );
      expect(base64.decode(aes128Key!).length, 16);

      final String? aes192Key = await runner.run(
        <String>['keygen', '-p', 'test', '-e', '192', '-i', '1'],
      );
      expect(base64.decode(aes192Key!).length, 24);

      final String? aes256Key = await runner.run(
        <String>['keygen', '-p', 'test', '-e', '256', '-i', '1'],
      );
      expect(base64.decode(aes256Key!).length, 32);
    });

    test('derives key from passphrase with salt', () async {
      final String? aes128Key = await runner.run(
        <String>['keygen', '-p', 'test', '-s', 'salt', '-e', '128', '-i', '1'],
      );
      expect(base64.decode(aes128Key!).length, 16);

      final String? aes192Key = await runner.run(
        <String>['keygen', '-p', 'test', '-s', 'salt', '-e', '192', '-i', '1'],
      );
      expect(base64.decode(aes192Key!).length, 24);

      final String? aes256Key = await runner.run(
        <String>['keygen', '-p', 'test', '-s', 'salt', '-e', '256', '-i', '1'],
      );
      expect(base64.decode(aes256Key!).length, 32);
    });
  });

  group('enigma-cli encrypt-text command', () {
    final EncryptTextCommand command = EncryptTextCommand();
    runner.addCommand(command);

    test('encrypts plaintext with a given key', () async {
      final String key = base64.encode(List<int>.filled(32, 0));
      final String? cipherText = await runner.run(
        <String>['encrypt-text', '-i', 'plaintext', '-k', key],
      );
      expect(cipherText, isNotNull);
    });
  });

  group('enigma-cli decrypt-text command', () {
    final DecryptTextCommand command = DecryptTextCommand();
    runner.addCommand(command);

    test('decrypts ciphertext with a given key', () async {
      final Uint8List key = Uint8List.fromList(List<int>.filled(32, 0));
      final Uint8List iv = Uint8List.fromList(List<int>.filled(16, 0));
      final String base64Key = base64.encode(key);

      final String encryptedData = enigma.encryptText(key: key, iv: iv, text: 'plaintext');
      final String? decryptedText = await runner.run(
        <String>['decrypt-text', '-i', encryptedData, '-k', base64Key],
      );
      expect(decryptedText, 'plaintext');
    });
  });

  group('enigma-cli encrypt-file command', () {
    final EncryptFileCommand encryptCommand = EncryptFileCommand();
    runner.addCommand(encryptCommand);

    test('encrypts a file with a given key', () async {
      final String key = base64.encode(List<int>.filled(32, 0));
      final File inputFile = await File('input.txt').writeAsString('Input file content');

      final String? response = await runner.run(
        <String>['encrypt-file', '-i', inputFile.path, '-k', key],
      );
      expect(response, contains('File encrypted'));
      expect(File('${inputFile.path}.aes256').existsSync(), isTrue);

      await inputFile.delete();
      await File('${inputFile.path}.aes256').delete();
    });
  });

  group('enigma-cli decrypt-file command', () {
    final DecryptFileCommand decryptCommand = DecryptFileCommand();
    runner.addCommand(decryptCommand);

    test('decrypts a file with a given key', () async {
      final String key = base64.encode(List<int>.filled(32, 0));
      final File inputFile = await File('input.txt').writeAsString('Input file content');

      String? response = await runner.run(
        <String>['encrypt-file', '-i', inputFile.path, '-k', key],
      );
      expect(response, contains('File encrypted'));

      await inputFile.delete();
      expect(File('input.txt').existsSync(), isFalse);

      expect(File('${inputFile.path}.aes256').existsSync(), isTrue);
      final File outputFile = File('input.txt.aes256');

      response = await runner.run(
        <String>['decrypt-file', '-i', outputFile.path, '-k', key],
      );

      expect(response, contains('File decrypted'));
      expect(File('input.txt').existsSync(), isTrue);
      expect(await File('input.txt').readAsString(), 'Input file content');

      await outputFile.delete();
      await File('input.txt').delete();
    });
  });
}
