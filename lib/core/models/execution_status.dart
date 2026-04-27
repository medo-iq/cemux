enum ExecutionStatus {
  idle,
  loaded,
  running,
  paused,
  halted,
  error;

  bool get isRunning => this == running;
}
