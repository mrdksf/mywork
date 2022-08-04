public with sharing class TestCardController {
    public Dummy__c prod {get;set;}
    public String target{get;set;}
    public String p{get;set;}
    public Contact ct {get;set;}
    public Boolean req{get;set;}
    public TestCardController() {
        this.prod = new Dummy__c();
        this.target = 'f1';
        x = 0;
        ct = new Contact();
        req = false;
    }

    public Integer x {get;set;}

    public void next(){
        x++;
        req = true;
        if(x == 0 ){
            this.target='f1';
        }else if(x == 1){
            this.target='f2';
        }else if(x == 2){
            this.target='f3';
        }else{
            this.target='f4';
        }
        System.debug(this.prod.Text__c);
        //this.prod.Text__c = String.valueOf(x);
    }

    public void prev(){
        x--;
        if(x == 0 ){
            this.target='f1';
        }else if(x == 1){
            this.target='f2';
        }else if(x == 2){
            this.target='f3';
        }else{
            this.target='f4';
        }
    }

    public void save(){
        Apexpages.addMessage(new ApexPages.Message( ApexPages.severity.INFO, 'エラーメッセージのテストです。'));
        ApexPages.currentPage().getParameters().put('st','ok');
    }
}