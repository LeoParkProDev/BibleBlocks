import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bible_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../theme/app_colors.dart';

enum ChecklistFilter { all, oldTestament, newTestament, unfinished }

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  ChecklistFilter _filter = ChecklistFilter.all;
  int? _expandedBookIndex;

  List<BibleBook> get _filteredBooks {
    return BibleData.books.where((book) {
      return switch (_filter) {
        ChecklistFilter.all => true,
        ChecklistFilter.oldTestament => book.testament == Testament.old,
        ChecklistFilter.newTestament => book.testament == Testament.new_,
        ChecklistFilter.unfinished => () {
            final data = ref.read(progressProvider).value ?? {};
            final read = data[book.index]?.length ?? 0;
            return read < book.chapters;
          }(),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(progressProvider);
    final totalRead = ref.watch(totalReadProvider);
    final overallProgress = ref.watch(overallProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('체크리스트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => _showProfileDialog(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              // 전체 진행률
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$totalRead / ${BibleData.totalChapters}장',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${(overallProgress * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: overallProgress,
                        minHeight: 10,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 필터 칩
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _filterChip('전체', ChecklistFilter.all),
                    const SizedBox(width: 8),
                    _filterChip('구약', ChecklistFilter.oldTestament),
                    const SizedBox(width: 8),
                    _filterChip('신약', ChecklistFilter.newTestament),
                    const SizedBox(width: 8),
                    _filterChip('미완료', ChecklistFilter.unfinished),
                  ],
                ),
              ),

              // 책 리스트
              Expanded(
                child: progressAsync.when(
                  data: (data) => _buildBookList(data),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Center(child: Text('오류: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, ChecklistFilter filter) {
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

  Widget _buildBookList(Map<int, Set<int>> data) {
    final books = _filteredBooks;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final readChapters = data[book.index] ?? {};
        final isExpanded = _expandedBookIndex == book.index;
        final isComplete = readChapters.length == book.chapters;
        final progress =
            book.chapters > 0 ? readChapters.length / book.chapters : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // 책 헤더
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedBookIndex = isExpanded ? null : book.index;
                  });
                },
                onLongPress: () async {
                  HapticFeedback.mediumImpact();
                  final willMarkRead = !isComplete;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        willMarkRead ? '전체 읽음 처리' : '읽음 해제',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      content: Text(
                        willMarkRead
                            ? '${book.name} ${book.chapters}장 전체를 읽음 처리하시겠습니까?'
                            : '${book.name} 읽음 기록을 모두 해제하시겠습니까?',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text(
                            '취소',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(
                            willMarkRead ? '읽음 처리' : '해제',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true || !context.mounted) return;
                  ref
                      .read(progressProvider.notifier)
                      .toggleAllChapters(book.index, book.chapters);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        willMarkRead
                            ? '${book.name} ${book.chapters}장 전체 읽음'
                            : '${book.name} 읽기 초기화됨',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // 아이콘
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isComplete
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : book.testament == Testament.old
                                  ? AppColors.primaryBg
                                  : AppColors.secondaryBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: isComplete
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: AppColors.primary,
                                )
                              : Text(
                                  book.testament == Testament.old ? '구' : '신',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: book.testament == Testament.old
                                        ? AppColors.primary
                                        : AppColors.secondary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 이름 + 진행률
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  book.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${readChapters.length}/${book.chapters}장',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                backgroundColor: AppColors.border,
                                valueColor: AlwaysStoppedAnimation(
                                  book.testament == Testament.old
                                      ? AppColors.primary
                                      : AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              // 아코디언: 장 그리드
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: _buildChapterGrid(book, readChapters),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showProfileDialog(BuildContext context) {
    final user = ref.read(authProvider).value;
    final isGuest = ref.read(isGuestProvider).value ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 프로필 이미지
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundImage: user?.profileImageUrl != null
                  ? NetworkImage(user!.profileImageUrl!)
                  : null,
              child: user?.profileImageUrl == null
                  ? const Icon(Icons.person, size: 32, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(height: 12),
            // 닉네임
            Text(
              isGuest ? '게스트' : (user?.nickname ?? '사용자'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (isGuest) ...[
              const SizedBox(height: 4),
              const Text(
                '로그인하면 데이터가 계정에 저장됩니다',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 20),
            // 로그아웃 / 로그인 버튼
            SizedBox(
              width: double.infinity,
              child: isGuest
                  ? OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ref.read(isGuestProvider.notifier).set(false);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('카카오 로그인으로 전환'),
                    )
                  : OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ref.read(authProvider.notifier).logout();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('로그아웃'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterGrid(BibleBook book, Set<int> readChapters) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: book.chapters,
      itemBuilder: (context, index) {
        final chapter = index + 1;
        final isRead = readChapters.contains(chapter);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            ref
                .read(progressProvider.notifier)
                .toggleChapter(book.index, chapter);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isRead ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isRead ? AppColors.primary : AppColors.border,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$chapter',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isRead ? FontWeight.w600 : FontWeight.normal,
                color: isRead ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      },
    );
  }
}
