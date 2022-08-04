public with sharing class DuplicateViewController {

    public DuplicateUser__c dup{get;set;}
    public Map<Id,Account> AccountMap {get;set;}
    public Map<Id,Contact> ContactMap {get;set;}
    public String MergePageUrl {get;set;}

    private static final List<String> accountMergeFieldNames = new List<String>{'Fax','AccountNumber','Phone'};
    private static final String mergeUrlBase2 = '/merge/conmergewizard.jsp?goNext=+Next+&id={0}&cid={1}&cid={2}';
    private static final String mergeUrlBase3 = '/merge/conmergewizard.jsp?goNext=+Next+&id={0}&cid={1}&cid={2}&cid={3}';

    public DuplicateViewController(ApexPages.StandardController stdController) {
        this.dup = [
                    SELECT
                        Id,
                        Userids__c
                    FROM
                        DuplicateUser__c
                    WHERE
                        Id = :stdController.getId()
                    ];

         prepare();
    }

    private void prepare(){

        this.ContactMap = new Map<Id,Contact>(
            [
                SELECT
                    Id,
                    AccountId,
                    Account.Name,
                    Name,
                    MailingPostalCode,
                    MailingState,
                    MailingCity,
                    MailingStreet
                FROM
                    Contact
                WHERE
                    Id IN :this.dup.Userids__c.split(',')
            ]
        );

        Set<String> accountIdSet = new Set<String>();
        for(Contact contact : this.ContactMap.values()){
            accountIdSet.add(contact.AccountId);
        }

        this.AccountMap = new Map<Id,Account>(
            [
                SELECT
                    Id,
                    Name,
                    Fax,
                    AccountNumber,
                    Phone,
                    Tradestyle
                FROM
                    Account
                WHERE
                    Id in :accountIdSet
            ]
        );
    }

    public Pagereference mergeContacts(){

        List<String> selectedContactIds = String.valueOf(Apexpages.currentPage().getParameters().get('selectedContacts')).split(',');

        List<Contact> contactsToMerge = new List<Contact>();
        for(String id : selectedContactIds){
            contactsToMerge.add(this.ContactMap.get(id));
        }
/*
        if(this.ContactMap.size() > 3){

            for(Integer i = 0 ; i < 3; i++){
                targets.add(this.ContactMap[i]);
            }
        }else{
            targets = this.ContactMap;
        }
*/
        Account masterAccountRecord = mergeAccount(contactsToMerge);
        if(masterAccountRecord == null){
            return null;
        }

        prepare();

        List<String> urlParameters = new List<String>();
        urlParameters.add(masterAccountRecord.Id);
        for(Contact contact : contactsToMerge){
            urlParameters.add(contact.Id);
        }

        if(contactsToMerge.size() > 2){
            this.MergePageUrl = String.format(mergeUrlBase3, urlParameters);
        }else{
            this.MergePageUrl = String.format(mergeUrlBase2, urlParameters);
        }

        return null;
    }

    private Account mergeAccount(List<Contact> contacts){

        Set<Account> accountSet = new Set<Account>();
        for(Contact contact : contacts){
            accountSet.add(this.AccountMap.get(contact.AccountId));
        }

        List<Account> accounts = new List<Account>(accountSet);

        if(accounts.size() <= 1){
            return accounts[0];
        }


        Account masterAccountRecord = accounts.remove(0);
        for(Account account : accounts){
            mergeTo(masterAccountRecord, account);
        }

        try{
            //Database.merge(masterAccountRecord, accounts, true);
        }catch(Exception ex){
            Apexpages.addMessages(ex);
            return null;
        }

        return masterAccountRecord;
    }

    private void mergeTo(Account masterAccountRecord, Account other){
        for(String fieldName : accountMergeFieldNames){

            if(masterAccountRecord.get(fieldName) == null && other.get(fieldName) != null){
                masterAccountRecord.put(fieldName, other.get(fieldName));
            }
        }
    }

}