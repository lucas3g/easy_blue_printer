import 'dart:typed_data';

import 'package:easy_blue_printer/easy_blue_printer.dart';
import 'package:easy_blue_printer/easy_blue_printer_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Registra a ordem das chamadas para provar quando cada future completa.
///
/// Nenhum método toca o socket: no plugin de verdade, `printData`, `printImage`
/// e `printEmptyLine` só enchem um buffer nativo, e quem envia é `commitPrint`.
class FakePlatform extends EasyBluePrinterPlatform with MockPlatformInterfaceMixin {
  final List<String> calls = [];

  /// Quando presente, é lançado pelo `commitPrint` — o envio falhando, que é
  /// o que o app precisa enxergar.
  Object? commitError;

  @override
  Future<bool> printData({required String data, required FS fontSize, required TA textAlign, required bool bold}) async {
    calls.add('printData:$data');
    return true;
  }

  @override
  Future<void> printEmptyLine({required int callTimes}) async {
    calls.add('printEmptyLine:$callTimes');
  }

  @override
  Future<bool> printImage({required Uint8List bytes, required TA textAlign}) async {
    calls.add('printImage:${bytes.length}');
    return true;
  }

  /// O envio tem começo e fim de propósito: o que interessa é se o future de
  /// quem chamou completou depois do **fim**, e não depois da chamada. Os
  /// bytes levam segundos para sair, e era exatamente aí que o app avisava
  /// "impresso" com a impressora ainda puxando papel.
  @override
  Future<void> commitPrint() async {
    calls.add('commit:inicio');
    await Future<void>.delayed(Duration.zero);
    final error = commitError;
    if (error != null) throw error;
    calls.add('commit:fim');
  }

  @override
  Future<List<BluetoothDevice>> getPairedDevices() async => [];

  @override
  Future<bool> connectToDevice(BluetoothDevice device) async => true;

  @override
  Future<bool> disconnectFromDevice() async => true;

  @override
  Future<bool> isConnected() async => true;

  @override
  Future<void> requestBluetoothPermissions() async {}

  @override
  Future<void> configurePrinter(PaperConfig config) async {}
}

void main() {
  late FakePlatform platform;

  setUp(() {
    platform = FakePlatform();
    EasyBluePrinterPlatform.instance = platform;
  });

  test('o future de printData só completa depois do commitPrint', () async {
    // A lista é copiada dentro do `then`, e não depois do `await`: é no
    // instante em que o future completa que a pergunta faz sentido.
    List<String>? noMomentoDoCompleto;

    await EasyBluePrinter.instance
        .printData(data: 'CUPOM', fontSize: FS.medium, textAlign: TA.center, bold: false)
        .then((_) => noMomentoDoCompleto = List.of(platform.calls));

    expect(noMomentoDoCompleto, ['printData:CUPOM', 'commit:inicio', 'commit:fim']);
  });

  test('o future de printImage só completa depois do commitPrint', () async {
    List<String>? noMomentoDoCompleto;

    await EasyBluePrinter.instance
        .printImage(bytes: Uint8List(32), textAlign: TA.center)
        .then((_) => noMomentoDoCompleto = List.of(platform.calls));

    expect(noMomentoDoCompleto, ['printImage:32', 'commit:inicio', 'commit:fim']);
  });

  test('a falha do commitPrint chega a quem chamou', () async {
    platform.commitError = StateError('Socket desconectado durante envio');

    await expectLater(
      EasyBluePrinter.instance.printImage(bytes: Uint8List(8), textAlign: TA.center),
      throwsA(isA<StateError>()),
    );
  });

  test('chamadas enfileiradas juntas saem num commit só', () async {
    final printer = EasyBluePrinter.instance;

    await Future.wait([
      printer.printData(data: 'A', fontSize: FS.medium, textAlign: TA.left, bold: false),
      printer.printData(data: 'B', fontSize: FS.medium, textAlign: TA.left, bold: false),
      printer.printEmptyLine(callTimes: 3),
    ]);

    expect(platform.calls, ['printData:A', 'printData:B', 'printEmptyLine:3', 'commit:inicio', 'commit:fim']);
  });
}
