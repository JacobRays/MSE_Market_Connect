import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/admin_ad_service.dart';
import 'package:mse_market_connect/shared/models/ad_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AdEditorScreen extends StatefulWidget {
  final AdModel? existing;
  const AdEditorScreen({super.key, this.existing});

  @override
  State<AdEditorScreen> createState() => _AdEditorScreenState();
}

class _AdEditorScreenState extends State<AdEditorScreen> {
  final _service = AdminAdService();

  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _imageUrl = TextEditingController();
  final _actionUrl = TextEditingController();
  final _priority = TextEditingController();

  bool _active = true;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      _subtitle.text = e.subtitle ?? '';
      _imageUrl.text = e.imageUrl ?? '';
      _actionUrl.text = e.actionUrl ?? '';
      _priority.text = e.priority.toString();
      _active = e.isActive;
    } else {
      _priority.text = '0';
      _active = true;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _imageUrl.dispose();
    _actionUrl.dispose();
    _priority.dispose();
    super.dispose();
  }

  int _parsePriority() => int.tryParse(_priority.text.trim()) ?? 0;

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    setState(() => _saving = true);
    try {
      final subtitle = _subtitle.text.trim();
      final imageUrl = _imageUrl.text.trim();
      final actionUrl = _actionUrl.text.trim();
      final priority = _parsePriority();

      final e = widget.existing;
      if (e == null) {
        await _service.createAd(
          title: title,
          subtitle: subtitle.isEmpty ? null : subtitle,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          actionUrl: actionUrl.isEmpty ? null : actionUrl,
          isActive: _active,
          priority: priority,
        );
      } else {
        await _service.updateAd(
          id: e.id,
          title: title,
          subtitle: subtitle.isEmpty ? null : subtitle,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          actionUrl: actionUrl.isEmpty ? null : actionUrl,
          isActive: _active,
          priority: priority,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final e = widget.existing;
    if (e == null) return;

    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete advert?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    setState(() => _deleting = true);
    try {
      await _service.deleteAd(e.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $err')));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _imageUrl.text.trim();
    final act = _actionUrl.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New Advert' : 'Edit Advert'),
        actions: [
          if (widget.existing != null)
            IconButton(
              tooltip: 'Delete',
              onPressed: (_saving || _deleting) ? null : _delete,
              icon: _deleting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
            ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (img.isNotEmpty)
            Card(
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                img,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Image preview failed. Check the URL.'),
                ),
              ),
            ),
          if (img.isNotEmpty) const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Title'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subtitle,
                    decoration: const InputDecoration(
                      labelText: 'Subtitle (optional)',
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _imageUrl,
                    decoration: const InputDecoration(
                      labelText: 'Image URL (https://...)',
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _actionUrl,
                    decoration: const InputDecoration(
                      labelText: 'Action URL (optional)',
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority (higher shows first)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                  if (act.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => launchUrl(Uri.parse(act)),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Test Action URL'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
