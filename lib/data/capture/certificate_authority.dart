import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 代理抓包用的根 CA 与动态站点证书。
///
/// 所有 RSA 生成都在后台 isolate 里做:`generateRSAKeyPair` 是同步的 CPU 密集
/// 操作,跑在主 isolate 上会把事件循环卡住数秒,界面既画不出「正在抓包」,
/// 也来不及处理已到达的连接。
class CaptureCertificateAuthority {
  CaptureCertificateAuthority();

  static const String _caCertName = 'codecraft-capture-ca.crt';
  static const String _caKeyName = 'codecraft-capture-ca.key';

  String? _caCertPem;
  String? _caKeyPem;
  Map<String, String>? _caSubject;
  Directory? _dir;
  final Map<String, SecurityContext> _hostContexts = {};
  final Map<String, Future<SecurityContext>> _hostContextFutures = {};
  bool _ready = false;

  /// 首次初始化要现场生成 RSA 密钥对,在手机上要数秒。
  /// 并发调用(预热 + 首个 HTTPS 请求)必须共用同一次初始化,
  /// 否则会重复生成多份 CA,既慢又会让已安装的证书对不上。
  Future<void>? _initFuture;

  bool get ready => _ready;
  String? get caCertPem => _caCertPem;
  String? get baseDir => _dir?.path;

  Future<void> ensureInitialized() {
    if (_ready) return Future.value();
    // 失败后必须清掉缓存,否则后续调用会一直拿到同一个失败 Future,
    // 表现为 CA 永远「未就绪」、所有 HTTPS 都 MITM 失败。
    return _initFuture ??= _init().catchError((Object error, StackTrace st) {
      _initFuture = null;
      Error.throwWithStackTrace(error, st);
    });
  }

  Future<void> _init() async {
    if (_ready) return;
    _dir = Directory(p.join(
      (await getApplicationSupportDirectory()).path,
      'capture-ca',
    ));
    if (!await _dir!.exists()) await _dir!.create(recursive: true);
    final certFile = File(p.join(_dir!.path, _caCertName));
    final keyFile = File(p.join(_dir!.path, _caKeyName));

    if (await certFile.exists() && await keyFile.exists()) {
      _caCertPem = await certFile.readAsString();
      _caKeyPem = await keyFile.readAsString();
      // 必须先取到局部变量:闭包里写 _caCertPem 会隐式捕获 this,
      // 而 CaptureCertificateAuthority 不是可发送对象,Isolate.run 会直接报
      // ArgumentError: Illegal argument in isolate message。
      final certPem = _caCertPem!;
      _caSubject = await Isolate.run(() => _subjectOf(certPem));
      _ready = true;
      return;
    }

    // 首次运行:密钥对 + 自签名证书都在后台 isolate 生成。
    // 注意用顶层函数引用(而不是闭包),闭包会隐式捕获 this,
    // 而本对象不是可发送对象,Isolate.run 会抛 Illegal argument in isolate message。
    final generated = await Isolate.run(_generateCaMaterial);
    _caCertPem = generated.certPem;
    _caKeyPem = generated.keyPem;
    _caSubject = generated.subject;

    await certFile.writeAsString(_caCertPem!);
    await keyFile.writeAsString(_caKeyPem!);
    _ready = true;
  }

  /// 后台预热 CA:应用启动时就跑,避免首次点「启动」时现场生成 2048 位密钥而卡几秒。
  /// 失败不抛错——真正启动时 ensureInitialized 会重试。
  Future<void> warmUp() async {
    try {
      await ensureInitialized();
    } catch (_) {}
  }

  Future<File> exportCaCertFile() async {
    await ensureInitialized();
    return File(p.join(_dir!.path, _caCertName));
  }

  Future<Uint8List> exportCaCertBytes() async {
    await ensureInitialized();
    return Uint8List.fromList(_caCertPem!.codeUnits);
  }

  /// 为目标 host 生成/获取服务端 TLS 上下文（用于 MITM）。
  ///
  /// 首次为某个域名签发证书需要现场生成 2048 位 RSA 密钥对（手机上数百毫秒到数秒），
  /// 所以结果按 host 缓存；同一个 Future 也缓存，避免并发请求重复生成。
  Future<SecurityContext> serverContextForHost(String host) {
    final normalized = host.trim().toLowerCase();
    final cached = _hostContexts[normalized];
    if (cached != null) return Future.value(cached);
    return _hostContextFutures[normalized] ??=
        _buildHostContext(normalized).catchError((Object error, StackTrace st) {
          // 失败后清缓存:否则后续请求会一直复用同一个失败 Future,
          // 这个域名就再也抓不到了。
          _hostContextFutures.remove(normalized);
          Error.throwWithStackTrace(error, st);
        });
  }

  Future<SecurityContext> _buildHostContext(String normalized) async {
    await ensureInitialized();

    // 同样只能传局部值:闭包捕获 this 会让 Isolate.run 报 Illegal argument。
    final caKeyPem = _caKeyPem!;
    final caCertPem = _caCertPem!;
    final caSubject = Map<String, String>.from(_caSubject!);

    // 密钥对与签发同样在后台 isolate 完成,否则首个 HTTPS 请求会卡住整个界面。
    final material = await Isolate.run(
      () => _generateHostMaterial(caKeyPem, caCertPem, caSubject, normalized),
    );

    final context = SecurityContext();
    // 服务端证书链 + 私钥。
    context.useCertificateChainBytes(
      Uint8List.fromList('${material.certPem}\n$caCertPem'.codeUnits),
    );
    context.usePrivateKeyBytes(Uint8List.fromList(material.keyPem.codeUnits));
    _hostContexts[normalized] = context;
    // 建好就把 Future 换成已完成的上下文,避免长期持有键对以外的临时 Future。
    _hostContextFutures.remove(normalized);
    return context;
  }

  void clearHostCache() {
    _hostContexts.clear();
    _hostContextFutures.clear();
  }
}

/// 后台 isolate 生成的结果:证书 PEM、私钥 PEM,CA 还带 issuer subject。
class _CertMaterial {
  const _CertMaterial(this.certPem, this.keyPem, this.subject);

  final String certPem;
  final String keyPem;
  final Map<String, String> subject;
}

/// 生成根 CA:密钥对 + 自签名证书。必须是顶层函数,Isolate.run 才能执行。
_CertMaterial _generateCaMaterial() {
  final pair = CryptoUtils.generateRSAKeyPair(keySize: 2048);
  final privateKey = pair.privateKey as RSAPrivateKey;
  final publicKey = pair.publicKey as RSAPublicKey;
  final keyPem = CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);

  const dn = {
    'CN': 'CodeCraft Capture CA',
    'O': 'CodeCraft',
    'OU': 'Capture',
  };
  final csr = X509Utils.generateRsaCsrPem(dn, privateKey, publicKey);
  final certPem = X509Utils.generateSelfSignedCertificate(
    privateKey,
    csr,
    3650,
    cA: true,
    keyUsage: const [
      KeyUsage.KEY_CERT_SIGN,
      KeyUsage.CRL_SIGN,
      KeyUsage.DIGITAL_SIGNATURE,
    ],
    serialNumber: DateTime.now().millisecondsSinceEpoch.toString(),
  );
  return _CertMaterial(certPem, keyPem, _subjectOf(certPem));
}

/// 为单个域名签发由 CA 签名的服务端证书。
_CertMaterial _generateHostMaterial(
  String caKeyPem,
  String caCertPem,
  Map<String, String> caSubject,
  String host,
) {
  final caPrivateKey = CryptoUtils.rsaPrivateKeyFromPem(caKeyPem);
  final pair = CryptoUtils.generateRSAKeyPair(keySize: 2048);
  final privateKey = pair.privateKey as RSAPrivateKey;
  final publicKey = pair.publicKey as RSAPublicKey;
  final keyPem = CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);

  final dn = {'CN': host, 'O': 'CodeCraft Capture'};
  final csr = X509Utils.generateRsaCsrPem(dn, privateKey, publicKey);
  final certPem = X509Utils.generateSelfSignedCertificate(
    caPrivateKey,
    csr,
    825,
    sans: [host],
    keyUsage: const [
      KeyUsage.DIGITAL_SIGNATURE,
      KeyUsage.KEY_ENCIPHERMENT,
    ],
    extKeyUsage: const [ExtendedKeyUsage.SERVER_AUTH],
    issuer: caSubject,
    serialNumber: '${DateTime.now().microsecondsSinceEpoch}${host.hashCode.abs()}',
  );
  return _CertMaterial(certPem, keyPem, const {});
}

/// 取证书的 subject 作为签发子证书时的 issuer。
Map<String, String> _subjectOf(String certPem) {
  try {
    final data = X509Utils.x509CertificateFromPem(certPem);
    final subject = data.tbsCertificate?.subject;
    if (subject != null && subject.isNotEmpty) {
      return {
        for (final e in subject.entries)
          if (e.value != null) e.key: e.value!,
      };
    }
  } catch (_) {}
  return {'CN': 'CodeCraft Capture CA', 'O': 'CodeCraft', 'OU': 'Capture'};
}
