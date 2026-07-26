// reference_tables.dart — 法令の数値比較表など、複数問題で共通して参照される
// 図解データを一元管理する。explanation_screen で問題文/解説文にキーワードが
// 含まれる場合に該当する表を自動表示する。
//
// 個々の問題JSONを書き換えるのではなく、キーワードマッチで疎結合に紐付けることで
// 814問全体への影響を避けつつ保守しやすい構成にしている。

class ReferenceTable {
  final String title;
  final String? note;
  final List<String> headers;
  final List<List<String>> rows;
  final List<String> keywords; // 問題文/解説文にこの語が含まれていれば表示対象

  const ReferenceTable({
    required this.title,
    this.note,
    required this.headers,
    required this.rows,
    required this.keywords,
  });
}

/// 全ての参照表(法令数値比較表・図解データ)一覧
const List<ReferenceTable> kReferenceTables = [
  ReferenceTable(
    title: '事務室の空気環境の基準値',
    note: '事務所衛生基準規則(空気調和設備等による調整)',
    headers: ['項目', '基準値'],
    rows: [
      ['一酸化炭素の含有率', '100万分の10以下(10ppm以下)'],
      ['二酸化炭素の含有率', '100万分の1,000以下(1,000ppm以下)'],
      ['室の気流', '0.5m/秒以下'],
      ['室温', '18℃以上28℃以下'],
      ['相対湿度', '40%以上70%以下'],
    ],
    keywords: ['事務室の空気環境', '二酸化炭素の含有率', '空気調和設備', '機械換気設備'],
  ),
  ReferenceTable(
    title: '照度(ルクス)の作業区分基準',
    note: '事務所衛生基準規則 第10条(照度)',
    headers: ['作業の区分', '基準値'],
    rows: [
      ['精密な作業', '300ルクス以上'],
      ['普通の作業', '150ルクス以上'],
      ['粗な作業', '70ルクス以上'],
    ],
    keywords: ['照度', 'ルクス', '精密な作業', '普通の作業', '粗な作業'],
  ),
  ReferenceTable(
    title: 'じん肺管理区分と措置',
    note: 'じん肺法に基づく管理区分の考え方',
    headers: ['管理区分', 'エックス線写真の像', '対応'],
    rows: [
      ['管理一', '第1型に満たない', '通常の勤務でよい'],
      ['管理二', '第1型または第2型', '定期健康診断(1年に1回)'],
      ['管理三イ', '第2型または第3型', '定期健康診断(6か月に1回)'],
      ['管理三ロ', '第3型または第4型(大陰影なし)', '定期健康診断(6か月に1回)+作業転換の努力義務'],
      ['管理四', '第4型(大陰影あり)', '療養(就業禁止に相当する扱い)'],
    ],
    keywords: ['じん肺管理区分', 'じん肺健康診断', 'じん肺法', '地方じん肺診査医'],
  ),
  ReferenceTable(
    title: '衛生管理者の選任数(常時使用する労働者数)',
    note: '労働安全衛生規則 第7条',
    headers: ['常時使用する労働者数', '衛生管理者数'],
    rows: [
      ['50人以上200人以下', '1人以上'],
      ['201人以上500人以下', '2人以上'],
      ['501人以上1,000人以下', '3人以上'],
      ['1,001人以上2,000人以下', '4人以上'],
      ['2,001人以上3,000人以下', '5人以上'],
      ['3,001人以上', '6人以上'],
    ],
    keywords: ['衛生管理者の選任', '衛生管理体制', '衛生管理者数'],
  ),
  ReferenceTable(
    title: '産業医の選任数の目安',
    note: '労働安全衛生規則 第13条',
    headers: ['常時使用する労働者数', '産業医の選任'],
    rows: [
      ['50人以上999人以下', '1人以上(嘱託可)'],
      ['1,000人以上3,000人以下', '1人以上(専属)'],
      ['3,001人以上', '2人以上(専属)'],
    ],
    keywords: ['産業医の選任', '専属の産業医', '産業医数'],
  ),
  ReferenceTable(
    title: '作業環境測定の管理区分(作業環境評価基準)',
    note: '有機溶剤・特定化学物質・粉じん等の作業環境測定結果の評価に共通する区分',
    headers: ['管理区分', '評価の意味', '対応'],
    rows: [
      ['第1管理区分', '作業環境は良好', '現状維持'],
      ['第2管理区分', 'なお改善の余地あり', '施設・設備等の点検、改善に努める'],
      ['第3管理区分', '作業環境が不良', '直ちに施設・設備・作業方法等の点検、改善+保護具着用'],
    ],
    keywords: ['作業環境評価基準', '有機溶剤中毒予防規則'],
  ),
];

/// 問題文・解説文からキーワードマッチする参照表を検索する
List<ReferenceTable> findReferenceTables(String combinedText) {
  final result = <ReferenceTable>[];
  for (final table in kReferenceTables) {
    for (final kw in table.keywords) {
      if (combinedText.contains(kw)) {
        result.add(table);
        break;
      }
    }
  }
  return result;
}
