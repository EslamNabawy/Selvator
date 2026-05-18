import 'package:flutter_test/flutter_test.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';
import 'package:wisely/src/domain/services/nickname_service.dart';

void main() {
  const service = NicknameService();

  test('uses hardcoded nour female special case', () {
    expect(service.nickname('Nour', gender: UserGender.female), 'nourindty');
  });

  test('female names ending with vowels use vowel swap transform', () {
    expect(service.nickname('Sama', gender: UserGender.female), 'semo');
    expect(service.nickname('Sara', gender: UserGender.female), 'sero');
    expect(service.nickname('Mona', gender: UserGender.female), 'meno');
    expect(service.nickname('Reda', gender: UserGender.female), 'rodo');
  });

  test('everyone else uses stretch transform', () {
    expect(service.nickname('Karim', gender: UserGender.male), 'kariiiim');
    expect(service.nickname('Walid', gender: UserGender.male), 'waliiiid');
    expect(service.nickname('Ali', gender: UserGender.male), 'aliiiii');
    expect(service.nickname('Khaled', gender: UserGender.male), 'khaaled');
  });

  test('names without vowels return normalized name', () {
    expect(service.nickname('  MYTH  ', gender: UserGender.male), 'myth');
  });
}
