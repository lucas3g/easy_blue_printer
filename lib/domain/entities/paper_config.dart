/// Quanto a cabeça térmica aquece a cada ponto.
///
/// Mais calor escurece o traço e melhora a leitura de texto pequeno e de
/// códigos de barras, ao custo de imprimir um pouco mais devagar e de gastar
/// mais a cabeça. O comando é o `ESC 7` das térmicas ESC/POS.
///
/// Nem toda impressora o implementa. A que não implementa costuma ignorá-lo,
/// mas há modelos que imprimem os parâmetros como texto — por isso o padrão é
/// não mandar nada e manter o que vem de fábrica.
enum PrintDensity {
  /// Padrão de fábrica da maioria das térmicas.
  normal(80),

  /// Um passo mais escuro. É o que costuma resolver texto miúdo apagado.
  dark(120),

  /// O limite prático antes de o traço começar a borrar.
  darkest(160);

  const PrintDensity(this.heatingTime);

  /// `n2` do `ESC 7`, em unidades de 10µs.
  final int heatingTime;
}

class PaperConfig {
  final int widthPixels;

  /// `null` mantém o aquecimento de fábrica e não envia comando nenhum.
  final PrintDensity? density;

  const PaperConfig({required this.widthPixels, this.density});

  /// Bobina de 58mm — largura de 384 pixels (padrão mais comum)
  static const PaperConfig roll58mm = PaperConfig(widthPixels: 384);

  /// Bobina de 80mm — largura de 576 pixels
  static const PaperConfig roll80mm = PaperConfig(widthPixels: 576);

  PaperConfig copyWith({PrintDensity? density}) => PaperConfig(widthPixels: widthPixels, density: density ?? this.density);

  @override
  String toString() => 'PaperConfig(widthPixels: $widthPixels, density: $density)';
}
