/// Formats a duration in milliseconds as `m:ss` or `h:mm:ss`.
String formatDurationMs(num? milliseconds) {
  if (milliseconds == null || milliseconds <= 0) {
    return '0:00';
  }

  final totalSeconds = milliseconds ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  String two(int v) => v.toString().padLeft(2, '0');

  return hours > 0
      ? '$hours:${two(minutes)}:${two(seconds)}'
      : '$minutes:${two(seconds)}';
}
