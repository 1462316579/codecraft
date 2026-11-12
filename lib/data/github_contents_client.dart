import 'dart:convert';

import 'package:dio/dio.dart';

/// GitHub Contents API 客户端：直接通过 REST API 读写文件，无需 SSH/gh CLI。
///
/// 限制：Contents API 只能看到 Git 提交状态，无法反映 Codespace 内未提交的改动。
/// 适用于：文件浏览、读取已提交文件、创建/更新文件（自动创建 commit）。
class GitHubContentsClient {
  GitHubContentsClient({
    required this.token,
    required this.owner,
    required this.repo,
    this.ref,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final String token;
  final String owner;
  final String repo;
  final String? ref;
  final Dio _dio;

  String get _baseUrl => 'https://api.github.com';

  Map<String, String> get headers => {
        'Accept': 'application/vnd.github+json',
        'Authorization': 'Bearer $token',
        'X-GitHub-Api-Version': '2022-11-28',
      };

  Map<String, String> get _headers => headers;

  /// 列出目录内容。
  ///
  /// 返回条目列表，每个条目包含 name/type/path/size/sha。
  /// type 为 'file' 或 'dir'。
  Future<List<ContentEntry>> listDir(String path) async {
    final url = '$_baseUrl/repos/$owner/$repo/contents/${_encodePath(path)}';
    final params = <String, String>{};
    if (ref != null && ref!.isNotEmpty) params['ref'] = ref!;

    final response = await _dio.get<Map<String, dynamic>>(
      url,
      queryParameters: params.isEmpty ? null : params,
      options: Options(headers: _headers),
    );

    final data = response.data;
    if (data is List) {
      return (data as List)
          .whereType<Map<String, dynamic>>()
          .map(ContentEntry.fromJson)
          .toList();
    }
    // 单文件返回
    if (data is Map<String, dynamic>) {
      return [ContentEntry.fromJson(data)];
    }
    return [];
  }

  /// 读取文件内容（文本）。
  Future<String> readFile(String path) async {
    final url = '$_baseUrl/repos/$owner/$repo/contents/${_encodePath(path)}';
    final params = <String, String>{};
    if (ref != null && ref!.isNotEmpty) params['ref'] = ref!;

    final response = await _dio.get<Map<String, dynamic>>(
      url,
      queryParameters: params.isEmpty ? null : params,
      options: Options(headers: _headers),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final content = data['content'] as String?;
      final encoding = data['encoding'] as String?;
      if (content != null && encoding == 'base64') {
        return utf8.decode(base64.decode(content.replaceAll('\n', '')));
      }
      return content ?? '';
    }
    throw Exception('Unexpected response format');
  }

  /// 读取文件内容（二进制）。
  Future<List<int>> readBytes(String path) async {
    final url = '$_baseUrl/repos/$owner/$repo/contents/${_encodePath(path)}';
    final params = <String, String>{};
    if (ref != null && ref!.isNotEmpty) params['ref'] = ref!;

    final response = await _dio.get<Map<String, dynamic>>(
      url,
      queryParameters: params.isEmpty ? null : params,
      options: Options(headers: _headers),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final content = data['content'] as String?;
      final encoding = data['encoding'] as String?;
      if (content != null && encoding == 'base64') {
        return base64.decode(content.replaceAll('\n', ''));
      }
    }
    throw Exception('Unexpected response format');
  }

  /// 写入文件（创建或更新）。
  ///
  /// [message] 为 commit message。如果文件已存在，需要传入其 SHA。
  Future<void> writeFile(String path, String content, {String? message, String? sha}) async {
    final url = '$_baseUrl/repos/$owner/$repo/contents/${_encodePath(path)}';
    final body = <String, dynamic>{
      'message': message ?? 'Update $path',
      'content': base64.encode(utf8.encode(content)),
    };
    if (ref != null && ref!.isNotEmpty) body['branch'] = ref!;
    if (sha != null) body['sha'] = sha;

    await _dio.put<Map<String, dynamic>>(
      url,
      data: body,
      options: Options(headers: _headers),
    );
  }

  /// 获取文件的 SHA（用于更新）。
  Future<String?> getFileSha(String path) async {
    try {
      final url = '$_baseUrl/repos/$owner/$repo/contents/${_encodePath(path)}';
      final params = <String, String>{};
      if (ref != null && ref!.isNotEmpty) params['ref'] = ref!;

      final response = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: params.isEmpty ? null : params,
        options: Options(headers: _headers),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['sha'] as String?;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
    return null;
  }

  /// 检查文件/目录是否存在。
  Future<bool> exists(String path) async {
    try {
      final url = '$_baseUrl/repos/$owner/$repo/contents/${_encodePath(path)}';
      final params = <String, String>{};
      if (ref != null && ref!.isNotEmpty) params['ref'] = ref!;

      await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: params.isEmpty ? null : params,
        options: Options(headers: _headers),
      );
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return false;
      rethrow;
    }
  }

  /// 检查是否为目录。
  Future<bool> isDirectory(String path) async {
    try {
      final entries = await listDir(path);
      return entries.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// 删除文件。
  Future<void> deleteFile(String path, String sha) async {
    final url = '$_baseUrl/repos/$owner/$repo/contents/${_encodePath(path)}';
    await _dio.delete<Map<String, dynamic>>(
      url,
      data: {
        'message': 'Delete $path',
        'sha': sha,
      },
      options: Options(headers: _headers),
    );
  }

  String _encodePath(String path) {
    // Remove leading slash
    final cleaned = path.startsWith('/') ? path.substring(1) : path;
    if (cleaned.isEmpty) return '';
    return cleaned.split('/').map(Uri.encodeComponent).join('/');
  }
}

/// Contents API 返回的条目。
class ContentEntry {
  const ContentEntry({
    required this.name,
    required this.path,
    required this.type,
    this.size = 0,
    this.sha = '',
  });

  final String name;
  final String path;
  final String type; // 'file' or 'dir'
  final int size;
  final String sha;

  bool get isFile => type == 'file';
  bool get isDir => type == 'dir';

  factory ContentEntry.fromJson(Map<String, dynamic> json) => ContentEntry(
        name: json['name'] as String? ?? '',
        path: json['path'] as String? ?? '',
        type: json['type'] as String? ?? 'file',
        size: (json['size'] as num?)?.toInt() ?? 0,
        sha: json['sha'] as String? ?? '',
      );
}
