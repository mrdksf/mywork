global class UserNormalizeBatch implements Database.Batchable<sObject>, Database.Stateful{

    // ユーザ正規化ユーティリティクラス
    private UserNormalizeUtil util = new UserNormalizeUtil();
    // 後続バッチ処理のバッチサイズ
    private static final Integer CALLBACK_BATCH_SIZE = 500;

    /*
     * start
    */
    global Database.QueryLocator start(Database.BatchableContext context) {

        system.debug('********** Normalize start **************');

        // 正規化ユーティリティクラスに開始時刻をセット
        this.util.StartTime = Datetime.now();
        // 正規化ユーティリティクラスにバッチIDをセット
        this.util.BatchJobId = context.getJobId();

        //　ユーザを全件取得
        return Database.getQueryLocator(
                [
                    SELECT
                        Id,
                        Name,
                        MailingPostalCode,
                        MailingState,
                        MailingCity,
                        MailingStreet
                    FROM
                        Contact
                ]
        );
    }

    /*
     * execute
    */
    global void execute(Database.BatchableContext context, List<Contact> contacts) {

        system.debug('********** Normalize execute **************');

        if (contacts.isEmpty() == false) {

            // ユーティリティクラスのnormalizeメソッドを呼び出す
            // 処理結果がfalse（失敗）の場合、ジョブを中止しエラーメールを送信する
            if (this.util.normalize(contacts) == false) {

                System.abortJob(context.getJobId());

                this.util.sendErrorMail();
            }

        }

    }

    /*
     * finish
    */
    global void finish(Database.BatchableContext context) {

        system.debug('********** Normalize finish **************');

        // 後続のバッチ処理を実行
        UserNormalizeCallbackBatch callback = new UserNormalizeCallbackBatch(this.util);
        Database.executeBatch(callback, CALLBACK_BATCH_SIZE);

    }

}