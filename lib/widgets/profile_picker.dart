import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/profile_photo_url.dart';
import '../theme/app_theme.dart';

class ProfilePicker extends StatefulWidget {
  final String? profileImagePath;
  final ValueChanged<XFile?> onImageSelected;

  const ProfilePicker({
    super.key,
    required this.profileImagePath,
    required this.onImageSelected,
  });

  @override
  State<ProfilePicker> createState() => _ProfilePickerState();
}

class _ProfilePickerState extends State<ProfilePicker> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        widget.onImageSelected(image);
      }
    } catch (e) {
      // Abaikan jika pengguna membatalkan
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Sumber Foto Profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSourceOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Kamera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _buildSourceOption(
                      icon: Icons.image_rounded,
                      label: 'Galeri',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGold.withOpacity(0.15),
              border: Border.all(color: AppTheme.primaryGold, width: 2),
            ),
            child: Icon(icon, color: AppTheme.primaryGold, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = resolveProfilePhotoUrl(widget.profileImagePath) ?? '';
    final canShowRemotePreview =
        resolvedUrl.isNotEmpty &&
        (resolvedUrl.startsWith('http://') ||
            resolvedUrl.startsWith('https://') ||
            resolvedUrl.startsWith('blob:') ||
            resolvedUrl.startsWith('data:'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Profil',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showImageSourceSheet,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 56,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.inputGrey,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2C303E), width: 1.5),
            ),
            child: Row(
              children: [
                if (widget.profileImagePath != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryGold.withOpacity(0.15),
                    ),
                    child: ClipOval(
                      child: canShowRemotePreview
                          ? Image.network(
                              resolvedUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person_rounded,
                                  color: AppTheme.primaryGold,
                                  size: 18,
                                );
                              },
                            )
                          : Image.file(
                              File(widget.profileImagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person_rounded,
                                  color: AppTheme.primaryGold,
                                  size: 18,
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Foto Profil Terpilih',
                      style: TextStyle(color: AppTheme.textWhite, fontSize: 15),
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.file_upload_outlined,
                    color: AppTheme.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pilih foto',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
