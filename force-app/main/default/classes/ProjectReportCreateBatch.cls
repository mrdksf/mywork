global class ProjectReportCreateBatch implements Database.Batchable<ProjectReport__c>{
    
    private List<ProjectReport__c> reports = null;
    private List<Assign__c> assigns = null;
    
    public ProjectReportCreateBatch(List<ProjectReport__c> reports, List<Assign__c> assigns){
        this.reports = reports;
        this.assigns = assigns;
    }
    
    global System.Iterable<ProjectReport__c> start(Database.BatchableContext BC){
        return this.reports;//Database.getQueryLocator('select id, StartsFrom__c, EndsOn__c from Project__c where ID = \'' + '\''); 
    }
    
    global void execute(Database.BatchableContext BC, List<ProjectReport__c> reports){
        insert reports;
        
        for(ProjectReport__c report : reports){
			List<Task__c> tasks = ProjectReportUtils.getTasks(this.assigns, report.ID, report.ReportDate__c);
        }
    }

    global void finish(Database.BatchableContext BC){
    }
}