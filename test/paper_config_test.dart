import 'package:easy_blue_printer/easy_blue_printer.dart';
import 'package:easy_blue_printer/easy_blue_printer_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaperConfig.effectiveLinesPerSecond', () {
    test('sem nada pedido usa o padrão conservador', () {
      expect(PaperConfig.roll80mm.effectiveLinesPerSecond, 250);
      expect(PaperConfig.defaultLinesPerSecond, 250);
    });

    test('densidade escura desacelera o envio', () {
      expect(
        const PaperConfig(widthPixels: 576, density: PrintDensity.normal)
            .effectiveLinesPerSecond,
        250,
      );
      expect(
        const PaperConfig(widthPixels: 576, density: PrintDensity.dark)
            .effectiveLinesPerSecond,
        188,
      );
      expect(
        const PaperConfig(widthPixels: 576, density: PrintDensity.darkest)
            .effectiveLinesPerSecond,
        150,
      );
    });

    test('a velocidade pedida é a base do desconto da densidade', () {
      expect(
        const PaperConfig(
          widthPixels: 576,
          density: PrintDensity.dark,
          linesPerSecond: 200,
        ).effectiveLinesPerSecond,
        150,
      );
    });

    test('nunca chega a zero', () {
      expect(
        const PaperConfig(widthPixels: 384, linesPerSecond: 0)
            .effectiveLinesPerSecond,
        1,
      );
    });

    test('copyWith preserva o ritmo', () {
      const config = PaperConfig(widthPixels: 384, linesPerSecond: 180);
      expect(config.copyWith(density: PrintDensity.dark).linesPerSecond, 180);
    });
  });

  group('configurePrinter no canal', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final platform = MethodChannelEasyBluePrinter();
    late Map<Object?, Object?> argumentos;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (call) async {
        argumentos = call.arguments as Map<Object?, Object?>;
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, null);
    });

    test('manda o ritmo já descontado da densidade', () async {
      await platform.configurePrinter(
        const PaperConfig(
          widthPixels: 576,
          density: PrintDensity.dark,
          linesPerSecond: 200,
        ),
      );
      expect(argumentos['paperWidth'], 576);
      expect(argumentos['heatingTime'], 120);
      expect(argumentos['linesPerSecond'], 150);
    });

    test('sem densidade não manda aquecimento, mas manda o ritmo', () async {
      await platform.configurePrinter(PaperConfig.roll58mm);
      expect(argumentos.containsKey('heatingTime'), isFalse);
      expect(argumentos['linesPerSecond'], 250);
    });
  });
}
