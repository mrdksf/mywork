public class mySendmail {

    public static void send(){
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
		String[] sendingTo = new String[]{'muracom@18x7nvbnj69j9ffi43et0khodua252afece9s1hu882wdfwh5k.6f-2siieua4.ap4.apex.salesforce.com'};
		semail.setToAddresses(sendingTo);
		semail.setSubject('Single Email message Example');
		semail.setPlainTextBody('㎡');
        semail.setCharset('UTF-8');
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] {semail});
    }
}