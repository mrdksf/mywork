public class ProjectUtils {

    public static void updateAssignName(List<Project__c> projects){
        
        Set<ID> projectIds = new Set<ID>();
        for(Project__c project : projects)
            projectIds.add(project.ID);
        
        List<Project__c> targetProjects = [select ID, ProjectNo__c, (select ID, Name, Member__r.Abbr__c from AssignOnProject__r) from Project__c where ID in :projectIds];
        List<Assign__c> updatingAssigns = new List<Assign__c>();
        
        for(Project__c project: targetProjects){
            for(Assign__c assign : project.AssignOnProject__r){
                if(assign.Name != project.ProjectNo__c + '-' + assign.Member__r.Abbr__c){
                    assign.Name = project.ProjectNo__c + '-' + assign.Member__r.Abbr__c;
                    updatingAssigns.add(assign);
                }
            }
        }
        
        if(updatingAssigns.size() > 0)
            update updatingAssigns;
    }
    
     public static void updateReportName(List<Project__c> projects){
        
        Set<ID> projectIds = new Set<ID>();
        for(Project__c project : projects)
            projectIds.add(project.ID);
        
        List<Project__c> targetProjects = [select ID, (select ID, Name, DocumentNo__c from ReportOnProject__r) from Project__c where ID in :projectIds];
        List<ProjectReport__c> updatingReports = new List<ProjectReport__c>();
        
        for(Project__c project: targetProjects){
            for(ProjectReport__c report : project.ReportOnProject__r){
                if(report.Name != report.DocumentNo__c){
                    report.Name = report.DocumentNo__c;
                    updatingReports.add(report);
                }
            }
        }
        
        if(updatingReports.size() > 0)
            update updatingReports;
    }   
}