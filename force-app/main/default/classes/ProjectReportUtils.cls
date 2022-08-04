public class ProjectReportUtils {
    
    public static List<ProjectReport__c> geta(Id projectId){
        List<ProjectReport__c> reports = new List<ProjectReport__c>();
        List<AggregateResult> results = getMaxReportDate(projectId);
        Date lastReportDate = getDefaultReportDate();
        if(results.size() > 0){
            lastReportDate = (Date)results[0].get('maxDate');
        }
        
        Project__c project = [select id, StartsFrom__c, EndsOn__c from Project__c where ID = :projectId];
        List<Assign__c> assigns = getProjectAssignees(projectId);
        
        Date current = getNextReportDate(lastReportDate);
        
        if(getReportCount(current, project.EndsOn__c) > 300){
            throw new DmlException('Too many reports to create');
        }
        
        while(current < project.EndsOn__c){
            //List<Task__c> tasks = getTasks(assigns, ID reportId, Date startOfWeek)
            current = getNextReportDate(current);
        }
        
		return reports;
    }
    
    private static Integer getReportCount(Date startDate, Date endDate){
        Integer count = 0;
        Date current = startDate;
        while(current < endDate){
			count++;
            current = getNextReportDate(current);
        }
        return count;
    }
    
    public static Date getLastReportDate(Id projectId){
        try{
        	List<AggregateResult> results = getMaxReportDate(projectId);
            Date lastReportDate = (Date)results[0].get('maxDate');
            if(lastReportDate == null)
                return getDefaultReportDate();
           	else
                return lastReportDate;
        }catch(Exception ex){
            return getDefaultReportDate();
        }
    }
    
    public static Date getNextReportDate(Id projectId){
        return getLastReportDate(projectId).addDays(7);
    }
    
    public static Date getNextReportDate(Date latest){
        return latest.addDays(7);
    }
    
    public static void createTasks(ID reportId, Boolean withHour){
    	insert getTasks(reportId, withHour);
    }
    
    public static void createTasks(List<ID> reportIds, Boolean withHour){
        List<Task__c> tasks = new List<Task__c>();
        for(ID id : reportIds){
            tasks.addAll(getTasks(id, withHour));
        }
        insert tasks;
    }
    
    public static List<Task__c> getTasks(List<Assign__c> assigns, ID reportId, Date startOfWeek){
        List<Task__c> tasks = new List<Task__c>();
        for(Assign__c assign : assigns){
            if(assign.AssignEndDate__c >= startOfWeek){
                Task__c task = new Task__c();
                task.Assign__c = assign.Id;
                task.ProjectReport__c = reportId;
                tasks.add(task);
            }
        }
        return tasks;
    }
    
    public static List<Task__c> getTasks(ID reportId, Boolean withHour){
        List<Task__c> tasks = new List<Task__c>();
        ID projectId = getProjectId(reportId);
        Date startOfWeek = getLastReportDate(projectId).toStartOfWeek();
         
        for(Assign__c assign : getProjectAssignees(projectId)){
            if(assign.AssignEndDate__c >= startOfWeek){
                Task__c task = new Task__c();
                task.Assign__c = assign.Id;
                task.ProjectReport__c = reportId;
                if(withHour){
                	setWorkingHours(assign,task);
                }
                tasks.add(task);
            }
        }
        
        return tasks;
    }
    
    private static void setWorkingHours(Assign__c assign, Task__c task){
        task.WorkingHourOnLastFri__c = assign.Member__r.BaseWorkTime__c;
        task.WorkingHourOnMon__c = assign.Member__r.BaseWorkTime__c;
        task.WorkingHourOnTue__c = assign.Member__r.BaseWorkTime__c;
        task.WorkingHourOnWed__c = assign.Member__r.BaseWorkTime__c;
        task.WorkingHourOnThu__c = assign.Member__r.BaseWorkTime__c;
        task.WorkingHourOnFri__c = assign.Member__r.BaseWorkTime__c;
    }
    
    private static List<Assign__c> getProjectAssignees(Id projectId){
        return [select
                	id,
					Member__r.BaseWorkTime__c,
                	AssignEndDate__c
                from Assign__c
                where Project__c = :projectId
               ];
    }
    
    private static ID getProjectId(Id reportId){
    	ProjectReport__c report =  [select
                                        id,
                                        Project__c
                                    from ProjectReport__c
                                    where id = :reportId
                                   ];
        return report.Project__c;
    }
    
    private static List<AggregateResult> getMaxReportDate(Id projectId){
        return [select
					max(ReportDate__c) maxDate
                From ProjectReport__c
                Where Project__c = :projectId
                ];        
    }     
    
    private static Date getDefaultReportDate(){
        return Date.today().toStartOfWeek().addDays(-2);
    }
}