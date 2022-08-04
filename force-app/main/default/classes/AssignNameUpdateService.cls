public class AssignNameUpdateService {

    public static void updateName(List<ID> memberIds){
        List<Member__c> members = getMembers(memberIds);
        List<Assign__c> assigns = new List<Assign__c>();
        for(Member__c member : members){
            for(Assign__c assign : member.AssignOnMember__r){
                assign.Name = assign.Project__r.ProjectNo__c + '_' + member.Abbr__c;
                assigns.add(assign);
            }
        }
        
		update assigns;
    }
    
    private static List<Member__c> getMembers(List<ID> memberIds){
        return [Select
                                   Id,
                                   Name,
                                   Abbr__c,
                                   (Select
                                    Id,
                                    Name,
                                    Project__r.ProjectNo__c
                                   From AssignOnMember__r)
            					   From Member__c
                                   Where id in :memberIds
        							];
       	
    }
}