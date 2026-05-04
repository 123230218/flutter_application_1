import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';

class SmartImage extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final BoxFit fit;

  const SmartImage({
    super.key,
    required this.url,
    this.width = 48,
    this.height = 48,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _buildPlaceholder();
    }

    // Handle SVG Data URIs
    if (url!.startsWith('data:image/svg+xml;base64,')) {
      try {
        final base64String = url!.substring(26);
        final decoded = base64.decode(base64String);
        return SvgPicture.memory(
          decoded,
          width: width,
          height: height,
          fit: fit,
          placeholderBuilder: (_) => _buildLoading(),
        );
      } catch (e) {
        return _buildPlaceholder();
      }
    }

    // Handle normal assets
    if (url!.startsWith('assets/')) {
      return Image.asset(
        url!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    // Handle network images
    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => _buildLoading(),
      errorWidget: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF1A1A1A),
      child: Icon(Icons.memory, size: width * 0.5, color: Colors.grey[700]),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
