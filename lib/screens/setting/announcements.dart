import 'package:flutter/material.dart';

import '../../api/suda_api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_models.dart';
import '../../services/token_storage.dart';
import '../../utils/suda_json_util.dart';
import '../../utils/sub_screen_route.dart';
import '../../widgets/default_popup.dart';
import '../../widgets/app_scaffold.dart';
import 'announcement_detail.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final List<AppNoticeDto> _notices = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLastPage = false;
  int _currentPage = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchPage(0);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_isLastPage &&
        _notices.isNotEmpty) {
      _fetchPage(_currentPage + 1);
    }
  }

  Future<void> _fetchPage(int page) async {
    if (page == 0) {
      if (_isLoading) return;
      setState(() {
        _isLoading = true;
      });
    } else {
      if (_isLoadingMore || _isLastPage) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final accessToken = await TokenStorage.loadAccessToken();
      if (accessToken == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
            _isLastPage = true;
            _error = null;
          });
        }
        return;
      }

      _error = null;
      final pageData = await SudaApiClient.getNotices(
        accessToken: accessToken,
        page: page,
        size: 10,
      );

      if (!mounted) return;

      setState(() {
        if (page == 0) {
          _notices
            ..clear()
            ..addAll(pageData.content);
        } else {
          _notices.addAll(pageData.content);
        }
        _currentPage = page;
        _isLastPage = pageData.last;
        _isLoading = false;
        _isLoadingMore = false;
        _error = null;
      });
    } catch (e, st) {
      debugPrint('[DEBUG] Announcements fetch error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = e.toString();
      });
    }
  }

  String _formatDate(String? publishedAt) {
    if (publishedAt == null || publishedAt.isEmpty) return '';
    final dt = DateTime.tryParse(publishedAt);
    if (dt == null) return publishedAt.length >= 10 ? publishedAt.substring(0, 10) : publishedAt;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  Future<void> _onItemTap(BuildContext context, AppNoticeDto item) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    AppNoticeDto? notice;
    try {
      final accessToken = await TokenStorage.loadAccessToken();
      if (accessToken != null) {
        notice = await SudaApiClient.getNotice(
          accessToken: accessToken,
          noticeId: item.id,
        );
      }
    } catch (_) {
      // Ignore; notice stays null
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (notice == null) {
      await showAnnouncementsPostNoLongerAvailableDefaultPopup(context);
    } else {
      Navigator.push(
        context,
        SubScreenRoute(
          page: AnnouncementDetailScreen(noticeId: item.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      backgroundColor: Colors.black,
      centerTitle: l10n.settingsAnnouncements,
      body: SizedBox.expand(
        child: _buildBody(context, l10n),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_isLoading && _notices.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (_notices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? l10n.noticesEmpty,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() => _error = null);
                    _fetchPage(0);
                  },
                  child: Text(
                    'Retry',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.only(top: 12),
      itemCount: _notices.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _notices.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        }

        final item = _notices[index];
        final titleText = SudaJsonUtil.localizedText(item.title);
        final contentText = SudaJsonUtil.localizedText(item.content);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _onItemTap(context, item),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white54,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (titleText.isNotEmpty)
                    Text(
                      titleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  if (titleText.isNotEmpty && contentText.isNotEmpty)
                    const SizedBox(height: 4),
                  if (contentText.isNotEmpty)
                    Text(
                      contentText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatDate(item.publishedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white54,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> showAnnouncementsPostNoLongerAvailableDefaultPopup(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context).textTheme;
  await DefaultPopup.show(
    context,
    bodyWidget: Text(
      l10n.postNoLongerAvailable,
      style: theme.bodyLarge?.copyWith(color: Colors.white),
      textAlign: TextAlign.center,
    ),
    buttons: [
      DefaultPopupButton(
        type: DefaultPopupButtonType.primary,
        label: l10n.backToHome,
        onPressed: () {},
      ),
    ],
  );
}

Future<void> showAnnouncementsPostNoLongerAvailableDefaultPopupForLab(
  BuildContext context,
) =>
    showAnnouncementsPostNoLongerAvailableDefaultPopup(context);
