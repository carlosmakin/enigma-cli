import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:enigma_cli/enigma_cli.dart';
import 'package:test/test.dart';
import 'package:enigma/enigma.dart';

void main() {
  final CommandRunner<String> runner = CommandRunner<String>(name, description);

  group('enigma-cli keygen command', () {
    final KeygenCommand command = KeygenCommand();
    runner.addCommand(command);

    test('generates random key', () async {
      for (final AESKeyStrength strength in AESKeyStrength.values) {
        final String? key = await runner.run(
          <String>['keygen', '-r', '-S', '${strength.numBits}'],
        );
        expect(base64.decode(key!).length, strength.numBytes);
      }
    });

    test('derives key from passphrase without salt', () async {
      for (final AESKeyStrength strength in AESKeyStrength.values) {
        final String? key = await runner.run(
          <String>['keygen', '-p', 'test', '-S', '${strength.numBits}', '-i', '1'],
        );
        expect(base64.decode(key!).length, strength.numBytes);
      }
    });

    test('derives key from passphrase with salt', () async {
      for (final AESKeyStrength strength in AESKeyStrength.values) {
        final String? key = await runner.run(
          <String>['keygen', '-p', 'test', '-s', 'salt', '-S', '${strength.numBits}', '-i', '1'],
        );
        expect(base64.decode(key!).length, strength.numBytes);
      }
    });
  });

  group('enigma-cli encrypt-text command', () {
    final EncryptTextCommand command = EncryptTextCommand();
    runner.addCommand(command);

    test('encrypts plaintext with a given key', () async {
      for (final AESKeyStrength strength in AESKeyStrength.values) {
        final String key = base64.encode(List<int>.generate(strength.numBytes, (int i) => i));
        final String? cipherText = await runner.run(
          <String>['encrypt-text', '-i', 'plaintext', '-k', key],
        );
        expect(cipherText, isNotNull);
      }
    });
  });

  group('enigma-cli decrypt-text command', () {
    final DecryptTextCommand command = DecryptTextCommand();
    runner.addCommand(command);

    test('decrypts ciphertext with a given key', () async {
      for (final AESKeyStrength strength in AESKeyStrength.values) {
        final Uint8List key =
            Uint8List.fromList(List<int>.generate(strength.numBytes, (int i) => i));
        final Uint8List iv = Uint8List.fromList(List<int>.generate(16, (int i) => i));
        final String base64Key = base64.encode(key);

        final String cipherText = encryptTextWithEmbeddedIV(key: key, iv: iv, text: 'plaintext');
        final String? plainText = await runner.run(
          <String>['decrypt-text', '-i', cipherText, '-k', base64Key],
        );
        expect(plainText, 'plaintext');
      }
    });
  });

  group('enigma-cli encrypt-file command', () {
    final EncryptFileCommand encryptCommand = EncryptFileCommand();
    runner.addCommand(encryptCommand);

    test('encrypts a file with a given key', () async {
      for (final AESKeyStrength strength in AESKeyStrength.values) {
        final String key = base64.encode(List<int>.generate(strength.numBytes, (int i) => i));
        final File inputFile = await File('input.txt').writeAsString('Input file content');

        final String? response = await runner.run(
          <String>['encrypt-file', '-i', inputFile.path, '-k', key],
        );
        expect(response, contains('File encrypted'));
        expect(File('${inputFile.path}.aes${strength.numBits}').existsSync(), isTrue);

        await inputFile.delete();
        await File('${inputFile.path}.aes${strength.numBits}').delete();
      }
    });
  });

  group('enigma-cli decrypt-file command', () {
    final DecryptFileCommand decryptCommand = DecryptFileCommand();
    runner.addCommand(decryptCommand);

    test('decrypts a file with a given key', () async {
      for (final AESKeyStrength strength in AESKeyStrength.values) {
        final String key = base64.encode(List<int>.generate(strength.numBytes, (int i) => i));
        final File inputFile = await File('input.txt').writeAsString('Input file content');

        String? response = await runner.run(
          <String>['encrypt-file', '-i', inputFile.path, '-k', key],
        );
        expect(response, contains('File encrypted'));

        await inputFile.delete();
        expect(File('input.txt').existsSync(), isFalse);

        expect(File('${inputFile.path}.aes${strength.numBits}').existsSync(), isTrue);
        final File outputFile = File('input.txt.aes${strength.numBits}');

        response = await runner.run(
          <String>['decrypt-file', '-i', outputFile.path, '-k', key],
        );

        expect(response, contains('File decrypted'));
        expect(File('input.txt').existsSync(), isTrue);
        expect(await File('input.txt').readAsString(), 'Input file content');

        await outputFile.delete();
        await File('input.txt').delete();
      }
    });
  });
}
