import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../feedback/empty_view.dart';
import '../feedback/error_view.dart';
import '../feedback/shimmer_loading.dart';

class PaginatedListView<T> extends StatefulWidget {
  final List<T> items;
  final bool isLoading;
  final bool hasNextPage;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? emptyWidget;
  final EdgeInsets padding;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.isLoading,
    required this.hasNextPage,
    required this.onRefresh,
    required this.onLoadMore,
    required this.itemBuilder,
    this.errorMessage,
    this.emptyWidget,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _scrollController = ScrollController();

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (!widget.isLoading && widget.hasNextPage) {
        widget.onLoadMore();
      }
    }
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

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.brandBlue,
      backgroundColor: AppColors.darkCard,
      child: ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        itemCount: widget.items.length + (widget.hasNextPage ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= widget.items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.brandBlue,
                  ),
                ),
              ),
            );
          }
          return widget.itemBuilder(context, widget.items[index], index);
        },
      ),
    );
  }
}
