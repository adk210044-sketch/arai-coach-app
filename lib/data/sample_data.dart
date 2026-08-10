// sample_data.dart — shared.jsx のサンプルデータをDart化・拡充
// 出典: design_handoff_hygiene_manager_app/shared.jsx

import '../models/question.dart';
import '../models/category.dart';
import '../models/chat_message.dart';

/// カテゴリ一覧（実際の試験区分に準拠）
final List<CategoryStat> kCategories = [
  const CategoryStat(
    key: 'law_general',
    name: '関係法令(有害以外)',
    total: 220,
    correct: 178,
    weak: false,
  ),
  const CategoryStat(
    key: 'law_harm',
    name: '関係法令(有害)',
    total: 180,
    correct: 96,
    weak: true,
  ),
  const CategoryStat(
    key: 'labor_general',
    name: '労働衛生(有害以外)',
    total: 210,
    correct: 152,
    weak: false,
  ),
  const CategoryStat(
    key: 'labor_harm',
    name: '労働衛生(有害)',
    total: 190,
    correct: 88,
    weak: true,
  ),
  const CategoryStat(
    key: 'physiology',
    name: '労働生理',
    total: 200,
    correct: 168,
    weak: false,
  ),
];

/// 直近14日の学習ログ（草生やす用）
final List<int> kStudyLog14 = [
  3,
  8,
  12,
  0,
  5,
  15,
  20,
  18,
  0,
  10,
  22,
  25,
  14,
  12,
];

/// 30日ヒートマップ
final List<int> kHeatmap30 = [
  0,
  2,
  5,
  8,
  12,
  0,
  3,
  10,
  15,
  20,
  18,
  22,
  0,
  6,
  9,
  14,
  17,
  25,
  20,
  12,
  8,
  0,
  5,
  11,
  16,
  22,
  28,
  24,
  18,
  14,
];

/// AIチャットのサンプル履歴
List<ChatMessage> buildInitialChatMessages() => [
  ChatMessage(
    role: ChatRole.ai,
    text: '初めまして、あらいコーチだよ!\n何か気になった問題はあるかな?',
  ),
  ChatMessage(role: ChatRole.user, text: '有害業務の作業主任者の選任基準、いつも混乱します'),
  ChatMessage(
    role: ChatRole.ai,
    text:
        'ここは受験生あるあるだから大丈夫だよ。\n\n覚え方は「危険を伴う作業=有資格者が現場を仕切る」と考えると整理しやすいんだ。\n\n代表例を3つだけ押さえておこうね:\n・特定化学物質作業\n・有機溶剤作業\n・高圧室内作業\n\n練習問題、いま3問だけ出してみようか?',
  ),
];

const List<String> kQuickReplies = ['3問だけ出す', 'よく出る問題は?', '平均合格率は?', '暗記のコツ'];

/// 問題プール(サンプル20問)
final List<Question> kQuestionPool = [
  const Question(
    id: 'q_r5_10_23',
    year: '令和5年10月公表',
    categoryKey: 'physiology',
    categoryName: '労働生理',
    subCategory: '呼吸',
    format: QuestionFormat.choice5,
    number: '問23',
    text: '呼吸に関する次のAからDの記述について、正しいものの組合せは(1)〜(5)のうちどれか。',
    items: [
      'A. 呼吸は、胸腔内容積が周期的に増減し、それに伴って肺が拡張・収縮を繰り返すことで行われる。',
      'B. 横隔膜が下降し、胸郭内容積が増して内圧が低くなるにつれ、鼻腔、気管などの気道を経て肺内へ流れ込む空気を呼気という。',
      'C. チェーンストークス呼吸とは、延髄の呼吸中枢の機能が衰えることで、次第に呼吸が浅くなって停止した後、深い呼吸が始まる状態を周期的に繰り返す異常呼吸をいう。',
      'D. 呼吸のリズムをコントロールしているのは、間脳の視床下部である。',
    ],
    choices: ['(1) A, B', '(2) A, C', '(3) A, D', '(4) B, C', '(5) C, D'],
    correctIndex: 1,
    aiExplanation:
        'Bは「呼気」ではなく「吸気」の説明です。息を吐く動作が呼気。Dの呼吸中枢は延髄にあり、視床下部ではありません。AとCは正しい記述のため、正解は(2)。',
  ),
  const Question(
    id: 'q_r4_04_03',
    year: '令和4年4月公表',
    categoryKey: 'law_general',
    categoryName: '関係法令(有害以外)',
    subCategory: '安全衛生管理体制',
    format: QuestionFormat.ox,
    number: '問3',
    text: '常時50人以上の労働者を使用する事業場では、業種を問わず衛生管理者を選任しなければならない。',
    choices: ['正しい', '誤り'],
    correctIndex: 0,
    aiExplanation:
        '労働安全衛生法第12条により、常時50人以上の労働者を使用する事業場では業種を問わず衛生管理者の選任義務があります。よって◯。',
  ),
  const Question(
    id: 'q_r5_04_11',
    year: '令和5年4月公表',
    categoryKey: 'law_harm',
    categoryName: '関係法令(有害)',
    subCategory: '作業主任者',
    format: QuestionFormat.ox,
    number: '問11',
    text: '有機溶剤等を用いて行う塗装作業については、有機溶剤作業主任者を選任しなければならない。',
    choices: ['正しい', '誤り'],
    correctIndex: 0,
    aiExplanation:
        '有機溶剤中毒予防規則により、有機溶剤等を取り扱う一定の作業では有機溶剤作業主任者の選任が義務付けられています。塗装作業は代表例のひとつです。よって◯。',
  ),
  const Question(
    id: 'q_r4_10_18',
    year: '令和4年10月公表',
    categoryKey: 'labor_harm',
    categoryName: '労働衛生(有害)',
    subCategory: '局所排気装置',
    format: QuestionFormat.choice5,
    number: '問18',
    text: '局所排気装置に関する次のAからDの記述について、誤っているものの組合せは(1)〜(5)のうちどれか。',
    items: [
      'A. フードの開口面は、汚染源にできるだけ近づけるほうが効果的である。',
      'B. スロット型フードは、外付け式フードの一種である。',
      'C. ダクトは、断面積を大きくするほど、搬送速度が確保しやすくなる。',
      'D. 排風機は、できるだけ空気清浄装置の前(汚染空気側)に設置する。',
    ],
    choices: ['(1) A, B', '(2) A, C', '(3) B, C', '(4) B, D', '(5) C, D'],
    correctIndex: 4,
    aiExplanation:
        'Cはダクトの断面積を大きくすると搬送速度は「下がる」ため誤り。Dの排風機は空気清浄装置の後(清浄空気側)に設置するのが原則で、これも誤り。よって(5) C, D が正解。',
  ),
  const Question(
    id: 'q_r5_10_05',
    year: '令和5年10月公表',
    categoryKey: 'law_general',
    categoryName: '関係法令(有害以外)',
    subCategory: '健康診断',
    format: QuestionFormat.ox,
    number: '問5',
    text: '雇入時の健康診断は、常時使用する労働者であれば雇入れ後3か月以内に実施すればよい。',
    choices: ['正しい', '誤り'],
    correctIndex: 1,
    aiExplanation: '雇入時健康診断は「雇入れの際」に実施する必要があり、3か月以内という猶予規定はありません。よって×。',
  ),
  const Question(
    id: 'q_r3_04_29',
    year: '令和3年4月公表',
    categoryKey: 'physiology',
    categoryName: '労働生理',
    subCategory: '血液',
    format: QuestionFormat.choice5,
    number: '問29',
    text: '血液に関する次の記述のうち、正しいものはどれか。',
    items: [
      'A. 血液の血漿成分は、水分が約90%を占め、蛋白質、糖質、脂質、電解質を含む。',
      'B. 白血球のうちリンパ球には、細菌や異物を認識し攻撃するT細胞やB細胞が含まれる。',
      'C. 赤血球は骨髄で作られ、寿命は約120日である。',
      'D. 血小板は止血作用を担い、寿命は約1年である。',
    ],
    choices: [
      '(1) A, B, C',
      '(2) A, B, D',
      '(3) A, C, D',
      '(4) B, C, D',
      '(5) A, B, C, D',
    ],
    correctIndex: 0,
    aiExplanation:
        'Dの血小板の寿命は約1年ではなく、実際は約10日程度です。A・B・Cは正しい記述のため、正解は(1) A, B, C。',
  ),
  const Question(
    id: 'q_r4_04_15',
    year: '令和4年4月公表',
    categoryKey: 'labor_general',
    categoryName: '労働衛生(有害以外)',
    subCategory: 'メンタルヘルス',
    format: QuestionFormat.ox,
    number: '問15',
    text: 'ストレスチェックは、常時使用する労働者数が50人以上の事業場において、1年に1回実施することが義務付けられている。',
    choices: ['正しい', '誤り'],
    correctIndex: 0,
    aiExplanation:
        '労働安全衛生法により、常時50人以上の労働者を使用する事業場では、1年に1回のストレスチェック実施が義務付けられています。よって◯。',
  ),
  const Question(
    id: 'q_r5_04_08',
    year: '令和5年4月公表',
    categoryKey: 'law_harm',
    categoryName: '関係法令(有害)',
    subCategory: '特定化学物質',
    format: QuestionFormat.ox,
    number: '問8',
    text: '特定化学物質を製造し、又は取り扱う作業場においては、6か月以内ごとに1回、定期に、特定化学物質健康診断を実施しなければならない。',
    choices: ['正しい', '誤り'],
    correctIndex: 0,
    aiExplanation:
        '特定化学物質障害予防規則により、対象業務に常時従事する労働者に対しては6か月以内ごとに1回の健康診断実施が義務付けられています。よって◯。',
  ),
  const Question(
    id: 'q_r3_10_12',
    year: '令和3年10月公表',
    categoryKey: 'labor_harm',
    categoryName: '労働衛生(有害)',
    subCategory: '粉じん障害',
    format: QuestionFormat.ox,
    number: '問12',
    text: 'じん肺は、粉じんを吸入することによって肺に生じる線維増殖性変化を主体とする疾病であり、吸入を中止した後も進行することがある。',
    choices: ['正しい', '誤り'],
    correctIndex: 0,
    aiExplanation:
        'じん肺は粉じんの吸入により肺に線維増殖性変化が生じる疾病で、原因物質の吸入を中止しても進行する場合(続発性)があります。よって◯。',
  ),
  const Question(
    id: 'q_r4_10_31',
    year: '令和4年10月公表',
    categoryKey: 'physiology',
    categoryName: '労働生理',
    subCategory: '神経系',
    format: QuestionFormat.choice5,
    number: '問31',
    text: '神経系に関する次のAからDの記述について、正しいものの組合せは(1)〜(5)のうちどれか。',
    items: [
      'A. 神経系を構成する基本的な単位である神経細胞は、ニューロンともいわれ、細胞体、樹状突起、軸索からなる。',
      'B. 交感神経系は、身体の機能をより活動的に調整する働きがある。',
      'C. 副交感神経系は、身体の機能を鎮静化する働きがある。',
      'D. 中枢神経系は、脳と末梢神経で構成されている。',
    ],
    choices: [
      '(1) A, B, C',
      '(2) A, B, D',
      '(3) A, C, D',
      '(4) B, C, D',
      '(5) A, B, C, D',
    ],
    correctIndex: 0,
    aiExplanation:
        'Dは誤り。中枢神経系は「脳と脊髄」で構成され、末梢神経系は中枢神経系とは別のカテゴリです。A・B・Cは正しいため、正解は(1)。',
  ),
];

Question sampleQuestionByFormat(QuestionFormat f) {
  return kQuestionPool.firstWhere(
    (q) => q.format == f,
    orElse: () => kQuestionPool.first,
  );
}
