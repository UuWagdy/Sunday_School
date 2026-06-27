import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/repositories/settings_repository.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = SettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('uses default Arabic program name when no setting exists', () async {
    expect(await repository.getProgramName(), SettingsRepository.defaultProgramName);
  });

  test('uses default Arabic program name when stored setting is empty', () async {
    await repository.saveSetting(SettingsRepository.programNameKey, '   ');

    expect(await repository.getProgramName(), SettingsRepository.defaultProgramName);
  });

  test('saves trimmed custom program name', () async {
    await repository.saveProgramName('  مدرسة الشمامسة  ');

    expect(await repository.getSetting(SettingsRepository.programNameKey), 'مدرسة الشمامسة');
    expect(await repository.getProgramName(), 'مدرسة الشمامسة');
  });

  test('rejects empty custom program name', () async {
    expect(
      () => repository.saveProgramName('   '),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects overly long custom program name', () async {
    final longName = 'أ' * (SettingsRepository.maxProgramNameLength + 1);

    expect(
      () => repository.saveProgramName(longName),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('clears custom program name back to default', () async {
    await repository.saveProgramName('مدرسة الشمامسة');
    await repository.deleteProgramName();

    expect(await repository.getProgramName(), SettingsRepository.defaultProgramName);
  });
}
