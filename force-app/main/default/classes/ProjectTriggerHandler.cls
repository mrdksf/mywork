public class ProjectTriggerHandler {
    
    public static void onBeforeInsert(Map<Id, Project__c> newMap){
        
    }
    
    public static void onAfterInsert(Map<Id, Project__c> oldMap, Map<Id, Project__c> newMap){
        
    }

    public static void onBeforeUpdate(Map<Id, Project__c> newMap){
        
    }

    public static void onAfterUpdate(Map<Id, Project__c> oldMap, Map<Id, Project__c> newMap){
        ProjectUtils.updateAssignName((List<Project__c>)newMap.values());
        ProjectUtils.updateReportName((List<Project__c>)newMap.values());
    }

}