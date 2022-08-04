public class TestAttController {

    public Blob up{get;set;}
    
    public pagereference doup(){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment at = new Messaging.EmailFileAttachment();
        at.setbody(up);
        at.setfilename('test.txt');
        message.setFileAttachments(new List<Messaging.EmailFileAttachment>{at});
		message.toAddresses = new String[] { 'rockfield.d.m@gmail.com' };
		message.subject = 'Opt Out Test Message';
		message.plainTextBody = 'This is the message body.';
		Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
       	Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        return null;
    }
}