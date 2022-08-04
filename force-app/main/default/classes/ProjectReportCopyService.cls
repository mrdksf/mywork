global class ProjectReportCopyService {

    webservice static String copy(String reportId){
		return executeCopy(reportId);
    }
    
	private static String executeCopy(String reportId){
        ProjectReport__c sourceReport = getSourceReport(reportId);

        Project__c project = getProject(sourceReport.Project__c);
        Date baseDate = ProjectReportUtils.getLastReportDate(project.Id).addDays(7);
        List<ID> validAssignIds = getValidAssignIds(project, baseDate);
        
        ProjectReport__c newReport = copyProjectReport(sourceReport, baseDate);
        copyTask(sourceReport, newReport.Id, validAssignIds);
        
        return 'Copied';       
    }
    
    private static ProjectReport__c copyProjectReport(ProjectReport__c sourceReport, Date baseDate){
        ProjectReport__c newReport = sourceReport.clone(false,true);
        newReport.Sys_BaseDate__c = baseDate;
        newReport.TaskOverviewThisWeek__c = sourceReport.TaskOverviewNextWeek__c;
        newReport.TaskOverviewNextWeek__c = null;
        newReport.Sys_SkipAutoCreateTasks__c = true;
        insert newReport;
        return newReport;
    }
    
    private static void copyTask(ProjectReport__c sourceReport, ID newReportId, List<ID> validAssignIds){
        List<Task__c> newTasks = new List<Task__c>();
        for(Task__c oldTask : sourceReport.TaskOnReport__r){
            if(validAssignIds.contains(oldTask.Assign__c)){
                Task__c newTask = oldTask.clone(false, true);
                newTask.ProjectReport__c = newReportId;
                newTask.TaskScheduledNextWeek__c = null;
                newTask.Achievement__c = null;
                newTask.TaskScheduledThisWeek__c = oldTask.TaskScheduledNextWeek__c;
                newTasks.add(newTask);
            }
        }
        insert newTasks;
    }
    
    private static Project__c getProject(ID projectId){
        return [select
                    Id,
                    EndsOn__c,
                    (select id, AssignEndDate__c from AssignOnProject__r)
                from Project__c
                where id = :projectId
               ];        
    }
    
    private static List<ID> getValidAssignIds(Project__c project, Date baseDate){
        Date startOfWeek = baseDate.toStartOfWeek();
        List<ID> validAssignIds = new List<ID>();
        
        for(Assign__c projectMember : project.AssignOnProject__r){
            if(projectMember.AssignEndDate__c >= startOfWeek){
                validAssignIds.add(projectMember.Id);
            }
        }
        
        return validAssignIds;
    }
        
    private static ProjectReport__c getSourceReport(String reportId){
        
        return [select
                    Name,
                    QCDProblem__c,
                    Project__c,
                    ActualReviewCount__c,
                    ScheduledReviewCount__c,
                    ReviewReportCount__c,
                    CurrentPhase__c,
                    TaskOverviewThisWeek__c,
                    Progress__c,
                    ProgressRate__c,
                    Information__c,
                    DelayCause__c,
                    DelayMeasure__c,
                    Remarks__c,
                    ProblemRate__c,
                    TaskOverviewNextWeek__c,
                    (select
                        Achievement__c,
                        Assign__c,
                        WorkingHourOnLastFri__c,
                        WorkingHourOnLastSat__c,
                        WorkingHourOnLastSun__c,
                        WorkingHourOnMon__c,
                        WorkingHourOnTue__c,
                        WorkingHourOnWed__c,
                        WorkingHourOnThu__c,
                        WorkingHourOnFri__c,
                        WorkingHourOnSat__c,
                        WorkingHourOnSun__c,
                        ManHourOnLastFri__c,
                        ManHourOnLastSat__c,
                        ManHourOnLastSun__c,
                        ManHourOnMon__c,
                        ManHourOnThu__c,
                        ManHourOnTue__c,
                        ManHourOnWed__c,
                        ProjectReport__c,
                        ReportDate__c,
                        TaskScheduledNextWeek__c,
                        TaskScheduledThisWeek__c
                     from TaskOnReport__r
                     order by Assign__r.DisplayOrder__c
                    )
                From ProjectReport__c
                Where id = :reportId
                ];
    }

}