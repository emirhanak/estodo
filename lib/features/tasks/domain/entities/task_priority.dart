enum TaskPriority {
  low,
  medium,
  high;

  String get label {
    return switch (this) {
      TaskPriority.low => 'Low',
      TaskPriority.medium => 'Medium',
      TaskPriority.high => 'High',
    };
  }
}
