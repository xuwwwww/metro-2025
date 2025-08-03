import 'package:flutter/material.dart';
import '../models/app_item.dart';
import 'icon_picker.dart';
import 'color_picker.dart';

typedef OnAdd = void Function(AppItem item);

class AddIconButton extends StatelessWidget {
  final OnAdd onAdd;
  AddIconButton({Key? key, required this.onAdd}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add_circle, color: Colors.teal, size: 36),
      tooltip: '新增icon/widget',
      onPressed: () async {
        final item = await showDialog<AppItem>(
          context: context,
          builder: (context) => const _AddDialog(),
        );
        if (item != null) {
          onAdd(item);
        }
      },
    );
  }
}

class _AddDialog extends StatefulWidget {
  const _AddDialog();
  @override
  State<_AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<_AddDialog> {
  final TextEditingController _controller = TextEditingController();
  IconData _icon = Icons.apps;
  Color _color = Colors.teal;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新增icon/widget'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: '輸入名稱'),
              onSubmitted: (value) => _submit(),
            ),
            const SizedBox(height: 12),
            const Text('選擇圖示'),
            IconPicker(
              selectedIcon: _icon,
              onIconSelected: (icon) => setState(() => _icon = icon),
            ),
            const SizedBox(height: 12),
            const Text('選擇顏色'),
            SimpleColorPicker(
              selectedColor: _color,
              onColorSelected: (color) => setState(() => _color = color),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('新增')),
      ],
    );
  }

  void _submit() {
    if (_controller.text.trim().isNotEmpty) {
      Navigator.pop(
        context,
        AppItem(name: _controller.text.trim(), icon: _icon, color: _color),
      );
    }
  }
}
