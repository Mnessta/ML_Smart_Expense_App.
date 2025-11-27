import 'package:flutter/material.dart';

class QuickAddTemplate {
  const QuickAddTemplate({
    required this.label,
    required this.amount,
    required this.category,
    this.icon = Icons.add,
  });

  final String label;
  final double amount;
  final String category;
  final IconData icon;
}

class QuickAddTemplates extends StatefulWidget {
  const QuickAddTemplates({super.key, required this.onTemplateSelected});

  final Function(QuickAddTemplate) onTemplateSelected;

  @override
  State<QuickAddTemplates> createState() => _QuickAddTemplatesState();
}

class _QuickAddTemplatesState extends State<QuickAddTemplates> {
  static const List<QuickAddTemplate> _defaults = <QuickAddTemplate>[
    QuickAddTemplate(
      label: 'Coffee',
      amount: 5.0,
      category: 'Food',
      icon: Icons.coffee,
    ),
    QuickAddTemplate(
      label: 'Matatu',
      amount: 2.0,
      category: 'Transport',
      icon: Icons.directions_bus,
    ),
    QuickAddTemplate(
      label: 'Lunch',
      amount: 10.0,
      category: 'Food',
      icon: Icons.lunch_dining,
    ),
    QuickAddTemplate(
      label: 'Snacks',
      amount: 3.0,
      category: 'Food',
      icon: Icons.fastfood,
    ),
  ];

  late List<QuickAddTemplate> _templates;

  @override
  void initState() {
    super.initState();
    _templates = List<QuickAddTemplate>.from(_defaults);
  }

  void _handleClear(QuickAddTemplate template) {
    setState(() {
      _templates.removeWhere(
        (t) => t.label == template.label && t.category == template.category,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Quick Add',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemCount: _templates.length,
            itemBuilder: (BuildContext context, int index) {
              final QuickAddTemplate template = _templates[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onLongPress: () async {
                    final bool? confirmClear = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Remove ${template.label}?'),
                          content: const Text(
                            'Hold for a second to confirm clearing this shortcut.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Clear',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                    if (confirmClear == true) {
                      _handleClear(template);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${template.label} removed from Quick Add',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: InkWell(
                    onTap: () => widget.onTemplateSelected(template),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            template.icon,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              template.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
