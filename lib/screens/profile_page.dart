import 'dart:io' show File;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/services/session_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.session});

  final SessionController session;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _bioController;
  late Future<List<Itinerary>> _itinerariesFuture;
  bool _savingBio = false;
  bool _pickingAvatar = false;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.session.bio ?? '');
    _itinerariesFuture = widget.session.itineraries();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  String _initials() {
    final username = widget.session.username?.trim() ?? '';
    if (username.isEmpty) {
      return '?';
    }
    final parts = username.split(RegExp(r'[\s._-]+')).where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _formatMemberSince(BuildContext context, AppLocalizations l10n) {
    final date = widget.session.memberSince;
    if (date == null) {
      return l10n.memberSinceDevice;
    }
    final localeName = Localizations.localeOf(context).languageCode;
    return l10n.memberSince(DateFormat.yMMM(localeName).format(date));
  }

  Future<void> _pickAvatar() async {
    setState(() => _pickingAvatar = true);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 900, imageQuality: 85);
      if (picked != null) {
        await widget.session.updateAvatarPath(picked.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.couldNotPickImage(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _pickingAvatar = false);
    }
  }

  Future<void> _saveBio() async {
    setState(() => _savingBio = true);
    try {
      await widget.session.updateBio(_bioController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.bioUpdatedSnackbar)),
      );
    } finally {
      if (mounted) setState(() => _savingBio = false);
    }
  }

  Widget _glassPanel({required Widget child, EdgeInsets? padding, BorderRadius? borderRadius}) {
    final radius = borderRadius ?? BorderRadius.circular(18);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildAvatarImage() {
    final path = widget.session.avatarPath;
    if (path == null || path.isEmpty) {
      return Center(
        child: Text(
          _initials(),
          style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.w800),
        ),
      );
    }
    if (kIsWeb) {
      return Image.network(path, fit: BoxFit.cover);
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }

  Widget _buildAvatar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _pickingAvatar ? null : _pickAvatar,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [colors.primary, colors.tertiary]),
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 3),
            ),
            child: ClipOval(
              child: _pickingAvatar
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : _buildAvatarImage(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: colors.primary, width: 2),
              ),
              child: Icon(Icons.camera_alt, size: 15, color: colors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11.5), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitcher(BuildContext context, AppLocalizations l10n) {
    final effective = (widget.session.locale?.languageCode ?? Localizations.localeOf(context).languageCode) == 'fr'
        ? 'fr'
        : 'en';
    final colors = Theme.of(context).colorScheme;
    return _glassPanel(
      borderRadius: BorderRadius.circular(22),
      child: Row(
        children: [
          const Icon(Icons.language, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.languageLabel,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
              ButtonSegment(value: 'fr', label: Text(l10n.languageFrench)),
            ],
            selected: {effective},
            onSelectionChanged: (selection) {
              widget.session.setLocale(Locale(selection.first));
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              foregroundColor: Colors.white70,
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: colors.primary.withValues(alpha: 0.85),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _glassPanel(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: [
                  _buildAvatar(context),
                  const SizedBox(height: 14),
                  Text(
                    widget.session.username ?? l10n.travellerFallback,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                  if ((widget.session.email ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(widget.session.email!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildInfoPill(Icons.calendar_today, _formatMemberSince(context, l10n)),
                      _buildInfoPill(Icons.location_on, l10n.basedInYaounde),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      FutureBuilder<List<Itinerary>>(
                        future: _itinerariesFuture,
                        builder: (context, snapshot) {
                          final count = snapshot.data?.length;
                          return _buildStatTile(
                            icon: Icons.map,
                            label: l10n.itinerariesStatLabel,
                            value: count?.toString() ?? '—',
                          );
                        },
                      ),
                      _buildStatTile(icon: Icons.explore, label: l10n.regionStatLabel, value: 'Yaoundé'),
                      _buildStatTile(icon: Icons.favorite, label: l10n.featuredSpotsStatLabel, value: '4'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _glassPanel(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.aboutMeTitle,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: l10n.bioHint,
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _savingBio ? null : _saveBio,
                      icon: _savingBio
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(l10n.saveButton),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildLanguageSwitcher(context, l10n),
            const SizedBox(height: 16),
            _glassPanel(
              borderRadius: BorderRadius.circular(22),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.signedInAs(widget.session.username ?? l10n.unknownUser),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => widget.session.logout(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    icon: const Icon(Icons.logout, size: 18),
                    label: Text(l10n.logoutButton),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill(IconData icon, String label) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
