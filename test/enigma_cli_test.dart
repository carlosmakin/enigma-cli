import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:enigma_cli/enigma_cli.dart';
import 'package:test/test.dart';
import 'package:enigma/enigma.dart';

void main() {
  final CommandRunner<String> runner = CommandRunner<String>(name, description)
    ..addCommand(KeygenCommand())
    ..addCommand(EncryptTextCommand())
    ..addCommand(DecryptTextCommand())
    ..addCommand(EncryptFileCommand())
    ..addCommand(DecryptFileCommand());

  for (final AESKeyStrength strength in AESKeyStrength.values) {
    final int bitStrength = strength.numBits;
    final int byteStrength = strength.numBytes;
    final String base64Key = base64.encode(List<int>.generate(byteStrength, (int i) => i));

    group('enigma-cli keygen command', () {
      test('generates random $bitStrength-bit key', () async {
        final String? response = await runner.run(
          <String>['keygen', '-r', '-S', '$bitStrength'],
        );
        expect(response, isNotNull);
        expect(base64.decode(response!).length, byteStrength);
      });

      test('derives $bitStrength-bit key from passphrase with salt', () async {
        final String? response = await runner.run(
          <String>['keygen', '-p', 'test', '-s', 'salt', '-S', '$bitStrength', '-i', '1'],
        );
        expect(response, isNotNull);
        expect(base64.decode(response!).length, byteStrength);
      });

      test('derives $bitStrength-bit key from passphrase without salt', () async {
        final String? response = await runner.run(
          <String>['keygen', '-p', 'test', '-S', '$bitStrength', '-i', '1'],
        );
        expect(response, isNotNull);
        expect(base64.decode(response!).length, byteStrength);
      });
    });

    group('enigma-cli encrypt-text command', () {
      test('encrypts plaintext with a given $bitStrength-bit key', () async {
        final String? response = await runner.run(
          <String>['encrypt-text', '-i', 'plaintext', '-k', base64Key],
        );
        expect(response, isNotNull);
      });
    });

    group('enigma-cli decrypt-text command', () {
      test('decrypts ciphertext with a given $bitStrength-bit key', () async {
        final Uint8List key = base64.decode(base64Key);
        final Uint8List iv = Uint8List.fromList(List<int>.generate(16, (int i) => i));

        final String cipherText = encryptTextWithEmbeddedIV(key: key, iv: iv, text: 'plaintext');
        final String? response = await runner.run(
          <String>['decrypt-text', '-i', cipherText, '-k', base64Key],
        );
        expect(response, 'plaintext');
      });
    });

    group('enigma-cli encrypt-file command', () {
      test('encrypts file with a given $bitStrength-bit key', () async {
        final File inputFile = await File('input.txt').writeAsString('Input file content');

        final String? response = await runner.run(
          <String>['encrypt-file', '-i', inputFile.path, '-k', base64Key],
        );
        expect(response, contains('File encrypted'));
        expect(File('${inputFile.path}.aes$bitStrength').existsSync(), isTrue);

        await inputFile.delete();
        await File('${inputFile.path}.aes$bitStrength').delete();
      });
    });

    group('enigma-cli decrypt-file command', () {
      test('decrypts file with a given $bitStrength-bit key', () async {
        final File inputFile = await File('input.txt').writeAsString('Input file content');

        String? response = await runner.run(
          <String>['encrypt-file', '-i', inputFile.path, '-k', base64Key],
        );
        expect(response, contains('File encrypted'));

        await inputFile.delete();
        expect(File('input.txt').existsSync(), isFalse);

        expect(File('${inputFile.path}.aes$bitStrength').existsSync(), isTrue);
        final File outputFile = File('input.txt.aes$bitStrength');

        response = await runner.run(
          <String>['decrypt-file', '-i', outputFile.path, '-k', base64Key],
        );

        expect(response, contains('File decrypted'));
        expect(File('input.txt').existsSync(), isTrue);
        expect(await File('input.txt').readAsString(), 'Input file content');

        await outputFile.delete();
        await File('input.txt').delete();
      });
    });
  }
}
