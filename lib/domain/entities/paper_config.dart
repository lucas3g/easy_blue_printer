class PaperConfig {
  final int widthPixels;

  const PaperConfig({required this.widthPixels});

  /// Bobina de 58mm — largura de 384 pixels (padrão mais comum)
  static const PaperConfig roll58mm = PaperConfig(widthPixels: 384);

  /// Bobina de 80mm — largura de 576 pixels
  static const PaperConfig roll80mm = PaperConfig(widthPixels: 576);

  @override
  String toString() => 'PaperConfig(widthPixels: $widthPixels)';
}
