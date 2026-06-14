import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/bible_data.dart';
import '../../models/verse_annotation.dart';
import '../../providers/annotation_provider.dart';
import '../../theme/app_colors.dart';

enum NotesFilter { all, bookmark, note, highlight }

/// 하이라이트·북마크·노트를 한 곳에서 보고, 검색하고, 절로 이동한다.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  NotesFilter _filter = NotesFilter.all;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _citation(VerseAnnotation a) =>
      '${BibleData.books[a.bookIndex].name} ${a.chapter}:${a.verse}';

  List<VerseAnnotation> _visible(Map<String, VerseAnnotation> all) {
    final query = _searchController.text.trim();
    final list = all.values.where((a) {
      switch (_filter) {
        case NotesFilter.all:
          break;
        case NotesFilter.bookmark:
          if (!a.bookmarked) return false;
        case NotesFilter.note:
          if (!a.hasNote) return false;
        case NotesFilter.highlight:
          if (!a.hasHighlight) return false;
      }
      if (query.isNotEmpty) {
        final haystack = '${_citation(a)} ${a.note ?? ''}';
        if (!haystack.contains(query)) return false;
      }
      return true;
    }).toList()
      ..sort((x, y) => y.updatedAt.compareTo(x.updatedAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(annotationProvider).value ?? const {};
    final items = _visible(all);

    return Scaffold(
      appBar: AppBar(title: const Text('내 노트·북마크')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '구절·메모 검색',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    _chip('전체', NotesFilter.all),
                    const SizedBox(width: 8),
                    _chip('북마크', NotesFilter.bookmark),
                    const SizedBox(width: 8),
                    _chip('노트', NotesFilter.note),
                    const SizedBox(width: 8),
                    _chip('하이라이트', NotesFilter.highlight),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? _emptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _tile(context, items[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, NotesFilter filter) {
    final selected = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.bookmarks_outlined,
              size: 44, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text(
            '아직 표시한 구절이 없어요',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              '본문을 읽다가 절을 탭해 하이라이트·북마크·노트를 남겨보세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, VerseAnnotation a) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(
        '/reader/${a.bookIndex}/${a.chapter}?verse=${a.verse}',
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (a.hasHighlight)
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 3, right: 10),
                decoration: BoxDecoration(
                  color: Color(a.color!),
                  shape: BoxShape.circle,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _citation(a),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (a.hasNote) ...[
                    const SizedBox(height: 4),
                    Text(
                      a.note!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (a.bookmarked)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.bookmark, size: 18, color: AppColors.gold),
              ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
