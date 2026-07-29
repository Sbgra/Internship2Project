import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';

/// Yazar profil sayfasının üst bölümü — sade.
class ProfileHeader extends StatelessWidget {
  final UserProfileModel profile;
  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                backgroundImage:
                    profile.profilePicture != null &&
                        profile.profilePicture!.isNotEmpty
                    ? NetworkImage(profile.profilePicture!)
                    : null,
                child:
                    profile.profilePicture == null ||
                        profile.profilePicture!.isEmpty
                    ? Text(
                        profile.initials,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.email,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              profile.bio!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            '${profile.articleCount} makale · ${profile.joinedFormatted} tarihinde katıldı',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Divider(),
        ],
      ),
    );
  }
}
