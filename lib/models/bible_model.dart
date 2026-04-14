import 'package:flutter/material.dart';

enum BibleModelType {
  book,
  noahsArk,
  solomonsTemple,
}

extension BibleModelTypeExt on BibleModelType {
  String get label => switch (this) {
        BibleModelType.book => '성경책',
        BibleModelType.noahsArk => '노아의 방주',
        BibleModelType.solomonsTemple => '솔로몬 성전',
      };

  String get description => switch (this) {
        BibleModelType.book => '아이소메트릭 성경책 블록',
        BibleModelType.noahsArk => '창세기 6-9장의 노아의 방주',
        BibleModelType.solomonsTemple => '왕상 6-7장의 솔로몬 성전',
      };

  IconData get icon => switch (this) {
        BibleModelType.book => Icons.auto_stories,
        BibleModelType.noahsArk => Icons.sailing,
        BibleModelType.solomonsTemple => Icons.account_balance,
      };

  String get storageKey => name;
}
