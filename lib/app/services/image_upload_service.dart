import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api/api_client.dart';

class ImageUploadService extends GetxService {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final ImagePicker _picker = ImagePicker();
  
  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      print('🖼️ Opening gallery picker...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      print('📷 Gallery picker result: ${image?.path ?? 'null'}');
      if (image != null) {
        print('📝 Image details - Name: ${image.name}, Size: ${await image.length()} bytes');
      }
      return image;
    } catch (e) {
      print('❌ Gallery picker error: $e');
      Get.snackbar('Error', 'Failed to pick image from gallery');
      return null;
    }
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      print('📸 Opening camera...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      print('📷 Camera result: ${image?.path ?? 'null'}');
      if (image != null) {
        print('📝 Image details - Name: ${image.name}, Size: ${await image.length()} bytes');
      }
      return image;
    } catch (e) {
      print('❌ Camera error: $e');
      Get.snackbar('Error', 'Failed to capture image from camera');
      return null;
    }
  }

  /// Upload image to backend API using the new base64 endpoint
  Future<String?> uploadImage(XFile imageFile, {String? folder}) async {
    try {
      print('🚀 Starting image upload...');
      
      // Validate image first
      if (!await validateImageForUpload(imageFile)) {
        return null;
      }
      
      // Read file as bytes and convert to base64
      print('📖 Reading image file...');
      final bytes = await imageFile.readAsBytes();
      final base64Content = base64Encode(bytes);
      
      print('📊 File size: ${bytes.length} bytes');
      print('📊 Base64 length: ${base64Content.length} characters');
      
      // Prepare request body for new API
      final requestBody = {
        'base64Content': base64Content,
        'fileName': imageFile.name,
        'folderName': folder ?? 'general', // Default to general folder
        'contentType': 'image/jpeg', // Default content type
      };
      
      print('🌐 Uploading to: ${ApiClient.baseUrl}${ApiClient.apiPath}/UploadFile');
      
      // Send POST request with JSON body
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}${ApiClient.apiPath}/UploadFile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Upload response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Handle both lowercase 'success' and uppercase 'Success'
        final isSuccess = jsonResponse['success'] == true || jsonResponse['Success'] == true;
        
        if (isSuccess) {
          // Get the FileKey from upload response
          final fileKey = jsonResponse['FileKey'] as String?;
          final bucketName = jsonResponse['BucketName'] as String?;
          
          if (fileKey != null) {
            // Use API to get presigned URL for the uploaded file
            final presignedUrl = await getPresignedUrl(fileKey);
            if (presignedUrl != null) {
              print('✅ Upload successful with presigned URL: $presignedUrl');
              return presignedUrl;
            } else {
              // Fallback to direct S3 URL if presigned URL fails
              if (bucketName != null) {
                final fallbackUrl = 'https://$bucketName.s3.amazonaws.com/$fileKey';
                print('✅ Upload successful with fallback URL: $fallbackUrl');
                return fallbackUrl;
              }
            }
          }
          
          // Try direct fileUrl if available
          final directUrl = jsonResponse['fileUrl'] as String?;
          if (directUrl != null) {
            print('✅ Upload successful with direct URL: $directUrl');
            return directUrl;
          }
          
          print('❌ No valid URL found in response');
          return null;
        } else {
          final error = jsonResponse['errorMessage'] ?? jsonResponse['ErrorMessage'] ?? 'Upload failed';
          print('❌ Upload failed: $error');
          Get.snackbar('Error', error);
          return null;
        }
      } else {
        try {
          final errorResponse = jsonDecode(response.body);
          final error = errorResponse['errorMessage'] ?? 'Upload failed';
          print('❌ Upload failed: $error');
          Get.snackbar('Error', error);
        } catch (e) {
          print('❌ Upload failed with status ${response.statusCode}');
          Get.snackbar('Error', 'Upload failed with status ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      print('💥 Upload error: $e');
      Get.snackbar('Error', 'Failed to upload image: ${e.toString()}');
      return null;
    }
  }

  /// Upload profile image using the new base64 API endpoint
  Future<String?> uploadProfileImage(XFile imageFile) async {
    try {
      print('🚀 Starting profile image upload...');
      
      // Validate image first
      if (!await validateImageForUpload(imageFile)) {
        return null;
      }
      
      // Read file as bytes and convert to base64
      print('📖 Reading image file...');
      final bytes = await imageFile.readAsBytes();
      final base64Content = base64Encode(bytes);
      
      print('📊 File size: ${bytes.length} bytes');
      print('📊 Base64 length: ${base64Content.length} characters');
      
      // Prepare request body for new API
      final requestBody = {
        'base64Content': base64Content,
        'fileName': imageFile.name,
        'folderName': 'profiles', // Profile images folder
        'contentType': 'image/jpeg', // Default content type
      };
      
      print('🌐 Uploading to: ${ApiClient.baseUrl}${ApiClient.apiPath}/UploadFile');
      
      // Send POST request with JSON body
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}${ApiClient.apiPath}/UploadFile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Upload response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Handle both lowercase 'success' and uppercase 'Success'
        final isSuccess = jsonResponse['success'] == true || jsonResponse['Success'] == true;
        
        if (isSuccess) {
          // Get the FileKey from upload response
          final fileKey = jsonResponse['FileKey'] as String?;
          final bucketName = jsonResponse['BucketName'] as String?;
          
          if (fileKey != null) {
            // Use API to get presigned URL for the uploaded file
            final presignedUrl = await getPresignedUrl(fileKey);
            if (presignedUrl != null) {
              print('✅ Upload successful with presigned URL: $presignedUrl');
              return presignedUrl;
            } else {
              // Fallback to direct S3 URL if presigned URL fails
              if (bucketName != null) {
                final fallbackUrl = 'https://$bucketName.s3.amazonaws.com/$fileKey';
                print('✅ Upload successful with fallback URL: $fallbackUrl');
                return fallbackUrl;
              }
            }
          }
          
          // Try direct fileUrl if available
          final directUrl = jsonResponse['fileUrl'] as String?;
          if (directUrl != null) {
            print('✅ Upload successful with direct URL: $directUrl');
            return directUrl;
          }
          
          print('❌ No valid URL found in response');
          return null;
        } else {
          final error = jsonResponse['errorMessage'] ?? jsonResponse['ErrorMessage'] ?? 'Profile image upload failed';
          print('❌ Upload failed: $error');
          Get.snackbar('Error', error);
          return null;
        }
      } else {
        try {
          final errorResponse = jsonDecode(response.body);
          final error = errorResponse['errorMessage'] ?? 'Profile image upload failed';
          print('❌ Upload failed: $error');
          Get.snackbar('Error', error);
        } catch (e) {
          print('❌ Upload failed with status ${response.statusCode}');
          Get.snackbar('Error', 'Profile image upload failed with status ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      print('💥 Upload error: $e');
      Get.snackbar('Error', 'Failed to upload profile image: ${e.toString()}');
      return null;
    }
  }

  /// Upload business logo using the new base64 API endpoint
  Future<String?> uploadBusinessLogo(XFile imageFile) async {
    try {
      print('🚀 Starting business logo upload...');
      
      // Validate image first
      if (!await validateImageForUpload(imageFile)) {
        return null;
      }
      
      // Read file as bytes and convert to base64
      print('📖 Reading image file...');
      final bytes = await imageFile.readAsBytes();
      final base64Content = base64Encode(bytes);
      
      print('📊 File size: ${bytes.length} bytes');
      print('📊 Base64 length: ${base64Content.length} characters');
      
      // Prepare request body for new API
      final requestBody = {
        'base64Content': base64Content,
        'fileName': imageFile.name,
        'folderName': 'logos', // Business logos folder
        'contentType': 'image/jpeg', // Default content type
      };
      
      print('🌐 Uploading to: ${ApiClient.baseUrl}${ApiClient.apiPath}/UploadFile');
      
      // Send POST request with JSON body
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}${ApiClient.apiPath}/UploadFile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Upload response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Handle both lowercase 'success' and uppercase 'Success'
        final isSuccess = jsonResponse['success'] == true || jsonResponse['Success'] == true;
        
        if (isSuccess) {
          // Get the FileKey from upload response
          final fileKey = jsonResponse['FileKey'] as String?;
          final bucketName = jsonResponse['BucketName'] as String?;
          
          if (fileKey != null) {
            // Use API to get presigned URL for the uploaded file
            final presignedUrl = await getPresignedUrl(fileKey);
            if (presignedUrl != null) {
              print('✅ Upload successful with presigned URL: $presignedUrl');
              return presignedUrl;
            } else {
              // Fallback to direct S3 URL if presigned URL fails
              if (bucketName != null) {
                final fallbackUrl = 'https://$bucketName.s3.amazonaws.com/$fileKey';
                print('✅ Upload successful with fallback URL: $fallbackUrl');
                return fallbackUrl;
              }
            }
          }
          
          // Try direct fileUrl if available
          final directUrl = jsonResponse['fileUrl'] as String?;
          if (directUrl != null) {
            print('✅ Upload successful with direct URL: $directUrl');
            return directUrl;
          }
          
          print('❌ No valid URL found in response');
          return null;
        } else {
          final error = jsonResponse['errorMessage'] ?? jsonResponse['ErrorMessage'] ?? 'Business logo upload failed';
          print('❌ Upload failed: $error');
          Get.snackbar('Error', error);
          return null;
        }
      } else {
        try {
          final errorResponse = jsonDecode(response.body);
          final error = errorResponse['errorMessage'] ?? 'Business logo upload failed';
          print('❌ Upload failed: $error');
          Get.snackbar('Error', error);
        } catch (e) {
          print('❌ Upload failed with status ${response.statusCode}');
          Get.snackbar('Error', 'Business logo upload failed with status ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      print('💥 Upload error: $e');
      Get.snackbar('Error', 'Failed to upload business logo: ${e.toString()}');
      return null;
    }
  }

  /// Show image picker options dialog
  Future<XFile?> showImagePickerDialog() async {
    XFile? selectedImage;
    
    await Get.dialog(
      AlertDialog(
        title: const Text('Select Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Get.back();
                selectedImage = await pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Get.back();
                selectedImage = await pickImageFromCamera();
              },
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

  /// Delete image from backend (which then deletes from S3)
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
      return false;
    }
  }

  /// Validate image file before upload
  bool validateImageFile(XFile file) {
    // Check file extension
    final extension = file.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      Get.snackbar('Error', 'Invalid file type. Please select a JPG, PNG, or WebP image.');
      return false;
    }

    return true;
  }

  /// Get file size in MB
  Future<double> getFileSizeInMB(XFile file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Validate file size (max 5MB)
  Future<bool> validateFileSize(XFile file, {double maxSizeMB = 5.0}) async {
    final sizeMB = await getFileSizeInMB(file);
    if (sizeMB > maxSizeMB) {
      Get.snackbar('Error', 'File size cannot exceed ${maxSizeMB}MB. Current size: ${sizeMB.toStringAsFixed(1)}MB');
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
      print('🔗 Getting presigned URL for: $fileKey');
      
      // Prepare request body for presigned URL API
      final requestBody = {
        'folderName': fileKey.contains('/') ? fileKey.split('/').first : 'general',
        'fileKeys': [fileKey],
        'expirationHours': 24, // 24 hours expiration
      };
      
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}${ApiClient.apiPath}/GetPresignedUrls'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Presigned URL response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final isSuccess = jsonResponse['success'] == true || jsonResponse['Success'] == true;
        
        if (isSuccess) {
          // Handle both lowercase and uppercase field names
          final fileUrls = jsonResponse['fileUrls'] as List? ?? jsonResponse['FileUrls'] as List?;
          if (fileUrls != null && fileUrls.isNotEmpty) {
            final firstFile = fileUrls.first as Map<String, dynamic>;
            // Handle both lowercase and uppercase field names
            final presignedUrl = firstFile['presignedUrl'] as String? ?? firstFile['PresignedUrl'] as String?;
            final isAvailable = firstFile['isAvailable'] as bool? ?? firstFile['IsAvailable'] as bool? ?? false;
            
            if (isAvailable && presignedUrl != null) {
              print('✅ Presigned URL obtained: $presignedUrl');
              return presignedUrl;
            }
          }
        }
      }
      
      print('❌ Failed to get presigned URL');
      return null;
    } catch (e) {
      print('💥 Presigned URL error: $e');
      return null;
    }
  }
}
