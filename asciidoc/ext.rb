# 見出し番号の書式とレベルごとの字下げを変える拡張
CIRCLED = %w(① ② ③ ④ ⑤ ⑥ ⑦ ⑧ ⑨ ⑩)

class Asciidoctor::Section
  def numerals
    nums = []; s = self
    while s.is_a?(Asciidoctor::Section) && s.level >= 1
      nums.unshift s.numeral.to_i; s = s.parent
    end
    nums
  end
  # 見出しに出す短い番号
  def sectnum delimiter = '.', append = nil
    v = numerals
    case v.size
    when 1..3 then v.join('.')
    when 4 then "(#{v[-1]})"
    else CIRCLED[v[-1] - 1]
    end
  end
  # 参照に出す完全な番号 2.1.1 (2)①
  def full_sectnum
    v = numerals
    s = v.take(3).join('.')
    s += " (#{v[3]})" if v.size >= 4
    s += CIRCLED[v[4] - 1] if v.size >= 5
    s
  end
  def xreftext xrefstyle = nil
    full_sectnum
  end
end

class JaPdfConverter < (Asciidoctor::Converter.for 'pdf')
  register_for 'pdf'
  # 見出し2以降は、見出しと本文をまとめてこの幅ずつ字下げ（pt）
  #   0 で字下げなし。1.5em にするなら 10.5 * 1.5
  SECTION_INDENT = 10.5 * 1.5

  def convert_section sect, opts = {}
    sect.level >= 2 && SECTION_INDENT > 0 ? indent(SECTION_INDENT) { super } : super
  end
end
