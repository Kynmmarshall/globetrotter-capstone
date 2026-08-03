import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/interest_tags.dart';
import 'package:trip_io/screens/location_picker_page.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/widgets/glass_panel.dart';

/// Lets any signed-in user propose a new destination. It never touches the
/// live catalog directly - the backend stores it with status="pending" and
/// it only becomes visible to everyone once an admin approves it in the
/// website dashboard (see trip_io_backend/website/admin.html).
class SubmitDestinationPage extends StatefulWidget {
  const SubmitDestinationPage({super.key, required this.session});

  final SessionController session;

  @override
  State<SubmitDestinationPage> createState() => _SubmitDestinationPageState();
}

class _SubmitDestinationPageState extends State<SubmitDestinationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _submitting = false;
  bool _pickingImage = false;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  double? _lat;
  double? _lon;

  static const double _backgroundBreakpoint = 700;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  Future<void> _pickImage() async {
    setState(() => _pickingImage = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 88,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedImage = picked;
          _pickedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<({double lat, double lon})>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(initialLat: _lat, initialLon: _lon),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _lat = result.lat;
        _lon = result.lon;
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    try {
      final created = await widget.session.submitDestination(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        lat: _lat,
        lon: _lon,
        tags: _selectedTags.toList(),
      );

      // The destination proposal itself already succeeded at this point -
      // an image upload failure is reported separately rather than made to
      // look like the whole submission failed, since it didn't.
      final image = _pickedImage;
      final imageBytes = _pickedImageBytes;
      String? imageError;
      if (image != null && imageBytes != null) {
        try {
          await widget.session.uploadDestinationImage(
            created.id,
            imageBytes,
            image.name,
          );
        } catch (e) {
          imageError = e.toString().replaceFirst('Exception: ', '');
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imageError == null
                ? l10n.submitDestinationSuccess
                : l10n.submitDestinationSuccessImageFailed(imageError),
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
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
    );
  }

  Widget _buildLocationPicker(AppLocalizations l10n) {
    final hasPoint = _lat != null && _lon != null;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _pickLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(
              hasPoint ? Icons.place : Icons.add_location_alt_outlined,
              size: 18,
              color: Colors.white70,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasPoint
                    ? l10n.submitDestinationLocationPickedLabel(
                        _lat!.toStringAsFixed(5),
                        _lon!.toStringAsFixed(5),
                      )
                    : l10n.submitDestinationLocationPickButton,
                style: TextStyle(
                  color: hasPoint ? Colors.white : Colors.white60,
                  fontSize: 13.5,
                  fontWeight: hasPoint ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (hasPoint)
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.white54),
                onPressed: () => setState(() {
                  _lat = null;
                  _lon = null;
                }),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(AppLocalizations l10n) {
    final bytes = _pickedImageBytes;
    return InkWell(
      onTap: _pickingImage ? null : _pickImage,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: _pickingImage
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              )
            : bytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(bytes, fit: BoxFit.cover),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 18,
                        color: Colors.white,
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _pickedImage = null;
                          _pickedImageBytes = null;
                        }),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.white54,
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.submitDestinationAddPhoto,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompactBackground =
              constraints.maxWidth < _backgroundBreakpoint;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                isCompactBackground
                    ? 'assets/backgrounds/mobile.png'
                    : 'assets/backgrounds/pc.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                GlassPanel(
                                  borderRadius: BorderRadius.circular(999),
                                  padding: EdgeInsets.zero,
                                  child: IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                    tooltip: MaterialLocalizations.of(
                                      context,
                                    ).backButtonTooltip,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GlassPanel(
                              borderRadius: BorderRadius.circular(22),
                              padding: const EdgeInsets.all(18),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.add_location_alt,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            l10n.submitDestinationTitle,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.submitDestinationSubtitle,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    _buildImagePicker(l10n),
                                    const SizedBox(height: 18),
                                    TextFormField(
                                      controller: _nameController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      cursorColor: Colors.white,
                                      decoration: _fieldDecoration(
                                        l10n.submitDestinationNameLabel,
                                      ),
                                      validator: (value) =>
                                          (value == null ||
                                              value.trim().isEmpty)
                                          ? l10n.submitDestinationNameRequired
                                          : null,
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _locationController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      cursorColor: Colors.white,
                                      decoration: _fieldDecoration(
                                        l10n.submitDestinationLocationLabel,
                                        hint:
                                            l10n.submitDestinationLocationHint,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildLocationPicker(l10n),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _descriptionController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      cursorColor: Colors.white,
                                      minLines: 3,
                                      maxLines: 6,
                                      decoration: _fieldDecoration(
                                        l10n.submitDestinationDescriptionLabel,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      l10n.interestsLabel,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: interestTags.map((tag) {
                                        final selected = _selectedTags.contains(
                                          tag,
                                        );
                                        return FilterChip(
                                          label: Text(
                                            _capitalize(tag),
                                            style: TextStyle(
                                              color: selected
                                                  ? Colors.white
                                                  : const Color(0xFF1A2530),
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          selected: selected,
                                          showCheckmark: false,
                                          avatar: selected
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: Colors.white,
                                                )
                                              : null,
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.88),
                                          selectedColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.85),
                                          side: BorderSide(
                                            color: Colors.white.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                          onSelected: (value) {
                                            setState(() {
                                              if (value) {
                                                _selectedTags.add(tag);
                                              } else {
                                                _selectedTags.remove(tag);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      l10n.submitDestinationReviewNotice,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton.icon(
                                        onPressed: _submitting ? null : _submit,
                                        icon: _submitting
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(Icons.send, size: 18),
                                        label: Text(
                                          l10n.submitDestinationButton,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
