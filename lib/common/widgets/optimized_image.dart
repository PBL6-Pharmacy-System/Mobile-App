import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Widget tối ưu để hiển thị hình ảnh từ network
/// - Cache hình ảnh để load nhanh hơn lần sau
/// - Hiển thị placeholder shimmer khi đang load
/// - Hiển thị error widget khi load thất bại
class OptimizedImage extends StatelessWidget {
  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      // Placeholder khi đang load
      placeholder: (context, url) => placeholder ?? _buildShimmerPlaceholder(),
      // Widget hiển thị khi load lỗi
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
      // Cache config
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
      // Memory cache
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildShimmerPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey[400],
        size: 32,
      ),
    );
  }
}

/// Widget hiển thị avatar với cache
class OptimizedAvatar extends StatelessWidget {
  const OptimizedAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24,
    this.backgroundColor,
    this.placeholder,
  });

  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[200],
        child:
            placeholder ??
            Icon(Icons.person, size: radius, color: Colors.grey[400]),
      );
    }

    // Xử lý URL - đảm bảo URL hợp lệ
    String finalUrl = imageUrl!;
    // Nếu URL bắt đầu bằng /uploads, thêm base URL
    if (finalUrl.startsWith('/uploads')) {
      finalUrl = 'http://192.168.1.88:3000$finalUrl';
    }
    // Log để debug
    debugPrint('🖼️ [OptimizedAvatar] Loading image: $finalUrl');

    return CachedNetworkImage(
      imageUrl: finalUrl,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[200],
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[200],
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[200],
        child:
            placeholder ??
            Icon(Icons.person, size: radius, color: Colors.grey[400]),
      ),
    );
  }
}
