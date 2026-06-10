import 'dart:async';

import "package:dio/dio.dart";
import 'package:dorna/screens/auth/auth_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../controllers/auth/auth_controller.dart';
import '../services/telemetry_service.dart';
import '../utils/local_platform_storage.dart';
import '../utils/utils.dart';
import '../widgets/ui/toast.dart';

enum ApiType {
  production,
  develop,
}

enum ApiMethod {
  get,
  post,
  put,
  patch,
  delete,
  download,
}

/// A singleton class responsible for handling API requests using Dio.
/// This class provides a centralized way to make network requests
/// and manage API-related configurations.
class ApiClient {
  /// Dio instance for making HTTP requests.
  static Dio? _dio;

  /// The type of API environment (e.g., production, development).
  static ApiType apiType = ApiType.develop;

  /// Base URL for API requests based on the environment.
  static String baseUrl = apiType == ApiType.production
      ? "https://dorna.thepersa.com/"
      : "https://dorna.thepersa.com/";

  static bool _isNoInternetToastShowing = false;

  /// Private constructor to prevent direct instantiation.
  ApiClient._internal();

  /// Singleton instance of [ApiClient].
  static final ApiClient _apiClient = ApiClient._internal();

  /// Factory constructor to return the singleton instance of [ApiClient].
  factory ApiClient() {
    return _apiClient;
  }

  static isDevelopVersion() => apiType == ApiType.develop;

  /// Initializes the Dio instance with necessary configurations.
  Dio _init() {
    if (_dio == null) {
      _dio = Dio();

      _dio!.options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (!kIsWeb) 'Charset': 'utf-8',
      };
      _dio!.interceptors.add(ApiInterceptors(_dio!));
      _dio!.options.baseUrl = baseUrl;
      if (!kReleaseMode) {
        // customization
        _dio!.interceptors.add(PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ));
      }
      return _dio!;
    } else {
      return _dio!;
    }
  }

  /// Sends an HTTP request to the specified [url] with the given [method] and [data].
  ///
  /// [url] - The endpoint for the request.
  /// [method] - The HTTP method to use (e.g., GET, POST, PUT, DELETE).
  /// [data] - Optional data to send with the request (for POST, PUT).
  /// [headers] - Optional per-request headers to include.
  /// [showError] - Flag to show error messages on failure.
  /// [queryParameters] - Optional query parameters for the request.
  /// [timeout] - Optional timeout duration for the request.
  ///
  /// Returns a [Future<Response?>] that completes with the server's response.
  Future<Response?> request({
    required String url,
    required ApiMethod method,
    Object? data,
    Map<String, dynamic>? headers,
    bool showError = true,
    bool showVpnError = false,
    Map<String, dynamic>? queryParameters,
    String? savePath,
    String? baseUrl,
    CancelToken? cancelToken,
    Duration? timeout,
    String? telemetryEventName,
    List skipErrorStatusCodes = const [],
  }) async {
    var dio = _init();
    if ((method == ApiMethod.post || method == ApiMethod.put) && data == null) {
      data = {};
    }

    dio.options.baseUrl = baseUrl ?? ApiClient.baseUrl;

    //add to current header if not null
    if (headers != null) {
      for (var key in headers.keys) {
        dio.options.headers[key] = headers[key];
      }
    }

    // Create a CancelToken for precise timeout control if timeout is specified
    CancelToken? timeoutCancelToken;
    Timer? timeoutTimer;
    final stopwatch = Stopwatch()..start();

    if (timeout != null) {
      timeoutCancelToken = cancelToken ?? CancelToken();
      timeoutTimer = Timer(timeout, () {
        if (!timeoutCancelToken!.isCancelled) {
          timeoutCancelToken
              .cancel('Request timeout after ${timeout.inMilliseconds}ms');
        }
      });
    }

    // Use the timeout cancel token if provided, otherwise use the original one
    final effectiveCancelToken = timeoutCancelToken ?? cancelToken;

    try {
      Response? response;
      switch (method) {
        case ApiMethod.get:
          response = await dio.get(
            url,
            queryParameters: queryParameters,
            cancelToken: effectiveCancelToken,
          );
          break;
        case ApiMethod.post:
          response = await dio.post(
            url,
            data: data,
            queryParameters: queryParameters,
            cancelToken: effectiveCancelToken,
          );
          break;
        case ApiMethod.put:
          response = await dio.put(
            url,
            data: data,
            queryParameters: queryParameters,
            cancelToken: effectiveCancelToken,
          );
          break;
        case ApiMethod.patch:
          response = await dio.patch(
            url,
            data: data,
            queryParameters: queryParameters,
            cancelToken: effectiveCancelToken,
          );
          break;
        case ApiMethod.delete:
          response = await dio.delete(
            url,
            data: data,
            queryParameters: queryParameters,
            cancelToken: effectiveCancelToken,
          );
          break;
        case ApiMethod.download:
          response = await dio.download(
            url,
            savePath,
            cancelToken: effectiveCancelToken,
          );
          break;
        default:
          response = await dio.get(
            url,
            queryParameters: queryParameters,
            cancelToken: effectiveCancelToken,
          );
          break;
      }

      // Cancel the timeout timer if request completed successfully
      timeoutTimer?.cancel();
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;

      if (telemetryEventName != null) {
        TelemetryService.emitEvent(
          telemetryEventName,
          properties: {
            'ok': response.statusCode == 200,
            'http_status': response.statusCode,
            'latency_ms': latency,
          },
        );
      }

      //remove headers if not null
      if (headers != null) {
        for (var key in headers.keys) {
          dio.options.headers.remove(key);
        }
      }

      return response;
    } catch (e) {
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;
// Cancel the timeout timer in case of error
      timeoutTimer?.cancel();
      //remove headers if not null
      if (headers != null) {
        for (var key in headers.keys) {
          dio.options.headers.remove(key);
        }
      }

      if (e is DioException) {
        if (telemetryEventName != null) {
          TelemetryService.emitEvent(
            telemetryEventName,
            properties: {
              'ok': e.response?.statusCode == 200,
              'http_status': e.response?.statusCode,
              'latency_ms': latency,
            },
          );
        }
        debugPrint(
            'mylog e.response?.statusCode: ${e.response?.statusCode} showError: $showError e.type: ${e.type}');
        if (e.response?.statusCode == null && showError) {
          if (!_isNoInternetToastShowing && e.type != DioExceptionType.cancel) {
            _isNoInternetToastShowing = true;
            showNetworkToast(e: e, context: Utils.appContext!);
            //add delay to avoid showing multiple toasts
            Future.delayed(const Duration(seconds: 4), () {
              _isNoInternetToastShowing = false;
            });
          }
          return e.response;
        }
        if (e.response?.statusCode == 500 &&
            showError &&
            !skipErrorStatusCodes.contains(500)) {
          if (e.response?.data.runtimeType != List &&
              e.response?.data.runtimeType != String &&
              e.response?.data['messageText'] != null) {
            showCustomToast(e.response?.data['messageText'], Utils.appContext,
                isServerError: true);
          } else {
            showNetworkToast(e: e, context: Utils.appContext!);
          }
          return e.response;
        }
        if (e.response?.statusCode == 404 &&
            showError &&
            !skipErrorStatusCodes.contains(404)) {
          showCustomToast('Resource not found', Utils.appContext,
              isError: true);
          return e.response;
        }
        if (e.response?.statusCode == 429 &&
            showError &&
            !skipErrorStatusCodes.contains(429)) {
          showNetworkToast(e: e, context: Utils.appContext!);
          return e.response;
        }
        if (e.response?.statusCode == 522 &&
            showError &&
            !skipErrorStatusCodes.contains(522)) {
          showNetworkToast(e: e, context: Utils.appContext!);
          return e.response;
        }
        rethrow;
      } else {
        if (showError) {
          showCustomToast('Data could not be fetched', Utils.appContext);
        } else {
          rethrow;
        }
      }
    }
  }

  /// Checks if the Dio error should trigger a user-facing error message.
  ///
  /// [e] - The caught exception.
  ///
  /// Returns `true` if the error should trigger a message, otherwise `false`.
  static bool isDioErrorForShow(e) {
    if (e is DioException &&
        (e.response?.statusCode == 400 ||
            e.response?.statusCode == 502 ||
            e.response?.statusCode == 504)) {
      return true;
    }
    return false;
  }

  /// Checks if the Dio error message is related to rate limiting.
  ///
  /// [e] - The caught exception.
  ///
  /// Returns `true` if the error is related to rate limiting, otherwise `false`.
  static bool hasDioErrorMessage(e) {
    if (e is DioException && (e.response?.statusCode == 429)) {
      return true;
    }
    return false;
  }

  /// Retrieves the error message for rate limiting errors.
  ///
  /// [e] - The caught exception.
  ///
  /// Returns the error message if it exists, otherwise `null`.
  static String? getDioErrorMessage(e) {
    if (e is DioException && (e.response?.statusCode == 411)) {
      return '411 Error';
    }
    if (e is DioException && (e.response?.statusCode == 429)) {
      return e.response?.data['detail'] ?? 'Too Many Requests';
    }
    if (e is DioException && (e.response?.statusCode == 400)) {
      return e.response?.data['message'] ?? 'Error 400 status code';
    }
    if (e is DioException && (e.response?.statusCode == 522)) {
      return 'Error 522 status code';
    }
    if (e is DioException && (e.response?.statusCode == 500)) {
      if (e.response?.data.runtimeType != List &&
          e.response?.data.runtimeType != String &&
          e.response?.data['messageText'] != null) {
        showCustomToast(e.response?.data['messageText'], Utils.appContext,
            isError: true);
      } else {
        return 'Internal Server Error: (${e.response?.data})';
      }
    }
    return null;
  }

}

class ApiInterceptors extends Interceptor {
  final Dio _dio;
  LocalPlatformStorage storage = const LocalPlatformStorage();
  final authController = Get.find<AuthController>();
  static bool isRefreshed = false;
  static bool isRefreshing = false;
  static String accessToken = '';

  ApiInterceptors(this._dio);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    var token = await storage.read(
      key: 'access_token',
    );
    accessToken = token ?? '';
    var refreshToken = await storage.read(
      key: 'refresh_token',
    );

    if (kDebugMode) {
      debugPrint('mylog token=$token');
      debugPrint('mylog refreshToken=$refreshToken');
    }
    if (token != null) {
      options.headers["Authorization"] = 'Bearer $token';
    }
    options.path = Utils.replaceHttps(options.path) ?? options.path;

    super.onRequest(options, handler);
  }

  @override
  void onResponse(var response, ResponseInterceptorHandler handler) {
    if (response.statusCode != 401 &&
        !response.requestOptions.path.contains('token/refresh/')) {
      isRefreshed = false;
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    debugPrint(
        'mylog dio error ${error.requestOptions.path} statusCode=${error.response?.statusCode}');

    // Skip token refresh for auth-related endpoints
    if ((error.requestOptions.path.toString().contains('signin') ||
        error.requestOptions.path.toString().contains('signup') ||
        error.requestOptions.path.toString().contains('preauth') ||
        error.requestOptions.path.toString().contains('refresh') ||
        error.requestOptions.path.toString().contains('google') ||
        error.requestOptions.path.toString().contains('apple') ||
        error.requestOptions.path.toString().contains('logout'))) {
      return super.onError(error, handler);
    }

    if (error.response?.statusCode == 401) {
      // Prevent multiple simultaneous refresh attempts
      if (isRefreshing) {
        // Wait for the ongoing refresh to complete
        while (isRefreshing) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // If refresh was successful, retry the original request
        if (isRefreshed) {
          try {
            final token = await storage.read(key: 'access_token');
            if (token != null) {
              error.requestOptions.headers["Authorization"] = 'Bearer $token';
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            }
          } catch (e) {
            debugPrint('Error retrying request after token refresh: $e');
          }
        }

        // If we reach here, refresh failed or token is still invalid
        authController.logout(sendLogoutRequest: false);
        await Get.offAllNamed(AuthScreen.routeName);
        return super.onError(error, handler);
      }

      // Start token refresh process
      isRefreshing = true;
      isRefreshed = false;

      try {
        final refreshSuccess = await authController.refreshToken();

        if (refreshSuccess) {
          isRefreshed = true;
          isRefreshing = false;

          // Retry the original request with new token
          final token = await storage.read(key: 'access_token');
          if (token != null) {
            error.requestOptions.headers["Authorization"] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
        } else {
          // Refresh failed, logout user
          isRefreshing = false;
          authController.logout(sendLogoutRequest: false);
          await Get.offAllNamed(AuthScreen.routeName);
        }
      } catch (e) {
        debugPrint('Error during token refresh: $e');
        isRefreshing = false;
        if (e.getDioError()?.response?.statusCode == 401) {
          authController.logout(sendLogoutRequest: false);
          await Get.offAllNamed(AuthScreen.routeName);
        } else {
          super.onError(e.getDioError() ?? error, handler);
        }
      }
    } else {
      super.onError(error, handler);
    }
  }
}
