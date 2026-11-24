import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../feedback/empty_view.dart';
import '../feedback/error_view.dart';
import '../feedback/shimmer_loading.dart';

class SliverPaginatedView<T> extends StatefulWidget {
  final List<T> items;
  final bool isLoading;
  final bool hasNextPage;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? emptyWidget;
  final bool isGrid;
  final int gridCrossAxisCount;
  final double gridChildAspectRatio;
  final EdgeInsets padding;

  const SliverPaginatedView({
    super.key,
    required this.items,
    required this.isLoading,
    required this.hasNextPage,
    required this.onRefresh,
    required this.onLoadMore,
    required this.itemBuilder,
    this.emptyWidget,
    this.errorMessage,
    this.isGrid = true,
    this.gridCrossAxisCount = 3,
    this.gridChildAspectRatio = 0.58,
    this.padding = const EdgeInsets.all(AppSpacing.p16),
  });

  @override
  State<SliverPaginatedView<T>> createState() => _SliverPaginatedViewState<T>();
}

class _SliverPaginatedViewState<T> extends State<SliverPaginatedView<T>> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show / Hide scroll to top button
    if (_scrollController.offset > 400 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 400 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }

    // Prefetch at 80% scroll depth
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0 && currentScroll >= maxScroll * 0.8) {
      if (!widget.isLoading && widget.hasNextPage) {
        widget.onLoadMore();
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.errorMessage != null && widget.items.isEmpty) {
      return ErrorView(
        message: widget.errorMessage!,
        onRetry: widget.onRefresh,
      );
    }

    if (widget.isLoading && widget.items.isEmpty) {
      return const ShimmerMediaGrid(count: 9);
    }

    if (widget.items.isEmpty) {
      return widget.emptyWidget ?? const EmptyView();
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: widget.onRefresh,
          color: AppColors.brandBlue,
          backgroundColor: AppColors.darkCard,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: widget.padding,
                sliver: widget.isGrid
                    ? SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: widget.gridCrossAxisCount,
                          childAspectRatio: widget.gridChildAspectRatio,
                          crossAxisSpacing: AppSpacing.p12,
                          mainAxisSpacing: AppSpacing.p16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => widget.itemBuilder(context, widget.items[index], index),
                          childCount: widget.items.length,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.p12),
                            child: widget.itemBuilder(context, widget.items[index], index),
                          ),
                          childCount: widget.items.length,
                        ),
                      ),
              ),

              // Bottom Loader / Inline Retry
              if (widget.hasNextPage)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: widget.errorMessage != null
                          ? TextButton.icon(
                              onPressed: widget.onLoadMore,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Failed to load more. Tap to retry'),
                            )
                          : const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.brandBlue,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Floating Scroll-To-Top Button
        if (_showScrollToTop)
          Positioned(
            right: 20,
            bottom: 24,
            child: FloatingActionButton.small(
              onPressed: _scrollToTop,
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.keyboard_arrow_up_rounded, size: 24),
            ),
          ),
      ],
    );
  }
}
