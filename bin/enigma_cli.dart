import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:enigma_cli/enigma_cli.dart';

void main(List<String> args) async {
  final CommandRunner<String> runner = CommandRunner<String>(name, description);

  runner.addCommand(KeygenCommand());
  runner.addCommand(EncryptTextCommand());
  runner.addCommand(DecryptTextCommand());
  runner.addCommand(EncryptFileCommand());
  runner.addCommand(DecryptFileCommand());

  try {
    stdout.writeln(await runner.run(args) ?? '');
  } catch (e) {
    stdout.write('$e');
  }
}
