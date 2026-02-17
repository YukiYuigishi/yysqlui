# Step 1 & 2 実装計画: Scaffolding + UI Layout

## ゴール
`ratatui` + `crossterm` による基本イベントループと、上下分割ペイン（Result Pane / Editor Pane / Status Bar）の描画を実装する。

## 追加する依存クレート

| クレート | バージョン | 理由 |
|---------|-----------|------|
| `crossterm` | 0.29 | イベント(キー入力等)の直接ハンドリングに必要。ratatui経由で間接依存はあるが、`event` モジュールを直接使うため明示的に追加 |
| `anyhow` | 1 | エラーハンドリング（CLAUDE.md指定） |
| `color-eyre` | 0.6 | パニック時の見やすいエラー表示（TUIアプリでは重要） |

**注:** `tokio`, `tui-textarea`, `sqlx` 等はStep 3以降で追加。まずは同期イベントループで動くものを作る。

## ファイル構成

```
src/
├── main.rs          # エントリポイント: Terminal初期化 + イベントループ起動
├── app.rs           # App構造体（状態管理）+ update関数
├── ui.rs            # 描画ロジック（view関数）
└── event.rs         # イベントハンドリング（crossterm events → App action）
```

## 実装詳細

### 1. `src/app.rs` - 状態管理
```rust
pub enum ActivePane { Result, Editor }
pub enum Mode { Normal, Insert }

pub struct App {
    pub active_pane: ActivePane,
    pub mode: Mode,
    pub should_quit: bool,
    pub editor_content: String,     // 暫定。後でtui-textareaに置き換え
    pub result_rows: Vec<Vec<String>>, // 暫定。後でsqlxの結果型に置き換え
}
```

### 2. `src/ui.rs` - レイアウト描画
- `Layout::vertical` で3分割: Result(70%) / Editor(25%) / StatusBar(1行)
- Result Pane: `Table` ウィジェット（ダミーデータ表示）
- Editor Pane: `Paragraph` ウィジェット（暫定。後でtui-textarea）
- Status Bar: `Paragraph` with mode / pane情報

### 3. `src/event.rs` - イベント処理
- `crossterm::event::read()` でブロッキング読み取り（250msポーリング）
- `q` (Normal mode) → 終了
- `Tab` → ペイン切り替え
- `i` (Normal mode) → Insert mode
- `Esc` → Normal mode

### 4. `src/main.rs` - エントリポイント
- Terminal初期化 (alternate screen, raw mode)
- メインループ: `event → update → view`
- 終了時のクリーンアップ (restore terminal)

## テスト方針 (TDD)
- `app.rs`: App状態遷移のユニットテスト（ペイン切替、モード切替、quit）
- `ui.rs`: ratatuiの`TestBackend`を用いた描画テスト（レイアウト比率の検証）
- Red→Green→Refactorサイクルで進める

## 実装順序
1. `App` 構造体と状態遷移テスト (Red→Green)
2. `ui.rs` レイアウト描画 + 描画テスト (Red→Green)
3. `event.rs` イベントハンドリング
4. `main.rs` 統合 + 動作確認
5. Refactor
