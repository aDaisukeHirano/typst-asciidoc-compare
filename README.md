# typst-asciidoc-compare

同じ内容の文書を Typst と AsciiDoc（asciidoctor-pdf）で作り、PDF の出来を比べるためのリポジトリです。

```
.
├── typst/
│   ├── sample.typ      本文・書式の設定
│   └── sample.pdf      出力結果
└── asciidoc/
    ├── sample.adoc     本文
    ├── theme.yml       テーマ（余白・フォント・ヘッダー・フッターなど）
    ├── ext.rb          拡張（見出し番号の書式・参照の番号・見出しごとの字下げ）
    ├── flow.svg        図
    ├── fonts/          Noto Sans JP（Regular / Bold）
    ├── build.sh        PDF を作るスクリプト
    └── sample.pdf      出力結果
```

## Typst

### 準備

```sh
brew install typst
brew install --cask font-noto-sans-jp
```

Noto Sans JP がない環境では、ヒラギノ角ゴで代用されます。

### コンパイル

```sh
typst compile typst/sample.typ
```

`typst/sample.pdf` が作られます。保存するたびに自動でコンパイルしたい場合は、次のコマンドを使います。

```sh
typst watch typst/sample.typ
```

## AsciiDoc

### 準備

```sh
brew install asciidoctor
```

`asciidoctor-pdf` も一緒にインストールされます。フォントは `asciidoc/fonts/` に同梱しているので、インストールは不要です。

### コンパイル

```sh
./asciidoc/build.sh
```

`asciidoc/sample.pdf` が作られます。`build.sh` の中身は次のコマンドです。

```sh
cd asciidoc
asciidoctor-pdf -r ./ext.rb -a pdf-theme=theme.yml -a pdf-fontsdir=fonts sample.adoc
```

### 拡張（ext.rb）

asciidoctor-pdf の標準機能では実現できない次の3つを、`ext.rb` で追加しています。
`build.sh` が `-r ./ext.rb` で読み込みます。

#### 1. 見出し番号の書式をレベルごとに変える

標準では、どのレベルも `1.2.3.4.5` のように数字をつなげた番号になります。
`Asciidoctor::Section#sectnum` を上書きし、レベルに応じて次の書式にしています。

| 見出し（AsciiDoc の記法） | レベル | 表示 |
|---|---|---|
| `==` | 1 | `1` |
| `===` | 2 | `1.2` |
| `====` | 3 | `1.2.3` |
| `=====` | 4 | `(1)` |
| `======` | 5 | `①` |

この番号は、見出しと目次の両方に使われます。

#### 2. 参照で番号をすべて出す

見出しには短い番号（`(2)` など）しか出ませんが、本文から参照するときは、どの節かが分かるように番号をすべて出します。
`Asciidoctor::Section#xreftext` を上書きしています。

```asciidoc
詳細は第<<sec-detail-b>>節を参照してください。
```

これは「詳細は第2.1.1 (2)節を参照してください。」と表示されます。レベル5なら `3.1.1 (1)①` のようになります。

#### 3. 見出しの深さに合わせて本文も字下げする

標準のテーマ設定（`section-indent`）でも字下げはできますが、全レベルが同じ幅になります。
PDF コンバーターの `convert_section` を上書きし、レベル2以降の見出しを、その下の本文や図表とまとめて 1.5 文字ずつ字下げしています。
見出しが入れ子になっているので、深いレベルほど字下げが大きくなります。

字下げ幅は `ext.rb` の `SECTION_INDENT`（単位は pt）で変えられます。`0` にすると字下げしません。

#### 拡張の注意点

- ①〜⑩ までしか用意していません。レベル5の見出しが同じ親の下に11個以上あると、番号が出ません。
- 参照の表示を上書きしているので、`xrefstyle` 属性の指定は見出しへの参照には効きません（図表への参照は標準どおり「図 1」「表 1」と表示されます）。
- 拡張で使っているのは asciidoctor の公開されたクラスとメソッドだけですが、asciidoctor や asciidoctor-pdf を更新したら、PDF の見た目を確認してください。

### 注意

- `asciidoc/fonts/` のフォントは、Noto Sans JP の可変フォントから Regular（太さ 400）と Bold（太さ 700）を切り出したものです。asciidoctor-pdf（Prawn）は可変フォントに対応しておらず、可変フォントのままでは太字になりません。
- 動作を確認したのは、asciidoctor-pdf 2.3.15 と Asciidoctor 2.0.26 の組み合わせです。
