import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/api_client.dart';
import '../../controllers/auth/auth_controller.dart';

/// Circular user avatar: shows the signed-in user's photo when one exists,
/// otherwise a neutral person glyph. Reused across the Today / Profile /
/// Settings headers. Reactive to avatar upload/remove via the cache key.
class UserAvatar extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const UserAvatar({super.key, this.size = 48, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = Get.find<AuthController>();
    final avatar = Obx(() {
      final hasAvatar = auth.getUserDetails.avatarExist == true;
      final placeholder = Icon(Icons.person,
          size: size * 0.55, color: cs.onSurfaceVariant.withValues(alpha: 0.6));
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.surfaceContainerHigh,
          border: Border.all(color: cs.surfaceContainerHighest, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasAvatar
            ? CachedNetworkImage(
                imageUrl:
                    '${ApiClient.baseUrl}v1/user/me/avatar?k=${auth.avatarCacheKey.value}',
                cacheKey: auth.avatarCacheKey.value,
                fit: BoxFit.cover,
                httpHeaders: {
                  'Authorization': 'Bearer ${ApiInterceptors.accessToken}'
                },
                errorWidget: (_, _, _) => Center(child: placeholder),
                placeholder: (_, _) => Center(child: placeholder),
              )
            : Center(child: placeholder),
      );
    });

    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}
