class MiniGameResult {
  final bool didCatch;
  final int bonusXp;
  final double elapsedSeconds;

  const MiniGameResult({
    required this.didCatch,
    required this.bonusXp,
    required this.elapsedSeconds,
  });

  const MiniGameResult.failed({this.elapsedSeconds = 50})
      : didCatch = false,
        bonusXp = 0;
}
