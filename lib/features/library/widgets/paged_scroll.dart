import 'package:flutter/material.dart';

/// Fires [onLoadMore] when the user scrolls close to the end of the list.
class PagedScrollListener extends StatelessWidget {
  const PagedScrollListener({
    super.key,
    required this.child,
    required this.onLoadMore,
  });

  final Widget child;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.maxScrollExtent > 0 &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 600) {
          onLoadMore();
        }
        return false;
      },
      child: child,
    );
  }
}

/// Trailing slot of a paged list: spinner while loading, retry on failure.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({
    super.key,
    required this.isLoading,
    required this.failed,
    required this.onRetry,
  });

  final bool failed;
  final bool isLoading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (failed) {
      return Center(
        child: TextButton(
          onPressed: onRetry,
          child: const Text('Falha ao carregar — tentar novamente'),
        ),
      );
    }

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
