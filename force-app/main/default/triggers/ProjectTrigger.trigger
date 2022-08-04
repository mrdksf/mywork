trigger ProjectTrigger on Project__c (before insert, after insert, before update, after update) {

    if(Trigger.isBefore){
        
        if(Trigger.isInsert)
            ProjectTriggerHandler.onBeforeInsert(Trigger.newMap);
        
        if(Trigger.isUpdate)
            ProjectTriggerHandler.onBeforeUpdate(Trigger.newMap);
    }
    
    if(Trigger.isAfter){
         if(Trigger.isInsert)
            ProjectTriggerHandler.onAfterInsert(Trigger.oldMap, Trigger.newMap);
        
        if(Trigger.isUpdate)
            ProjectTriggerHandler.onAfterUpdate(Trigger.oldMap, Trigger.newMap);       
    }
}