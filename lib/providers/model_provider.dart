import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bible_model.dart';

const _key = 'selected_model';

final modelProvider =
    NotifierProvider<ModelNotifier, BibleModelType>(ModelNotifier.new);

class ModelNotifier extends Notifier<BibleModelType> {
  @override
  BibleModelType build() {
    _load();
    return BibleModelType.book;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      final match = BibleModelType.values.where((e) => e.storageKey == saved);
      if (match.isNotEmpty) {
        state = match.first;
      }
    }
  }

  Future<void> set(BibleModelType type) async {
    state = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, type.storageKey);
  }
}
