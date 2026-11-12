/// shell 命令的安全静态分析器(逐值移植自上游 ShellCommandParser)——授权系统的安全核心。
///
/// 职责:把一条命令行拆成「顶层段」并分词,同时判断这条命令是否**可被静态判定**。
/// 自动放行只在「可判定 且 每一段都命中 ALLOW 规则」时发生;任何无法静态判定的构造都把命令
/// 降级为「必须弹窗、不可记忆」,避免授权被绕过。
///
/// 安全约定(务必维持):
/// - 引号感知:单/双引号内的 `&& || | ;` 等不视为分隔符,不会被错误拆段。
/// - 不可静态判定([ShellAnalysis.analyzable] = false)的触发条件:
///     · 命令替换 `$(...)`、反引号(双引号内仍生效,单引号内不生效);
///     · 子 shell / 分组括号 `(` `)`、进程替换;
///     · 输出重定向到**绝对路径**(`> /...`、`>> /...`)——可绕过 cwd 写到工作区外;
///     · 未闭合的引号。
///   相对重定向(落在 cwd=工作区内)视为安全。输入重定向 `<` 不触发。
/// - 匹配按**字面首 token**:`/usr/bin/node` 不会被 `node` 规则命中(宁可多问,不误放)。
/// - 段首的环境赋值(`FOO=bar cmd`)在取程序名/匹配时被跳过。
class ShellCommandParser {
  const ShellCommandParser._();

  static final RegExp _envAssign = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*=.*$');

  /// 已知的「子命令分发器」程序:其第一个非 flag 参数是子命令。
  /// 对这类程序,「始终允许」应连子命令一起记忆,避免仅记 `git` 就把 `git push` 一起放行。
  static const Set<String> subcommandDispatchers = {
    'git', 'gh',
    'npm', 'npx', 'yarn', 'pnpm', 'pnpx',
    'cargo', 'rustup',
    'go',
    'pip', 'pip3', 'poetry', 'uv', 'conda',
    'gradle', 'mvn', 'sbt',
    'docker', 'kubectl', 'helm',
    'adb', 'fastlane',
    'brew', 'apt', 'apt-get', 'gem', 'bundle',
    'az', 'aws', 'gcloud', 'terraform', 'ansible',
  };

  /// [segments] 顶层每一段的 token 列表;[analyzable] 是否可静态判定。
  static ShellAnalysis analyze(String command) {
    final segments = <List<String>>[];
    var current = <String>[];
    final token = StringBuffer();
    var tokenStarted = false;
    var analyzable = true;
    var quote = _quoteNone;
    // 上一个算子是输出重定向时为 true:下一个 token 若是绝对路径则判定为不可静态判定。
    var expectRedirectTarget = false;

    void flushToken() {
      if (!tokenStarted) return;
      final text = token.toString();
      if (expectRedirectTarget) {
        if (text.startsWith('/')) analyzable = false;
        expectRedirectTarget = false;
      }
      current.add(text);
      token.clear();
      tokenStarted = false;
    }

    void flushSegment() {
      flushToken();
      if (current.isNotEmpty) {
        segments.add(current);
        current = <String>[];
      }
    }

    var i = 0;
    while (i < command.length) {
      final char = command[i];
      if (quote == _quoteSingle) {
        if (char == "'") {
          quote = _quoteNone;
        } else {
          token.write(char);
          tokenStarted = true;
        }
        i++;
        continue;
      }
      if (quote == _quoteDouble) {
        if (char == '"') {
          quote = _quoteNone;
          tokenStarted = true;
          i++;
        } else if (char == '`') {
          // 双引号内命令替换/反引号仍会执行 → 不可静态判定。
          analyzable = false;
          token.write(char);
          tokenStarted = true;
          i++;
        } else if (char == r'$' && i + 1 < command.length && command[i + 1] == '(') {
          analyzable = false;
          token.write(char);
          tokenStarted = true;
          i++;
        } else {
          token.write(char);
          tokenStarted = true;
          i++;
        }
        continue;
      }
      // 引号外
      if (char == "'") {
        quote = _quoteSingle;
        tokenStarted = true;
        i++;
      } else if (char == '"') {
        quote = _quoteDouble;
        tokenStarted = true;
        i++;
      } else if (char == r'\') {
        // 行末续行跳过;其余转义取下一字符字面值。
        if (i + 1 < command.length) {
          if (command[i + 1] != '\n') {
            token.write(command[i + 1]);
            tokenStarted = true;
          }
          i += 2;
        } else {
          i++;
        }
      } else if (char == '`' || char == '(' || char == ')') {
        analyzable = false;
        token.write(char);
        tokenStarted = true;
        i++;
      } else if (char == '\n' || char == ';') {
        flushSegment();
        i++;
      } else if (char == '&') {
        flushSegment();
        i += (i + 1 < command.length && command[i + 1] == '&') ? 2 : 1;
      } else if (char == '|') {
        flushSegment();
        i += (i + 1 < command.length && command[i + 1] == '|') ? 2 : 1;
      } else if (char == '>') {
        flushToken();
        i += (i + 1 < command.length && command[i + 1] == '>') ? 2 : 1;
        expectRedirectTarget = true;
      } else if (char == '<') {
        flushToken();
        i++;
      } else if (char.trim().isEmpty) {
        flushToken();
        i++;
      } else {
        token.write(char);
        tokenStarted = true;
        i++;
      }
    }
    if (quote != _quoteNone) analyzable = false; // 未闭合引号:不可信
    flushSegment();
    return ShellAnalysis(segments: segments, analyzable: analyzable);
  }

  static const int _quoteNone = 0;
  static const int _quoteSingle = 1;
  static const int _quoteDouble = 2;

  /// 跳过段首环境赋值后的有效 token。
  static List<String> effectiveTokens(List<String> tokens) {
    var index = 0;
    while (index < tokens.length && _envAssign.hasMatch(tokens[index])) {
      index++;
    }
    return index == 0 ? tokens : tokens.sublist(index);
  }

  /// 该段默认记忆的命令前缀 = 程序名 token;空段返回 null。
  static String? programPrefix(List<String> tokens) => effectiveTokens(tokens).firstOrNull;

  /// 「始终允许」可记忆的命令前缀:
  /// - rm:递归/通配删除不可记忆;普通单文件删除记忆为完整命令前缀;
  /// - 非分发器程序:仅程序名(`cat`/`ls`);
  /// - 子命令分发器:程序名 + 紧随的第一个非 flag 子命令(`git pull`),紧跟 flag 时退化为程序名。
  static String? rememberablePrefix(List<String> tokens) {
    final effective = effectiveTokens(tokens);
    final program = effective.firstOrNull;
    if (program == null) return null;
    final rm = parseRmInfo(tokens);
    if (rm.isRm) {
      if (rm.targetPaths.isEmpty || rm.isRecursive || rm.isWildcard) return null;
      return effective.join(' ');
    }
    if (!subcommandDispatchers.contains(program)) return program;
    final sub = effective.length > 1 ? effective[1] : null;
    if (sub == null || sub.startsWith('-')) return program;
    return '$program $sub';
  }

  /// token 前缀匹配:规则 [pattern] 的 token 序列是该段有效 token 序列的前缀即命中。
  static bool matches(String pattern, List<String> segmentTokens) {
    final patternTokens = pattern
        .trim()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    if (patternTokens.isEmpty) return false;
    final effective = effectiveTokens(segmentTokens);
    if (effective.length < patternTokens.length) return false;
    for (var k = 0; k < patternTokens.length; k++) {
      if (effective[k] != patternTokens[k]) return false;
    }
    return true;
  }

  /// 解析该命令段是否为 rm 删除操作及其参数信息(是否递归、通配与目标路径)。
  static RmInfo parseRmInfo(List<String> tokens) {
    final effective = effectiveTokens(tokens);
    final program = effective.firstOrNull;
    if (program != 'rm' && program?.endsWith('/rm') != true) {
      return const RmInfo(isRm: false, isRecursive: false, isWildcard: false, targetPaths: []);
    }
    var isRecursive = false;
    var isWildcard = false;
    final targetPaths = <String>[];
    var hasDoubleDash = false;
    for (var index = 1; index < effective.length; index++) {
      final token = effective[index];
      if (!hasDoubleDash && token == '--') {
        hasDoubleDash = true;
        continue;
      }
      if (!hasDoubleDash && token.startsWith('-') && token != '-') {
        if (token == '--recursive' ||
            (!token.startsWith('--') && (token.contains('r') || token.contains('R')))) {
          isRecursive = true;
        }
        continue;
      }
      if (token.contains('*') || token.contains('?')) isWildcard = true;
      targetPaths.add(token);
    }
    return RmInfo(
      isRm: true,
      isRecursive: isRecursive,
      isWildcard: isWildcard,
      targetPaths: targetPaths,
    );
  }
}

/// 静态分析结果。
class ShellAnalysis {
  const ShellAnalysis({required this.segments, required this.analyzable});

  final List<List<String>> segments;
  final bool analyzable;
}

/// rm 段的信息。
class RmInfo {
  const RmInfo({
    required this.isRm,
    required this.isRecursive,
    required this.isWildcard,
    required this.targetPaths,
  });

  final bool isRm;
  final bool isRecursive;
  final bool isWildcard;
  final List<String> targetPaths;
}

/// 内置安全白名单(逐值移植自上游 BuiltInSafeCommands):常见且确属「只读、无副作用、无网络、
/// 不派生子进程」的命令前缀,自动放行不弹窗。代码内置、不可变——容器内的 AI 无法改写给自己扩权。
///
/// 设计原则(务必维持):只收录「无论如何传参都只读」的命令;能写文件、改状态、联网、或派生执行
/// 子进程的命令一律不收(node/python/sh -c/env/xargs/find/sed/awk/curl/wget/git 的写子命令等)。
class BuiltInSafeCommands {
  const BuiltInSafeCommands._();

  /// git 中「任意参数都只读」的子命令前缀。
  static const List<String> gitReadOnlyPrefixes = [
    'git status', 'git log', 'git diff', 'git show', 'git blame',
    'git rev-parse', 'git ls-files', 'git describe', 'git for-each-ref',
    'git cat-file', 'git ls-tree', 'git config --get',
    'git stash list', 'git remote -v',
  ];

  /// 自动放行的安全命令前缀(按 token 前缀匹配)。
  static const List<String> safePrefixes = [
    // 目录/文件元信息查看(只读)
    'ls', 'pwd', 'tree', 'stat', 'file', 'du', 'df',
    'basename', 'dirname', 'realpath', 'readlink', 'lsof',
    // 文件内容查看(只读)
    'cat', 'head', 'tail', 'less', 'more', 'wc', 'nl', 'tac', 'paste', 'column',
    // 搜索(只读)
    'grep', 'egrep', 'fgrep', 'rg', 'ack', 'zgrep',
    // 文本处理(只读;不含 sed/awk,二者可 -i/system 改文件)
    'sort', 'uniq', 'cut', 'tr', 'fold', 'fmt', 'expand', 'unexpand', 'rev', 'comm', 'diff', 'cmp',
    // 信息/查找/系统监视(只读;不含 env/printenv)
    'echo', 'printf', 'date', 'whoami', 'id', 'uname', 'hostname', 'uptime', 'nproc', 'cal',
    'which', 'type', 'whereis', 'locate', 'getconf',
    'ps', 'top', 'free', 'htop', 'vmstat', 'lscpu', 'lsblk', 'arch', 'clear', 'history', 'true', 'false',
    ...gitReadOnlyPrefixes,
  ];

  /// 该段是否命中任一内置安全前缀。
  static bool isSafe(List<String> segmentTokens) =>
      safePrefixes.any((prefix) => ShellCommandParser.matches(prefix, segmentTokens));
}