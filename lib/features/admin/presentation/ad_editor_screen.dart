import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/admin_ad_service.dart';
import 'package:mse_market_connect/shared/models/ad_model.dart';

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

  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ad = widget.existing;
    if (ad != null) {
      _title.text = ad.title;
      _subtitle.text = ad.subtitle ?? '';
      _imageUrl.text = ad.imageUrl ?? '';
      _actionUrl.text = ad.actionUrl ?? '';
      _priority.text = ad.priority.toString();
      _isActive = ad.isActive;
    } else {
      _priority.text = '0';
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

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    final pr = int.tryParse(_priority.text.trim()) ?? 0;

    setState(() => _saving = true);
    try {
      await _service.upsertAd(
        id: widget.existing?.id,
        title: _title.text.trim(),
        subtitle: _subtitle.text.trim().isEmpty ? null : _subtitle.text.trim(),
        imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
        actionUrl: _actionUrl.text.trim().isEmpty ? null : _actionUrl.text.trim(),
        isActive: _isActive,
        priority: pr,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save ad: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.existing?.id;
    if (id == null) return;

    setState(() => _saving = true);
    try {
      await _service.deleteAd(id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete ad: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Advert' : 'New Advert')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _title,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _subtitle,
                        decoration: const InputDecoration(labelText: 'Subtitle (optional)'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _imageUrl,
                        decoration: const InputDecoration(
                          labelText: 'Image URL (optional)',
                          hintText: 'https://...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _actionUrl,
                        decoration: const InputDecoration(
                          labelText: 'Action URL (optional)',
                          hintText: 'https://...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _priority,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Priority (higher = first)'),
                      ),
                      const SizedBox(height: 6),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        title: const Text('Active'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
              if (isEdit) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _saving ? null : _delete,
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
