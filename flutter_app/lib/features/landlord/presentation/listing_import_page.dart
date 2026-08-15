import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';

class ListingImportPage extends ConsumerStatefulWidget {
  const ListingImportPage({super.key});

  @override
  ConsumerState<ListingImportPage> createState() => _ListingImportPageState();
}

class _ListingImportPageState extends ConsumerState<ListingImportPage> {
  Map<String, dynamic>? _preview;
  var _busy = false;

  Future<void> _pickAndPreview() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read CSV bytes')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final text = utf8.decode(bytes);
      final preview = await ref.read(mobileApiRepositoryProvider).previewListingImport(
            csvText: text,
            filename: file.name,
          );
      setState(() => _preview = preview);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _execute() async {
    final preview = _preview;
    if (preview == null) return;
    final rows = preview['rows'];
    if (rows is! List || rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid rows to import')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await ref.read(mobileApiRepositoryProvider).executeListingImport(
            filename: '${preview['filename'] ?? 'import.csv'}',
            rows: rows.cast<dynamic>().map((e) => Map<String, dynamic>.from(e as Map)).toList(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${res['imported']} · failed ${res['failed']}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _preview;
    return Scaffold(
      appBar: AppBar(title: const Text('CSV import')),
      body: ListView(
        padding: const EdgeInsets.all(NyumbaTokens.space6),
        children: [
          const Text(
            'Upload a CSV of listings. Rows import as inactive drafts for review.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _pickAndPreview,
            icon: const Icon(Icons.upload_file),
            label: const Text('Choose CSV'),
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (p != null) ...[
            const SizedBox(height: 24),
            Text('Total rows: ${p['totalRows']}'),
            Text('Valid: ${p['validCount']} · Errors: ${p['errorCount']} · Dupes: ${p['duplicateCount']}'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _execute,
              child: const Text('Import valid rows'),
            ),
          ],
        ],
      ),
    );
  }
}
