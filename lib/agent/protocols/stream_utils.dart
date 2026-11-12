import 'dart:async';

/// [forwardStream] 的事件处理结果:继续或结束本轮流。
enum ForwardAction { next, finish }

/// 首个事件的最长等待:超时以 [onTimeout] 给出的错误收尾(上层据此断开并重试)。
///
/// 只约束第一个事件,之后的静默间隔由调用方的空闲超时负责;
/// 与 [forwardStream] 同理用控制器转发,保证静默期取消能即时透传。
Stream<T> firstByteTimeoutStream<T>({
  required Stream<T> source,
  required Duration timeout,
  required Object Function() onTimeout,
}) {
  late StreamController<T> controller;
  StreamSubscription<T>? subscription;
  Timer? timer;
  var done = false;

  void finish() {
    timer?.cancel();
    timer = null;
  }

  void fail(Object error) {
    if (done) return;
    done = true;
    finish();
    unawaited(subscription?.cancel());
    controller.addError(error);
    unawaited(controller.close());
  }

  controller = StreamController<T>(
    onListen: () {
      timer = Timer(timeout, () => fail(onTimeout()));
      subscription = source.listen(
        (event) {
          if (done) return;
          finish();
          controller.add(event);
        },
        onError: (Object error, StackTrace stack) {
          if (done) return;
          done = true;
          finish();
          controller.addError(error, stack);
          unawaited(controller.close());
        },
        onDone: () {
          if (done) return;
          done = true;
          finish();
          unawaited(controller.close());
        },
      );
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () async {
      done = true;
      finish();
      await subscription?.cancel();
    },
  );
  return controller.stream;
}

/// 把「上游事件流 → 下游分块流」的逐事件映射实现为控制器转发。
///
/// 为什么不用 async* 生成器:生成器只在「产出」的时刻响应订阅取消,
/// 处于静默期(反复过滤、等待上游数据)时取消会被挂住(实测)。
/// 这里用 StreamController 把 pause/resume/cancel 立即透传给上游订阅,
/// 保证「停止生成」能即时生效、连接能立即关闭。
Stream<Out> forwardStream<In, Out>({
  required Stream<In> source,
  required ForwardAction Function(In event, void Function(Out) emit) onEvent,

  /// 上游正常结束(未走 [ForwardAction.finish])时调用;抛错即以下游错误收尾。
  void Function(void Function(Out) emit)? onDone,
}) {
  late StreamController<Out> controller;
  StreamSubscription<In>? subscription;
  var done = false;

  void emit(Out chunk) {
    if (!done) controller.add(chunk);
  }

  void fail(Object error, StackTrace stack) {
    if (done) return;
    done = true;
    controller.addError(error, stack);
    unawaited(controller.close());
  }

  controller = StreamController<Out>(
    onListen: () {
      subscription = source.listen(
        (event) {
          if (done) return;
          final ForwardAction action;
          try {
            action = onEvent(event, emit);
          } catch (error, stack) {
            fail(error, stack);
            unawaited(subscription?.cancel());
            return;
          }
          if (action == ForwardAction.finish) {
            done = true;
            unawaited(subscription?.cancel());
            unawaited(controller.close());
          }
        },
        onError: (Object error, StackTrace stack) => fail(error, stack),
        onDone: () {
          if (done) return;
          try {
            onDone?.call(emit);
          } catch (error, stack) {
            fail(error, stack);
            return;
          }
          done = true;
          unawaited(controller.close());
        },
      );
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () async {
      done = true;
      await subscription?.cancel();
    },
  );
  return controller.stream;
}