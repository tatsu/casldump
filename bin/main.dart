import 'dart:io';
import 'dart:mirrors';
import 'dart:typed_data';

import 'package:casldump/casldump.dart';

void main(List<String> arguments) async {
  if (arguments.length != 1) {
    print('Usage: casldump filename');
    return;
  }

  var bytes = await new File(arguments[0]).readAsBytesSync();
  Uint16List words = new Uint16List.view((bytes as Uint8List).buffer);

  bool isContinued = false;
  bool isReturned = false;
  int offset = 0;
  int prevWord;
  Operation operation;
  stdout.write('MAIN  START\n');
  for (final word in words) {
    if (isContinued) {
      operation.parse(operation, offset - 1, prevWord, word);
      isContinued = false;
    } else {
      int op = word >> 8;
      operation = operations[op];
      if ((operation == null || operation.mnemonic == #NOP) && isReturned) {
        operation = dcOperation;
      }
      if (operation != null) {
        if (operation.mnemonic == #RET) {
          isReturned = true;
        }
        if (operation.size != 1) {
          prevWord = word;
          isContinued = true;
        } else {
          operation.parse(operation, offset, word);
        }
      } else {
        print('${offset.toRadixString(16).padLeft(4, '0')} ${word.toRadixString(
            16).padLeft(4, '0')}');
      }
    }
    ++offset;
  }
  stdout.write('      END\n');
}
