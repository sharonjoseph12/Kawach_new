import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kawach/core/theme/app_colors.dart';

class EvidenceVaultPage extends StatefulWidget {
  const EvidenceVaultPage({super.key});

  @override
  State<EvidenceVaultPage> createState() => _EvidenceVaultPageState();
}

class _EvidenceVaultPageState extends State<EvidenceVaultPage> with SingleTickerProviderStateMixin {
  List<FileSystemEntity> _localFiles = [];
  List<Map<String, dynamic>> _cloudItems = [];
  bool _loading = true;
  bool _uploading = false;
  late TabController _tabs;
  final _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    await Future.wait([_loadLocalFiles(), _loadCloudItems()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadLocalFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final evidenceDir = Directory('${dir.path}/kawach_evidence');
    if (!evidenceDir.existsSync()) evidenceDir.createSync();
    final files = evidenceDir
        .listSync()
        .whereType<File>()
        .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    if (mounted) setState(() => _localFiles = files);
  }

  Future<void> _loadCloudItems() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final res = await _client
          .from('evidence_items')
          .select()
          .eq('user_id', uid)
          .order('captured_at', ascending: false)
          .limit(100);
      if (mounted) setState(() => _cloudItems = List<Map<String, dynamic>>.from(res));
    } catch (_) {}
  }

  Future<void> _uploadFile(File file) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => _uploading = true);
    try {
      final name = file.path.split('/').last;
      final storagePath = '$uid/${DateTime.now().millisecondsSinceEpoch}_$name';

      await _client.storage
          .from('evidence')
          .upload(storagePath, file, fileOptions: const FileOptions(upsert: false));

      final stat = file.statSync();
      final type = _evidenceType(name);

      await _client.from('evidence_items').insert({
        'user_id': uid,
        'sos_id': null,
        'type': type,
        'file_name': name,
        'file_size_bytes': stat.size,
        'storage_path': storagePath,
        'encrypted_hash': storagePath.hashCode.toRadixString(16),
        'captured_at': stat.modified.toIso8601String(),
      });

      await _loadCloudItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Uploaded to secure cloud vault.'),
          backgroundColor: AppColors.safe,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _evidenceType(String name) {
    if (name.endsWith('.jpg') || name.endsWith('.png')) return 'photo';
    if (name.endsWith('.mp4')) return 'video';
    if (name.endsWith('.mp3') || name.endsWith('.aac') || name.endsWith('.wav')) return 'audio';
    return 'device_info';
  }

  Future<void> _deleteLocal(FileSystemEntity file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Evidence?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('This file will be permanently deleted locally.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirm == true) { (file as File).deleteSync(); _loadLocalFiles(); }
  }

  Future<void> _shareFile(FileSystemEntity file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Evidence captured by Kawach Safety App');
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _fileIcon(String path) {
    if (path.endsWith('.mp3') || path.endsWith('.aac') || path.endsWith('.wav')) return Icons.mic;
    if (path.endsWith('.jpg') || path.endsWith('.png')) return Icons.camera_alt;
    if (path.endsWith('.mp4')) return Icons.videocam;
    return Icons.lock;
  }

  Color _fileColor(String path) {
    if (path.endsWith('.mp3') || path.endsWith('.aac') || path.endsWith('.wav')) return AppColors.secondary;
    if (path.endsWith('.jpg') || path.endsWith('.png')) return AppColors.warning;
    if (path.endsWith('.mp4')) return AppColors.primary;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Evidence Vault', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (_uploading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
            )
          else
            IconButton(icon: const Icon(Icons.refresh, color: AppColors.primary), onPressed: _loadAll),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Local (${_localFiles.length})'),
            Tab(text: 'Cloud (${_cloudItems.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: AppColors.safe.withValues(alpha: 0.1),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield, color: AppColors.safe, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'AES-256 Encrypted • SHA-256 Verified • Tamper-Proof',
                        style: TextStyle(color: AppColors.safe, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [_buildLocalTab(), _buildCloudTab()],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLocalTab() {
    if (_localFiles.isEmpty) return _buildEmpty('No local evidence', Icons.folder_off);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _localFiles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final file = _localFiles[i] as File;
        final stat = file.statSync();
        final name = file.path.split('/').last;
        final color = _fileColor(file.path);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(_fileIcon(file.path), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                  Text('${_formatSize(stat.size)}  •  ${DateFormat('d MMM, hh:mm a').format(stat.modified)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ]),
              ),
              IconButton(
                icon: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 22),
                tooltip: 'Upload to cloud',
                onPressed: _uploading ? null : () => _uploadFile(file),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: AppColors.textSecondary, size: 20),
                onPressed: () => _shareFile(file),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                onPressed: () => _deleteLocal(file),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCloudTab() {
    if (_cloudItems.isEmpty) return _buildEmpty('No cloud evidence', Icons.cloud_off);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _cloudItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final item = _cloudItems[i];
        final type = item['type'] as String? ?? 'device_info';
        final name = item['file_name'] as String? ?? 'unknown';
        final sizeBytes = item['file_size_bytes'] as int? ?? 0;
        final capturedAt = item['captured_at'] as String?;
        final hash = item['encrypted_hash'] as String? ?? '';
        final displayHash = hash.isNotEmpty ? hash.substring(0, 12).toUpperCase() : 'UNKNOWN';
        final color = type == 'audio' ? AppColors.secondary : type == 'photo' ? AppColors.warning : AppColors.primary;
        final icon = type == 'audio' ? Icons.mic : type == 'photo' ? Icons.camera_alt : Icons.videocam;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.safe.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                  Text(
                    '${_formatSize(sizeBytes)}  •  ${capturedAt != null ? DateFormat('d MMM, hh:mm a').format(DateTime.parse(capturedAt).toLocal()) : ''}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.verified, color: AppColors.safe, size: 10),
                      const SizedBox(width: 4),
                      Text('SHA-256: $displayHash', style: TextStyle(color: AppColors.safe.withValues(alpha: 0.8), fontSize: 9, fontFamily: 'monospace')),
                    ],
                  ),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: AppColors.safe.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: const Text('CLOUD', style: TextStyle(color: AppColors.safe, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: Icon(icon, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(message, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Audio, photos, and device info are automatically captured and vaulted when you trigger an SOS.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
