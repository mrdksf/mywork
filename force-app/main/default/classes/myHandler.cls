global class myHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

        DuplicateUser__c d = new DuplicateUser__c();
        d.BatchJobId__c = email.plainTextBody;
        insert d;
        return result;
    }
}