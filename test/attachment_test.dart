import 'dart:io';

import 'package:codecraft/agent/models/agent_attachment.dart';
import 'package:codecraft/agent/models/agent_message.dart';
import 'package:codecraft/agent/tools/workspace.dart';
import 'package:codecraft/data/attachment_store.dart';
import 'package:codecraft/features/chat/widgets/message_bubble.dart';
import 'package:codecraft/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// 1x1 透明 PNG。
const List<int> _pngBytes = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

void main() {
  late Directory root;
  late Directory source;
  late Workspace workspace;

  setUp(() {
    root = Directory.systemTemp.createTempSync('ws_attach');
    source = Directory.systemTemp.createTempSync('ws_source');
    workspace = Workspace(root.path);
  });

  tearDown(() {
    root.deleteSync(recursive: true);
    source.deleteSync(recursive: true);
  });

  File writeSource(String name, List<int> bytes) =>
      File(p.join(source.path, name))..writeAsBytesSync(bytes);

  test('上传文件:落到工作区 .codecraft/attachments,按扩展名取 MIME', () async {
    final file = writeSource('notes.md', List.filled(2048, 0x61));

    final attachment = await AttachmentStore.copyToWorkspace(
      workspace: workspace,
      sourcePath: file.path,
      fileName: 'notes.md',
      includeImageData: false,
    );

    expect(attachment.isImage, isFalse);
    expect(attachment.fileName, 'notes.md');
    expect(attachment.containerPath, '~/workspace/.codecraft/attachments/notes.md');
    expect(attachment.localPath, p.join(root.path, '.codecraft', 'attachments', 'notes.md'));
    expect(File(attachment.localPath).existsSync(), isTrue);
    expect(attachment.sizeBytes, 2048);
    expect(attachment.mimeType, 'text/plain');
  });

  test('同名文件加序号;选择器给的 MIME 优先', () async {
    final first = writeSource('a.bin', [1, 2, 3]);
    final second = writeSource('b.bin', [4, 5, 6]);

    final one = await AttachmentStore.copyToWorkspace(
      workspace: workspace,
      sourcePath: first.path,
      fileName: 'dump.bin',
      mimeTypeHint: 'application/x-custom',
      includeImageData: false,
    );
    final two = await AttachmentStore.copyToWorkspace(
      workspace: workspace,
      sourcePath: second.path,
      fileName: 'dump.bin',
      includeImageData: false,
    );

    expect(one.fileName, 'dump.bin');
    expect(one.mimeType, 'application/x-custom');
    expect(two.fileName, 'dump-1.bin');
    expect(two.containerPath, '~/workspace/.codecraft/attachments/dump-1.bin');
    expect(two.mimeType, 'application/octet-stream');
  });

  test('文件名清洗:路径分隔符与非法字符换下划线,空名回落 upload', () async {
    final file = writeSource('x.txt', [7]);

    final cleaned = await AttachmentStore.copyToWorkspace(
      workspace: workspace,
      sourcePath: file.path,
      fileName: 'a:b*c?.txt',
      includeImageData: false,
    );
    final blank = await AttachmentStore.copyToWorkspace(
      workspace: workspace,
      sourcePath: file.path,
      fileName: '   ',
      includeImageData: false,
    );

    expect(cleaned.fileName, 'a_b_c_.txt');
    expect(blank.fileName, 'upload');
  });

  test('图片:png 正常上传并读盘,bmp 与超限图片各自报错', () async {
    final png = writeSource('pic.png', _pngBytes);
    final bmp = writeSource('pic.bmp', [1, 2, 3]);
    final huge = writeSource('huge.png', List.filled(AttachmentStore.maxImageUploadBytes + 1, 0));

    final image = await AttachmentStore.copyToWorkspace(
      workspace: workspace,
      sourcePath: png.path,
      fileName: 'pic.png',
      includeImageData: true,
    );
    expect(image.isImage, isTrue);
    expect(image.mimeType, 'image/png');
    expect(image.sizeBytes, _pngBytes.length);
    expect(
      image.containerPath,
      '~/workspace/.codecraft/attachments/pic.png',
    );

    expect(
      () => AttachmentStore.copyToWorkspace(
        workspace: workspace,
        sourcePath: bmp.path,
        fileName: 'pic.bmp',
        includeImageData: true,
      ),
      throwsA(
        isA<AttachmentUploadException>().having(
          (error) => error.error,
          'error',
          AttachmentUploadError.unsupportedImageType,
        ),
      ),
    );
    expect(
      () => AttachmentStore.copyToWorkspace(
        workspace: workspace,
        sourcePath: huge.path,
        fileName: 'huge.png',
        includeImageData: true,
      ),
      throwsA(
        isA<AttachmentUploadException>().having(
          (error) => error.error,
          'error',
          AttachmentUploadError.imageTooLarge,
        ),
      ),
    );
  });

  test('附件清单拼接进请求正文', () {
    const attachments = [
      AgentAttachment(
        fileName: 'notes.md',
        containerPath: '~/workspace/.codecraft/attachments/notes.md',
        localPath: '/tmp/notes.md',
        mimeType: 'text/plain',
        sizeBytes: 10,
        isImage: false,
      ),
    ];

    expect(
      appendAttachmentsToRequest('看看这个', attachments, '附件:'),
      '看看这个\n\n附件:\n- notes.md:~/workspace/.codecraft/attachments/notes.md',
    );
    expect(
      appendAttachmentsToRequest('', attachments, '附件:'),
      '附件:\n- notes.md:~/workspace/.codecraft/attachments/notes.md',
    );
    expect(appendAttachmentsToRequest('看看这个', const [], '附件:'), '看看这个');
  });

  testWidgets('消息附件行:文件名 + 大小 · 容器路径,图片可点开预览', (tester) async {
    final root2 = Directory.systemTemp.createTempSync('ws_bubble');
    addTearDown(() => root2.deleteSync(recursive: true));
    final imageFile = File(p.join(root2.path, 'shot.png'))..writeAsBytesSync(_pngBytes);
    final message = AgentMessage(
      id: 'm1',
      sessionId: 's1',
      role: MessageRole.user,
      content: '',
      timestamp: 0,
      attachmentsJson: AgentAttachment.encodeList([
        AgentAttachment(
          fileName: 'shot.png',
          containerPath: '~/workspace/.codecraft/attachments/shot.png',
          localPath: imageFile.path,
          mimeType: 'image/png',
          sizeBytes: 67,
          isImage: true,
        ),
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MessageBubble.fromMessage(message)),
      ),
    );

    expect(find.text('shot.png'), findsOneWidget);
    expect(find.text('67 B · ~/workspace/.codecraft/attachments/shot.png'), findsOneWidget);

    await tester.tap(find.text('shot.png'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('关闭'), findsOneWidget, reason: '点图片应打开全屏查看器');

    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('关闭'), findsNothing);
  });

  test('文件大小简写', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(2048), '2 KB');
    expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
  });
}