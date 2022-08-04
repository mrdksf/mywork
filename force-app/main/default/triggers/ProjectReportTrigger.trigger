trigger ProjectReportTrigger on ProjectReport__c (before insert, after insert) {
    
    if(Trigger.isBefore && Trigger.isInsert){
        for(ProjectReport__c newReport : Trigger.New){
            if(!newReport.Sys_SkipAutoCreateTasks__c && newReport.Sys_BaseDate__c == null){
                newReport.Sys_BaseDate__c = ProjectReportUtils.getNextReportDate(newReport.Project__c);
            }
        }    
    }
    
    if(Trigger.isAfter && Trigger.isInsert){
        List<ID> ids = new List<ID>();
        for(ProjectReport__c newReport : Trigger.New){
            if(!newReport.Sys_SkipAutoCreateTasks__c){
                ids.add(newReport.Id);
            }
        }
        
        if(ids.size() > 0){
            ProjectReportUtils.createTasks(ids, true);
        }
    }
}