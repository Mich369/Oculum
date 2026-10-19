import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('level milestone reserves round up and cannot be claimed twice', () {
    expect(oculumLevelMilestoneRewards(4, []), isEmpty);
    expect(oculumLevelMilestoneRewards(200, []), {
      5: 2,
      15: 4,
      25: 7,
      50: 13,
      100: 25,
      200: 50,
    });
    expect(oculumLevelMilestoneRewards(25, [5, 15]), {25: 7});
    expect(
      oculumLevelMilestoneRewards(200, [5, 15, 25, 50, 100, 200]),
      isEmpty,
    );
    expect(oculumLevelMilestoneRewards(5, [5, 15]), isEmpty);
  });
  test('standard and learning title capacity follows confirmed grades', () {
    expect(
      [
        for (final g in [0, 2, 3, 5, 6, 8, 9, 12])
          oculumStandardTitleCapacity(g),
      ],
      [6, 6, 7, 7, 8, 8, 9, 9],
    );
    expect(oculumLearningTitleCapacity(0), 1);
    expect(oculumLearningTitleCapacity(3), 4);
    expect(oculumLearningTitleCapacity(-1), 1);
  });
  test('legacy reputation stays at root and keeps karma data', () {
    final entry = ReputationEntry.fromJson({
      'cityName': 'Moon Hills',
      'value': 12,
      'baseValue': 8,
      'lastKarmaApplied': 4,
      'userModified': true,
    });
    expect(entry.folder, '');
    expect(entry.value, 12);
    expect(entry.baseValue, 8);
    expect(entry.lastKarmaApplied, 4);
    expect(entry.userModified, isTrue);
  });
  test('nested folders survive JSON and do not change reputation', () {
    final entry = ReputationEntry(
      cityName: 'Porto',
      folder: 'Regione/Costa/Porto',
      value: -18,
      description: 'Ricercato',
      userModified: true,
    );
    final restored = ReputationEntry.fromJson(entry.toJson());
    expect(restored.folder, 'Regione/Costa/Porto');
    expect(restored.value, -18);
    expect(restored.description, 'Ricercato');
    restored.folder = 'Regione/Capitale';
    expect(restored.value, -18);
  });
  test('all parents and empty folders survive without a fixed count limit', () {
    final paths = [for (var i = 0; i < 150; i++) 'Regioni/R$i/Capitale'];
    final folders = oculumReputationFolderAncestors(paths);
    expect(folders.length, 301);
    expect(
      folders,
      containsAll(['Regioni', 'Regioni/R149', 'Regioni/R149/Capitale']),
    );
    expect(
      oculumReputationFolderPath(' / Regione // ./ Città /../ '),
      'Regione/Città',
    );
    expect(oculumReputationFolderAncestors(['', '/']), isEmpty);
  });
}
