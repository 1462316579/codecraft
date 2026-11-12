import 'package:codecraft/data/git/git_error_message.dart';
import 'package:flutter_test/flutter_test.dart';

/// git 失败输出的友好文案映射(`GitErrorMessage.friendly`)。
/// 每个模式匹配分支一个用例,入参尽量贴近真实 git stderr 文案,未命中时原样返回 raw。
void main() {
  // ── 删除/切换分支 ───────────────────────────────────────────

  test('删除已检出分支 → 提示先切换分支', () {
    const raw = "error: Cannot delete branch 'main' checked out at '/root/workspace'";
    expect(GitErrorMessage.friendly(raw), '无法删除当前所在分支,请先切换到其他分支');
  });

  test('分支未完全合并 → 提示无法安全删除', () {
    const raw = "error: The branch 'feat/old' is not fully merged.\n"
        "If you are sure you want to delete it, run 'git branch -D feat/old'.";
    expect(GitErrorMessage.friendly(raw), '该分支有未合并的提交,无法安全删除');
  });

  test('无效引用 → 提示不存在', () {
    expect(GitErrorMessage.friendly('fatal: invalid reference: nope'), '分支、标签或提交不存在');
  });

  test('本地改动会被覆盖 → 提示先提交或储藏', () {
    const raw = 'error: Your local changes to the following files would be overwritten by checkout:\n'
        '\tapp/src/Main.kt\nPlease commit your changes or stash them before you switch branches.';
    expect(GitErrorMessage.friendly(raw), '本地有未提交的改动会被覆盖,请先提交或储藏后再切换分支');
  });

  // ── 远程不可用 / 无权限 ─────────────────────────────────────

  test('远程不是仓库 → 提示远程不可用', () {
    expect(
      GitErrorMessage.friendly("fatal: 'origin' does not appear to be a git repository"),
      '远程仓库不可用或无访问权限',
    );
  });

  test('读不到远程 → 提示远程不可用', () {
    const raw = 'fatal: Could not read from remote repository.\n\n'
        'Please make sure you have the correct access rights and the repository exists.';
    expect(GitErrorMessage.friendly(raw), '远程仓库不可用或无访问权限');
  });

  // ── 鉴权失败 ────────────────────────────────────────────────

  test('鉴权失败 → 提示检查凭据', () {
    expect(
      GitErrorMessage.friendly(
        "fatal: Authentication failed for 'https://github.com/user/repo.git/'",
      ),
      '远程鉴权失败,请检查凭据配置(用户名/密码/Token)',
    );
  });

  test('用户名或 token 无效 → 提示检查凭据', () {
    expect(
      GitErrorMessage.friendly('fatal: Invalid username or token.'),
      '远程鉴权失败,请检查凭据配置(用户名/密码/Token)',
    );
  });

  test('Permission denied → 提示检查凭据', () {
    // 真实场景通常紧跟 “Could not read from remote repository”,但那会先命中更靠前的
    // 「远程不可用」分支(friendly 按顺序匹配),故此处仅保留 Permission denied 本身。
    expect(
      GitErrorMessage.friendly('git@github.com: Permission denied (publickey).'),
      '远程鉴权失败,请检查凭据配置(用户名/密码/Token)',
    );
  });

  test('不支持密码鉴权 → 提示未提供有效凭据', () {
    expect(
      GitErrorMessage.friendly('remote: Password authentication is not supported for GitHub.'),
      '远程鉴权失败,未提供有效凭据,请检查凭据配置',
    );
  });

  // ── 仓库不存在 ──────────────────────────────────────────────

  test('仓库不存在(大写)→ 提示仓库缺失', () {
    const raw = "remote: Repository not found.\n"
        "fatal: repository 'https://github.com/user/nope.git/' not found";
    expect(GitErrorMessage.friendly(raw), '远程仓库不存在或无访问权限');
  });

  test('repository 与 not found 组合 → 提示仓库缺失', () {
    expect(
      GitErrorMessage.friendly("fatal: repository 'https://git.example.com/team/deleted.git' not found"),
      '远程仓库不存在或无访问权限',
    );
  });

  // ── 拉取 / 推送 ─────────────────────────────────────────────

  test('无跟踪信息 → 提示无法拉取', () {
    const raw = 'There is no tracking information for the current branch.\n'
        'Please specify which branch you want to rebase against.';
    expect(GitErrorMessage.friendly(raw), '当前分支未关联远程分支,无法拉取');
  });

  test('未配置推送目标 → 提示未配置远程', () {
    const raw = 'fatal: No configured push destination.\n'
        'Either specify the URL from the command-line or configure a remote repository using\n'
        '\n    git remote add <name> <url>\n\nand then push using the remote name';
    expect(GitErrorMessage.friendly(raw), '未配置远程仓库,无法推送');
  });

  test('非快进被拒 → 提示先拉取', () {
    const raw = 'To https://github.com/user/repo.git\n'
        ' ! [rejected]        main -> main (non-fast-forward)\n'
        "error: failed to push some refs to 'https://github.com/user/repo.git'";
    expect(GitErrorMessage.friendly(raw), '推送被拒绝,远程有更新的提交,请先拉取');
  });

  test('rejected + fetch first → 提示先拉取', () {
    expect(
      GitErrorMessage.friendly(' ! [rejected]        main -> main (fetch first)'),
      '推送被拒绝,远程有更新的提交,请先拉取',
    );
  });

  test('远程已有新提交 → 提示先拉取', () {
    const raw = 'hint: Updates were rejected because the remote contains work that you do not\n'
        'hint: have locally. This is usually caused by another repository pushing\n'
        'hint: to the same ref.';
    expect(GitErrorMessage.friendly(raw), '推送被拒绝,远程有更新的提交,请先拉取');
  });

  // ── 提交署名 ────────────────────────────────────────────────

  test('未配置 who you are → 提示填写署名', () {
    const raw = '*** Please tell me who you are.\n\nRun\n\n'
        '  git config --global user.email "you@example.com"\n'
        '  git config --global user.name "Your Name"';
    expect(GitErrorMessage.friendly(raw), '尚未配置提交署名,请在设置中填写用户名和邮箱');
  });

  test('Author identity unknown → 提示填写署名', () {
    expect(
      GitErrorMessage.friendly('fatal: Author identity unknown'),
      '尚未配置提交署名,请在设置中填写用户名和邮箱',
    );
  });

  // ── 未命中 / 空输入 ─────────────────────────────────────────

  test('未命中 → 原样返回', () {
    const raw = 'fatal: bad config line 1 in file .git/config';
    expect(GitErrorMessage.friendly(raw), raw);
  });

  test('空字符串 → 返回空', () {
    expect(GitErrorMessage.friendly(''), '');
  });

  test('全空白 → 原样返回', () {
    const raw = '  \n\t ';
    expect(GitErrorMessage.friendly(raw), raw);
  });

  // ── 其余分支的补充覆盖(上游未单列用例,实现里存在)─────────

  test('仓库被占用 → 提示稍后重试', () {
    expect(
      GitErrorMessage.friendly('fatal: Unable to create /repo/.git/index.lock: File exists'),
      '仓库正被其他 Git 操作占用,请稍后重试',
    );
  });

  test('索引损坏 → 提示重新打开仓库', () {
    expect(GitErrorMessage.friendly('fatal: index file corrupt'), 'Git 索引文件已损坏,请关闭后重新打开仓库');
  });

  test('磁盘写入失败先于鉴权判断', () {
    expect(
      GitErrorMessage.friendly('error: unable to write new index file: Permission denied'),
      '无法写入仓库文件,请检查存储权限或剩余空间',
    );
  });

  test('合并冲突 → 提示前往状态页', () {
    expect(
      GitErrorMessage.friendly('CONFLICT (content): Merge conflict in a.txt\nAutomatic merge failed'),
      '合并产生冲突,请前往状态页查看并解决冲突',
    );
  });

  test('未跟踪文件会被覆盖 → 先行命中', () {
    expect(
      GitErrorMessage.friendly('error: untracked working tree files would be overwritten by merge'),
      '存在会被覆盖的未跟踪文件,请先移动或删除后再继续',
    );
  });

  test('没有可提交的改动', () {
    expect(GitErrorMessage.friendly('nothing to commit, working tree clean'), '没有需要提交的改动');
  });

  test('无共同历史', () {
    expect(
      GitErrorMessage.friendly('fatal: refusing to merge unrelated histories'),
      '两个分支没有共同历史,无法合并',
    );
  });

  test('克隆目录非空', () {
    expect(
      GitErrorMessage.friendly("fatal: destination path 'x' already exists and is not an empty directory."),
      '当前工作区目录非空,无法直接克隆到当前目录',
    );
  });

  test('网络不可达', () {
    expect(
      GitErrorMessage.friendly('fatal: unable to access ...: Could not resolve host: github.com'),
      '无法解析远程主机地址,请检查网络或代理',
    );
  });

  test('证书校验失败', () {
    expect(
      GitErrorMessage.friendly('fatal: server certificate verification failed. CAfile: none'),
      '安全连接建立失败(服务器证书校验或 TLS 握手失败)',
    );
  });

  test('无改动可储藏', () {
    expect(GitErrorMessage.friendly('No local changes to save'), '当前没有需要储藏的改动');
  });
}