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
  normal(80, 1.0),

  /// Um passo mais escuro. É o que costuma resolver texto miúdo apagado.
  dark(120, 0.75),

  /// O limite prático antes de o traço começar a borrar.
  darkest(160, 0.6);

  const PrintDensity(this.heatingTime, this.speedFactor);

  /// `n2` do `ESC 7`, em unidades de 10µs.
  final int heatingTime;

  /// Quanto da velocidade de fábrica sobra com este aquecimento.
  ///
  /// Cada linha fica mais tempo sob a cabeça, então o papel anda mais devagar
  /// — e o envio tem que acompanhar, ou o buffer da impressora estoura no meio
  /// do raster e o resto dos bytes sai como caracteres soltos no papel.
  final double speedFactor;
}

class PaperConfig {
  final int widthPixels;

  /// `null` mantém o aquecimento de fábrica e não envia comando nenhum.
  final PrintDensity? density;

  /// Quantas linhas de raster por segundo a impressora queima com o
  /// aquecimento de fábrica. É o que dita o ritmo do envio: não há controle de
  /// fluxo no Bluetooth dessas impressoras, só um piso de tempo por bloco.
  ///
  /// `null` usa [defaultLinesPerSecond]. Errar para menos custa alguns
  /// segundos de impressão; errar para mais enche o buffer e o fim do
  /// documento sai como lixo.
  final int? linesPerSecond;

  const PaperConfig({
    required this.widthPixels,
    this.density,
    this.linesPerSecond,
  });

  /// 250 linhas/s ≈ 31 mm/s a 203 dpi. O catálogo das térmicas portáteis diz
  /// 50–90 mm/s, mas isso vale para papel pouco preenchido: um boleto, com
  /// barras e faixas pretas, derruba a velocidade real — e 400 linhas/s, o
  /// valor até a 2.3.0, estourava o buffer no meio de documentos longos.
  static const int defaultLinesPerSecond = 250;

  /// O ritmo que vai para o lado nativo: a velocidade pedida, descontado o
  /// quanto a [density] escolhida deixa a impressora mais lenta.
  int get effectiveLinesPerSecond {
    final base = linesPerSecond ?? defaultLinesPerSecond;
    final factor = density?.speedFactor ?? 1.0;
    final efetivo = (base * factor).round();
    return efetivo < 1 ? 1 : efetivo;
  }

  /// Bobina de 58mm — largura de 384 pixels (padrão mais comum)
  static const PaperConfig roll58mm = PaperConfig(widthPixels: 384);

  /// Bobina de 80mm — largura de 576 pixels
  static const PaperConfig roll80mm = PaperConfig(widthPixels: 576);

  PaperConfig copyWith({PrintDensity? density, int? linesPerSecond}) =>
      PaperConfig(
        widthPixels: widthPixels,
        density: density ?? this.density,
        linesPerSecond: linesPerSecond ?? this.linesPerSecond,
      );

  @override
  String toString() =>
      'PaperConfig(widthPixels: $widthPixels, density: $density, '
      'linesPerSecond: $linesPerSecond)';
}
