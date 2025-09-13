import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api/api_client.dart';

class ImageUploadService extends GetxService {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final ImagePicker _picker = ImagePicker();
  
  // Web-safe iOS platform check (avoids dart:io Platform usage)
  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  
  /// iOS-safe image picker from gallery with permission handling
  Future<XFile?> pickImageFromGallery() async {
    try {
  // Check and request photo library permission on iOS
  if (_isIOS) {
        final permission = await Permission.photos.status;
        if (permission.isDenied || permission.isPermanentlyDenied) {
          final result = await Permission.photos.request();
          if (result.isDenied || result.isPermanentlyDenied) {
            _showPermissionDeniedDialog('Photo Library', 
              'Please enable Photo Library access in Settings > Privacy > Photos > FindMeBiz');
            return null;
          }
        }
      }
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        debugPrint('✅ Image picked from gallery: ${image.name}');
      }
      return image;
    } catch (e) {
      debugPrint('❌ Gallery picker error: $e');
      _showUserFriendlyError('Gallery Error', 
        'Unable to access photo gallery. Please try again or check app permissions.');
      return null;
    }
  }

  /// iOS-safe image picker from camera with comprehensive permission handling
  Future<XFile?> pickImageFromCamera() async {
    try {
      // iOS-specific permission checks
  if (_isIOS) {
        // Check camera permission
        final cameraPermission = await Permission.camera.status;
        if (cameraPermission.isDenied || cameraPermission.isPermanentlyDenied) {
          final result = await Permission.camera.request();
          if (result.isDenied) {
            _showPermissionDeniedDialog('Camera', 
              'Camera access is required to take photos. Please enable Camera access in Settings > Privacy > Camera > FindMeBiz');
            return null;
          } else if (result.isPermanentlyDenied) {
            _showPermissionSettingsDialog('Camera');
            return null;
          }
        }
      }
      
      // Attempt to open camera with error handling
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear, // More stable on iOS
      );
      
      if (image != null) {
        debugPrint('✅ Image captured from camera: ${image.name}');
        // Immediate success feedback
        Get.snackbar(
          'Photo Captured',
          'Successfully captured photo',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
        );
      } else {
        debugPrint('⚠️ Camera picker cancelled by user');
      }
      return image;
    } catch (e) {
      debugPrint('❌ Camera picker error: $e');
      
      // Specific error handling for iOS
      String errorMessage = 'Unable to access camera. Please try again.';
      if (e.toString().contains('camera_access_denied')) {
        errorMessage = 'Camera access denied. Please enable camera permissions in Settings.';
      } else if (e.toString().contains('not_available')) {
        errorMessage = 'Camera is not available on this device.';
      } else if (e.toString().contains('already_active')) {
        errorMessage = 'Camera is being used by another app. Please close other camera apps and try again.';
      }
      
      _showUserFriendlyError('Camera Error', errorMessage);
      return null;
    }
  }

  /// Show iOS Settings redirect dialog for permanently denied permissions
  void _showPermissionSettingsDialog(String permissionType) {
    Get.dialog(
      AlertDialog(
        title: Text('$permissionType Permission Required'),
        content: Text(
          '$permissionType access is permanently disabled. Please enable it in Settings > Privacy > $permissionType > FindMeBiz to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettings(); // Opens iOS Settings app
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Show permission denied dialog with instructions
  void _showPermissionDeniedDialog(String permissionType, String message) {
    Get.dialog(
      AlertDialog(
        title: Text('$permissionType Access Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show user-friendly error messages
  void _showUserFriendlyError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.orange.withOpacity(0.1),
      colorText: Colors.orange,
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Enhanced image picker dialog with better iOS support
  Future<XFile?> showImagePickerDialog() async {
    XFile? selectedImage;
    
    // Check if both camera and gallery are available
    final bool cameraAvailable = await _isCameraAvailable();
    final bool galleryAvailable = await _isGalleryAvailable();
    
    if (!cameraAvailable && !galleryAvailable) {
      _showUserFriendlyError('No Image Sources', 
        'Neither camera nor photo library is accessible. Please check app permissions.');
      return null;
    }
    
    await Get.dialog(
      AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (galleryAvailable)
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Photo Library'),
                subtitle: const Text('Choose from existing photos'),
                onTap: () async {
                  Get.back();
                  selectedImage = await pickImageFromGallery();
                },
              ),
            if (cameraAvailable)
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Camera'),
                subtitle: const Text('Take a new photo'),
                onTap: () async {
                  Get.back();
                  selectedImage = await pickImageFromCamera();
                },
              ),
            if (!cameraAvailable && !galleryAvailable)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No image sources available. Please check app permissions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
    return selectedImage;
  }

  /// Check if camera is available and has permissions
  Future<bool> _isCameraAvailable() async {
    try {
  if (_isIOS) {
        final permission = await Permission.camera.status;
        return !permission.isPermanentlyDenied;
      }
      return true; // Assume available on other platforms
    } catch (e) {
      return false;
    }
  }

  /// Check if gallery/photos is available and has permissions
  Future<bool> _isGalleryAvailable() async {
    try {
  if (_isIOS) {
        final permission = await Permission.photos.status;
        return !permission.isPermanentlyDenied;
      }
      return true; // Assume available on other platforms
    } catch (e) {
      return false;
    }
  }

  /// Upload image with enhanced error handling
  Future<String?> uploadImage(XFile imageFile, {String? folder}) async {
    try {
      debugPrint('📤 Starting image upload: ${imageFile.name}');
      
      // Validate image first
      if (!await validateImageForUpload(imageFile)) {
        return null;
      }
      
      // Read file as bytes and convert to base64
      final bytes = await imageFile.readAsBytes();
      final base64Content = base64Encode(bytes);
      
      // Prepare request body for new API
      final requestBody = {
        'base64Content': base64Content,
        'fileName': imageFile.name,
        'folderName': folder ?? 'general',
        'contentType': _getContentType(imageFile),
      };
      
      // Send POST request with timeout
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}${ApiClient.apiPath}/UploadFile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final isSuccess = jsonResponse['success'] == true || jsonResponse['Success'] == true;
        
        if (isSuccess) {
          final fileKey = jsonResponse['FileKey'] as String?;
          final bucketName = jsonResponse['BucketName'] as String?;
          
          if (fileKey != null) {
            final presignedUrl = await getPresignedUrl(fileKey);
            if (presignedUrl != null) {
              debugPrint('✅ Image uploaded successfully: $presignedUrl');
              return presignedUrl;
            } else if (bucketName != null) {
              final fallbackUrl = 'https://$bucketName.s3.amazonaws.com/$fileKey';
              debugPrint('⚠️ Using fallback URL: $fallbackUrl');
              return fallbackUrl;
            }
          }
          
          final directUrl = jsonResponse['fileUrl'] as String?;
          if (directUrl != null) {
            debugPrint('✅ Got direct URL: $directUrl');
            return directUrl;
          }
        }
      }
      
      _showUserFriendlyError('Upload Failed', 
        'Failed to upload image. Please check your internet connection and try again.');
      return null;
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      _showUserFriendlyError('Upload Error', 
        'Network error occurred. Please check your connection and try again.');
      return null;
    }
  }

  /// Get content type from XFile
  String _getContentType(XFile imageFile) {
    if (imageFile.mimeType != null && imageFile.mimeType!.isNotEmpty) {
      return imageFile.mimeType!;
    }

    final fileName = imageFile.name.toLowerCase();
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
      return 'image/jpeg';
    } else if (fileName.endsWith('.png')) {
      return 'image/png';
    } else if (fileName.endsWith('.webp')) {
      return 'image/webp';
    } else if (fileName.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/jpeg'; // Safe default
  }

  /// Upload business logo with iOS safety
  Future<String?> uploadBusinessLogo(XFile imageFile) async {
    return await uploadImage(imageFile, folder: 'logos');
  }

  /// Upload profile image with iOS safety
  Future<String?> uploadProfileImage(XFile imageFile) async {
    return await uploadImage(imageFile, folder: 'profiles');
  }

  /// Delete image from backend
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final response = await _apiClient.delete(
        '/FMB/DeleteImage',
        queryParams: {'imageUrl': imageUrl},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Delete image error: $e');
      return false;
    }
  }

  /// Validate image file with better error messages
  bool validateImageFile(XFile file) {
    if (file.mimeType != null && file.mimeType!.isNotEmpty) {
      final mimeType = file.mimeType!.toLowerCase();
      if (mimeType == 'image/jpeg' || mimeType == 'image/jpg' ||
          mimeType == 'image/png' || mimeType == 'image/webp') {
        return true;
      }
    }

    final fileName = file.name.toLowerCase();
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png') || fileName.endsWith('.webp')) {
      return true;
    }

    _showUserFriendlyError('Invalid File Type', 
      'Please select a valid image file (JPG, PNG, or WebP).');
    return false;
  }

  /// Get file size in MB
  Future<double> getFileSizeInMB(XFile file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Validate file size with user-friendly messages
  Future<bool> validateFileSize(XFile file, {double maxSizeMB = 5.0}) async {
    final sizeMB = await getFileSizeInMB(file);
    if (sizeMB > maxSizeMB) {
      _showUserFriendlyError('File Too Large', 
        'Image size (${sizeMB.toStringAsFixed(1)}MB) exceeds the ${maxSizeMB}MB limit. Please choose a smaller image.');
      return false;
    }
    return true;
  }

  /// Complete validation for image upload
  Future<bool> validateImageForUpload(XFile file) async {
    if (!validateImageFile(file)) return false;
    if (!await validateFileSize(file)) return false;
    return true;
  }

  /// Get presigned URL for a file using the API
  Future<String?> getPresignedUrl(String fileKey) async {
    try {
      final requestBody = {
        'folderName': fileKey.contains('/') ? fileKey.split('/').first : 'general',
        'fileKeys': [fileKey],
        'expirationHours': 24,
      };
      
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}${ApiClient.apiPath}/GetPresignedUrls'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final isSuccess = jsonResponse['success'] == true || jsonResponse['Success'] == true;
        
        if (isSuccess) {
          final fileUrls = jsonResponse['fileUrls'] as List? ?? jsonResponse['FileUrls'] as List?;
          if (fileUrls != null && fileUrls.isNotEmpty) {
            final firstFile = fileUrls.first as Map<String, dynamic>;
            final presignedUrl = firstFile['presignedUrl'] as String? ?? firstFile['PresignedUrl'] as String?;
            final isAvailable = firstFile['isAvailable'] as bool? ?? firstFile['IsAvailable'] as bool? ?? false;
            
            if (isAvailable && presignedUrl != null) {
              return presignedUrl;
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Presigned URL error: $e');
      return null;
    }
  }
}