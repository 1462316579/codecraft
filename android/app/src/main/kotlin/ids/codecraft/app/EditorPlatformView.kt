package ids.codecraft.app

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.view.View
import android.widget.FrameLayout
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.github.rosemoe.sora.event.ContentChangeEvent
import io.github.rosemoe.sora.event.PublishSearchResultEvent
import io.github.rosemoe.sora.event.SelectionChangeEvent
import io.github.rosemoe.sora.langs.textmate.TextMateColorScheme
import io.github.rosemoe.sora.langs.textmate.TextMateLanguage
import io.github.rosemoe.sora.langs.textmate.registry.FileProviderRegistry
import io.github.rosemoe.sora.langs.textmate.registry.GrammarRegistry
import io.github.rosemoe.sora.langs.textmate.registry.ThemeRegistry
import io.github.rosemoe.sora.langs.textmate.registry.model.ThemeModel
import io.github.rosemoe.sora.langs.textmate.registry.provider.FileResolver
import io.github.rosemoe.sora.text.UndoManager
import io.github.rosemoe.sora.widget.CodeEditor
import io.github.rosemoe.sora.widget.EditorSearcher
import io.github.rosemoe.sora.widget.schemes.EditorColorScheme
import org.eclipse.tm4e.core.registry.IThemeSource
import java.io.InputStream

/**
 * TextMate 语法与主题从 Flutter 资产读取(assets/textmate/ 下,与上游 assets 同源)。
 *
 * 与上游的差别:上游用 sora 自带的 [io.github.rosemoe.sora.langs.textmate.registry.provider.AssetsFileResolver]
 * 直接读 Android assets 根;本项目的资产先经 pubspec 打进 `assets/flutter_assets/assets/`,
 * 因此用 [FlutterAssetFileResolver] 加前缀定位。
 */
object TextMateSetup {
    const val THEME_DARK = "dark_plus"
    const val THEME_LIGHT = "light_plus"

    private const val ASSET_LANGUAGES = "textmate/languages.json"

    @Volatile
    private var initialized = false

    /** 幂等:编辑器页每次打开都会调用,只有首次真正加载(语法全量解析较慢,需在后台线程)。 */
    @Synchronized
    fun ensureInitialized(context: Context) {
        if (initialized) return
        FileProviderRegistry.getInstance().addFileProvider(FlutterAssetFileResolver(context))
        // 语法与主题全量解析较慢,必须放到后台线程,否则首次打开编辑器会阻塞
        // Flutter 主线程,表现为进入内容页面先白屏、点击屏幕才显示内容。
        // 初始化完成前,applyLanguage 找不到语法会降级为纯文本(已在 scopeNameFor
        // 里做空安全),不影响已打开编辑器的正常使用;深浅主题切换时会重新应用。
        Thread {
            loadThemes()
            GrammarRegistry.getInstance().loadGrammars(ASSET_LANGUAGES)
            initialized = true
        }.start()
    }

    private fun loadThemes() {
        val registry = ThemeRegistry.getInstance()
        listOf(THEME_DARK to true, THEME_LIGHT to false).forEach { (name, dark) ->
            val path = "textmate/$name.json"
            val stream = FileProviderRegistry.getInstance().tryGetInputStream(path) ?: return@forEach
            registry.loadTheme(
                ThemeModel(IThemeSource.fromInputStream(stream, path, null), name).apply {
                    isDark = dark
                },
            )
        }
    }

    /** 切换当前语法主题,须与界面深浅一致,否则 token 配色与背景对不上。 */
    fun applyTheme(dark: Boolean) {
        ThemeRegistry.getInstance().setTheme(if (dark) THEME_DARK else THEME_LIGHT)
    }

    fun themeModel(dark: Boolean): ThemeModel? =
        ThemeRegistry.getInstance().findThemeByThemeName(if (dark) THEME_DARK else THEME_LIGHT)

    /**
     * 给出 TextMate scopeName,仅覆盖 assets/textmate/languages.json 里实际打包的语法。
     * 返回 null 表示不高亮、按纯文本显示:TextMateLanguage.create 对未注册 scope 会抛异常。
     */
    fun scopeNameFor(path: String): String? {
        val fileName = path.substringAfterLast('/')
        val scope = scopeByExtension(fileName.substringAfterLast('.', "").lowercase()) ?: return null
        return scope.takeIf { GrammarRegistry.getInstance().findGrammar(it) != null }
    }

    private fun scopeByExtension(ext: String): String? = when (ext) {
        "kt", "kts" -> "source.kotlin"
        "java" -> "source.java"
        "py", "pyw", "pyi" -> "source.python"
        "js", "mjs", "cjs", "jsx" -> "source.js"
        "ts", "mts", "cts" -> "source.ts"
        "tsx" -> "source.tsx"
        "json" -> "source.json"
        "jsonc", "json5" -> "source.json.comments"
        "yaml", "yml" -> "source.yaml"
        "sh", "bash", "zsh", "ksh", "bashrc", "zshrc", "profile" -> "source.shell"
        "go" -> "source.go"
        "rs" -> "source.rust"
        "c", "h" -> "source.c"
        "cpp", "cc", "cxx", "hpp", "hh", "hxx" -> "source.cpp"
        "css" -> "source.css"
        "php" -> "source.php"
        "lua" -> "source.lua"
        "xml" -> "text.xml"
        "html", "htm" -> "text.html.basic"
        "md", "markdown" -> "text.html.markdown"
        else -> null
    }
}

/** 从 Flutter 资产读 TextMate 文件:`textmate/x` → `flutter_assets/assets/textmate/x`。 */
class FlutterAssetFileResolver(private val context: Context) : FileResolver {
    override fun resolveStreamByPath(path: String): InputStream? = try {
        context.assets.open("flutter_assets/assets/$path")
    } catch (_: Exception) {
        null
    }
}

/**
 * 平台视图:Dart 侧传 `path` / `text` / `dark` / `fontSize` 调用 `load`,
 * 之后可用 `getText` / `setText` / `undo` / `redo` / `ensureLineVisible` 等指令操作编辑器。
 */
class EditorPlatformView(
    private val context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
) : PlatformView {
    private val container = FrameLayout(context).apply {
        layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT,
        )
    }
    private val editor = CodeEditor(context).apply {
        layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT,
        )
    }
    private var sink: EventChannel.EventSink? = null

    /** 与界面主题一致的外表层色,用于把编辑器底色向主题靠拢;null 时用兜底值。 */
    private var themeSurface: Int? = null

    init {
        TextMateSetup.ensureInitialized(context)
        container.addView(editor)

        editor.isEditable = true
        editor.isFocusable = true
        editor.isFocusableInTouchMode = true
        
        // 关键修复: 递归通知所有父容器(包括 Flutter 宿主)不要拦截触控事件
        editor.setOnTouchListener { v, _ -> 
            var parent = v.parent
            while (parent != null) {
                if (parent is android.view.View) {
                    parent.requestDisallowInterceptTouchEvent(true)
                }
                parent = parent.parent
            }
            editor.requestFocus()
            false 
        }
        
        editor.typefaceText = Typeface.MONOSPACE
        editor.typefaceText = Typeface.MONOSPACE
        editor.typefaceLineNumber = Typeface.MONOSPACE
        // 关闭字体连字,保证每个字符原样显示
        editor.setLigatureEnabled(false)
        // 关闭功能字符渲染,避免 Tab 等显示为符号占位符
        editor.setRenderFunctionCharacters(false)
        editor.nonPrintablePaintingFlags = 0
        // 关闭光标移动动画:切行时高亮原位消失、目标位出现,不逐行滑动。
        editor.isCursorAnimationEnabled = false
        // 行号左侧固定预留一点间距,避免数字贴边。
        editor.setLineNumberMarginLeft(spToPx(LINE_NUMBER_MARGIN_SP))
        // 滚到底后仍可再上滑半屏(sora 默认值,显式固定)。
        editor.verticalExtraSpaceFactor = VERTICAL_EXTRA_SPACE_FACTOR
        // sora 默认把 8 秒内的连续输入并成一条撤销记录,一次撤销会吞掉整段输入。
        UndoManager.setMergeTimeLimit(UNDO_MERGE_WINDOW_MS)

        EventChannel(messenger, "codecraft/editor/events/$viewId").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    sink = events
                }

                override fun onCancel(arguments: Any?) {
                    sink = null
                }
            },
        )

        editor.subscribeEvent(ContentChangeEvent::class.java) { event, _ ->
            // UndoManager 先改文本、后移动栈指针,回调里同帧读 canUndo/canRedo 拿到的是
            // 移动前的旧值(撤销后重做键不亮、撤销到底后撤销键仍亮),延后一帧才准。
            event.editor.post {
                sink?.success(
                    mapOf(
                        "type" to "contentChanged",
                        "text" to editor.text.toString(),
                        "canUndo" to editor.canUndo(),
                        "canRedo" to editor.canRedo(),
                    ),
                )
            }
        }
        editor.subscribeEvent(SelectionChangeEvent::class.java) { _, _ ->
            val cursor = editor.cursor
            sink?.success(
                mapOf(
                    "type" to "selectionChanged",
                    "line" to cursor.leftLine + 1,
                    "column" to cursor.leftColumn + 1,
                ),
            )
        }
        // 搜索在后台线程执行,结果回来后才通知 Dart 侧更新计数。
        // sink 只能在主线程调,事件可能从搜索线程发出,统一 post 回主线程。
        // 这里不自动跳到第一个匹配:`gotoNext` 内部的 setSelectionRegion 会
        // requestFocus,把焦点从搜索框抢回编辑器并收起键盘,每敲一个字都会弹走。
        editor.subscribeEvent(PublishSearchResultEvent::class.java) { _, _ ->
            editor.post { publishSearchState() }
        }

        MethodChannel(messenger, "codecraft/editor/methods/$viewId").setMethodCallHandler { call, result ->
            handle(call, result)
        }
    }

    private fun spToPx(sp: Float): Float = sp * context.resources.displayMetrics.scaledDensity

    private fun applyLanguage(path: String) {
        val scope = TextMateSetup.scopeNameFor(path)
        editor.setEditorLanguage(
            if (scope == null) null else TextMateLanguage.create(scope, true),
        )
    }

    /**
     * 应用语法主题并把底色向界面主题靠拢。
     *
     * TextMate 主题的背景(Dark+ 的 #1E1E1E、Light+ 的纯白)是按 VSCode 的中性色调的,
     * 原样使用会让编辑区在带色温的主题下明显脱离其余界面,所以掺入九成主题表面色。
     */
    private fun applyColors(dark: Boolean, surface: Int?) {
        if (surface != null) themeSurface = surface
        TextMateSetup.applyTheme(dark)
        val model = TextMateSetup.themeModel(dark) ?: return
        editor.setColorScheme(TextMateColorScheme.create(model))
        val scheme = editor.colorScheme
        val base = scheme.getColor(EditorColorScheme.WHOLE_BACKGROUND)
        val tinted = themeSurface?.let { lerpColor(base, it, EDITOR_THEME_TINT) } ?: base
        scheme.setColor(EditorColorScheme.WHOLE_BACKGROUND, tinted)
        // 行号 gutter 与编辑区拉开一点亮度差,便于区分;随主题自适应。
        scheme.setColor(
            EditorColorScheme.LINE_NUMBER_BACKGROUND,
            lerpColor(tinted, if (dark) Color.WHITE else Color.BLACK, 0.08f),
        )
        scheme.setColor(
            EditorColorScheme.LINE_NUMBER,
            if (dark) 0xFF64748B.toInt() else 0xFF8E8E93.toInt(),
        )
        scheme.setColor(
            EditorColorScheme.CURRENT_LINE,
            if (dark) 0xFF13273F.toInt() else 0xFFF2F2F7.toInt(),
        )
        scheme.setColor(EditorColorScheme.SELECTION_INSERT, 0xFF2563EB.toInt())
        editor.invalidate()
    }

    private fun lerpColor(from: Int, to: Int, fraction: Float): Int = Color.argb(
        (Color.alpha(from) + (Color.alpha(to) - Color.alpha(from)) * fraction).toInt(),
        (Color.red(from) + (Color.red(to) - Color.red(from)) * fraction).toInt(),
        (Color.green(from) + (Color.green(to) - Color.green(from)) * fraction).toInt(),
        (Color.blue(from) + (Color.blue(to) - Color.blue(from)) * fraction).toInt(),
    )

    /** 根据「显示空白符号」合成 sora 的非打印字符绘制标志。 */
    private fun applyNonPrintable(whitespace: Boolean) {
        var flags = 0
        if (whitespace) {
            flags = flags or CodeEditor.FLAG_DRAW_WHITESPACE_LEADING or
                CodeEditor.FLAG_DRAW_WHITESPACE_INNER or
                CodeEditor.FLAG_DRAW_WHITESPACE_TRAILING or
                CodeEditor.FLAG_DRAW_WHITESPACE_FOR_EMPTY_LINE or
                CodeEditor.FLAG_DRAW_LINE_SEPARATOR
        }
        editor.nonPrintablePaintingFlags = flags
    }

    /** 符号栏方向键:水平移动一个字符,跨越行首/行尾时换到相邻行。 */
    private fun moveCursor(forward: Boolean) {
        val cursor = editor.cursor
        val line = cursor.leftLine
        val column = cursor.leftColumn
        if (forward) {
            val lineLength = editor.text.getColumnCount(line)
            when {
                column < lineLength -> editor.setSelection(line, column + 1)
                line < editor.lineCount - 1 -> editor.setSelection(line + 1, 0)
            }
        } else {
            when {
                column > 0 -> editor.setSelection(line, column - 1)
                line > 0 -> editor.setSelection(line - 1, editor.text.getColumnCount(line - 1))
            }
        }
    }

    /**
     * 把目标行滚到可视区中部。
     *
     * 按布局算出的目标偏移可能因布局尚未就绪而为空,此时退回 sora 官方的「仅保证可见」。
     * Dart 侧会在若干帧后重试:设置迟到、语法分析完成、自动换行重排都会把位置冲掉。
     */
    private fun ensureLineVisible(line: Int) {
        if (editor.lineCount <= 0) return
        val target = line.coerceIn(0, editor.lineCount - 1)
        editor.setSelection(target, 0)
        val desired = runCatching {
            val rowBottom = editor.layout.getCharLayoutOffset(target, 0)[0]
            val rowTop = rowBottom - editor.rowHeight
            (rowTop - (editor.height - editor.rowHeight) / 2f).toInt()
                .coerceIn(0, editor.scrollMaxY.coerceAtLeast(0))
        }.getOrNull()
        if (desired == null) {
            editor.ensurePositionVisible(target, 0)
            return
        }
        editor.scroller.startScroll(editor.offsetX, editor.offsetY, 0, desired - editor.offsetY, 0)
        editor.scroller.abortAnimation()
        editor.invalidate()
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "load" -> {
                val path = call.argument<String>("path").orEmpty()
                val text = call.argument<String>("text").orEmpty()
                val dark = call.argument<Boolean>("dark") ?: false
                val fontSize = call.argument<Number>("fontSize")?.toFloat() ?: 14f
                applyColors(dark, call.argument<Number>("surface")?.toInt())
                editor.setTextSize(fontSize)
                editor.setText(text)
                
                // 强力唤醒: 立即切换容器可见性, 强迫合成器刷新快照
                container.post {
                    container.visibility = android.view.View.INVISIBLE
                    container.post {
                        container.visibility = android.view.View.VISIBLE
                        editor.requestFocus()
                        editor.isFocusable = true
                        editor.isFocusableInTouchMode = true
                        editor.setSelection(0, 0)
                        container.invalidate()
                    }
                }
                
                applyLanguage(path)
                result.success(null)
            }
            "getText" -> result.success(editor.text.toString())
            "setText" -> {
                editor.setText(call.argument<String>("text").orEmpty())
                container.post {
                    container.visibility = android.view.View.INVISIBLE
                    container.post {
                        container.visibility = android.view.View.VISIBLE
                        editor.requestFocus()
                        editor.isFocusable = true
                        editor.isFocusableInTouchMode = true
                        editor.setSelection(0, 0)
                        container.invalidate()
                    }
                }
                result.success(null)
            }
            "setTheme" -> {
                applyColors(
                    call.argument<Boolean>("dark") ?: false,
                    call.argument<Number>("surface")?.toInt(),
                )
                result.success(backgroundColor())
            }
            "setFontSize" -> {
                editor.setTextSize(call.argument<Number>("size")?.toFloat() ?: 14f)
                result.success(null)
            }
            "setWordwrap" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                editor.isWordwrap = enabled
                editor.invalidate()
                editor.requestLayout()
                result.success(null)
            }
            "setIndentGuide" -> {
                editor.isBlockLineEnabled = call.argument<Boolean>("enabled") ?: true
                result.success(null)
            }
            "applySettings" -> {
                val args = call.arguments as? Map<String, Any> ?: emptyMap()
                (args["fontSize"] as? Number)?.toFloat()?.let { editor.setTextSize(it) }
                (args["wordWrap"] as? Boolean)?.let {
                    editor.isWordwrap = it
                    editor.invalidate()
                    editor.requestLayout()
                }
                (args["showIndentGuide"] as? Boolean)?.let { editor.isBlockLineEnabled = it }
                (args["showWhitespace"] as? Boolean)?.let { applyNonPrintable(it) }
                result.success(null)
            }
            "commitText" -> {
                editor.commitText(call.argument<String>("text").orEmpty())
                result.success(null)
            }
            "moveCursor" -> {
                moveCursor(call.argument<Boolean>("forward") ?: true)
                result.success(null)
            }
            "ensureLineVisible" -> {
                ensureLineVisible(call.argument<Number>("line")?.toInt() ?: 0)
                result.success(null)
            }
            "getLineCount" -> result.success(editor.lineCount)
            "getBackgroundColor" -> result.success(backgroundColor())
            "replaceAll" -> {
                // 整文替换:包在 batch edit 里,一次撤销就能回到替换前(排版用)。
                val text = call.argument<String>("text").orEmpty()
                val content = editor.text
                content.beginBatchEdit()
                try {
                    content.replace(0, content.length, text)
                } finally {
                    content.endBatchEdit()
                }
                result.success(null)
            }
            "search" -> {
                val query = call.argument<String>("query").orEmpty()
                if (query.isEmpty()) {
                    editor.searcher.stopSearch()
                } else {
                    editor.searcher.search(
                        query,
                        EditorSearcher.SearchOptions(EditorSearcher.SearchOptions.TYPE_NORMAL, false),
                    )
                }
                result.success(null)
            }
            "searchNext" -> {
                val searcher = editor.searcher
                val moved = searcher.hasQuery() && searcher.gotoNext()
                if (moved) revealSearchMatch()
                publishSearchState()
                result.success(moved)
            }
            "searchPrevious" -> {
                val searcher = editor.searcher
                val moved = searcher.hasQuery() && searcher.gotoPrevious()
                if (moved) revealSearchMatch()
                publishSearchState()
                result.success(moved)
            }
            "stopSearch" -> {
                editor.searcher.stopSearch()
                result.success(null)
            }
            "undo" -> {
                editor.undo()
                result.success(null)
            }
            "redo" -> {
                editor.redo()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun backgroundColor(): Int = editor.colorScheme.getColor(EditorColorScheme.WHOLE_BACKGROUND)

    /**
     * 上报搜索状态(匹配总数与当前序号)。
     *
     * sora 只在一次搜索结束时发 [PublishSearchResultEvent],`gotoNext`/`gotoPrevious`
     * 不发,所以翻页后要自己补报一次,否则界面上的「第几个/共几个」会停在旧值。
     *
     * 必须先用 [EditorSearcher.hasQuery] 把门:`stopSearch()` 会把 currentPattern 置空
     * 并照样派发一次事件,此后读 `matchedPositionCount`/`currentMatchedPositionIndex`
     * 都会抛 IllegalStateException("pattern not set")。这个异常发生在主线程的 post
     * 里,没人接就是进程崩溃——点搜索框的叉必然走到这条路径。
     */
    private fun publishSearchState() {
        val searcher = editor.searcher
        val active = searcher.hasQuery()
        sink?.success(
            mapOf(
                "type" to "searchResult",
                "count" to if (active) searcher.matchedPositionCount else 0,
                "index" to if (active) searcher.currentMatchedPositionIndex else -1,
            ),
        )
    }

    /** 把当前匹配滚进可视区:匹配可能在屏幕外,不滚过去看起来就像按钮没反应。 */
    private fun revealSearchMatch() {
        val cursor = editor.cursor
        editor.ensurePositionVisible(cursor.leftLine, cursor.leftColumn)
    }

    override fun getView(): View = container

    override fun dispose() {
        sink = null
        editor.release()
    }

    private companion object {
        /** 撤销合并窗口:间隔超过它的输入不再并入上一条撤销记录。sora 默认 8000ms。 */
        const val UNDO_MERGE_WINDOW_MS = 500L

        /** 行号左侧预留间距(sp)。 */
        const val LINE_NUMBER_MARGIN_SP = 2f

        /** 垂直额外视口空间系数(占编辑器高度的比例),用于底部过度滚动。 */
        const val VERTICAL_EXTRA_SPACE_FACTOR = 0.5f

        /** 编辑器底色向主题表面色靠拢的比例。 */
        const val EDITOR_THEME_TINT = 0.9f
    }
}

/** PlatformView 工厂:每个实例分配独立 viewId,供方法/事件通道区分。 */
class EditorViewFactory(private val messenger: BinaryMessenger) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        EditorPlatformView(context, messenger, viewId)
}