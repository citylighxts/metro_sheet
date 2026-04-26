import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:metro_sheet/widgets/sheet_music_card.dart';
import 'package:metro_sheet/models/sheet_music.dart';

void main() {
  testWidgets('SheetMusicCard menampilkan judul dan metadata', (
    WidgetTester tester,
  ) async {
    final sheet = SheetMusic(
      id: 1,
      title: 'Moonlight Sonata',
      composer: 'Beethoven',
      bpm: 72,
      imagePath: '/tmp/non-existing-file.jpg',
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SheetMusicCard(sheet: sheet, onTap: () {}, onDelete: () {}),
        ),
      ),
    );

    expect(find.text('Moonlight Sonata'), findsOneWidget);
    expect(find.text('72 BPM  •  4/4'), findsOneWidget);
  });
}
