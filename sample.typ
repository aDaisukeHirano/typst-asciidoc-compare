// ============================================================
// sample.typ  ―  見出し番号（1.2.3 → (1) → ②）と参照のサンプル
// ============================================================

// ---------- 基本設定 ----------
// ヘッダー・フッターに入れる共通の文字列
#let doc-title = [Typst 見出し番号サンプル]
#let doc-footer = [社内資料]

// そのページの見出し1（なければ直前の見出し1）を「第2章 手法」の形で返す
#let current-chapter() = {
  let pg = here().page()
  let hs = query(heading.where(level: 1, outlined: true))
    .filter(h => h.numbering != none and h.location().page() <= pg)
  if hs.len() == 0 { return none }
  let ch = hs.last()
  [第#counter(heading).at(ch.location()).first()章#h(0.5em)#ch.body]
}

#set page(
  paper: "a4",
  margin: (x: 15mm, y: 20mm),
  header: context {
    set text(size: 9pt)
    grid(
      columns: (1fr, auto),
      align: (left, right),
      doc-title, current-chapter(),
    )
    v(-0.6em)
    line(length: 100%, stroke: 0.5pt)
  },
  footer: context {
    set text(size: 9pt)
    line(length: 100%, stroke: 0.5pt)
    v(-0.6em)
    grid(
      columns: (1fr, auto, 1fr),
      align: (left, center, right),
      doc-footer,
      counter(page).display("1 / 1", both: true),
      current-chapter(),
    )
  },
)
#set text(
  lang: "ja",
  size: 10.5pt,
  font: ("Noto Sans JP", "Hiragino Sans"), // Noto Sans JP がない環境ではヒラギノ角ゴで代替
)
#set par(justify: true, leading: 0.9em, first-line-indent: 0em)

// ---------- 章番号の組み立て ----------
// 配列 v（例: (1,2,3,4,2)）から「1.2.3 (4)②」の完全な番号を作る
#let full(v) = {
  let base = numbering("1.1.1", ..v.slice(0, calc.min(3, v.len())))
  if v.len() <= 3 {
    base
  } else if v.len() == 4 {
    [#base #numbering("(1)", v.at(3))]
  } else {
    [#base #numbering("(1)", v.at(3))#numbering("①", v.at(4))]
  }
}

// 見出しに表示する番号（レベルごとに短い書式）
//   レベル1〜3 : 1 / 1.2 / 1.2.3
//   レベル4    : (1)
//   レベル5    : ①
#set heading(
  numbering: (..n) => {
    let v = n.pos()
    if v.len() <= 3 {
      numbering("1.1.1", ..v)
    } else if v.len() == 4 {
      numbering("(1)", v.last())
    } else {
      numbering("①", v.last())
    }
  },
  supplement: none,
)

// 見出しの左余白（レベル1, 2, 3, 4, 5 の順）
#let heading-indent = (0pt, 1.5em, 3em, 4.5em, 6em)

// 見出しの見た目
#show heading: it => {
  set par(first-line-indent: 0pt)
  set text(font: ("Noto Sans JP", "Hiragino Sans"))
  let sizes = (16pt, 13pt, 11.5pt, 10.5pt, 10.5pt)
  set text(size: sizes.at(it.level - 1), weight: "bold")
  // 見出しの上の余白（レベル1〜5）。数値を変えれば間隔を調整できる
  let above = (2.2em, 1.8em, 1.6em, 1.4em, 1.2em)
  v(above.at(it.level - 1), weak: true)
  // レベルごとの左余白（レベル1〜5）。数値を変えれば深さを調整できる
  pad(left: heading-indent.at(it.level - 1))[
    #if it.numbering != none [
      #context {
        let n = counter(heading).at(it.location())
        numbering(it.numbering, ..n)
      }#h(0.6em)
    ]
    #it.body
  ]
  v(0.7em, weak: true)
}


// 図表の見た目
//   表のキャプションは上、図のキャプションは下に置く
#show figure.where(kind: table): set figure.caption(position: top)
#show figure: set par(first-line-indent: 0pt, justify: false)
#show figure: set block(breakable: false)
#set table(stroke: 0.5pt, inset: 6pt, align: center + horizon)

// 「1.2.3 (1)②」形式で章番号を参照する関数
//   使い方: 第#sec(<ラベル>)節
#let sec(lbl) = context {
  let h = query(lbl).first()
  full(counter(heading).at(h.location()))
}

// 番号付き箇条書きの書式（ブロックごとに切り替えるための関数）
//   本文の左端から1字下げて表示する
#set enum(indent: 1em)
#set list(indent: 1em)
#let paren-list(..items) = {
  set enum(numbering: "(1)")
  enum(..items)
}

// 本文の左余白：直前の見出しと同じ深さだけ字下げする
//   文書を見出しで区切り、見出しの後ろの本文をまとめて pad で包む
//   （最初の見出しより前のタイトル・目次は字下げしない）
#show: doc => {
  // 空白・改行だけのかたまりは包まない（見出しが続くときの余分な空きを防ぐ）
  let blank = ([ ].func(), parbreak, linebreak)
  let flush(out, buf, level) = {
    if buf.len() == 0 {
      out
    } else if buf.all(c => c.func() in blank) {
      out + buf
    } else {
      out + (pad(left: heading-indent.at(level - 1), buf.join()),)
    }
  }
  let level = 0
  let buf = ()
  let out = ()
  for c in doc.children {
    if c.func() == heading or c.func() == pagebreak {
      out = flush(out, buf, level)
      buf = ()
      if c.func() == heading {
        level = c.at("depth", default: 1)
        // 見出し1の前で改ページ（すでにページ先頭なら何もしない）
        if level == 1 { out.push(pagebreak(weak: true)) }
      }
      out.push(c)
    } else if level == 0 {
      out.push(c)
    } else {
      buf.push(c)
    }
  }
  flush(out, buf, level).join()
}

// ---------- タイトル・目次 ----------
#align(center)[
  #text(size: 20pt, weight: "bold")[Typst 見出し番号サンプル] \
  #v(0.4em)
  #text(size: 11pt)[階層ごとに番号の書式を変える例]
]

#v(1em)

#outline(title: "目次", depth: 3)

#pagebreak()

// ---------- 本文 ----------
= はじめに <sec-intro>

この文書は、Typst で見出しの階層ごとに番号の書式を切り替える例です。技術文書や報告書では、章・節・項といった階層が深くなりがちで、すべてを「1.2.3.4.5」のような数字の連なりで表すと、かえって読みにくくなります。そこで本書では、階層に応じて番号の見た目を変えています。

番号の書式は次のとおりです。\
レベル1〜3：「1」「1.2」「1.2.3」の形式 \
レベル4：「(1)」の形式 \
レベル5：「①」の形式

また、見出しの深さに合わせて本文も字下げし、いま読んでいる箇所がどの階層に属するのかを、見た目でも把握できるようにしています。

== 目的 <sec-purpose>

文書を編集していると、章や節を追加・削除したり、順番を入れ替えたりすることがよくあります。そのたびに本文中の「第○節を参照」といった記述を手で直すのは手間がかかり、直し漏れによる誤りの原因にもなります。

本書では、見出しにラベルを付けて参照することで、番号がずれても参照が自動で追従することを確認します。たとえば、手法の詳細は第#sec(<sec-detail-b>)節にあります。

== 構成

本書は3つの章で構成されています。各章の内容は次のとおりです。必要な章から読み進めてもかまいません。

#paren-list(
  [第1章：はじめに],
  [第2章：手法],
  [第3章：評価],
)

= 手法 <sec-method>

== 全体像

提案する処理は、大きく3つの段階に分かれます（@fig-flow）。まず入力データを受け取り、前処理で扱いやすい形に整えたうえで、本処理でモデルの学習と推論を行います。

各段階は独立しているため、どれか1つだけを差し替えることもできます。たとえば、入力データの形式が変わった場合でも、前処理だけを修正すれば対応できます。

#figure(
  {
    let node(body) = rect(
      width: 7em, inset: 8pt, radius: 3pt,
      stroke: 0.8pt, fill: luma(235),
      align(center, body),
    )
    let arrow = text(size: 14pt)[$arrow.r$]
    grid(
      columns: 5,
      column-gutter: 0.8em,
      align: center + horizon,
      node[入力データ], arrow, node[前処理], arrow, node[本処理],
    )
  },
  caption: [処理の流れ],
) <fig-flow>

=== 前処理 <sec-pre>

前処理では、形式や品質がそろっていない入力データを正規化し、後段の本処理でそのまま使える状態にします。主な作業は、データの読み込みと欠損値の処理の2つです。

詳細は第#sec(<sec-detail-a>)節を参照してください。

==== データの読み込み <sec-detail-a>

入力ファイルは、作成した環境によって文字コードや改行コードが異なる場合があります。そのまま処理すると文字化けや行の区切り誤りが起きるため、読み込みの段階でこれらを統一します。

===== 文字コードの判定 <sec-detail-a1>

ファイルの先頭に BOM があるかどうかで、UTF-8 かどうかを判定します。BOM がない場合は、内容を読み取って Shift_JIS などの可能性を調べます。\
判定できなかったファイルは、処理を止めて利用者に確認を求めます。

===== 改行コードの統一

Windows で作成したファイルは CRLF、macOS や Linux では LF が使われるのが一般的です。本処理では行単位でデータを扱うため、すべての改行コードを LF に揃えます。

==== 欠損値の処理 <sec-detail-b>

実際のデータには、測定の失敗や入力漏れによって値が欠けている箇所が含まれます。欠損値をそのまま残すと、計算結果が正しく求まらないことがあるため、データの性質に応じて次のいずれかの方針で処理します。

===== 平均値で補完する

その列に含まれる値の平均を求め、欠損している箇所に当てはめます。手軽な方法ですが、外れ値が多い列では平均が偏るため注意が必要です。

===== 直前の値で補完する

時系列データのように、前後の値が近いと期待できる場合に使います。1つ前の行の値をそのまま引き継ぐため、急な変化がある箇所では誤差が大きくなります。

===== 該当行を除外する

欠損値を含む行を、データセットから丸ごと取り除きます。補完による誤差は生じませんが、除外する行が多いとデータ量が大きく減ってしまいます。\
全体の1割を超える場合は、ほかの方法を検討してください。

=== 本処理

本処理では、前処理の結果（第#sec(<sec-pre>)節）を入力として、モデルの学習と、学習したモデルを使った推論を行います。

==== モデルの学習

学習では、学習率と反復回数の2つを主な設定値として与えます。学習率が大きすぎると結果が安定せず、小さすぎると学習に時間がかかります。

反復回数は、検証用データでの精度が伸びなくなった時点で打ち切ります。

==== 推論

学習済みモデルに新しい入力を与え、予測結果を出力します。出力は、後で評価に使えるよう、入力と対応づけてファイルに保存します。

= 評価 <sec-eval>

== 結果

従来手法と提案手法を、2つのデータセットで比較した結果を@tab-result に示します。表の見出しは「評価結果 → データセット → 指標」の3段にネストし、手法の列は同じ手法の行を縦に結合しています。

提案手法は、どの条件でも従来手法を上回りました。特に条件3では、データセットAの精度が 0.92 と最も高い値になっています。

#figure(
  {
  // 見出し3段を太字にする
  show table.cell: it => if it.y < 3 { strong(it) } else { it }
  table(
    columns: 6,
    fill: (x, y) => if y < 3 { luma(230) },
    table.header(
      // 1段目
      table.cell(rowspan: 3)[手法],
      table.cell(rowspan: 3)[条件],
      table.cell(colspan: 4)[評価結果],
      // 2段目
      table.cell(colspan: 2)[データセットA],
      table.cell(colspan: 2)[データセットB],
      // 3段目
      [精度], [再現率], [精度], [再現率],
    ),
    // 従来手法（2行を結合）
    table.cell(rowspan: 2)[従来手法],
    [条件1], [0.82], [0.75], [0.79], [0.71],
    [条件2], [0.84], [0.77], [0.80], [0.73],
    // 提案手法（3行を結合）
    table.cell(rowspan: 3)[提案手法],
    [条件1], [0.88], [0.83], [0.86], [0.80],
    [条件2], [0.90], [0.85], [0.87], [0.82],
    [条件3], [*0.92*], [*0.87*], [*0.89*], [*0.84*],
  )
  },
  kind: table,
  caption: [手法ごとの評価結果],
) <tab-result>

=== 精度

手法（第#sec(<sec-method>)章）の精度を、同じデータ・同じ評価指標で測定しました。公平に比べるため、乱数の種や学習の打ち切り条件もそろえています。

==== 比較条件 <sec-cond>

比較にあたっては、次の2つの手法を同じ環境で動かしました。\
使用した計算機やライブラリのバージョンは、どちらも同一です。

===== ベースライン <sec-baseline>

比較対象は、これまで社内で使われてきた従来手法です。設定値は、従来の運用で使っていたものをそのまま用いました。

===== 提案手法

提案手法を、ベースラインと同じ条件で実行します。条件1〜3は、学習率と反復回数の組み合わせを変えたものです。

== 考察

評価条件は第#sec(<sec-cond>)節、ベースラインは第#sec(<sec-baseline>)節に記載しています。いずれの条件でも提案手法が上回ったことから、前処理で欠損値を適切に扱ったことが精度の向上につながったと考えられます。

一方で、データセットBでは改善の幅が小さく、データの性質による差があることも分かりました。今後は、欠損値の補完方法をデータに応じて自動で選ぶ仕組みを検討します。

以上により、はじめに（第#sec(<sec-intro>)章）で述べた目的を達成できました。
