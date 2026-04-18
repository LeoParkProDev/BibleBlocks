import 'package:flutter/material.dart';

enum BibleModelType {
  book,
  noahsArk,
  solomonsTemple,
  pilgrimMountain,
}

extension BibleModelTypeExt on BibleModelType {
  String get label => switch (this) {
        BibleModelType.book => '성경책',
        BibleModelType.noahsArk => '노아의 방주',
        BibleModelType.solomonsTemple => '솔로몬 성전',
        BibleModelType.pilgrimMountain => '천로역정',
      };

  String get description => switch (this) {
        BibleModelType.book => '아이소메트릭 성경책 블록',
        BibleModelType.noahsArk => '창세기 6-9장의 노아의 방주',
        BibleModelType.solomonsTemple => '왕상 6-7장의 솔로몬 성전',
        BibleModelType.pilgrimMountain => '읽은 장 수만큼 순례길이 밝아집니다',
      };

  IconData get icon => switch (this) {
        BibleModelType.book => Icons.auto_stories,
        BibleModelType.noahsArk => Icons.sailing,
        BibleModelType.solomonsTemple => Icons.account_balance,
        BibleModelType.pilgrimMountain => Icons.terrain,
      };

  bool get supportsBlockInteraction => switch (this) {
        BibleModelType.pilgrimMountain => false,
        _ => true,
      };

  String get storageKey => name;
}
