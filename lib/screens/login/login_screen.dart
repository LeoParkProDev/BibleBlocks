import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AsyncLoading;
    final t = context.l10n;

    // 로그인 실패 시 실제 에러를 표면화 (조용히 메인으로 돌아가는 문제 진단/안내)
    ref.listen(authProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('로그인 실패: ${next.error}'),
              duration: const Duration(seconds: 8),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 앱 로고
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.darkBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Image.asset('assets/icon/icon_foreground.png'),
                ),
                const SizedBox(height: 24),

                // 타이틀
                const Text(
                  'BibleBlocks',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.loginTagline,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),

                // 카카오 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => ref.read(authProvider.notifier).login(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE500),
                      foregroundColor: const Color(0xFF191919),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            t.loginKakao,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // 게스트 모드
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          ref.read(isGuestProvider.notifier).set(true);
                        },
                  child: Text(
                    t.loginGuest,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
