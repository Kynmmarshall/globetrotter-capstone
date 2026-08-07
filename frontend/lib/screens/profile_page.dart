import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/screens/avatar_cropper_page.dart';
import 'package:trip_io/services/api_client.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/widgets/glass_panel.dart';
import 'package:trip_io/widgets/interest_tag_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.session});

  final SessionController session;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _bioController;
  late Future<List<Itinerary>> _itinerariesFuture;
  late Future<List<Destination>> _favoritesFuture;
  late Set<String> _selectedInterests;
  bool _savingBio = false;
  bool _pickingAvatar = false;
  bool _savingInterests = false;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.session.bio ?? '');
    _itinerariesFuture = widget.session.itineraries();
    _favoritesFuture = widget.session.favorites();
    _selectedInterests = widget.session.interests.toSet();
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
    final parts = username
        .split(RegExp(r'[\s._-]+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
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
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        final cropped = await Navigator.of(context).push<Uint8List>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => AvatarCropperPage(imageBytes: bytes),
          ),
        );
        if (cropped != null) {
          await widget.session.updateAvatar(cropped, 'avatar.png');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.couldNotPickImage(e.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _pickingAvatar = false);
    }
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: Text(l10n.logoutButton),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.session.logout();
  }

  Future<void> _saveBio() async {
    setState(() => _savingBio = true);
    try {
      await widget.session.updateBio(_bioController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.bioUpdatedSnackbar),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingBio = false);
    }
  }

  Future<void> _saveInterests() async {
    setState(() => _savingInterests = true);
    try {
      await widget.session.updateInterests(_selectedInterests.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.interestsUpdatedSnackbar),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _savingInterests = false);
    }
  }

  Widget _buildAvatarImage() {
    final url = ApiClient.resolveAssetUrl(widget.session.avatarUrl);
    if (url == null || url.isEmpty) {
      return Center(
        child: Text(
          _initials(),
          style: const TextStyle(
            fontSize: 30,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Text(
          _initials(),
          style: const TextStyle(
            fontSize: 30,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l10n.avatarSemanticLabel,
      child: GestureDetector(
        onTap: _pickingAvatar ? null : _pickAvatar,
        child: Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [colors.primary, colors.tertiary],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: _pickingAvatar
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
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
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsPanel(BuildContext context, AppLocalizations l10n) {
    return GlassPanel(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.interestsLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.interestsHelper,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          InterestTagPicker(
            selectedTags: _selectedInterests,
            onToggle: (tag, value) {
              setState(() {
                if (value) {
                  _selectedInterests.add(tag);
                } else {
                  _selectedInterests.remove(tag);
                }
              });
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _savingInterests ? null : _saveInterests,
              icon: _savingInterests
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(l10n.saveButton),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitcher(BuildContext context, AppLocalizations l10n) {
    final effective =
        (widget.session.locale?.languageCode ??
                Localizations.localeOf(context).languageCode) ==
            'fr'
        ? 'fr'
        : 'en';
    final colors = Theme.of(context).colorScheme;
    return GlassPanel(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.language, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.languageLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
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

  Widget _buildThemeSwitcher(BuildContext context, AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;
    return GlassPanel(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.brightness_6, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.themeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.themeSystem),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.themeLight),
              ),
              ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark)),
            ],
            selected: {widget.session.themeMode},
            onSelectionChanged: (selection) {
              widget.session.setThemeMode(selection.first);
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassPanel(
                borderRadius: BorderRadius.circular(22),
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _buildAvatar(context),
                    const SizedBox(height: 14),
                    Text(
                      widget.session.username ?? l10n.travellerFallback,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    if ((widget.session.email ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.session.email!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildInfoPill(
                          Icons.calendar_today,
                          _formatMemberSince(context, l10n),
                        ),
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
                        FutureBuilder<List<Destination>>(
                          future: _favoritesFuture,
                          builder: (context, snapshot) {
                            final count = snapshot.data?.length;
                            return _buildStatTile(
                              icon: Icons.favorite,
                              label: l10n.favoritesStatLabel,
                              value: count?.toString() ?? '—',
                            );
                          },
                        ),
                        FutureBuilder<List<Itinerary>>(
                          future: _itinerariesFuture,
                          builder: (context, snapshot) {
                            final places = snapshot.data
                                ?.expand((i) => i.destinations)
                                .toSet()
                                .length;
                            return _buildStatTile(
                              icon: Icons.explore,
                              label: l10n.placesPlannedStatLabel,
                              value: places?.toString() ?? '—',
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassPanel(
                borderRadius: BorderRadius.circular(22),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aboutMeTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
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
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: Text(l10n.saveButton),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildInterestsPanel(context, l10n),
              const SizedBox(height: 16),
              _buildLanguageSwitcher(context, l10n),
              const SizedBox(height: 16),
              _buildThemeSwitcher(context, l10n),
              const SizedBox(height: 16),
              GlassPanel(
                borderRadius: BorderRadius.circular(22),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.signedInAs(
                          widget.session.username ?? l10n.unknownUser,
                        ),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _confirmLogout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
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
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
