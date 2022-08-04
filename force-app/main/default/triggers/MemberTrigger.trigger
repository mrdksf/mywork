trigger MemberTrigger on Member__c (after update) {

    if(Trigger.isUpdate && Trigger.isAfter){
        List<ID> ids = new List<ID>();
        for(Member__c member : Trigger.new){
            if(member.Abbr__c != Trigger.oldMap.get(member.Id).Abbr__c){
                ids.add(member.Id);
            }
        }
        
        if(ids.size() > 0){
            AssignNameUpdateService.updateName(ids);
        }
    }
}