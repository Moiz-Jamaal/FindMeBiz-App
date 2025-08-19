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
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image from gallery');
      return null;
    }
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      Get.snackbar('Error', 'Failed to capture image from camera');
      return null;
    }
  }

  /// Upload image to backend API (which then uploads to S3)
  Future<String?> uploadImage(XFile imageFile, {String? folder}) async {
    try {
      // Prepare multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiClient.baseUrl}${ApiClient.apiPath}/UploadImage'),
      );

      // Add headers (without Content-Type as it's set automatically for multipart)
      request.headers.addAll({
        'Accept': 'application/json',
      });

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: imageFile.name,
        ),
      );

      // Add folder parameter if provided
      if (folder != null) {
        request.fields['folder'] = folder;
      }

      print('🚀 Uploading to: ${request.url}'); // Debug log

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📥 Upload response: ${response.statusCode} - $responseBody'); // Debug log

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        if (jsonResponse['success'] == true) {
          return jsonResponse['url'] as String?;
        } else {
          Get.snackbar('Error', jsonResponse['error'] ?? 'Upload failed');
          return null;
        }
      } else {
        try {
          final errorResponse = jsonDecode(responseBody);
          Get.snackbar('Error', errorResponse['error'] ?? 'Upload failed');
        } catch (e) {
          Get.snackbar('Error', 'Upload failed with status ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload image: ${e.toString()}');
      print('❌ Upload error: $e'); // Debug log
      return null;
    }
  }

  /// Upload profile image
  Future<String?> uploadProfileImage(XFile imageFile) async {
    try {
      // Prepare multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiClient.baseUrl}${ApiClient.apiPath}/UploadProfileImage'),
      );

      // Add headers (without Content-Type as it's set automatically for multipart)
      request.headers.addAll({
        'Accept': 'application/json',
      });

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: imageFile.name,
        ),
      );

      print('🚀 Uploading to: ${request.url}'); // Debug log

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📥 Upload response: ${response.statusCode} - $responseBody'); // Debug log

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        if (jsonResponse['success'] == true) {
          return jsonResponse['url'] as String?;
        } else {
          Get.snackbar('Error', jsonResponse['error'] ?? 'Profile image upload failed');
          return null;
        }
      } else {
        try {
          final errorResponse = jsonDecode(responseBody);
          Get.snackbar('Error', errorResponse['error'] ?? 'Profile image upload failed');
        } catch (e) {
          Get.snackbar('Error', 'Profile image upload failed with status ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload profile image: ${e.toString()}');
      print('❌ Upload error: $e'); // Debug log
      return null;
    }
  }

  /// Upload business logo
  Future<String?> uploadBusinessLogo(XFile imageFile) async {
    try {
      // Prepare multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiClient.baseUrl}${ApiClient.apiPath}/UploadBusinessLogo'),
      );

      // Add headers (without Content-Type as it's set automatically for multipart)
      request.headers.addAll({
        'Accept': 'application/json',
      });

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: imageFile.name,
        ),
      );

      print('🚀 Uploading to: ${request.url}'); // Debug log

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📥 Upload response: ${response.statusCode} - $responseBody'); // Debug log

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        if (jsonResponse['success'] == true) {
          return jsonResponse['url'] as String?;
        } else {
          Get.snackbar('Error', jsonResponse['error'] ?? 'Business logo upload failed');
          return null;
        }
      } else {
        try {
          final errorResponse = jsonDecode(responseBody);
          Get.snackbar('Error', errorResponse['error'] ?? 'Business logo upload failed');
        } catch (e) {
          Get.snackbar('Error', 'Business logo upload failed with status ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload business logo: ${e.toString()}');
      print('❌ Upload error: $e'); // Debug log
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
}
