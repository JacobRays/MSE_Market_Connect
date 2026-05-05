import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/payment_settings_service.dart';
import 'package:mse_market_connect/core/services/premium_upgrade_service.dart';
import 'package:mse_market_connect/shared/models/premium_request_model.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  final _settings = PaymentSettingsService();
  final _service = PremiumUpgradeService();

  bool _loading = true;
  bool _submitting = false;

  String _instructions = 'Loading...';
  String? _loadError;

  List<PremiumRequestModel> _requests = [];

  final _amountController = TextEditingController(text: '50000');
  final _referenceController = TextEditingController();

  String? _method; // mpamba|airtel|bank
  PlatformFile? _picked;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final instr = await _settings.getPremiumInstructions();
      final reqs = await _service.getMyRequests();

      if (!mounted) return;
      setState(() {
        _instructions = instr;
        _requests = reqs;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _instructions = 'Unable to load premium instructions.\n\nReason: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickReceipt() async {
    final res = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'pdf'],
    );

    if (!mounted) return;
    if (res == null || res.files.isEmpty) return;

    setState(() => _picked = res.files.first);
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    if (_picked?.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload proof of payment')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final file = _picked!;
      final receiptPath = await _service.uploadReceipt(
        bytes: file.bytes!,
        fileName: file.name,
        contentType: file.extension == 'pdf' ? 'application/pdf' : 'image/*',
      );

      await _service.createRequest(
        amount: amount,
        receiptPath: receiptPath,
        paymentMethod: _method,
        payerReference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted. Waiting for admin approval.')),
      );

      setState(() => _picked = null);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'PENDING';
      case 'approved':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Premium')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_instructions),
                    ),
                  ),
                  if (_loadError != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.red.withValues(alpha: 0.06),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Admin tip: check RLS on payment_settings and confirm the user is logged in.',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Submit proof of payment',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _method,
                            items: const [
                              DropdownMenuItem(value: 'mpamba', child: Text('TNM Mpamba')),
                              DropdownMenuItem(value: 'airtel', child: Text('Airtel Money')),
                              DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                            ],
                            onChanged: (v) => setState(() => _method = v),
                            decoration: const InputDecoration(
                              labelText: 'Payment method (optional)',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Amount (MWK)'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _referenceController,
                            decoration: const InputDecoration(
                              labelText: 'Reference (optional)',
                              hintText: 'Transaction ID / sender name',
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _submitting ? null : _pickReceipt,
                            icon: const Icon(Icons.upload_file),
                            label: Text(
                              _picked == null
                                  ? 'Upload proof (png/jpg/pdf)'
                                  : 'Selected: ${_picked!.name}',
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              child: _submitting
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Submit for approval'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Your requests', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  if (_requests.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No upgrade requests yet.'),
                      ),
                    )
                  else
                    ..._requests.map((r) {
                      final status = r.status;
                      final label = _statusLabel(status);
                      final reason = (status == 'rejected' &&
                              r.adminNote != null &&
                              r.adminNote!.trim().isNotEmpty)
                          ? 'REJECTED — reason: ${r.adminNote}'
                          : null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: ListTile(
                            title: Text('MWK ${r.amount.toStringAsFixed(0)} • $label'),
                            subtitle: Text(
                              reason ??
                                  ((r.payerReference == null ||
                                          r.payerReference!.trim().isEmpty)
                                      ? 'Reference: —'
                                      : 'Reference: ${r.payerReference}'),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
