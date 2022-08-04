public class DailyReportEmailTemplateService {
    
    private static final String DELIMITTER = '-----------------------------------------------------------------------';
    private static final String DEFAULT_VALUE = 'なし';
    private static final String LINE_FEED = '&#13;&#10;';
    
    public static String getSubject(List<Project__c> projects){
        String subject = System.Label.DailyReportEmailSubject;
        List<Member> members = new List<Member>();  
        for(Project__c project : projects){
            for(Assign__c assign : project.AssignOnProject__r){
                members.add(new Member((Integer)assign.DisplayOrder__c, assign.Member__r.Abbr__c));
            }
        }    
        
        members.sort();
        List<String> memberNames = new List<String>();
        for(Member mem : members){
            memberNames.add(mem.Name);
        }
        
        subject = subject.replace('@report_date', Date.today().format());
        subject = subject.replace('@members', String.join(memberNames, ', '));
        
        return subject;
    }
    
    public static String getBody(List<Project__c> projects){
        String body = '';
        
        for(Project__c project : projects){
            List<Assign__c> assigns = new List<Assign__c>();
            assigns.addAll(project.AssignOnProject__r);
            
            String content = DELIMITTER + LINE_FEED;
            content += System.Label.DailyReportEmailBody.replaceAll('\r\n', LINE_FEED);
            content = content.replace('@project_name', project.Name);
            content = content.replace('@progress', getValues(assigns, Schema.Assign__c.Progress__c, false));
            content = content.replace('@work_detail', getValues(assigns, Schema.Assign__c.WorkDetail__c, true));
            content = content.replace('@card', getValues(assigns, Schema.Assign__c.AdmissionCard__c, false));
            content = content.replace('@act_overtime', getValues(assigns, Schema.Assign__c.PreviousOverTime__c, false));
            content = content.replace('@est_overtime', getValues(assigns, Schema.Assign__c.EstimatedOverTime__c, false));
            content = content.replace('@remarks', getValues(assigns, Schema.Assign__c.Remarks__c, true));
            content += LINE_FEED;
            content += LINE_FEED;
            body += content;
        }
        
        body += DELIMITTER + LINE_FEED;
        
        return body;
    }
    
    private static String getValues(List<Assign__c> assigns, Schema.SObjectField field, Boolean feedLine){
        List<String> values = new List<String>();
        for(Assign__c assign : assigns){
            if(feedLine){
                values.add(assign.Member__r.Abbr__c + ':' + LINE_FEED + getValue(assign, field) + LINE_FEED);
            }else{
                values.add(assign.Member__r.Abbr__c + ':' + getValue(assign, field));
            }
        }
        
        return String.join(values, LINE_FEED).removeEnd(LINE_FEED);
    }    
    
    private static String getValue(Assign__c assign, Schema.SObjectField field){
        Object rawValue = assign.get(field);
        if(rawValue == null)
            return DEFAULT_VALUE;
        
        Schema.SOAPType type = field.getDescribe().getSOAPType();
        
        if(type == Schema.SOAPType.DOUBLE){
            Double doubleValue = (Double)rawValue;
            if(doubleValue == 0)
                return DEFAULT_VALUE;
            
            return doubleValue.format() + 'h';
        }
        
        return String.valueOf(rawValue);
    }
    
    private class Member implements Comparable{
        public Integer DisplayOrder {get; set;}
        public String Name {get; set;}
        
        public Member(Integer order, String name){
            this.DisplayOrder = order;
            this.Name = name;
        }
        
        public Integer compareTo(Object compareTo) {
            Member compareToEmp = (Member)compareTo;
            if (this.DisplayOrder == compareToEmp.DisplayOrder) return 0;
            if (this.DisplayOrder > compareToEmp.DisplayOrder) return 1;
            return -1;        
        }
    }
}