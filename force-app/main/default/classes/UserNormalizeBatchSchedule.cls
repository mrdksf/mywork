global class UserNormalizeBatchSchedule implements Schedulable {

    // バッチサイズ
    private static final Integer BATCH_SIZE = 500;

    /*
     * スケジュール済みジョブ実行
    */
    global void execute(SchedulableContext context) {

        // バッチ処理クラス生成
        UserNormalizeBatch batch = new UserNormalizeBatch();

        // ジョブ実行
        Database.executeBatch(batch, BATCH_SIZE);

    }

}