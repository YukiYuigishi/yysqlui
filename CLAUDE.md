# Claude Project Guide: Rust TUI Application

This guide defines the development standards and patterns for this Rust-based TUI project.

## 🛠 Tech Stack & Environment

- **Language:** Rust (Latest Stable)
- **Framework:** `ratatui` + `crossterm`
- **Architecture:** Simplified MVC / Elm Architecture (Update, View, Event)
- **Container Context:** `/app` directory, `claude_dev` user, `TERM=xterm-256color`

## 🧪 Testing Strategy (t-wada style)

"Clean Code that Works" — テストは設計のフィードバック装置である。

1. **Test-Driven Development (TDD):**
   - 実装の前に、まず失敗するテスト（Red）を書くこと。
   - 最小限の実装でテストを通し（Green）、その後にリファクタリング（Refactor）を行うこと。
2. **Behavior, not Implementation:**
   - 内部構造ではなく、公開インターフェースの振る舞いをテストすること。
3. **Assertive Programming:**
   - 表明（`assert!`）を活用し、不変条件をコードとテストの両方で表現すること。
4. **Snapshot Testing:**
   - TUIの描画結果（Buffer）の検証には `insta` クレートによるスナップショットテストを検討すること。

## 🛠 Critical Commands

- **Build:** `cargo build`
- **Check:** `cargo check`
- **Test:** `cargo test` (全テスト実行)
- **Specific Test:** `cargo test -- <test_name>`
- **Lint:** `cargo clippy -- -D warnings`
- **Format:** `cargo fmt`

## 📝 Coding Standards

- **Error Handling:** `anyhow` または `thiserror` を使用し、エラーを握り潰さないこと。
- **Immutability:** 原則としてイミュータブルなデータ構造を優先し、状態遷移を明示的に定義すること。
- **Documentation:** 公開関数には `///` でドキュメントを書き、可能な限り `doc test` を含めること。
- **English Priority:** - 技術的な問題解決やWeb検索が必要な場合は、英語情報を優先すること。
  - ただし、ユーザーとの対話は日本語で行うこと。

## 🚫 Constraints

- `docs/plan.md` の計画に従うこと
- 新しい依存関係を追加する際は、必ず理由を説明すること。
- UIとビジネスロジックを分離すること（UIは `Frame` への描画に徹し、ロジックはピュアな関数で行う）。
