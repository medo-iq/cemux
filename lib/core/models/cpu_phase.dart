enum CpuPhase {
  idle('IDLE'),
  fetch('FETCH'),
  decode('DECODE'),
  execute('EXECUTE'),
  halted('HALTED');

  const CpuPhase(this.label);

  final String label;
}
