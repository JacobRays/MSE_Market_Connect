import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/shared/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KycStatusScreen extends StatefulWidget {
  final ProfileModel profile;
  const KycStatusScreen({super.key, required this.profile});

  @override
  State<KycStatusScreen> createState() => _KycStatusScreenState();
}

class _KycStatusScreenState extends State<KycStatusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idNumberCtrl = TextEditingController();
  String? _selectedIdType = 'national_id';
  File? _frontImage;
  File? _backImage;
  bool _submitting = false;

  final _picker = ImagePicker();

  Future<void> _pickImage(bool isFront) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isFront) {
          _frontImage = File(picked.path);
        } else {
          _backImage = File(picked.path);
        }
      });
    }
  }

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;
    if (_frontImage == null || _backImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both front and back images')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final userId = widget.profile.id;
      final storage = Supabase.instance.client.storage;
      await storage.from('kyc_docs').upload(
        '$userId/front.jpg', _frontImage!,
        fileOptions: const FileOptions(upsert: true),
      );
      await storage.from('kyc_docs').upload(
        '$userId/back.jpg', _backImage!,
        fileOptions: const FileOptions(upsert: true),
      );
      await Supabase.instance.client.from('profiles').update({
        'kyc_status': 'pending',
        'kyc_details': {
          'id_type': _selectedIdType,
          'id_number': _idNumberCtrl.text.trim(),
          'front_url': '$userId/front.jpg',
          'back_url': '$userId/back.jpg',
        },
      }).eq('id', userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KYC submitted for review')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kyc = widget.profile.kycStatus;
    final status = (kyc ?? 'pending').toLowerCase();
    final alreadySubmitted = status == 'pending' || status == 'approved' || status == 'rejected';

    return Scaffold(
      appBar: AppBar(title: const Text('KYC Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (alreadySubmitted)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: status == 'approved'
                        ? AppTheme.gainColor.withValues(alpha: 0.1)
                        : status == 'rejected'
                            ? AppTheme.lossColor.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        status == 'approved' ? Icons.verified : Icons.info,
                        color: status == 'approved' ? AppTheme.gainColor : AppTheme.lossColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          status == 'approved'
                              ? 'Your identity is verified.'
                              : status == 'rejected'
                                  ? 'Verification rejected. Please re-submit.'
                                  : 'Verification in progress.',
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text('ID Type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedIdType,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'national_id', child: Text('National ID')),
                  DropdownMenuItem(value: 'passport', child: Text('Passport')),
                  DropdownMenuItem(value: 'drivers_license', child: Text("Driver's License")),
                ],
                onChanged: (v) => setState(() => _selectedIdType = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _idNumberCtrl,
                decoration: const InputDecoration(labelText: 'ID Number', border: OutlineInputBorder()),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              Text('Upload ID Images', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage(true),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                          image: _frontImage != null
                              ? DecorationImage(image: FileImage(_frontImage!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _frontImage == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [Icon(Icons.add_a_photo), Text('Front')],
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage(false),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                          image: _backImage != null
                              ? DecorationImage(image: FileImage(_backImage!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _backImage == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [Icon(Icons.add_a_photo), Text('Back')],
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitKyc,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit for Verification'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
