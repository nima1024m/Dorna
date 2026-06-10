import 'dart:convert';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:dorna/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../config/api_client.dart';
import '../../models/user_models.dart';
import '../../screens/auth/email_verification_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../services/keyboard_service.dart';
import '../../utils/local_platform_storage.dart';
import '../../widgets/ui/toast.dart';

/// Controller for handling user authentication operations.
class AuthController extends GetxController {
  /// Observable user object that holds the current user's details.
  final _user = User().obs;

  /// Local avatar cache key used by UI to cache-bust profile images.
  RxString avatarCacheKey = ''.obs;

  /// Client for making API requests.
  final apiClient = ApiClient();

  /// Service for keyboard and app group operations.
  final keyboardService = KeyboardService();

  /// loading login
  RxBool loadingGoogleLogin = false.obs;
  RxBool loadingAppleLogin = false.obs;

  CancelToken _updateProfileCancelToken = CancelToken();

  @override
  void onInit() {
    super.onInit();
    _syncTokensBetweenAppAndKeyboard();
    _loadAvatarCacheKey();
  }

  /// Initiates Google Sign-In flow and returns success status.
  ///
  /// On known API errors (e.g. 401/400), the error is rethrown for UI to handle,
  /// mirroring the pattern used in email/password sign-in.
  Future<bool?> googleSignIn() async {
    if (loadingGoogleLogin.value) return null;
    loadingGoogleLogin(true);
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
          serverClientId:
              '1089661853542-cp3c7vrsb5i3o1ahf65nvtk5r4d4gikq.apps.googleusercontent.com');
      final account = await googleSignIn.authenticate();

      // Retrieve ID token from Google
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Missing Google ID token');
      }
      log('mylog idToken=$idToken');

      // Exchange Google ID token for app tokens
      final response = await apiClient.request(
        url: 'v1/auth/google',
        method: ApiMethod.post,
        data: {
          'id_token': idToken,
        },
      );

      if (response?.statusCode == 200) {
        final data = response!.data;
        if (data['status'] == 'OK') {
          await saveUserTokens(
            accessToken: data['access_token']!,
            refreshToken: data['refresh_token']!,
          );
          await getUserData();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('mylog googleSignIn error=$e');
      // Propagate known validation/auth errors similar to other methods
      if (e.getDioError()?.response?.statusCode == 401 ||
          e.getDioError()?.response?.statusCode == 400) {
        rethrow;
      }
      return null;
    } finally {
      loadingGoogleLogin(false);
    }
  }

  Future<bool?> appleSignIn() async {
    if (loadingAppleLogin.value) return null;
    loadingAppleLogin(true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Missing Apple identity token');
      }
      // Clipboard.setData(ClipboardData(text: credential.identityToken.toString()));

      final response = await apiClient.request(
        url: 'v1/auth/apple',
        method: ApiMethod.post,
        data: {
          'identity_token': credential.identityToken,
        },
      );

      if (response?.statusCode == 200) {
        final data = response!.data;
        if (data['status'] == 'OK') {
          await saveUserTokens(
            accessToken: data['access_token']!,
            refreshToken: data['refresh_token']!,
          );
          await getUserData();
          return true;
        }
      }
      return false;
    } catch (e) {
      if (e.getDioError()?.response?.statusCode == 401 ||
          e.getDioError()?.response?.statusCode == 400) {
        rethrow;
      }
      return null;
    } finally {
      loadingAppleLogin(false);
    }
  }

  /// Syncs tokens between app and keyboard based on timestamps
  Future<void> _syncTokensBetweenAppAndKeyboard() async {
    try {
      final hasTokens = await hasUserTokens();
      if (!hasTokens) {
        debugPrint('No app tokens found, skipping sync');
        return;
      }

      // Get app token timestamp
      const LocalPlatformStorage storage = LocalPlatformStorage();
      final appTimestampStr = await storage.read(key: 'token_timestamp');
      final appTimestamp =
          appTimestampStr != null ? double.tryParse(appTimestampStr) : null;

      // Get keyboard token timestamp
      final keyboardTimestamp = await keyboardService.getTokenTimestamp();

      debugPrint('App token timestamp: $appTimestamp');
      debugPrint('Keyboard token timestamp: $keyboardTimestamp');

      // If both timestamps exist, compare them
      if (appTimestamp != null && keyboardTimestamp != null) {
        if (appTimestamp > keyboardTimestamp) {
          // App token is newer, send to keyboard
          debugPrint('App token is newer, syncing to keyboard');
          await keyboardService.saveTokens(
            accessToken: await getAccessToken(),
            refreshToken: await _getRefreshToken(),
            timestamp: appTimestamp,
          );
        } else if (keyboardTimestamp > appTimestamp) {
          // Keyboard token is newer, get from keyboard
          debugPrint('Keyboard token is newer, syncing to app');
          final keyboardAccessToken = await keyboardService.getAccessToken();
          final keyboardRefreshToken = await keyboardService.getRefreshToken();

          if (keyboardAccessToken != null && keyboardRefreshToken != null) {
            await storage.write(
                key: 'access_token', value: keyboardAccessToken);
            await storage.write(
                key: 'refresh_token', value: keyboardRefreshToken);
            await storage.write(
                key: 'token_timestamp', value: keyboardTimestamp.toString());
            debugPrint('Successfully synced keyboard tokens to app');
          }
        } else {
          debugPrint('Tokens are in sync (same timestamp)');
        }
      } else if (appTimestamp != null && keyboardTimestamp == null) {
        // App has timestamp but keyboard doesn't, sync to keyboard
        debugPrint('Keyboard has no timestamp, syncing from app');
        await keyboardService.saveTokens(
          accessToken: await getAccessToken(),
          refreshToken: await _getRefreshToken(),
          timestamp: appTimestamp,
        );
      } else if (appTimestamp == null && keyboardTimestamp != null) {
        // Keyboard has timestamp but app doesn't, sync to app
        debugPrint('App has no timestamp, syncing from keyboard');
        final keyboardAccessToken = await keyboardService.getAccessToken();
        final keyboardRefreshToken = await keyboardService.getRefreshToken();

        if (keyboardAccessToken != null && keyboardRefreshToken != null) {
          await storage.write(key: 'access_token', value: keyboardAccessToken);
          await storage.write(
              key: 'refresh_token', value: keyboardRefreshToken);
          await storage.write(
              key: 'token_timestamp', value: keyboardTimestamp.toString());
          debugPrint('Successfully synced keyboard tokens to app');
        }
      } else {
        // Neither has timestamp, just sync to keyboard for backwards compatibility
        debugPrint(
            'No timestamps found, syncing to keyboard for backwards compatibility');
        final timestamp = DateTime.now().millisecondsSinceEpoch / 1000.0;
        await keyboardService.saveTokens(
          accessToken: await getAccessToken(),
          refreshToken: await _getRefreshToken(),
          timestamp: timestamp,
        );
        await storage.write(
            key: 'token_timestamp', value: timestamp.toString());
      }
    } catch (e) {
      debugPrint('Error syncing tokens between app and keyboard: $e');
    }
  }

  /// Gets preauth token required for signin/signup operations.
  ///
  /// Returns the preauth token if successful, otherwise throws an error.
  Future<String?> getPreAuthToken() async {
    try {
      final response = await apiClient.request(
        url: 'v1/auth/pre-auth',
        method: ApiMethod.post,
        data: {
          'device_nonce': 'app',
        },
      );

      if (response?.statusCode == 200) {
        final data = response!.data;
        if (data['status'] == 'OK' && data['token'] != null) {
          return data['token'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting preauth token: $e');
      return null;
    }
  }

  /// Signs up a new user with email and password.
  ///
  /// Returns the access token if successful, otherwise throws an error.
  Future<bool?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      // First get preauth token
      final preAuthToken = await getPreAuthToken();
      if (preAuthToken == null) {
        throw Exception('Failed to get preauth token');
      }

      final response = await apiClient.request(
        url: 'v1/auth/signup',
        method: ApiMethod.post,
        data: {
          'email': email.trim().toLowerCase().toEnglishDigit(),
          'password': password,
        },
        headers: {
          'X-Preauth-Token': preAuthToken,
        },
      );

      if (response?.statusCode == 200) {
        final data = response!.data;
        if (data['status'] == 'OK') {
          return true;
        }
      }
      return false;
    } catch (e) {
      if (e.getDioError()?.response?.statusCode == 401 ||
          e.getDioError()?.response?.statusCode == 422 ||
          e.getDioError()?.response?.statusCode == 400 ||
          e.getDioError()?.response?.statusCode == 409) {
        rethrow;
      }
      return null;
    }
  }

  /// Signs in a user with email and password.
  ///
  /// Returns the access token if successful, otherwise throws an error.
  Future<bool?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // First get preauth token
      final preAuthToken = await getPreAuthToken();
      if (preAuthToken == null) {
        throw Exception('Failed to get preauth token');
      }

      final response = await apiClient.request(
        url: 'v1/auth/signin',
        method: ApiMethod.post,
        data: {
          'email': email.trim().toLowerCase().toEnglishDigit(),
          'password': password,
        },
        headers: {
          'X-Preauth-Token': preAuthToken,
        },
      );

      if (response?.statusCode == 200) {
        final data = response!.data;
        if (data['status'] == 'OK') {
          await saveUserTokens(
            accessToken: data['access_token']!,
            refreshToken: data['refresh_token']!,
          );
          await getUserData();
          return true;
        }
      }
      return false;
    } catch (e) {
      if (e.getDioError()?.response?.statusCode == 401 ||
          e.getDioError()?.response?.statusCode == 400) {
        rethrow;
      }
      return null;
    }
  }

  /// Resends the activation email to the user.
  ///
  /// Returns always true/false based on success
  Future<bool> resendActivation({required String email}) async {
    try {
      final response = await apiClient.request(
        url: 'v1/auth/resend-activation',
        method: ApiMethod.post,
        data: {
          'email': email.trim().toLowerCase().toEnglishDigit(),
        },
      );

      if (response?.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error resending activation: $e');
      return false;
    }
  }

  /// Initiates forgot password by sending a reset code to the user's email.
  ///
  /// Returns true if the server responds with OK, false otherwise, and null for unexpected errors.
  Future<bool?> forgotPassword({required String email}) async {
    try {
      final response = await apiClient.request(
        url: 'v1/auth/forgot',
        method: ApiMethod.post,
        data: {
          'email': email.trim().toLowerCase().toEnglishDigit(),
        },
        skipErrorStatusCodes: [500],
      );

      if (response?.statusCode == 200) {
        final data = response!.data;
        if (data['status'] == 'OK') {
          return true;
        }
      }
      return false;
    } catch (e) {
      if (e.getDioError()?.response?.statusCode == 500 ||
          e.getDioError()?.response?.statusCode == 422 ||
          e.getDioError()?.response?.statusCode == 400) {
        rethrow;
      }
      return null;
    }
  }

  /// Verifies the reset code sent to the user's email.
  ///
  /// Returns the verification token if successful, otherwise throws known errors.
  Future<String?> verifyReset({
    required String email,
    required String code,
  }) async {
    try {
      final response = await apiClient.request(
        url: 'v1/auth/verify-reset',
        method: ApiMethod.post,
        data: {
          'email': email.trim().toLowerCase().toEnglishDigit(),
          'code': code.trim().toEnglishDigit(),
        },
      );

      if (response?.statusCode == 200) {
        final data = response!.data;
        if (data['status'] == 'OK' && data['token'] != null) {
          return data['token'];
        }
      }
      return null;
    } catch (e) {
      if (e.getDioError()?.response?.statusCode == 422 ||
          e.getDioError()?.response?.statusCode == 400) {
        rethrow;
      }
      return null;
    }
  }

  /// Resets the user's password using the verification token.
  ///
  /// [email] User's email address.
  /// [newPassword] The new password to set.
  /// [verifyToken] Token from verify-reset endpoint, sent in `X-Verify-Token` header.
  /// Returns true if successful, false otherwise.
  Future<bool?> resetPassword({
    required String email,
    required String newPassword,
    required String verifyToken,
  }) async {
    try {
      final response = await apiClient.request(
        url: 'v1/auth/reset',
        method: ApiMethod.post,
        headers: {
          'X-Verify-Token': verifyToken,
        },
        data: {
          'email': email.trim().toLowerCase().toEnglishDigit(),
          'new_password': newPassword,
        },
      );

      if (response?.statusCode == 200) {
        final data = response!.data;
        if (data['status'] == 'OK') {
          if (data['message'] ==
              "Please verify your email before logging in.") {
            showCustomToast('Password reset successfully', Utils.appContext,
                isSuccess: true);
            resendActivation(email: email);
            Get.offAllNamed(
              EmailVerificationScreen.routeName,
              arguments: {'email': email},
            );
          }
          return null;
        }
      }
      return false;
    } catch (e) {
      if (e.getDioError()?.response?.statusCode == 422 ||
          e.getDioError()?.response?.statusCode == 400) {
        rethrow;
      }
      return null;
    }
  }

  /// Fetches the user's data from the server and updates the local user object.
  Future<bool?> getUserData() async {
    try {
      final response = await apiClient.request(
        url: 'v1/user/me',
        method: ApiMethod.get,
        showError: false,
      );
      if (response?.statusCode == 200) {
        var password = _user.value.password;

        var user = (User.fromJson(response!.data));
        user.password = password;
        _user.value = user;

        _user.refresh();
        await storeUser();
        // Ensure avatar cache key reflects current user id
        await _loadAvatarCacheKey();
        return true;
      } else if (response?.statusCode == 204) {
        await logout();
        Get.offAllNamed(SplashScreen.routeName);
      } else {
        return Future.error('Failed To getUserData');
      }
    } on DioException {
      rethrow;
    }
  }

  /// Updates the user's profile information.
  ///
  /// [name] The new name to update for the user.
  /// Returns true if successful, false otherwise.
  Future<bool?> updateProfile({
    required String name,
  }) async {
    _updateProfileCancelToken.cancel();
    _updateProfileCancelToken = CancelToken();
    try {
      final response = await apiClient.request(
        url: 'v1/user/me',
        method: ApiMethod.patch,
        data: {
          'full_name': name.trim(),
        },
        cancelToken: _updateProfileCancelToken,
        skipErrorStatusCodes: [500],
      );

      if (response?.statusCode == 200) {
        final data = response!.data;
        // Update the local user object with the response data
        var updatedUser = User.fromJson(data);
        updatedUser.password = _user.value.password; // Preserve password
        _user.value = updatedUser;
        _user.refresh();
        await storeUser();
        return true;
      }
      return false;
    } catch (e) {
      if (e.getDioError()?.response?.statusCode == 401 ||
          e.getDioError()?.response?.statusCode == 422 ||
          e.getDioError()?.response?.statusCode == 400 ||
          e.getDioError()?.response?.statusCode == 500 ||
          e.getDioError()?.type == DioExceptionType.cancel) {
        rethrow;
      }
      return null;
    }
  }

  /// Uploads a new avatar for the user.
  ///
  /// [filePath] The path to the image file to upload.
  /// Returns the avatar URL if successful, null otherwise.
  Future<String?> uploadAvatar({required String filePath}) async {
    try {
      // Create multipart file
      var type = filePath.split('.').last;
      final file = await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
        contentType: DioMediaType('image', type == 'jpg' ? 'jpeg' : type),
      );

      final formData = FormData.fromMap({
        'file': file,
      });

      final response = await apiClient.request(
        url: 'v1/user/me/avatar',
        method: ApiMethod.post,
        data: formData,
      );

      if (response?.statusCode == 200) {
        final data = response!.data;
        final avatarUrl = data['avatar_url'];

        _user.value.avatarExist = true;
        _user.refresh();
        await storeUser();
        // Invalidate avatar cache to fetch the new image
        await _bumpAvatarCacheVersion();

        return avatarUrl;
      }
      return null;
    } catch (e) {
      if (e.getDioError()?.response?.statusCode == 401 ||
          e.getDioError()?.response?.statusCode == 422 ||
          e.getDioError()?.response?.statusCode == 400) {
        rethrow;
      }
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  /// Changes the user's password.
  ///
  /// [oldPassword] The current password.
  /// [newPassword] The new password to set.
  /// Returns true if successful, false if server responded with failure, and null for unexpected errors.
  Future<bool?> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await apiClient.request(
        url: 'v1/user/me/password',
        method: ApiMethod.post,
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );

      if (response?.statusCode == 200) {
        final data = response!.data;
        if (data['status'] == 'OK') {
          // Optionally keep local password in sync
          _user.value.password = newPassword;
          _user.refresh();
          await storeUser();
          return true;
        }
      }
      return false;
    } catch (e) {
      // Propagate known validation/auth errors similar to other methods
      if (e.getDioError()?.response?.statusCode == 422 ||
          e.getDioError()?.response?.statusCode == 400) {
        rethrow;
      }
      return null;
    }
  }

  /// Removes the user's avatar.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool?> removeAvatar() async {
    try {
      final response = await apiClient.request(
        url: 'v1/user/me/avatar',
        method: ApiMethod.delete,
      );

      if (response?.statusCode == 200) {
        final data = response!.data;
        if (data['status'] == 'OK') {
          // Clear the avatar URL from the local user object
          _user.value.avatarExist = false;
          _user.refresh();
          await storeUser();
          // Invalidate avatar cache to remove the old image
          await _bumpAvatarCacheVersion();
          return true;
        }
      }
      return false;
    } catch (e) {
      if (e.getDioError()?.response?.statusCode == 401 ||
          e.getDioError()?.response?.statusCode == 422 ||
          e.getDioError()?.response?.statusCode == 400) {
        rethrow;
      }
      debugPrint('Error removing avatar: $e');
      return null;
    }
  }

  /// Deletes the user's account permanently.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool?> deleteAccount() async {
    try {
      final response = await apiClient.request(
        url: 'v1/user/me/delete',
        method: ApiMethod.delete,
      );

      if (response?.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      if (e.getDioError()?.response?.statusCode == 401 ||
          e.getDioError()?.response?.statusCode == 422 ||
          e.getDioError()?.response?.statusCode == 400) {
        rethrow;
      }
      return null;
    }
  }

  /// Deletes the user's personal data (but keeps the account).
  ///
  /// Returns true if successful, false otherwise.
  Future<bool?> deletePersonalData() async {
    try {
      final response = await apiClient.request(
        url: 'v1/user/data/delete',
        method: ApiMethod.delete,
      );

      if (response?.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      if (e.getDioError()?.response?.statusCode == 401 ||
          e.getDioError()?.response?.statusCode == 422 ||
          e.getDioError()?.response?.statusCode == 400) {
        rethrow;
      }
      return null;
    }
  }

  /// Saves both access and refresh tokens to local storage and app group.
  Future<void> saveUserTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    const LocalPlatformStorage storage = LocalPlatformStorage();
    final timestamp = DateTime.now().millisecondsSinceEpoch / 1000.0;

    // Save to local storage (existing functionality)
    await storage.write(
      key: 'access_token',
      value: accessToken,
    );
    await storage.write(
      key: 'refresh_token',
      value: refreshToken,
    );
    await storage.write(
      key: 'token_timestamp',
      value: timestamp.toString(),
    );

    // Also save to app group for keyboard extension access
    try {
      await keyboardService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        timestamp: timestamp,
      );
    } catch (e) {
      debugPrint('Failed to save tokens to app group: $e');
    }
  }

  /// Refreshes the access token using the refresh token.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> refreshToken() async {
    try {
      const LocalPlatformStorage storage = LocalPlatformStorage();
      final refreshToken = await storage.read(key: 'refresh_token');

      if (refreshToken == null) {
        debugPrint('No refresh token available');
        return false;
      }

      final response = await apiClient.request(
        url: 'v1/auth/refresh',
        method: ApiMethod.post,
        data: {
          'refresh_token': refreshToken,
        },
        showError: false,
      );

      if (response?.statusCode == 200) {
        final data = response!.data;
        if (data['status'] == 'OK') {
          await saveUserTokens(
            accessToken: data['access_token']!,
            refreshToken: data['refresh_token']!,
          );
          debugPrint('Token refreshed successfully');
          return true;
        }
      } else if (response?.statusCode == 401 || response?.statusCode == 403) {
        // Refresh token is expired or invalid
        debugPrint('Refresh token expired or invalid, clearing tokens');
        await storage.delete(key: 'access_token');
        await storage.delete(key: 'refresh_token');
        return false;
      }

      debugPrint('Failed to refresh token: ${response?.statusCode}');
      return false;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          // Refresh token is expired or invalid
          debugPrint('Refresh token expired or invalid, clearing tokens');
          const LocalPlatformStorage storage = LocalPlatformStorage();
          await storage.delete(key: 'access_token');
          await storage.delete(key: 'refresh_token');
        }
      }
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }

  /// Clears both access and refresh tokens from local storage and app group.
  Future<void> clearUserTokens() async {
    const LocalPlatformStorage storage = LocalPlatformStorage();

    // Clear from local storage (existing functionality)
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    await storage.delete(key: 'token_timestamp');

    // Also clear from app group
    try {
      await keyboardService.clearTokens();
    } catch (e) {
      debugPrint('Failed to clear tokens from app group: $e');
    }
  }

  Future<bool> hasUserTokens() async {
    const LocalPlatformStorage storage = LocalPlatformStorage();
    return await storage.read(key: 'access_token') != null &&
        await storage.read(key: 'refresh_token') != null;
  }

  getAccessToken() async {
    const LocalPlatformStorage storage = LocalPlatformStorage();
    return await storage.read(key: 'access_token');
  }

  _getRefreshToken() async {
    const LocalPlatformStorage storage = LocalPlatformStorage();
    return await storage.read(key: 'refresh_token');
  }

  /// Logs out the user and clears local storage data.
  Future<void> logout({bool sendLogoutRequest = true}) async {
    const LocalPlatformStorage storage = LocalPlatformStorage();
    if (sendLogoutRequest) {
      final response = await apiClient.request(
        url: 'v1/auth/logout',
        method: ApiMethod.post,
        data: {
          'refresh_token': await storage.read(key: 'refresh_token'),
        },
        showError: false,
      );
      if (response?.statusCode == 200) {
      } else {}
    }

    // Clear tokens from both local storage and app group
    await clearUserTokens();

    await storage.delete(
      key: 'user',
    );

    // Reset user state
    _user.value = User();
    _user.refresh();

    // await FirebaseMessaging.instance.deleteToken();
  }

  /// Stores the user's data locally.
  Future<void> storeUser() async {
    const LocalPlatformStorage storage = LocalPlatformStorage();

    await storage.write(
      key: 'user',
      value: json.encode(_user.value.toJson()),
    );
  }

  /// Retrieves the stored user data from local storage.
  Future<void> getStoredUser() async {
    const LocalPlatformStorage storage = LocalPlatformStorage();
    try {
      var userData = await storage.read(
        key: 'user',
      );
      if (userData != null) {
        _user.value = User.fromJson(json.decode(userData));
      }
    } catch (e) {}
  }

  Future<bool> isLoggedIn() async {
    const LocalPlatformStorage storage = LocalPlatformStorage();
    return await storage.containsKey(key: 'user');
  }

  /// Returns the current user details.
  User get getUserDetails {
    return _user.value;
  }

  /// Loads or initializes the local avatar cache key based on stored version.
  Future<void> _loadAvatarCacheKey() async {
    const LocalPlatformStorage storage = LocalPlatformStorage();
    final versionStr = await storage.read(key: 'avatar_cache_version');
    final version = int.tryParse(versionStr ?? '') ?? 1;
    final userId = _user.value.id ?? 'unknown';
    avatarCacheKey.value = 'avatar_${userId}_v$version';
  }

  /// Bumps the avatar cache version and updates the cache key.
  Future<void> _bumpAvatarCacheVersion() async {
    const LocalPlatformStorage storage = LocalPlatformStorage();
    final versionStr = await storage.read(key: 'avatar_cache_version');
    int version = int.tryParse(versionStr ?? '') ?? 1;
    version++;
    await storage.write(key: 'avatar_cache_version', value: version.toString());
    final userId = _user.value.id ?? 'unknown';
    final previousKey = avatarCacheKey.value;
    avatarCacheKey.value = 'avatar_${userId}_v$version';
    try {
      // Evict previous cache entry so the new one is fetched
      await CachedNetworkImage.evictFromCache(previousKey);
    } catch (e) {
      // ignore cache eviction errors
    }
  }
}
