import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/bible_data.dart';
import '../../providers/bible_text_provider.dart';
import '../../services/bible_text_service.dart';
import '../../theme/app_colors.dart';

/// 개역한글 전문(번들)에서 본문을 검색한다.
/// 결과를 탭하면 해당 절로 이동(리더가 스크롤·강조).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  int _searchToken = 0;

  List<SearchResult> _results = [];
  bool _searching = false;
  bool _hasSearched = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run(initial));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _run(q));
  }

  Future<void> _run(String query) async {
    final token = ++_searchToken;
    setState(() {
      _searching = true;
      _hasSearched = true;
      _progress = 0;
    });
    final service = ref.read(bibleTextServiceProvider);
    try {
      final results = await service.search(
        query,
        onProgress: (p) {
          if (token == _searchToken && mounted) {
            setState(() => _progress = p);
          }
        },
      );
      if (token != _searchToken || !mounted) return; // 최신 검색만 반영
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (_) {
      if (token != _searchToken || !mounted) return;
      setState(() {
        _results = [];
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: '본문 검색 (예: 사랑)',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 16),
          onChanged: _onChanged,
          onSubmitted: (v) {
            _debounce?.cancel();
            final q = v.trim();
            if (q.isNotEmpty) _run(q);
          },
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              tooltip: '지우기',
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                _onChanged('');
                setState(() {});
              },
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    if (_searching) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: LinearProgressIndicator(
              value: _progress == 0 ? null : _progress,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '본문을 검색하는 중…',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      );
    }

    if (!_hasSearched) {
      return _hint('찾고 싶은 단어나 구절을 입력하세요',
          '개역한글 전문에서 찾습니다. 공백은 무시하고 부분일치로 검색해요.');
    }

    if (_results.isEmpty) {
      return _hint('검색 결과가 없어요', '다른 단어로 다시 시도해 보세요.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '검색 결과 ${_results.length}건',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: _results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _resultTile(_results[i]),
          ),
        ),
      ],
    );
  }

  Widget _hint(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search, size: 44, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultTile(SearchResult r) {
    final book = BibleData.books[r.bookIndex];
    final citation = '${book.name} ${r.chapter}:${r.verse}';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () =>
          context.push('/reader/${r.bookIndex}/${r.chapter}?verse=${r.verse}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              citation,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            _snippet(r),
          ],
        ),
      ),
    );
  }

  Widget _snippet(SearchResult r) {
    const lead = 16; // 매칭어 앞 문맥 글자 수
    final start = (r.matchStart - lead).clamp(0, r.text.length);
    final pre = (start > 0 ? '…' : '') + r.text.substring(start, r.matchStart);
    final mid = r.text.substring(r.matchStart, r.matchEnd);
    final post = r.text.substring(r.matchEnd);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: pre),
          TextSpan(
            text: mid,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              backgroundColor: AppColors.primaryBg,
            ),
          ),
          TextSpan(text: post),
        ],
        style: const TextStyle(
          fontSize: 14,
          height: 1.45,
          color: AppColors.textPrimary,
        ),
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
