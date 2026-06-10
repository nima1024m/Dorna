import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/toast.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/api_client.dart';
import '../../controllers/auth/auth_controller.dart';
import '../ui/custom_button.dart';
import '../ui/image_picker_sheet.dart';

class ProfilePhoto extends StatefulWidget {
  const ProfilePhoto({Key? key}) : super(key: key);

  @override
  _ProfilePhotoState createState() => _ProfilePhotoState();
}

class _ProfilePhotoState extends State<ProfilePhoto> {
  XFile? _profilePhoto;
  final AuthController _authController = Get.find<AuthController>();
  bool _isUploading = false;

  void onProfilePhotoTap() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      builder: (BuildContext context) {
        return ImagePickerSheet(
            onImagePicked: (image) async {
              setState(() {
                _profilePhoto = image;
                _isUploading = true;
              });

              try {
                final avatarUrl = await _authController.uploadAvatar(
                  filePath: image.path,
                );

                if (avatarUrl != null) {
                  // Success - the AuthController already updated the user object
                } else {
                  // Failed to upload
                  showCustomToast(
                    'Failed to upload profile photo',
                    Utils.appContext,
                    isError: true,
                  );
                  setState(() {
                    _profilePhoto = null;
                  });
                }
              } catch (e) {
                var message = e.getDioBackendErrorMessage() ??
                    'Failed to upload profile photo';
                showCustomToast(message, Utils.appContext, isError: true);
                setState(() {
                  _profilePhoto = null;
                });
              } finally {
                setState(() {
                  _isUploading = false;
                });
              }
            },
            onRemoveImage: () async {
              setState(() {
                _isUploading = true;
              });

              try {
                final success = await _authController.removeAvatar();

                if (success == true) {
                  setState(() {
                    _profilePhoto = null;
                  });
                } else if (success == false) {
                  showCustomToast(
                      'Failed to remove profile photo', Utils.appContext,
                      isError: true);
                }
              } catch (e) {
                var message = e.getDioBackendErrorMessage() ??
                    'Failed to remove profile photo';
                showCustomToast(message, Utils.appContext, isError: true);
              } finally {
                setState(() {
                  _isUploading = false;
                });
              }
            },
            hasCurrentImage: _profilePhoto != null ||
                (_authController.getUserDetails.avatarExist == true));
      },
    );
  }

  Widget _buildProfileImage() {
    final currentUser = _authController.getUserDetails;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    var color = isDarkMode ? Colors.white : Colors.black;

    // Show local image if available (during upload process)
    if (_profilePhoto != null) {
      return ClipOval(
        child: Image.file(
          File(_profilePhoto!.path),
          fit: BoxFit.cover,
          width: 110,
          height: 110,
        ),
      );
    }

    // Show network image if available
    if (currentUser.avatarExist == true) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl:
              '${ApiClient.baseUrl}v1/user/me/avatar?k=${_authController.avatarCacheKey.value}',
          cacheKey: _authController.avatarCacheKey.value,
          fit: BoxFit.cover,
          width: 110,
          height: 110,
          httpHeaders: {
            'Authorization': 'Bearer ${ApiInterceptors.accessToken}'
          },
          errorListener: (e) {
            EasyDebounce.cancel('profilePhotoError');
            EasyDebounce.debounce(
                'profilePhotoError', const Duration(seconds: 2), () {
              if (e.toString().contains('401')) {
                debugPrint('mylog e $e');
                _authController.refreshToken().then((v) async {
                  await CachedNetworkImage.evictFromCache(
                      _authController.avatarCacheKey.value);
                  ApiInterceptors.accessToken =
                      await _authController.getAccessToken();
                  setState(() {});
                });
              }
            });
          },
          errorWidget: (context, error, stackTrace) {
            return Icon(
              Icons.person,
              size: 60,
              color: color.withOpacity(0.1),
            );
          },
          progressIndicatorBuilder: (context, child, loadingProgress) {
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.progress,
              ),
            );
          },
        ),
      );
    }

    // Show default icon
    return Icon(
      Icons.person,
      size: 60,
      color: color.withOpacity(0.1),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    var color = isDarkMode ? Colors.white : Colors.black;

    return Obx(() => GestureDetector(
          onTap: _isUploading ? null : onProfilePhotoTap,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.05),
                  ),
                  child: _buildProfileImage(),
                ),
                if (_isUploading)
                  Container(
                    width: 110,
                    height: 110,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  child: SizedBox(
                    width: 38,
                    height: 38,
                    child: CustomButton(
                      onPressed: _isUploading ? () {} : onProfilePhotoTap,
                      backgroundColor: isDarkMode ? Colors.black : Colors.white,
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : color.withOpacity(0.1),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      buttonWidget: SvgPicture.asset(
                        'assets/icons/ic_camera.svg',
                        width: 22,
                        height: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
