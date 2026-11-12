// Git 领域模型(对齐上游 feature/git/domain/model/GitModels.kt)。

/// 一条文件改动。[statusCode] 为 porcelain 风格代码(M/A/D/R/?? 等)。
class GitFileChange {
  const GitFileChange({required this.path, required this.statusCode, required this.staged});

  final String path;
  final String statusCode;
  final bool staged;

  bool get isUntracked => statusCode == '??';

  @override
  bool operator ==(Object other) =>
      other is GitFileChange &&
      other.path == path &&
      other.statusCode == statusCode &&
      other.staged == staged;

  @override
  int get hashCode => Object.hash(path, statusCode, staged);

  @override
  String toString() => 'GitFileChange($statusCode, $path, staged: $staged)';
}

class GitCommit {
  const GitCommit({
    required this.hash,
    required this.author,
    required this.date,
    required this.message,
    this.parents = const [],
    this.body = '',
  });

  final String hash;
  final String author;
  final String date;
  final String message;
  final List<String> parents;

  /// 提交说明正文(详情弹层里展示;与上游一致只取首行)。
  final String body;

  String get shortHash => hash.length <= 7 ? hash : hash.substring(0, 7);

  bool get isMerge => parents.length > 1;
}

class GitBranch {
  const GitBranch({
    required this.name,
    required this.current,
    required this.remote,
    this.upstream,
    this.ahead = 0,
    this.behind = 0,
  });

  final String name;
  final bool current;
  final bool remote;
  final String? upstream;
  final int ahead;
  final int behind;

  String get label => remote ? name.replaceFirst(RegExp(r'^[^/]+/'), '') : name;

  @override
  bool operator ==(Object other) =>
      other is GitBranch &&
      other.name == name &&
      other.current == current &&
      other.remote == remote &&
      other.upstream == upstream &&
      other.ahead == ahead &&
      other.behind == behind;

  @override
  int get hashCode => Object.hash(name, current, remote, upstream, ahead, behind);
}

class GitTag {
  const GitTag({required this.name, required this.commitHash});

  final String name;
  final String commitHash;

  @override
  bool operator ==(Object other) =>
      other is GitTag && other.name == name && other.commitHash == commitHash;

  @override
  int get hashCode => Object.hash(name, commitHash);
}

class GitStash {
  const GitStash({required this.index, required this.message, this.date = ''});

  /// `git stash list --pretty=%gd` 的原始值,形如 `stash@{0}`。
  final String index;
  final String message;
  final String date;
}

/// `git status` 聚合视图。
class GitStatus {
  const GitStatus({
    required this.branch,
    this.ahead = 0,
    this.behind = 0,
    this.staged = const [],
    this.unstaged = const [],
    this.untracked = const [],
    this.conflicted = const [],
    this.upstream,
    this.isDetached = false,
    this.isMerging = false,
  });

  final String branch;
  final int ahead;
  final int behind;

  /// 已暂存的改动(含 staged 的新增/删除/重命名)。
  final List<GitFileChange> staged;
  final List<GitFileChange> unstaged;

  /// 未跟踪(未暂存的新文件)。多级目录按顶层目录折叠(对齐 git status 默认行为)。
  final List<String> untracked;
  final List<GitFileChange> conflicted;
  final String? upstream;
  final bool isDetached;

  /// 是否处于合并中(有未解决冲突或合并待提交)。
  final bool isMerging;

  bool get hasChanges =>
      staged.isNotEmpty || unstaged.isNotEmpty || untracked.isNotEmpty || conflicted.isNotEmpty;
}

/// Git 页的三个 Tab。
enum GitTab { status, branches, log }

/// 提交署名(user.name / user.email)。
class GitIdentity {
  const GitIdentity({this.name = '', this.email = ''});

  final String name;
  final String email;

  bool get configured => name.trim().isNotEmpty && email.trim().isNotEmpty;

  Map<String, Object?> toJson() => {'name': name, 'email': email};

  static GitIdentity fromJson(Map<String, Object?> map) => GitIdentity(
        name: (map['name'] as String?) ?? '',
        email: (map['email'] as String?) ?? '',
      );
}