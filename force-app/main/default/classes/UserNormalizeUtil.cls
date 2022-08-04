public with sharing class UserNormalizeUtil {

    // --------------------- プロパティ -----------------------
    // 処理開始時刻
    public DateTime StartTime {get;set;}
    // 処理終了事項
    public DateTime EndTime {get;set;}
    // バッチ（ジョブ）ID
    public String BatchJobId {get;set;}

    // --------------------- メンバー変数 -----------------------
    // 正規化用ユーティリティクラス
    private NormalizeUtil normalizeUtil = new NormalizeUtil();
    // 正規化文字列マップ（キー：正規化文字列、値：ユーザのIDのList）
    private Map<String, List<ID>> normalizedStringMap = new Map<String, List<ID>>();
    // 総重複件数
    private Integer duplicateCount = 0;
    // 例外情報
    private Exception thrownException = null;
    // 正規化後の文字列長が255文字を超えていたユーザのIDのList
    private List<String> trimmedUserIds = new List<String>();
    // Upsert用重複レコードList
    private List<DuplicateUser__c> possibleDuplicates = new List<DuplicateUser__c>();
    // Delete用重複レコードList
    private List<DuplicateUser__c> extraDuplicates = new List<DuplicateUser__c>();

    private string currentRecordId = '';

    // --------------------- 定数 -----------------------
    private static final String COMMA = ',';
    //private static final String MAIL_ADDRESS = 'murakoshi_daiki@kakaku.com';
    private static final String MAIL_ADDRESS = 'longsight.d.m@gmail.com';
    private static final Integer MAX_LENGTH = 255;
    private static final String NANASHI = 'ななし';
    private static final String TEST = 'てすと';
    private static final String TEST2 = 'TEST';

    /*
     * 正規化
     * ユーザの名前・住所の正規化を行い、重複データを登録
    */
    public Boolean normalize(List<Contact> contacts){

        // メンバー変数初期化
        this.normalizedStringMap.clear();

        try{

            // 引数のユーザリストを全件ループ
            for (Contact contact : contacts) {

                // 名前を正規化
                String normalizedString = normalizeName(contact.Name);

                // 対象外のユーザの場合は処理をスキップ
                if (isTargetContact(normalizedString) == false) {

                    continue;

                }

                // 住所を正規化
                normalizedString += normalizeAddress(
                        contact.MailingPostalCode +
                        contact.MailingState +
                        contact.MailingCity +
                        contact.MailingStreet
                    );

                // 正規化した文字列の長さが255文字より大きい場合
                if (normalizedString.length() > MAX_LENGTH) {

                    // 255文字以降を切り捨てる
                    normalizedString = normalizedString.left(MAX_LENGTH);

                    // どのユーザが切り捨て対象となったかの情報を残すためメンバー変数に対象ユーザのIDを格納する
                    this.trimmedUserIds.add(contact.Id);
                }

                // マップに同一のキーが存在する場合、その値（List型）に対象のユーザのIDを追加する
                // 存在しない場合、対象のユーザのIDを含んだListを作成しマップに追加する
                if (this.normalizedStringMap.containsKey(normalizedString)) {

                    this.normalizedStringMap.get(normalizedString).add(contact.Id);

                }else{

                    this.normalizedStringMap.put(normalizedString, new List<ID>{contact.Id});

                }

            }

            // 重複レコードをUpsert
            upsertDuplicate();

            // 処理成功としてtrueを返却
            return true;

        }catch(Exception ex){

            // メンバー変数に例外自体を退避する
            this.thrownException = ex;

            // 処理失敗としてfalseを返却
            return false;

        }

    }

    /*
     * ユーザの名前から処理対象ユーザかを判定する
     * 処理対象の場合はtrue、処理対象外の場合はfalseを返却
    */
    private Boolean isTargetContact(String contactName){

        // 名前に「ななし」が含まれる場合は対象外とする
        if (contactName.contains(NANASHI)) {
            return false;
        }

        // 名前に「テスト」が含まれる場合は対象外とする
        if (contactName.contains(TEST)) {
            return false;
        }

        // 名前に「TEST」が含まれる場合は対象外とする
        if (contactName.contains(TEST2)){
            return false;
        }

        return true;
    }

    /*
     * 重複レコードを登録
     *
    */
    private void upsertDuplicate(){

        // メンバー変数初期化
        this.possibleDuplicates.clear();

        // マップのキー（正規化された文字列）を持つ重複レコードを全件取得しループ
        for (DuplicateUser__c possibleDuplicate : [SELECT Id, Key__c, UserIds__c, BatchJobId__c FROM DuplicateUser__c WHERE Key__c IN :this.normalizedStringMap.keySet()]) {

            // 現在のレコードのIDを退避
            this.currentRecordId = possibleDuplicate.Id;

            // ジョブIDが同一の場合
            if (possibleDuplicate.BatchJobId__c.equals(this.BatchJobId)) {

                // マップから値（ユーザのIDのList）を取得し、カンマで結合した文字列を「UserIds__c」に連結する
                possibleDuplicate.UserIds__c += COMMA + String.join(this.normalizedStringMap.remove(possibleDuplicate.Key__c), COMMA);

            }else{

                // マップから値（ユーザのIDのList）を取得し、カンマで結合した文字列で「UserIds__c」を上書きする
                possibleDuplicate.UserIds__c = String.join(this.normalizedStringMap.remove(possibleDuplicate.Key__c), COMMA);
                // 重複レコードのジョブIDを最新のジョブIDで上書きする
                possibleDuplicate.BatchJobId__c = this.BatchJobId;
            }

            // Upsert対象リストにUpdate対象として追加する
            this.possibleDuplicates.add(possibleDuplicate);

        }


        List<DuplicateUser__c> inserts = new List<DuplicateUser__c>();
        // マップを全件ループする
        for (String keyNormalizedString : this.normalizedStringMap.keySet()) {

            // マップのキー（正規化された文字列）及び値（ユーザのIDのList）を使用し重複レコードを作成する
            DuplicateUser__c newPossibleDuplicate = new DuplicateUser__c(
                                                        Key__c = keyNormalizedString,
                                                        UserIds__c = String.join(this.normalizedStringMap.get(keyNormalizedString), COMMA),
                                                        BatchJobId__c = this.BatchJobId
                                                    );

            // Upsert対象リストにInsert対象として追加する
            this.possibleDuplicates.add(newPossibleDuplicate);

        }

        // Upsert実行
        upsert this.possibleDuplicates;

    }

    /*
     * ユーザの名前を正規化
     * NormalizeUtilクラスを用い正規化処理を順次適用する
    */
    public String normalizeName(String name){

        name = normalizeUtil.removeSpaces(name);
        name = normalizeUtil.removeSymbols(name);
        name = normalizeUtil.replaceHyphens(name);
        name = normalizeUtil.replaceChinezeNum(name);
        name = normalizeUtil.replaceJapaneseNum(name);
        name = normalizeUtil.replaceCircledNum(name);
        name = normalizeUtil.replaceRomanNum(name);
        name = normalizeUtil.replaceSpecialNum(name);
        name = normalizeUtil.replaceJapaneseAlpha(name);
        name = normalizeUtil.replaceLowerCase(name);
        name = normalizeUtil.replaceOldHiragana(name);
        name = normalizeUtil.replaceDakuon(name);
        name = normalizeUtil.replaceSmallChar(name);
        name = normalizeUtil.replaceFullKatakana(name);
        name = normalizeUtil.replaceHalfKatakana(name);

        return name;
    }

    /*
     * ユーザの住所を正規化
     * NormalizeUtilクラスを用い正規化処理を順次適用する
    */
    public String normalizeAddress(String address){

        address = normalizeUtil.replaceSpecialString(address);
        address = normalizeUtil.removeSpaces(address);
        address = normalizeUtil.removeSymbols(address);
        address = normalizeUtil.replaceHyphens(address);
        address = normalizeUtil.replaceChinezeNum(address);
        address = normalizeUtil.replaceJapaneseNum(address);
        address = normalizeUtil.replaceCircledNum(address);
        address = normalizeUtil.replaceRomanNum(address);
        address = normalizeUtil.replaceSpecialNum(address);
        address = normalizeUtil.replaceJapaneseAlpha(address);
        address = normalizeUtil.replaceLowerCase(address);
        address = normalizeUtil.replaceOldHiragana(address);
        address = normalizeUtil.replaceDakuon(address);
        address = normalizeUtil.replaceSmallChar(address);
        address = normalizeUtil.replaceFullKatakana(address);
        address = normalizeUtil.replaceHalfKatakana(address);

        return address;
    }

    /*
     * 重複レコードとユーザとの紐づけ処理
     *
    */

    public Boolean updateUsers(List<DuplicateUser__c> possibleDuplicates){

        // 更新用ユーザList
        List<Contact> contacts = new List<Contact>();
        // 重複レコードに含まれるユーザのIDのList
        List<Id> contactIds = null;
        // 重複件数
        Integer count = 0;

        // メンバー変数初期化
        this.extraDuplicates.clear();

        try{

            // 引数の重複レコードを全件ループ
            for (DuplicateUser__c possibleDuplicate : possibleDuplicates) {

                // ジョブIDが異なる場合（今回の処理で作成・更新されたものではない場合）
                if (!possibleDuplicate.BatchJobId__c.equals(this.BatchJobId)) {

                    // 不要なデータとし削除対象に追加する
                    this.extraDuplicates.add(possibleDuplicate);
                    continue;
                }

                // 重複レコードのUserIds__cをカンマで分割しListに格納
                contactIds = possibleDuplicate.UserIds__c.split(',');

                // ユーザIDListのサイズが1より大きい場合、重複ユーザありとみなす
                if (contactIds.size() > 1) {
/*
                    // Listのサイズを重複件数に加算
                    count += contactIds.size();

                    // 対象のIDを全件ループ
                    for (Id contactId : contactIds) {

                        // 重複レコードとユーザを紐づけ更新対象ユーザListに追加する
                        contacts.add(new Contact(Id = contactId, UserDuplicate__c = possibleDuplicate.Id));

                    }
*/
                }else{

                    // 重複ユーザなしとみなし、削除対象重複レコードListに重複レコードを追加する
                    this.extraDuplicates.add(possibleDuplicate);

                }
            }

            // 総重複件数に重複件数を加算する
            this.duplicateCount += count;
/*
            // 更新対象ユーザListが空ではない場合
            if (contacts.isEmpty() == false) {

                // ユーザを更新
                update contacts;

            }
*/
            // 不要な重複レコードが存在した場合
            if (this.extraDuplicates.isEmpty() == false) {

                // 不要な重複レコードを削除
                delete this.extraDuplicates;

                // ごみ箱を空にする
                Database.emptyRecycleBin(this.extraDuplicates);

            }

            return true;

        }catch(Exception ex){

            // メンバー変数に例外自体を退避する
            this.thrownException = ex;

            // 処理失敗としてfalseを返却
            return false;

        }

    }


    /*
     * 正常終了時メール送信処理
     *
    */
    public void sendMail(){

        // 開始時刻と終了時刻から経過時間を取得
        Long startMillSec = this.startTime.getTime();
        Long endMillsec = this.endTime.getTime();
        Long elapsedMillSec = endMillsec - startMillSec;
        Datetime elapsedTime = Datetime.newInstance(elapsedMillSec);

        // 件名を設定
        String subject = '重複結果';
        // 本文を設定
        String message = '重複件数: ' +  String.valueof(this.duplicateCount) + '\n\n' +
                        '開始時刻: ' + String.valueof(this.startTime) + '\n' +
                        '終了時刻: ' + String.valueof(this.endTime) + '\n' +
                        '経過時間: ' + elapsedTime.formatGMT('HH:mm:ss:SSS') + '\n' +
                        '---------------------------------\n' +
                        '除外ID : ' + String.join(this.trimmedUserIds, ',');

        // メール送信処理を呼び出す
        send(subject, message);

    }

    /*
     * 異常終了時メール送信処理
     *
    */
    public void sendErrorMail(){

        // 件名を設定
        String subject = '重複結果　エラー!!!!!!!!!';
        // 本文を設定
        String message = '\n\n\n---------------------\n' +
                        this.thrownException.getMessage() + '\n' +
                        '----------------------------\n' +
                        this.thrownException.getStackTraceString()
 + '\n' +
                        'error:' + this.currentRecordId;
        // メール送信処理を呼び出す
        send(subject, message);

    }

    /*
     * メール送信処理
     *
    */
    private void send(String subject, String message) {

        // メール送信用オブジェクト
        Messaging.SingleEmailMessage mailMessaga = new Messaging.SingleEmailMessage();

        // 返信先を指定
        mailMessaga.setReplyTo(MAIL_ADDRESS);
        // 送信元名を指定
        mailMessaga.setSenderDisplayName('Salesforceシステム');
        // 宛先を指定
        mailMessaga.setToAddresses(new String[]{MAIL_ADDRESS});
        // 件名を指定
        mailMessaga.setSubject(subject);
        //送信本文を送信用オブジェクトにセットする
        mailMessaga.setPlainTextBody(message);

        //送信
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mailMessaga});

    }
}