import 'dart:io';
import 'dart:mirrors';

typedef void Parse(Operation operation, int offset, int word1, [int word2]);

class Operation {
  final Symbol mnemonic;
  final int code;
  final int size;
  final Parse parse;

  const Operation(this.mnemonic, this.code, this.size, this.parse);
}

class Instruction {
  int r;
  int x;
  int adr;

  int get r1 => r;
  int get r2 => x;

  Instruction.type_r(this.r);
  Instruction.type_r1_r2(this.r, this.x);
  Instruction.type_r_adr_x(this.r, this.adr, this.x);
  Instruction.type_adr_x(this.adr, this.x);
}

void parse(Operation operation, int offset, int word1, [int word2]) {
  stdout.write('L${offset.toRadixString(16).padLeft(4, '0')} ');
  stdout.write('${MirrorSystem.getName(operation.mnemonic).padRight(5, ' ')}');
  stdout.write('                    ; ${word1.toRadixString(16).padLeft(4, '0')}');
  stdout.write('\n');
}

void parse_dc(Operation operation, int offset, int word1, [int word2]) {
  stdout.write('L${offset.toRadixString(16).padLeft(4, '0')} ');
  stdout.write('${MirrorSystem.getName(operation.mnemonic).padRight(5, ' ')}');
  stdout.write('${(word1 & 0xFF).toRadixString(10).padLeft(3, ' ')}');
  stdout.write('                 ; ${word1.toRadixString(16).padLeft(4, '0')}');
  var c = (word1 &0xFF);
  if (0x20 <= c && c <= 0x7E) {
    stdout.write(" '${new String.fromCharCode(c)}'");
  } else if (c == 0x00) {
    stdout.write(' (might be DS)');
  }
  stdout.write('\n');
}

void parse_r(Operation operation, int offset, int word1, [int word2]) {
  Instruction inst = new Instruction.type_r((word1 >> 4) & 0xF);
  stdout.write('L${offset.toRadixString(16).padLeft(4, '0')} ');
  stdout.write('${MirrorSystem.getName(operation.mnemonic).padRight(5, ' ')}');
  stdout.write('GR${inst.r1}');
  stdout.write('                 ; ${word1.toRadixString(16).padLeft(4, '0')}');
  stdout.write('\n');
}

void parse_r1_r2(Operation operation, int offset, int word1, [int word2]) {
  Instruction inst = new Instruction.type_r1_r2((word1 >> 4) & 0xF, word1 & 0xF);
  stdout.write('L${offset.toRadixString(16).padLeft(4, '0')} ');
  stdout.write('${MirrorSystem.getName(operation.mnemonic).padRight(5, ' ')}');
  stdout.write('GR${inst.r1},GR${inst.r2}');
  stdout.write('           ; ${word1.toRadixString(16).padLeft(4, '0')}');
  stdout.write('\n');
}

void parse_r_adr_x(Operation operation, int offset, int word1, [int word2]) {
  Instruction inst = new Instruction.type_r_adr_x((word1 >> 4) & 0xF, word2, word1 & 0xF);
  stdout.write('L${offset.toRadixString(16).padLeft(4, '0')} ');
  stdout.write('${MirrorSystem.getName(operation.mnemonic).padRight(5, ' ')}');
  stdout.write('GR${inst.r},#${inst.adr.toRadixString(16).padLeft(4, '0')}');
  if (inst.x > 0) {
    stdout.write(',GR${inst.x}');
  } else {
    stdout.write('    ');
  }
  stdout.write('       ; ${word1.toRadixString(16).padLeft(4, '0')}');
  stdout.write(' ${word2.toRadixString(16).padLeft(4, '0')}');
  stdout.write('\n');
}

void parse_adr_x(Operation operation, int offset, int word1, [int word2]) {
  Instruction inst = new Instruction.type_adr_x(word2, word1 & 0xF);
  stdout.write('L${offset.toRadixString(16).padLeft(4, '0')} ');
  stdout.write('${MirrorSystem.getName(operation.mnemonic).padRight(5, ' ')}');
  stdout.write('#${inst.adr.toRadixString(16).padLeft(4, '0')}');
  if (inst.x > 0) {
    stdout.write(',GR${inst.x}');
  } else {
    stdout.write('    ');
  }
  stdout.write('           ; ${word1.toRadixString(16).padLeft(4, '0')}');
  stdout.write(' ${word2.toRadixString(16).padLeft(4, '0')}');
  stdout.write('\n');
}

Map<int, Operation> operations = {
  0x00: const Operation(#NOP,  0x00, 1, parse),
  0x10: const Operation(#LD,   0x10, 2, parse_r_adr_x),
  0x11: const Operation(#ST,   0x11, 2, parse_r_adr_x),
  0x12: const Operation(#LAD,  0x12, 2, parse_r_adr_x),
  0x14: const Operation(#LD,   0x14, 1, parse_r1_r2),
  0x20: const Operation(#ADDA, 0x20, 2, parse_r_adr_x),
  0x21: const Operation(#SUBA, 0x21, 2, parse_r_adr_x),
  0x22: const Operation(#ADDL, 0x22, 2, parse_r_adr_x),
  0x23: const Operation(#SUBL, 0x23, 2, parse_r_adr_x),
  0x24: const Operation(#ADDA, 0x24, 1, parse_r1_r2),
  0x25: const Operation(#SUBA, 0x25, 1, parse_r1_r2),
  0x26: const Operation(#ADDL, 0x26, 1, parse_r1_r2),
  0x27: const Operation(#SUBL, 0x27, 1, parse_r1_r2),
  0x30: const Operation(#AND,  0x30, 2, parse_r_adr_x),
  0x31: const Operation(#OR,   0x31, 2, parse_r_adr_x),
  0x32: const Operation(#XOR,  0x32, 2, parse_r_adr_x),
  0x34: const Operation(#AND,  0x34, 1, parse_r1_r2),
  0x35: const Operation(#OR,   0x35, 1, parse_r1_r2),
  0x36: const Operation(#XOR,  0x36, 1, parse_r1_r2),
  0x40: const Operation(#CPA,  0x40, 2, parse_r_adr_x),
  0x41: const Operation(#CPL,  0x41, 2, parse_r_adr_x),
  0x44: const Operation(#CPA,  0x44, 1, parse_r1_r2),
  0x45: const Operation(#CPL,  0x45, 1, parse_r1_r2),
  0x50: const Operation(#SLA,  0x50, 2, parse_r_adr_x),
  0x51: const Operation(#SRA,  0x51, 2, parse_r_adr_x),
  0x52: const Operation(#SLL,  0x52, 2, parse_r_adr_x),
  0x53: const Operation(#SRL,  0x53, 2, parse_r_adr_x),
  0x61: const Operation(#JMI,  0x61, 2, parse_adr_x),
  0x62: const Operation(#JNZ,  0x62, 2, parse_adr_x),
  0x63: const Operation(#JZE,  0x63, 2, parse_adr_x),
  0x64: const Operation(#JUMP, 0x64, 2, parse_adr_x),
  0x65: const Operation(#JPL,  0x65, 2, parse_adr_x),
  0x66: const Operation(#JOV,  0x66, 2, parse_adr_x),
  0x70: const Operation(#PUSH, 0x70, 2, parse_adr_x),
  0x71: const Operation(#POP,  0x71, 1, parse_r),
  0x80: const Operation(#CALL, 0x80, 2, parse_adr_x),
  0x81: const Operation(#RET,  0x81, 1, parse),
  0xF0: const Operation(#SVC,  0xF0, 2, parse_adr_x),
};

const dcOperation = const Operation(#DC, 0x00, 1, parse_dc);
