import '../cpu/cpu_error.dart';
import 'handlers/add_handler.dart';
import 'handlers/and_handler.dart';
import 'handlers/dec_handler.dart';
import 'handlers/div_handler.dart';
import 'handlers/inc_handler.dart';
import 'handlers/mov_handler.dart';
import 'handlers/mul_handler.dart';
import 'handlers/or_handler.dart';
import 'handlers/ret_handler.dart';
import 'handlers/rol_handler.dart';
import 'handlers/ror_handler.dart';
import 'handlers/sub_handler.dart';
import 'handlers/xchg_handler.dart';
import 'handlers/xor_handler.dart';
import 'instruction_handler.dart';

class InstructionRegistry {
  InstructionRegistry(Iterable<InstructionHandler> handlers) {
    for (final handler in handlers) {
      _handlers[handler.mnemonic] = handler;
    }
  }

  factory InstructionRegistry.mvp() {
    return InstructionRegistry(const [
      MovHandler(),
      XchgHandler(),
      AddHandler(),
      SubHandler(),
      IncHandler(),
      DecHandler(),
      MulHandler(),
      DivHandler(),
      AndHandler(),
      OrHandler(),
      XorHandler(),
      RolHandler(),
      RorHandler(),
      RetHandler(),
    ]);
  }

  final Map<String, InstructionHandler> _handlers = {};

  InstructionHandler resolve(String mnemonic) {
    final handler = _handlers[mnemonic.toUpperCase()];
    if (handler == null) {
      throw CpuExecutionException('Unsupported instruction "$mnemonic".');
    }
    return handler;
  }
}
