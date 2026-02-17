# Rust TUI SQL Client 開発計画書

## 1. プロジェクト概要

**製品コンセプト:**
「SQLを書く」ことよりも**「データを探索・閲覧する」**ことに特化した、VimライクなRust製TUIデータベースクライアント。
`psql` の閲覧性の悪さと、GUIクライアントの重さを解消し、ターミナルから出ることなく高速にリレーションを辿れる「Data Browser」を目指す。

**ターゲットユーザー:**

* Vim/Neovim を愛用するバックエンドエンジニア/SRE。
* マウスを使わずにキーボードだけで完結させたいユーザー。
* 重厚なGUIクライアントよりも、SSH先でも動くポータブルなバイナリを好むユーザー。

## 2. コア哲学 & UX (Core Philosophy)

1. **Vim-Native Navigation:**
* 全ての操作をホームポジション（`h`, `j`, `k`, `l`）で行う。
* モード（Normal / Insert）の概念を持つ。


2. **Persistent Context (コンテキストの永続化):**
* **画面分割 (Split View)** を基本とし、クエリエディタ（入力）とリザルトビュー（出力）を常に同時表示する。
* 新しい結果が表示されても、実行したクエリが画面外に流れない。


3. **Explore, Don't Just Query:**
* 外部キー（Foreign Key）を自動解決し、ハイパーリンクのようにジャンプできる機能（Relation Jump）を提供する。



## 3. 技術スタック (Technology Stack)

* **言語:** Rust (Latest Stable)
* **UIフレームワーク:** `ratatui` (TUIの事実上の標準)
* **バックエンド:** `crossterm` (Rawモード制御、クロスプラットフォーム)
* **非同期ランタイム:** `tokio` (DB操作のノンブロッキング化に必須)
* **データベース:** `sqlx` (Rust製、非同期対応のSQLドライバ)
* **エディタコンポーネント:** `tui-textarea` (Vimライクな入力挙動を低コストで実現)
* **設定・引数:** `clap` (CLI引数), `serde` (設定ファイル)

## 4. UIアーキテクチャ & レイアウト

Immediate Mode（即時描画モード）と非同期イベントループを採用する。

### 画面レイアウト (Screen Layout)

```text
+---------------------------------------------------------------+
|  [Sidebar] (Optional / Toggleable)                            |
|  - Connection A                                               |
|    - public                                                   |
|      - users                                                  |
|      - orders                                                 |
+---------------------------------------------------------------+
|  [Result Pane] (Main View: ~70-80% height)                    |
|  id | name       | email            | company_id (FK)         |
|  ---|------------|------------------|-----------------        |
|  1  | Alice      | alice@ex...      | 101 -> [Jump]           |
|  2  | Bob        | bob@exa...       | 102 -> [Jump]           |
|                                                               |
+---------------------------------------------------------------+
|  [Editor Pane] (Bottom: ~20-30% height)                       |
|  SELECT * FROM users WHERE id = 1__                           |
+---------------------------------------------------------------+
|  [Status Bar] Mode: NORMAL | DB: prod | 15ms | 2 rows         |
+---------------------------------------------------------------+

```

### 状態管理 (State Management)

* **App State:** `EditorState`（入力バッファ）と `TableState`（データ＆スクロール位置）を分離して保持する。
* **並行処理:** UIスレッド（描画）とDBスレッド（クエリ実行）の間は `tokio::sync::mpsc` チャンネルを用いて通信を行う。これによりUIのフリーズを防ぐ。

## 5. 機能要件 & ロードマップ

### Phase 1: MVP (Minimum Viable Product)

「編集 -> 実行 -> 閲覧」のループをVimキーバインドで回せる状態にする。

* **接続:** PostgreSQL (v1) への接続（接続文字列形式）。
* **画面分割:** 固定レイアウト（上が結果、下がエディタ）。
* **エディタ機能:**
* `tui-textarea` を用いたテキスト入力。
* **実行:** `Ctrl + Enter` (安全のためEnter単体での実行は禁止)。
* **ペイン移動:** `Tab` または `Ctrl+w` で上下移動。


* **ビューア機能:**
* スクロール可能なテーブル表示 (`j`/`k` で行移動, `h`/`l` で列移動)。
* 大量データへの基本的な対応。


* **Vimキーバインド:**
* エディタ内で `Esc` を押すと Normal Mode へ移行。



### Phase 2: Developer Experience (実用性の向上)

日常業務で使えるレベルへの引き上げ。

* **外部エディタ連携 (The "Hatch"):**
* エディタペインで `Ctrl + e` を押すと `$EDITOR` (vim/nvim) が起動。
* 一時ファイルにクエリを保存 -> エディタで編集 -> 保存して閉じるとTUIに反映。


* **クエリ管理:**
* **保存:** `:w <filename>` で現在のクエリをローカルの `.sql` ファイルとして保存。
* **読込:** ファイルブラウザまたはコマンドで `.sql` をロード。


* **履歴:**
* `Ctrl + r` で実行履歴をFuzzy Search（あいまい検索）。



### Phase 3: The "Killer" Features (差別化機能)

`psql` や他のツールにはない独自の強み。

* **Relation Jump (ドリルダウン):**
* スキーマから外部キー(FK)を検出。
* 結果ペインでFKセルを選択して `Enter` (または `gd`) を押すと、参照先テーブルを自動検索して表示（例: `SELECT * FROM companies WHERE id = 101`）。
* `Ctrl+o` で元のクエリ結果に戻る（ブラウザの「戻る」）。


* **スマートレイアウト:**
* JSONカラムや長文テキストの自動展開/ポップアップ表示。
* カラム固定（ExcelのようなFreeze Panes）。



## 6. 実装ステップの指示 (For AI Assistant)

以下の順序で実装を進めてください：

1. **Scaffolding:** `ratatui`, `tokio`, `crossterm` を用いたプロジェクトのセットアップ。基本的なイベントループの構築。
2. **UI Layout:** 静的な分割ペイン（上下分割）の描画実装。
3. **Input Handling:** `tui-textarea` の組み込みと、ペイン間のフォーカス移動の実装。
4. **Database Connection:** `sqlx` を用いた非同期接続プールと、単純なクエリ実行ロジック。
5. **Data Binding:** クエリ結果（`Row` vector）を Ratatui の Table ウィジェットへ流し込む処理。

まずは **Step 1 & 2** から着手し、メインループとUIレイアウトのコードを提示してください。
