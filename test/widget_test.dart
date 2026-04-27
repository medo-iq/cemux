import 'package:cemux/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('app opens directly into the 8086 simulator workspace', (
    tester,
  ) async {
    await tester.pumpWidget(const CemuXApp());
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    expect(find.text('8086 Assembly Simulator'), findsOneWidget);
    expect(find.text('ASSEMBLY PROGRAM'), findsOneWidget);
    expect(find.text('REGISTERS'), findsAtLeastNWidgets(1));
    expect(find.text('INSTRUCTION MEMORY'), findsOneWidget);
    expect(find.text('DATA MEMORY'), findsOneWidget);
    expect(find.text('Load'), findsOneWidget);
    expect(find.text('Step'), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Blank Program'), findsOneWidget);
  });

  testWidgets('example program selection puts 8086 commands in editor', (
    tester,
  ) async {
    await tester.pumpWidget(const CemuXApp());
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Blank Program'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('XCHG and ADD').last);
    await tester.pumpAndSettle();

    final editor = tester.widget<EditableText>(find.byType(EditableText));
    expect(editor.controller.text, contains('MOV AX,12CDH'));
    expect(editor.controller.text, contains('XCHG AX,BX'));
    expect(editor.controller.text, contains('ADD AX,BX'));
    expect(find.text('XCHG and ADD'), findsOneWidget);
  });
}
