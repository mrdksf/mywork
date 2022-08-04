public with sharing class NormalizeUtil {

    private Pattern regexpPatter = null;
    private List<Integer> codePointList = new List<Integer>();
    private static final Integer ADJUST_CODEPOINT = 65248;
    private static final String EMPTY = '';
    private static final String HYPHEN = '-';

    /*
     * 特定文字列の正規化処理
     * ゆらぎの多い特定文字を半角ハイフンに置換
    */
    public String replaceSpecialString(String value){
        return value.replaceAll(SpecialStringExp, HYPHEN);
    }

    /*
     * スペース正規化処理
     * 全角スペース 半角スペースを削除
    */
    public String removeSpaces(String value){
        return value.replaceAll(SpeceExp, EMPTY);
    }

    /*
     * 記号正規化処理
     * 記号を削除
    */
    public String removeSymbols(String value){
        return value.replaceAll(SymbolExp, EMPTY);
    }

    /*
     * ハイフン正規化処理
     * ハイフンを半角ハイフンに置換
    */
    public String replaceHyphens(String value){
        return value.replaceAll(HyphenExp, HYPHEN);
    }

    /*
     * 漢数字正規化処理
     * 漢数字を半角数字に置換
    */
    public String replaceChinezeNum(String value){
        return replaceEach(value, ChinezeNumberExp, ChineseNumberMap);
    }

    /*
     * 全角数字正規化処理
     * 全角数字を半角数字に置換
    */
    public String replaceJapaneseNum(String value){
        return replaceEachAlphaNumeric(value, JapaneseNumberExp);
    }

    /*
     * 丸数字正規化処理
     * 丸数字を半角数字に置換
    */
    public String replaceCircledNum(String value){
        return replaceEach(value, CircledNumberExp, CircledNumberMap);
    }

    /*
     * ローマ数字正規化処理
     * ローマ数字を半角数字に置換
    */
    public String replaceRomanNum(String value){
        return replaceEach(value, RomanNumberExp, RomanNumberMap);
    }

    /*
     * 括弧数字正規化処理
     * 括弧数字を半角数字に置換
    */
    public String replaceSpecialNum(String value){
        return replaceEach(value, SpecialNumberExp, SpecialNumberMap);
    }

    /*
     * 全角英字正規化処理
     * 全角英字を半角英字大文字に置換
    */
    public String replaceJapaneseAlpha(String value){
        return replaceEachAlphaNumeric(value, JapaneseAlphabetExp);
    }

    /*
     * 半角英字正規化処理
     * 半角英字を大文字に置換
    */
    public String replaceLowerCase(String value){
        return replaceEachUpper(value, LowerCaseAlphabetExp);
    }

    /*
     * 特殊なひらがな正規化処理
     * 旧仮名遣いを現代仮名遣いに置換
    */
    public String replaceOldHiragana(String value){
        return replaceEach(value, OldHiraganaExp, OldHiraganaMap);
    }

    /*
     * 濁音、半濁音正規化処理
     * 濁音、半濁音を濁音なしのカナに置換
    */
    public String replaceDakuon(String value){
        return replaceEach(value, DakuonExp, DakuonMap);
    }

    /*
     * 小音正規化処理
     * 小音を全角ひらがなに置換
    */
    public String replaceSmallChar(String value){
        return replaceEach(value, SmallCharExp, SmallCharMap);
    }

    /*
     * 全角カナ正規化処理
     * 全角カナを全角ひらがなに置換
    */
    public String replaceFullKatakana(String value){
        return replaceEach(value, FullKatakanaExp, FullKatakanaMap);
    }

    /*
     * 半角カナ正規化処理
     * 半角カナを全角ひらがなに置換
    */
    public String replaceHalfKatakana(String value){
        return replaceEach(value, HalfKatakanaExp, HalfKatakanaMap);
    }

    /*
     * 置換処理
     * 正規表現にマッチした文字列を変換マップの対応する値に置換
    */
    private String replaceEach(String value, String regExp, Map<String, String> conversionMap){

        // 正規表現をコンパイル
        this.regexpPatter = Pattern.compile(regExp);

        // Matcherオブジェクトを生成
        Matcher patternMatcher = this.regexpPatter.matcher(value);

        // パターンにマッチする文字列がなくなるまでループ
        while (patternMatcher.find()) {

            // パターンにマッチした文字列（グループ）を対応する文字列に置換
            value = value.replace(patternMatcher.group(), conversionMap.get(patternMatcher.group()));

        }

        // 置換後の文字列を返却
        return value;
    }

    /*
     * 置換処理（全角半角英数字置換）
     * 正規表現にマッチした文字列を対応する半角英数字に置換
    */
    private String replaceEachAlphaNumeric(String value, String regExp){

        // 正規表現をコンパイル
        this.regexpPatter = Pattern.compile(regExp);

        // Matcherオブジェクトを生成
        Matcher patternMatcher = this.regexpPatter.matcher(value);

        // パターンにマッチする文字列がなくなるまでループ
        while (patternMatcher.find()) {

            // パターンにマッチした文字列（グループ）を対応する半角英数字に置換
            value = value.replace(patternMatcher.group(), getAlphaNumeric(patternMatcher.group()));

        }

        // 置換後の文字列を返却
        return value;
    }

    /*
     * 半角英数字取得処理
     * 対象文字列コードポイントから対応する半角英数字を取得
    */
    private String getAlphaNumeric(String value){

        // コードポイントListをクリア
        this.codePointList.clear();

        // 引数の文字列のコードポイントから対応する半角英数字のコードポイントを算出しコードポイントListに追加
        this.codePointList.add(value.codePointAt(0) - ADJUST_CODEPOINT);

        // コードポイントから文字列を取得し返却する
        return String.fromCharArray(this.codePointList);
    }

    /*
     * 置換処理（小文字大文字置換）
     * 正規表現にマッチした文字列を大文字に置換
    */
    private String replaceEachUpper(String value, String regExp){

        // 正規表現をコンパイル
        this.regexpPatter = Pattern.compile(regExp);

        // Matcherオブジェクトを生成
        Matcher patternMatcher = this.regexpPatter.matcher(value);

        // パターンにマッチする文字列がなくなるまでループ
        while (patternMatcher.find()) {

            // パターンにマッチした文字列（グループ）を大文字に置換
            value = value.replace(patternMatcher.group(), patternMatcher.group().toUpperCase());

        }

        // 置換後の文字列を返却
        return value;
    }

    // ------------------- 正規表現 ---------------------------------------------------
    private static final String SpecialStringExp = '丁目|番地|番|号室|号|階|Ｆ|F';
    private static final String SpeceExp = '　| |\n|\r|\r\n';
    private static final String SymbolExp = '！|＂|＃|＄|％|＆|＇|（|）|＊|＋|，|．|／|：|；|＜|＝|＞|？|＠|［|＼|］|＾|｀|｛|｜|｝|’|´|\'';
    private static final String HyphenExp = '₋|―|⁻|ー|ｰ|‐|－|～|￣|＿|ー';
    private static final String ChinezeNumberExp = '一|二|三|四|五|六|七|八|九|十';
    private static final String JapaneseNumberExp = '１|２|３|４|５|６|７|８|９|０';
    private static final String CircledNumberExp = '①|②|③|④|⑤|⑥|⑦|⑧|⑨|⑩|⑪|⑫|⑬|⑭|⑮|⑯|⑰|⑱|⑲|⑳';
    private static final String RomanNumberExp = 'Ⅰ|Ⅱ|Ⅲ|Ⅳ|Ⅴ|Ⅵ|Ⅶ|Ⅷ|Ⅸ|Ⅹ|Ⅺ|Ⅻ';
    private static final String SpecialNumberExp = '⑴|⑵|⑶|⑷|⑸|⑹|⑺|⑻|⑼|⑽|⑾|⑿|⒀|⒁|⒂|⒃|⒄|⒅|⒆|⒇';
    private static final String JapaneseAlphabetExp = 'Ａ|Ｂ|Ｃ|Ｄ|Ｅ|Ｇ|Ｈ|Ｉ|Ｊ|Ｋ|Ｌ|Ｍ|Ｎ|Ｏ|Ｐ|Ｑ|Ｒ|Ｓ|Ｔ|Ｕ|Ｖ|Ｗ|Ｘ|Ｙ|Ｚ|ａ|ｂ|ｃ|ｄ|ｅ|ｆ|ｇ|ｈ|ｉ|ｊ|ｋ|ｌ|ｍ|ｎ|ｏ|ｐ|ｑ|ｒ|ｓ|ｔ|ｕ|ｖ|ｗ|ｘ|ｙ|ｚ';
    private static final String LowerCaseAlphabetExp = '[a-z]';
    private static final String OldHiraganaExp = 'ゐ|ゑ';
    private static final String DakuonExp = 'ヴ|ガ|ギ|グ|ゲ|ゴ|ザ|ジ|ズ|ゼ|ゾ|ダ|ヂ|ヅ|デ|ド|バ|ビ|ブ|ベ|ボ|パ|ピ|プ|ペ|ポ|ｳﾞ|ｶﾞ|ｷﾞ|ｸﾞ|ｹﾞ|ｺﾞ|ｻﾞ|ｼﾞ|ｽﾞ|ｾﾞ|ｿﾞ|ﾀﾞ|ﾁﾞ|ﾂﾞ|ﾃﾞ|ﾄﾞ|ﾊﾞ|ﾋﾞ|ﾌﾞ|ﾍﾞ|ﾎﾞ|ﾊﾟ|ﾋﾟ|ﾌﾟ|ﾍﾟ|ﾎﾟ';
    private static final String SmallCharExp = 'ぁ|ぃ|ぅ|ぇ|ぉ|ヵ|ヶ|っ|ゃ|ゅ|ょ|ゎ|ァ|ィ|ゥ|ェ|ォ|ャ|ュ|ョ|ッ|ｧ|ｨ|ｩ|ｪ|ｫ|ｬ|ｭ|ｮ|ｯ';
    private static final String FullKatakanaExp = 'ア|イ|ウ|エ|オ|カ|キ|ク|ケ|コ|サ|シ|ス|セ|ソ|タ|チ|ツ|テ|ト|ナ|ニ|ヌ|ネ|ノ|ハ|ヒ|フ|ヘ|ホ|マ|ミ|ム|メ|モ|ヤ|ユ|ヨ|ラ|リ|ル|レ|ロ|ワ|ヲ|ン';
    private static final String HalfKatakanaExp = 'ｱ|ｲ|ｳ|ｴ|ｵ|ｶ|ｷ|ｸ|ｹ|ｺ|ｻ|ｼ|ｽ|ｾ|ｿ|ﾀ|ﾁ|ﾂ|ﾃ|ﾄ|ﾅ|ﾆ|ﾇ|ﾈ|ﾉ|ﾊ|ﾋ|ﾌ|ﾍ|ﾎ|ﾏ|ﾐ|ﾑ|ﾒ|ﾓ|ﾔ|ﾕ|ﾖ|ﾗ|ﾘ|ﾙ|ﾚ|ﾛ|ﾜ|ｦ|ﾝ';

    // ------------------- 置換対象文字列と置換文字列のマップ ---------------------------
    private static final Map<String, String> ChineseNumberMap =  new Map<String, String>{
            '一'=> '1',
            '二'=> '2',
            '三'=> '3',
            '四'=> '4',
            '五'=> '5',
            '六'=> '6',
            '七'=> '7',
            '八'=> '8',
            '九'=> '9',
            '十'=> '10'
        };

    private static final Map<String, String> CircledNumberMap =  new Map<String, String>{
            '①'=> '1',
            '②'=> '2',
            '③'=> '3',
            '④'=> '4',
            '⑤'=> '5',
            '⑥'=> '6',
            '⑦'=> '7',
            '⑧'=> '8',
            '⑨'=> '9',
            '⑩'=> '10',
            '⑪'=> '11',
            '⑫'=> '12',
            '⑬'=> '13',
            '⑭'=> '14',
            '⑮'=> '15',
            '⑯'=> '16',
            '⑰'=> '17',
            '⑱'=> '18',
            '⑲'=> '19',
            '⑳'=> '20'
        };

    private static final Map<String, String> RomanNumberMap =  new Map<String, String>{
            'Ⅰ'=>'1',
            'Ⅱ'=>'2',
            'Ⅲ'=>'3',
            'Ⅳ'=>'4',
            'Ⅴ'=>'5',
            'Ⅵ'=>'6',
            'Ⅶ'=>'7',
            'Ⅷ'=>'8',
            'Ⅸ'=>'9',
            'Ⅹ'=>'10',
            'Ⅺ'=>'11',
            'Ⅻ'=>'12'
        };

    private static final Map<String, String> SpecialNumberMap =  new Map<String, String>{
            '⑴'=>'1',
            '⑵'=>'2',
            '⑶'=>'3',
            '⑷'=>'4',
            '⑸'=>'5',
            '⑹'=>'6',
            '⑺'=>'7',
            '⑻'=>'8',
            '⑼'=>'9',
            '⑽'=>'10',
            '⑾'=>'11',
            '⑿'=>'12',
            '⒀'=>'13',
            '⒁'=>'14',
            '⒂'=>'15',
            '⒃'=>'16',
            '⒄'=>'17',
            '⒅'=>'18',
            '⒆'=>'19',
            '⒇'=>'20'
        };

    private static final Map<String, String> OldHiraganaMap = new Map<String, String>{
            'ゐ'=>'い',
            'ゑ'=>'え'
        };

    private static final Map<String, String> DakuonMap =  new Map<String, String>{
            'ヴ'=>'ウ',
            'ガ'=>'カ',
            'ギ'=>'キ',
            'グ'=>'ク',
            'ゲ'=>'ケ',
            'ゴ'=>'コ',
            'ザ'=>'サ',
            'ジ'=>'シ',
            'ズ'=>'ス',
            'ゼ'=>'セ',
            'ゾ'=>'ソ',
            'ダ'=>'タ',
            'ヂ'=>'チ',
            'ヅ'=>'ツ',
            'デ'=>'テ',
            'ド'=>'ト',
            'バ'=>'ハ',
            'ビ'=>'ヒ',
            'ブ'=>'フ',
            'ベ'=>'ヘ',
            'ボ'=>'ホ',
            'パ'=>'ハ',
            'ピ'=>'ヒ',
            'プ'=>'フ',
            'ペ'=>'ヘ',
            'ポ'=>'ホ',
            'ｳﾞ'=>'ウ',
            'ｶﾞ'=>'カ',
            'ｷﾞ'=>'キ',
            'ｸﾞ'=>'ク',
            'ｹﾞ'=>'ケ',
            'ｺﾞ'=>'コ',
            'ｻﾞ'=>'サ',
            'ｼﾞ'=>'シ',
            'ｽﾞ'=>'ス',
            'ｾﾞ'=>'セ',
            'ｿﾞ'=>'ソ',
            'ﾀﾞ'=>'タ',
            'ﾁﾞ'=>'チ',
            'ﾂﾞ'=>'ツ',
            'ﾃﾞ'=>'テ',
            'ﾄﾞ'=>'ト',
            'ﾊﾞ'=>'ハ',
            'ﾋﾞ'=>'ヒ',
            'ﾌﾞ'=>'フ',
            'ﾍﾞ'=>'ヘ',
            'ﾎﾞ'=>'ホ',
            'ﾊﾟ'=>'ハ',
            'ﾋﾟ'=>'ヒ',
            'ﾌﾟ'=>'フ',
            'ﾍﾟ'=>'ヘ',
            'ﾎﾟ'=>'ホ'
        };

    private static final Map<String, String> SmallCharMap =  new Map<String, String>{
            'ぁ'=> 'あ',
            'ぃ'=> 'い',
            'ぅ'=> 'う',
            'ぇ'=> 'え',
            'ぉ'=> 'お',
            'ヵ'=> 'か',
            'ヶ'=> 'け',
            'っ'=> 'つ',
            'ゃ'=> 'や',
            'ゅ'=> 'ゆ',
            'ょ'=> 'よ',
            'ゎ'=> 'わ',
            'ァ'=> 'あ',
            'ィ'=> 'い',
            'ゥ'=> 'う',
            'ェ'=> 'え',
            'ォ'=> 'お',
            'ャ'=> 'や',
            'ュ'=> 'ゆ',
            'ョ'=> 'よ',
            'ッ'=>'つ',
            'ｧ'=> 'あ',
            'ｨ'=> 'い',
            'ｩ'=> 'う',
            'ｪ'=> 'え',
            'ｫ'=> 'お',
            'ｬ'=> 'や',
            'ｭ'=> 'ゆ',
            'ｮ'=> 'よ',
            'ｯ'=> 'う'
        };

    private static final Map<String, String> FullKatakanaMap =  new Map<String, String>{
            'ア'=>'あ',
            'イ'=>'い',
            'ウ'=>'う',
            'エ'=>'え',
            'オ'=>'お',
            'カ'=>'か',
            'キ'=>'き',
            'ク'=>'く',
            'ケ'=>'け',
            'コ'=>'こ',
            'サ'=>'さ',
            'シ'=>'し',
            'ス'=>'す',
            'セ'=>'せ',
            'ソ'=>'そ',
            'タ'=>'た',
            'チ'=>'ち',
            'ツ'=>'つ',
            'テ'=>'て',
            'ト'=>'と',
            'ナ'=>'な',
            'ニ'=>'に',
            'ヌ'=>'ぬ',
            'ネ'=>'ね',
            'ノ'=>'の',
            'ハ'=>'は',
            'ヒ'=>'ひ',
            'フ'=>'ふ',
            'ヘ'=>'へ',
            'ホ'=>'ほ',
            'マ'=>'ま',
            'ミ'=>'み',
            'ム'=>'む',
            'メ'=>'め',
            'モ'=>'も',
            'ヤ'=>'や',
            'ユ'=>'ゆ',
            'ヨ'=>'よ',
            'ラ'=>'ら',
            'リ'=>'り',
            'ル'=>'る',
            'レ'=>'れ',
            'ロ'=>'ろ',
            'ワ'=>'わ',
            'ヲ'=>'を',
            'ン'=>'ん'
        };

    private static final Map<String, String> HalfKatakanaMap =  new Map<String, String>{
            'ｱ'=>'あ',
            'ｲ'=>'い',
            'ｳ'=>'う',
            'ｴ'=>'え',
            'ｵ'=>'お',
            'ｶ'=>'か',
            'ｷ'=>'き',
            'ｸ'=>'く',
            'ｹ'=>'け',
            'ｺ'=>'こ',
            'ｻ'=>'さ',
            'ｼ'=>'し',
            'ｽ'=>'す',
            'ｾ'=>'せ',
            'ｿ'=>'そ',
            'ﾀ'=>'た',
            'ﾁ'=>'ち',
            'ﾂ'=>'つ',
            'ﾃ'=>'て',
            'ﾄ'=>'と',
            'ﾅ'=>'な',
            'ﾆ'=>'に',
            'ﾇ'=>'ぬ',
            'ﾈ'=>'ね',
            'ﾉ'=>'の',
            'ﾊ'=>'は',
            'ﾋ'=>'ひ',
            'ﾌ'=>'ふ',
            'ﾍ'=>'へ',
            'ﾎ'=>'ほ',
            'ﾏ'=>'ま',
            'ﾐ'=>'み',
            'ﾑ'=>'む',
            'ﾒ'=>'め',
            'ﾓ'=>'も',
            'ﾔ'=>'や',
            'ﾕ'=>'ゆ',
            'ﾖ'=>'よ',
            'ﾗ'=>'ら',
            'ﾘ'=>'り',
            'ﾙ'=>'る',
            'ﾚ'=>'れ',
            'ﾛ'=>'ろ',
            'ﾜ'=>'わ',
            'ｦ'=>'を',
            'ﾝ'=>'ん'
        };
}