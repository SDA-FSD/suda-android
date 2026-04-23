import 'dart:ui' show FontVariation;

import 'package:flutter/material.dart';

import '../../api/suda_api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_models.dart';
import '../../utils/default_markdown.dart';
import '../../services/token_storage.dart';
import '../../utils/suda_json_util.dart';
import '../../widgets/app_scaffold.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final int noticeId;

  const AnnouncementDetailScreen({
    super.key,
    required this.noticeId,
  });

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  static const List<FontVariation> _detailTitleWght = [FontVariation('wght', 600)];

  AppNoticeDto? _notice;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotice();
  }

  Future<void> _fetchNotice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final accessToken = await TokenStorage.loadAccessToken();
      if (accessToken == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Not authenticated';
          });
        }
        return;
      }

      final notice = await SudaApiClient.getNotice(
        accessToken: accessToken,
        noticeId: widget.noticeId,
      );

      if (!mounted) return;

      setState(() {
        _notice = notice;
        _isLoading = false;
        _error = notice == null ? 'Not found' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String? _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return null;
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate.length >= 10 ? isoDate.substring(0, 10) : isoDate;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      backgroundColor: Colors.black,
      centerTitle: l10n.settingsAnnouncements,
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (_error != null || _notice == null) {
      return Center(
        child: Text(
          _error ?? l10n.deletedPost,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final notice = _notice!;
    final titleText = SudaJsonUtil.localizedText(notice.title);
    final contentText = SudaJsonUtil.localizedText(notice.content);
    final dateStr = _formatDate(notice.publishedAt ?? notice.createdAt);

    const boxColor = Color(0xFF252525);
    final screenHeight = MediaQuery.of(context).size.height;
    final bodyHeight = screenHeight * 0.6;

    return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 (제목 위, 오른쪽 정렬)
              if (dateStr != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFB0B0B0),
                          ),
                    ),
                  ),
                ),
              // 제목 영역
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: boxColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontVariations: _detailTitleWght,
                          ),
                      children: DefaultMarkdown.buildSpans(
                        titleText.isNotEmpty ? titleText : '',
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontVariations: _detailTitleWght,
                            ) ??
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontVariations: _detailTitleWght,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              // 본문 영역 (고정 높이, 내부 세로 스크롤)
              SizedBox(
                height: bodyHeight,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: boxColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              height: 1.5,
                            ),
                        children: DefaultMarkdown.buildSpans(
                          contentText.isNotEmpty ? contentText : '',
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                height: 1.5,
                              ) ??
                              const TextStyle(
                                color: Colors.white,
                                height: 1.5,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
  }
}
