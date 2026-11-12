import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/news_service.dart';
import '../core/services/scraper_service.dart';
import '../core/services/user_prefs_service.dart';
import '../core/theme/app_theme.dart';

class NewsView extends StatefulWidget {
  const NewsView({super.key});

  @override
  State<NewsView> createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {
  bool _isLoading = true;
  List<NewsArticle> _articles = [];
  List<String> _filters = ['Football'];
  String _selectedFilter = 'Football';

  @override
  void initState() {
    super.initState();
    _initNews();
  }

  Future<void> _initNews() async {
    final favTeams = await UserPrefsService.getFavoriteTeams();
    setState(() {
      _filters = ['Football', ...favTeams];
    });
    await _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    final list = await NewsService.getSportsNews(keywords: _selectedFilter);
    setState(() {
      _articles = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // شريط فلترة الأخبار حسب فرقك المفضلة
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tag = _filters[index];
              final active = tag == _selectedFilter;
              return ChoiceChip(
                label: Text(tag),
                selected: active,
                selectedColor: AppTheme.accentCyan.withOpacity(0.18),
                backgroundColor: AppTheme.surfaceCard,
                side: BorderSide(
                  color: active ? AppTheme.accentCyan : AppTheme.borderSubtle,
                ),
                labelStyle: TextStyle(
                  color: active ? AppTheme.accentCyan : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedFilter = tag);
                  _loadArticles();
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // قائمة الأخبار
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentCyan),
                )
              : _articles.isEmpty
                  ? const Center(
                      child: Text(
                        'No news articles found for this topic.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppTheme.accentCyan,
                      onRefresh: _loadArticles,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _articles.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final article = _articles[index];
                          return GestureDetector(
                            onTap: () => _showArticleSheet(context, article),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          article.source.toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.9,
                                            color: AppTheme.accentCyan,
                                          ),
                                        ),
                                      ),
                                      if (article.publishedAt.length >= 10)
                                        Text(
                                          article.publishedAt.substring(0, 10),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    article.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                      height: 1.35,
                                    ),
                                  ),
                                  if (article.description.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      article.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  void _showArticleSheet(BuildContext context, NewsArticle article) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              article.source.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: AppTheme.accentCyan,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            if (article.description.isNotEmpty) ...[
              Text(
                article.description,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
              const Divider(color: AppTheme.borderSubtle, height: 28),
            ],

            // سحب وعرض نص المقال الكامل عبر ScrapeStack
            FutureBuilder<String?>(
              future: ScraperService.extractReadableArticle(article.url),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accentEmerald,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Extracting full article via ScrapeStack...',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final fullBody = snapshot.data;
                if (fullBody == null || fullBody.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Text(
                  fullBody,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.textSecondary,
                    height: 1.65,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
