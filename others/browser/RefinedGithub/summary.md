# GitHub 自定义 CSS 调试总结

> 工具：Refined GitHub 插件 + 自定义 CSS  
> 目标：在不破坏任何页面布局的前提下，将 GitHub 页面内容区域拓宽至 85vw

---

## 一、背景与初始方案

在 Refined GitHub 插件中注入了一段自定义 CSS，核心思路是将 GitHub 的主布局容器 `PageLayoutRoot` 限制到 85vw 并居中。初始 CSS：

```css
[class*="PageLayoutRoot"] {
  max-width: min(85vw, 100%) !important;
  min-width: 900px !important;
  margin-left: auto !important;
  margin-right: auto !important;
}
[class*="PageLayoutWrapper"] {
  max-width: 100% !important;
  width: 100% !important;
}
[data-width="large"] {
  max-width: 100% !important;
  width: 100% !important;
}
.container-lg, .container-xl {
  max-width: 100% !important;
}
```

---

## 二、问题一：Code Review diff 视图被撑宽

### 现象

PR 的「Files changed」页面中，diff 视图跟着 PageLayoutRoot 的 85vw 一起被撑宽，代码对比变得很难读。

### 调试过程

1. 最初尝试用 `:has(.js-diff-progressive-container)` 和 `:has([data-tab-item="files-tab"][aria-selected="true"])` 来检测「当前是否在 diff 页面」，均无效。
2. 在浏览器 Console 运行诊断脚本，逐步排查 PR Files changed 页面上的唯一性元素。
3. 最终发现 `#diff-comparison-viewer-container[data-side-panel-open]` 在所有 PR tab 上都存在，但 `data-side-panel-open` 属性只在 Files changed tab 激活时才出现，具有唯一性。

### 解决方案

```css
body:has(#diff-comparison-viewer-container[data-side-panel-open]) [class*="PageLayoutRoot"] {
  max-width: revert !important;
  min-width: revert !important;
  width: revert !important;
  margin-left: revert !important;
  margin-right: revert !important;
}
```

用 `revert` 关键字将宽度规则重置为浏览器默认值，而不是写死一个数值，这样对不同屏幕尺寸都能正常工作。

---

## 三、问题二：PR 列表页被误当成 README 拓宽

### 现象

`.container-lg, .container-xl` 的 `max-width: 100%` 规则过于宽泛，把 PR/Issue 列表页、Insights 页等也一并撑宽，导致布局错乱。

### 调试过程

1. 检查 PR 列表页的 DOM 结构，发现列表容器 `.js-check-all-container` 带有 `container-xl` 类，触发了 README 的宽度规则。
2. PR 列表容器位于 `PageLayoutRoot` 外部（GitHub 的特殊布局），所以不能靠父容器区分。

### 解决方案

将 `.container-lg, .container-xl` 规则限定在 `PageLayoutRoot` 内部，避免影响外部元素；同时单独为 PR/Issue 列表写一条专用规则：

```css
/* README/markdown 容器只在 PageLayoutRoot 内部拓宽 */
[class*="PageLayoutRoot"] .container-lg,
[class*="PageLayoutRoot"] .container-xl {
  max-width: 100% !important;
}

/* PR / Issue 列表单独拓宽 */
.js-check-all-container.container-xl {
  max-width: min(85vw, 100%) !important;
  width: 100% !important;
}
```

---

## 四、问题三：PR 详情页出现视觉偏移（overflow）

### 现象

PR Conversation 页面的内容区整体向右偏移，右侧出现横向滚动条，布局明显不对。

### 调试过程

1. 初步怀疑是 `margin: auto` 或 `min-width` 造成的，去掉后无效。
2. 在 Console 运行 `scrollWidth > clientWidth` 检测溢出，发现 `[class*="PageLayoutWrapper"]` 选中了最外层的一个元素，导致它被强制设置为 `max-width: 100%; width: 100%`，实际渲染宽度达到 2383px（视口只有 1728px），从而撑破了整个页面。

### 解决方案

完全删除 `[class*="PageLayoutWrapper"]` 的规则，仅保留 `PageLayoutRoot` 的规则，并将 `margin: auto` 补回去：

```css
[class*="PageLayoutRoot"] {
  max-width: min(85vw, 100%) !important;
  min-width: 900px !important;
  margin-left: auto !important;
  margin-right: auto !important;
}
```

---

## 五、问题四：PR 列表中「Review required」文字断行、溢出

### 现象

PR 列表每行的元信息区（作者、审核状态、时间、分支）出现：
- 「Review required」文字从中间断开（`word-break: break-all` 效果）
- 元信息换行到第二行，和作者名堆叠在一起
- 增宽到 90vw 后问题更明显

### 调试过程

1. 通过 Console 获取元素的 `getComputedStyle`，发现元信息所在的 `div` 带有内联样式 `style="word-break: break-all"`，这是 GitHub 动态注入的。
2. 同时发现 Refined GitHub 的 `align-issue-labels` 特性在这个 div 上设置了 `flex-basis: 100%`，导致它占满整行并换行。
3. 整个元信息行是一个 flex 容器，`.opened-by`（作者）没有限制宽度，把元信息挤到了右边甚至挤出视口。

### 解决过程（多轮迭代）

**第一轮**：覆盖 `word-break`：
```css
div[style*="word-break: break-all"] {
  word-break: normal !important;
}
```
有效但不够，元信息仍然换行。

**第二轮**：给元信息行加 `flex-wrap: nowrap`：
```css
.js-check-all-container div[style*="word-break: break-all"] {
  word-break: normal !important;
  flex-wrap: nowrap !important;
}
```
「Review required」消失了——原因是它的父元素 `.d-none.d-md-inline-flex` 内部也在换行，内容被压缩到 0 高度不可见。

**第三轮**：用 `max-width: 47%` 限制 `.opened-by` 宽度：
可行，但固定百分比在不同屏幕/缩放比例下不稳定，且用户调整到 90vw 后仍然对不齐。

**第四轮（最终方案）**：用 flexbox 弹性控制替代固定宽度：

```css
/* 元信息行：禁止换行，覆盖内联 word-break */
.js-check-all-container div[style*="word-break: break-all"] {
  word-break: normal !important;
  flex-wrap: nowrap !important;
}

/* 作者名：可收缩，不可增长，超出隐藏截断 */
.js-check-all-container .opened-by {
  flex: 0 1 auto !important;
  overflow: hidden !important;
  white-space: nowrap !important;
  min-width: 0 !important;
}

/* 元信息徽章组：固定自然宽度，不伸缩，内部也不换行 */
.js-check-all-container .d-none.d-md-inline-flex {
  flex: 0 0 auto !important;
  flex-wrap: nowrap !important;
}

/* "• Review required" 单行显示 */
.js-check-all-container .d-none.d-md-inline-flex .d-inline-block.ml-1 {
  white-space: nowrap !important;
}
```

**核心思路**：
- `.opened-by` 设置 `flex: 0 1 auto`（shrink 允许，grow 禁止）：当空间不足时，作者名自动收缩，让出空间给元信息。
- `.d-none.d-md-inline-flex` 设置 `flex: 0 0 auto`（既不 grow 也不 shrink）：元信息组永远保持自然宽度，不被压缩也不撑大。
- 两者组合保证了无论页面多宽，元信息组始终完整显示在作者名右侧。

---

## 六、最终 CSS 完整版

```css
/* ── wide layout ─────────────────────────────────────────────── */
/* 将主布局容器限制为 85vw 并居中 */
[class*="PageLayoutRoot"] {
  max-width: min(85vw, 100%) !important;
  min-width: 900px !important;
  margin-left: auto !important;
  margin-right: auto !important;
}

/* 将 data-width="large" 的内容容器撑满父级（如仓库文件浏览、Wiki） */
[data-width="large"] {
  max-width: 100% !important;
  width: 100% !important;
}

/* PageLayoutRoot 内部的 markdown/README 容器跟随父级拓宽 */
[class*="PageLayoutRoot"] .container-lg,
[class*="PageLayoutRoot"] .container-xl {
  max-width: 100% !important;
}

/* ── PR / Issue 列表 ─────────────────────────────────────────── */
/* 列表容器位于 PageLayoutRoot 外部，单独拓宽 */
.js-check-all-container.container-xl {
  max-width: min(85vw, 100%) !important;
  width: 100% !important;
}

/* ── PR Files changed tab：还原默认布局 ──────────────────────── */
/* #diff-comparison-viewer-container[data-side-panel-open] 在 Files
   changed tab 激活时才具有该属性，精确定位避免影响其他 PR tab    */
body:has(#diff-comparison-viewer-container[data-side-panel-open]) [class*="PageLayoutRoot"] {
  max-width: revert !important;
  min-width: revert !important;
  width: revert !important;
  margin-left: revert !important;
  margin-right: revert !important;
}

/* ── Releases 页：左侧元数据列保持窄宽 ──────────────────────── */
.col-md-2.flex-md-column {
  flex: 0 0 auto !important;
  width: auto !important;
  max-width: 200px !important;
}

/* ── Refined GitHub：隐藏 token 超限警告 flash ───────────────── */
[class*="rgh-"] .flash.flash-error {
  display: none !important;
}

/* ── PR 列表：修复元信息行布局 ───────────────────────────────── */
/* GitHub 动态注入 style="word-break: break-all"，覆盖并禁止换行  */
.js-check-all-container div[style*="word-break: break-all"] {
  word-break: normal !important;
  flex-wrap: nowrap !important;
}

/* 作者名：允许收缩，不允许增长，超出隐藏 */
.js-check-all-container .opened-by {
  flex: 0 1 auto !important;
  overflow: hidden !important;
  white-space: nowrap !important;
  min-width: 0 !important;
}

/* 元信息徽章组：固定自然宽度，内部不换行 */
.js-check-all-container .d-none.d-md-inline-flex {
  flex: 0 0 auto !important;
  flex-wrap: nowrap !important;
}

/* "• Review required" 等徽章文字保持单行 */
.js-check-all-container .d-none.d-md-inline-flex .d-inline-block.ml-1 {
  white-space: nowrap !important;
}
```

---

## 七、关键经验

| 经验 | 说明 |
|------|------|
| **用 `:has()` 做页面级条件** | 根据页面上某个唯一元素的存在/属性，对整个布局进行条件性覆盖，避免一条规则误伤所有页面 |
| **`revert` 比写死数值更健壮** | 重置宽度时用 `revert` 而非 `width: auto`，能恢复到浏览器默认值，对不同屏幕通用 |
| **`flex: 0 1 auto` vs `flex: 0 0 auto`** | 前者「可缩不可增」用于次要内容（作者名），后者「不缩不增」用于核心内容（元信息），是 flexbox 空间分配的精确控制手段 |
| **内联样式要用属性选择器覆盖** | GitHub 动态注入的 `style="..."` 优先级极高，必须用 `[style*="..."]` 配合 `!important` 才能覆盖 |
| **DevTools Console 诊断脚本** | 使用 `scrollWidth > clientWidth`、`getComputedStyle`、`getBoundingClientRect` 等方法在 Console 中精准定位溢出元素和问题样式，是调试 GitHub 动态 DOM 的核心手段 |
