import 'cpu_state.dart';
import 'intel_8086_engine.dart';

abstract class CpuEngine {
  factory CpuEngine() = Intel8086Engine;

  factory CpuEngine.intel8086() = Intel8086Engine;

  void loadProgram(String source);

  void stepPhase();

  int run({int maxCycles = 1000});

  void pause();

  void reset();

  CpuState getState();

  CpuState get state => getState();
}
