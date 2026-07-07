import 'package:flutter/material.dart';

import '../../../domain/enums.dart';

class SortOption<S> {
  const SortOption(this.value, this.label);

  final String label;
  final S value;
}

class SortSelection<S> {
  const SortSelection({required this.sortBy, required this.sortOrder});

  final S sortBy;
  final SortOrder sortOrder;
}

/// Bottom sheet with the sort fields for a list plus an asc/desc toggle.
Future<SortSelection<S>?> showSortSheet<S>({
  required BuildContext context,
  required List<SortOption<S>> options,
  required S current,
  required SortOrder currentOrder,
}) {
  return showModalBottomSheet<SortSelection<S>>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          SwitchListTile(
            title: const Text('Decrescente'),
            value: currentOrder == SortOrder.desc,
            onChanged: (desc) => Navigator.of(context).pop(
              SortSelection(
                sortBy: current,
                sortOrder: desc ? SortOrder.desc : SortOrder.asc,
              ),
            ),
          ),
          const Divider(height: 1),
          for (final option in options)
            ListTile(
              title: Text(option.label),
              trailing: option.value == current
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.of(context).pop(
                SortSelection(sortBy: option.value, sortOrder: currentOrder),
              ),
            ),
        ],
      ),
    ),
  );
}
