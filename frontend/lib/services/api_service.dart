import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/bead_recommendation.dart';
import '../models/cart_item_model.dart';
import '../models/design_model.dart';
import '../models/order_details.dart';
import '../models/palette_option.dart';
import '../models/upload_result.dart';
import '../models/user_model.dart';

/// Typed wrapper around every FastAPI endpoint the app calls.
class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();

  Dio get _dio => ApiClient.instance.dio;

  /// Overrides the client's default 90s receiveTimeout for calls that must survive a Render
  /// free-tier cold start on top of their own work — waking a sleeping backend (and its
  /// database) alone can take well over 90s, before any AI processing even starts. Used for
  /// the /generation/preview call (holds the connection open for the whole synchronous AI
  /// pipeline) and the /visualize and /regenerate kickoff calls (must survive the wake-up even
  /// though the AI work itself runs as a background task afterwards).
  static const _generationReceiveTimeout = Duration(minutes: 5);

  // ---- Auth / profile ----

  Future<UserModel> getMe() async {
    final response = await _dio.get('/auth/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> updateSettings({
    String? displayName,
    String? language,
    bool? darkMode,
    bool? notificationsEnabled,
  }) async {
    final response = await _dio.patch('/auth/me', data: {
      if (displayName != null) 'display_name': displayName,
      if (language != null) 'language': language,
      if (darkMode != null) 'dark_mode': darkMode,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
    });
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ---- Uploads ----

  /// folder must be one of: designs, sarees, blouses
  Future<UploadResult> uploadImage(
      Uint8List bytes, String fileName, String folder) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _dio.post('/uploads/$folder', data: formData);
    return UploadResult.fromJson(response.data as Map<String, dynamic>);
  }

  // ---- AI colour analysis ----

  Future<Map<String, dynamic>> analyzeColors({
    String? sareeImageUrl,
    String? sareeColorHex,
    String? blouseImageUrl,
    String? blouseColorHex,
    String? embroideryDesignUrl,
    OrderDetails? orderDetails,
  }) async {
    final response = await _dio.post('/analysis/colors', data: {
      'saree_image_url': sareeImageUrl,
      'saree_color_hex': sareeColorHex,
      'blouse_image_url': blouseImageUrl,
      'blouse_color_hex': blouseColorHex,
      'embroidery_design_url': embroideryDesignUrl,
      if (orderDetails != null && !orderDetails.isEmpty)
        'order_details': orderDetails.toJson(),
    });
    final data = response.data as Map<String, dynamic>;
    return {
      'detected_saree_color': data['detected_saree_color'],
      'detected_blouse_color': data['detected_blouse_color'],
      'detected_design_style': data['detected_design_style'],
      'palette_options': (data['palette_options'] as List)
          .map((e) => PaletteOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    };
  }

  // ---- AI preview generation ----

  Future<DesignModel> generatePreview({
    String? designId,
    required String embroideryDesignUrl,
    String? sareeImageUrl,
    String? sareeColorHex,
    String? blouseImageUrl,
    String? blouseColorHex,
    String? detectedSareeColor,
    String? detectedBlouseColor,
    String? detectedDesignStyle,
    List<BeadRecommendation> beadRecommendations = const [],
    List<PaletteOption> paletteOptions = const [],
    int selectedPaletteIndex = 0,
    String lookStyle = 'Luxury Look',
    OrderDetails? orderDetails,
  }) async {
    final response = await _dio.post(
      '/generation/preview',
      data: {
        'design_id': designId,
        'embroidery_design_url': embroideryDesignUrl,
        'saree_image_url': sareeImageUrl,
        'saree_color_hex': sareeColorHex,
        'blouse_image_url': blouseImageUrl,
        'blouse_color_hex': blouseColorHex,
        'detected_saree_color': detectedSareeColor,
        'detected_blouse_color': detectedBlouseColor,
        'detected_design_style': detectedDesignStyle,
        'bead_recommendations':
            beadRecommendations.map((b) => b.toJson()).toList(),
        'palette_options': paletteOptions.map((p) => p.toJson()).toList(),
        'selected_palette_index': selectedPaletteIndex,
        'look_style': lookStyle,
        if (orderDetails != null && !orderDetails.isEmpty)
          'order_details': orderDetails.toJson(),
      },
      options: Options(receiveTimeout: _generationReceiveTimeout),
    );
    return DesignModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Reference-image-faithful visualization: renders the exact uploaded embroidery stitched
  /// onto the exact uploaded blouse photo. The model decides placement, scale and orientation
  /// itself — no manual placement step. Requires an actual blouse photo (blouseImageUrl) —
  /// unlike generatePreview, there's no hex-colour fallback, since the edit pipeline needs a
  /// real base image to edit.
  ///
  /// The backend runs the actual generation (1-5 minutes: background removal + garment
  /// analysis + up to 2 rounds of image generation + QA scoring) as a background task rather
  /// than holding the HTTP request open — that reliably exceeded hosting platforms' reverse-
  /// proxy timeouts in production. This method polls GET /designs/{id} until it's done, so
  /// callers still just get a single completed (or failed) DesignModel back, same as before.
  Future<DesignModel> visualize({
    String? designId,
    required String embroideryDesignUrl,
    required String blouseImageUrl,
    String? sareeImageUrl,
    String? sareeColorHex,
    String lookStyle = 'Luxury Look',
    OrderDetails? orderDetails,
    List<BeadRecommendation> beadRecommendations = const [],
    List<PaletteOption> paletteOptions = const [],
    int selectedPaletteIndex = 0,
  }) async {
    final response = await _dio.post(
      '/generation/visualize',
      data: {
        'design_id': designId,
        'embroidery_design_url': embroideryDesignUrl,
        'blouse_image_url': blouseImageUrl,
        'saree_image_url': sareeImageUrl,
        'saree_color_hex': sareeColorHex,
        'look_style': lookStyle,
        if (orderDetails != null && !orderDetails.isEmpty)
          'order_details': orderDetails.toJson(),
        'bead_recommendations':
            beadRecommendations.map((b) => b.toJson()).toList(),
        'palette_options': paletteOptions.map((p) => p.toJson()).toList(),
        'selected_palette_index': selectedPaletteIndex,
      },
      options: Options(receiveTimeout: _generationReceiveTimeout),
    );
    final started = DesignModel.fromJson(response.data as Map<String, dynamic>);
    return _pollUntilComplete(started.id);
  }

  /// Same background-task + polling contract as [visualize] above.
  Future<DesignModel> regenerate(String designId, String lookStyle) async {
    final response = await _dio.post(
      '/generation/regenerate/$designId',
      queryParameters: {'look_style': lookStyle},
      options: Options(receiveTimeout: _generationReceiveTimeout),
    );
    final started = DesignModel.fromJson(response.data as Map<String, dynamic>);
    return _pollUntilComplete(started.id);
  }

  static const _pollInterval = Duration(seconds: 4);
  static const _pollTimeout = Duration(minutes: 8);

  /// Polls GET /designs/{id} until its status leaves "processing". Used by [visualize] and
  /// [regenerate], both of which return immediately with a "processing" design while the
  /// actual generation runs as a background task on the backend.
  Future<DesignModel> _pollUntilComplete(String designId) async {
    final deadline = DateTime.now().add(_pollTimeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(_pollInterval);
      final design = await getDesign(designId);
      if (design.isProcessing) continue;
      if (design.isFailed) {
        throw ApiException(
            design.errorMessage ?? 'Generation failed. Please try again.');
      }
      return design;
    }
    throw ApiException(
        'This is taking longer than expected. Check History in a few minutes — it may still complete in the background.');
  }

  // ---- Designs / history ----

  Future<List<DesignModel>> listDesigns({bool favouritesOnly = false}) async {
    final response = await _dio
        .get('/designs', queryParameters: {'favourites_only': favouritesOnly});
    return (response.data as List)
        .map((e) => DesignModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DesignModel> getDesign(String id) async {
    final response = await _dio.get('/designs/$id');
    return DesignModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DesignModel> updateDesign(String id,
      {bool? isFavourite, bool? isSaved, String? lookStyle}) async {
    final response = await _dio.patch('/designs/$id', data: {
      if (isFavourite != null) 'is_favourite': isFavourite,
      if (isSaved != null) 'is_saved': isSaved,
      if (lookStyle != null) 'look_style': lookStyle,
    });
    return DesignModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteDesign(String id) => _dio.delete('/designs/$id');

  Future<String> getWhatsappMessage(String id) async {
    final response = await _dio.get('/designs/$id/whatsapp-message');
    return (response.data as Map<String, dynamic>)['message'] as String;
  }

  // ---- Cart / buy materials ----

  Future<CartSummaryModel> getCart() async {
    final response = await _dio.get('/cart');
    return CartSummaryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CartSummaryModel> addDesignToCart(String designId) async {
    final response =
        await _dio.post('/cart/add', data: {'design_id': designId});
    return CartSummaryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CartSummaryModel> removeCartItem(String itemId) async {
    final response = await _dio.delete('/cart/$itemId');
    return CartSummaryModel.fromJson(response.data as Map<String, dynamic>);
  }
}
