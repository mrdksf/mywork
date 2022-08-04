global class UserNormalizeCallbackBatch implements Database.Batchable<sObject>, Database.Stateful{

    private UserNormalizeUtil util = null;

    /*
     * コンストラクタ
     * 引数：UserNormalizeUtil
    */
    public UserNormalizeCallbackBatch(UserNormalizeUtil util){
        this.util = util;
    }

    /*
     * start
    */
    global Database.QueryLocator start(Database.BatchableContext context) {

        system.debug('********** Normalize: callback start **************');

        // ジョブIDが先行ジョブのジョブIDと一致する重複レコードを全件取得
        return Database.getQueryLocator(
                [
                    SELECT
                        Id,
                        UserIds__c,
                        BatchJobId__c
                    FROM
                        DuplicateUser__c
                ]
        );
    }

    /*
     * execute
    */
    global void execute(Database.BatchableContext context, List<DuplicateUser__c> duplicates) {

        system.debug('********** Normalize: callback execute **************');

        if (duplicates.isEmpty() == false) {

            // ユーティリティクラスのupdateUsersメソッドを呼び出す
            // 処理結果がfalse（失敗）の場合、ジョブを中止しエラーメールを送信する
            if (this.util.updateUsers(duplicates) == false) {

                System.abortJob(context.getJobId());

                this.util.sendErrorMail();

            }

        }
    }

    /*
     * finish
    */
    global void finish(Database.BatchableContext context) {

        system.debug('********** Normalize: callback finish **************');

        // 正規化ユーティリティクラスに終了時刻をセット
        this.util.EndTime = Datetime.now();

        // 処理結果通知メールを送信
        this.util.sendMail();
    }

}