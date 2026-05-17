// lib/views/widgets/product_flutter run_picker.dart
// Widget cho phép chọn file ảnh từ thiết bị và tải lên Supabase Storage
// Thư mục lưu trữ: storage/image/product

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductImagePicker extends StatefulWidget {
  /// URL ảnh hiện tại (dùng khi chỉnh sửa sản phẩm đã có ảnh)
  final String? initialImageUrl;

  /// Callback trả về URL công khai sau khi tải ảnh lên thành công
  final void Function(String imageUrl) onImageUploaded;

  const ProductImagePicker({
    super.key,
    this.initialImageUrl,
    required this.onImageUploaded,
  });

  @override
  State<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends State<ProductImagePicker> {
  static const String _bucketName = 'image';
  static const int _maxFileSizeBytes = 5 * 1024 * 1024;

  // Trạng thái đang tải lên hay không
  bool _isUploading = false;

  // URL ảnh hiển thị preview (có thể là ảnh cũ hoặc ảnh vừa tải lên)
  String? _previewUrl;

  @override
  void initState() {
    super.initState();
    // Nếu có ảnh cũ (khi sửa sản phẩm), dùng làm preview ban đầu
    _previewUrl = widget.initialImageUrl;
  }

  /// Mở hộp thoại chọn file, sau đó tải lên Supabase Storage
  Future<void> _pickAndUploadImage() async {
    // Mở trình chọn file, chỉ cho phép chọn ảnh
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true, // Cần withData: true để lấy bytes trên web & mobile
    );

    // Người dùng huỷ chọn file → thoát
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    // Kiểm tra file có dữ liệu bytes không
    if (file.bytes == null) {
      _showError('Không thể đọc file. Vui lòng thử lại.');
      return;
    }

    if (file.size > _maxFileSizeBytes) {
      _showError('Ảnh vượt quá 5MB. Vui lòng chọn ảnh nhỏ hơn.');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final Uint8List fileBytes = file.bytes!;
      final String fileName = _sanitizeFileName(file.name);

      // Tạo tên file duy nhất bằng cách thêm timestamp vào trước tên file
      // Tránh trường hợp trùng tên file trong storage
      final String uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // Đường dẫn lưu file trong bucket: image/product/<tên_file_duy_nhất>
      final String storagePath = 'product/$uniqueFileName';

      // Tải file lên Supabase Storage bucket tên "image"
      await Supabase.instance.client.storage
          .from(_bucketName)
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              // Tự động xác định loại file (image/jpeg, image/png, ...)
              contentType: _getContentType(fileName),
              // Cho phép ghi đè nếu file cùng tên đã tồn tại
              upsert: true,
            ),
          );

      // Lấy URL công khai của file vừa tải lên để lưu vào database
      final String publicUrl = Supabase.instance.client.storage
          .from(_bucketName)
          .getPublicUrl(storagePath);

      // Cập nhật preview và thông báo cho widget cha biết URL ảnh mới
      if (!mounted) return;
      setState(() => _previewUrl = publicUrl);
      widget.onImageUploaded(publicUrl);
    } catch (e) {
      // Hiển thị lỗi nếu quá trình tải lên thất bại
      _showError('Tải ảnh thất bại: ${e.toString()}');
    } finally {
      // Dù thành công hay thất bại, luôn tắt trạng thái đang tải
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  String _sanitizeFileName(String fileName) {
    final extension = fileName.contains('.')
        ? '.${fileName.split('.').last.toLowerCase()}'
        : '.jpg';
    final baseName = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    final safeBaseName = baseName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return '${safeBaseName.isEmpty ? 'product-image' : safeBaseName}$extension';
  }

  /// Xác định content type dựa vào đuôi file
  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg'; // Mặc định là jpeg nếu không nhận ra đuôi file
    }
  }

  /// Hiển thị thông báo lỗi dạng SnackBar
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  /// Xoá ảnh đã chọn (chỉ xoá preview, không xoá file trên Supabase)
  void _clearImage() {
    setState(() => _previewUrl = null);
    // Thông báo cho widget cha rằng ảnh đã bị xoá (truyền chuỗi rỗng)
    widget.onImageUploaded('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nhãn tiêu đề của phần chọn ảnh
        Text(
          'Ảnh sản phẩm',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),

        // Khu vực hiển thị preview ảnh hoặc nút chọn file
        GestureDetector(
          onTap: _isUploading ? null : _pickAndUploadImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                // Đổi màu viền khi đang tải lên
                color: _isUploading
                    ? Colors.green.shade400
                    : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: _isUploading
                // Hiển thị vòng tải khi đang upload
                ? _buildUploadingState()
                : _previewUrl != null && _previewUrl!.isNotEmpty
                // Hiển thị ảnh preview nếu đã có ảnh
                ? _buildImagePreview()
                // Hiển thị giao diện chọn file nếu chưa có ảnh
                : _buildEmptyState(),
          ),
        ),

        const SizedBox(height: 8),

        // Nút hành động phía dưới: Tải ảnh lên / Đổi ảnh / Xoá ảnh
        Row(
          children: [
            // Nút tải ảnh lên hoặc đổi ảnh
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadImage,
              icon: Icon(
                _previewUrl != null ? Icons.swap_horiz : Icons.upload_file,
                size: 18,
              ),
              label: Text(_previewUrl != null ? 'Đổi ảnh' : 'Tải ảnh lên'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                side: BorderSide(color: Colors.green.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Chỉ hiển thị nút Xoá khi đã có ảnh
            if (_previewUrl != null && _previewUrl!.isNotEmpty) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _clearImage,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Xoá ảnh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),

        // Ghi chú định dạng file được hỗ trợ
        const SizedBox(height: 4),
        Text(
          'Hỗ trợ: JPG, PNG, WEBP, GIF • Tối đa 5MB',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  /// Giao diện khi đang tải ảnh lên Supabase
  Widget _buildUploadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.green.shade600, strokeWidth: 3),
        const SizedBox(height: 12),
        Text(
          'Đang tải ảnh lên...',
          style: TextStyle(color: Colors.green.shade600, fontSize: 14),
        ),
      ],
    );
  }

  /// Giao diện hiển thị preview ảnh đã chọn/tải lên
  Widget _buildImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Hiển thị ảnh từ URL Supabase
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            _previewUrl!,
            fit: BoxFit.cover,
            // Hiển thị placeholder khi ảnh đang tải
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.green.shade600,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            // Hiển thị icon lỗi nếu ảnh không tải được
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      size: 40,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Không tải được ảnh',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Overlay mờ khi hover (chỉ hiển thị icon chỉnh sửa)
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Nhấn để đổi ảnh',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Giao diện trống khi chưa có ảnh — hiển thị icon và hướng dẫn
  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 12),
        Text(
          'Nhấn để chọn ảnh',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'hoặc kéo thả ảnh vào đây',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}
