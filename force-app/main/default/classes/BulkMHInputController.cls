public class BulkMHInputController {

    public String ReportName {get;set;}
    public String ProjectName {get;set;}
    public List<ProjectReport__c> Reports {get{return getCurrentReport();}}
    public String ReportDate {get;set;}
    public String DisplayStartDate {get;set;}
    public String StartDate{get;set;}
    public Boolean HasRecords {get;set;}
    public Boolean HasTasks {get;set;}
    public Boolean HasNext { get; set; }
    public Boolean HasPrevious { get; set; }
    public Boolean HasSingleRecord{get;set;}
    public Integer PageNo {get;set;}
    public Integer LastPageNo {get;set;}
    public Integer PageNoFieldSize {get;set;}
    
    private ApexPages.StandardSetController setCtl = null;
    private static final Integer PAGE_SIZE = 1;

    public void prepare(){
		ID recordId = (ID)ApexPages.currentPage().getParameters().get('id');
        this.setCtl = getSetController(recordId);
        this.setCtl.setPageSize(PAGE_SIZE);
        this.HasRecords = this.setCtl.getResultSize() > 0;
        this.HasTasks = hasTasks();
        this.HasSingleRecord = this.setCtl.getResultSize() == 1;
        this.HasPrevious = false;
        this.HasNext = this.setCtl.getHasNext();
		this.PageNo = this.setCtl.getPageNumber();
        this.LastPageNo = this.setCtl.getResultSize();
        this.PageNoFieldSize = String.valueOf(this.LastPageNo).length();
        if(this.HasRecords){
            setPageInfo();
        }
    }

    public void movePrevious() {
        if (this.HasPrevious) {
            this.setCtl.previous();
			setPageInfo();
            this.HasNext = setCtl.getHasNext();           
            this.HasPrevious = setCtl.getHasPrevious();
        }
    }

    public void moveNext() {
        if(this.HasNext){
            this.setCtl.next();
			setPageInfo();            
            this.HasNext = setCtl.getHasNext();           
            this.HasPrevious = setCtl.getHasPrevious();
        }
    }
    
    public void jumpTo(){
        if(this.PageNo > this.LastPageNo)
            this.PageNo = this.LastPageNo;

        this.setCtl.setpageNumber(this.PageNo);
        setPageInfo();
        this.HasNext = setCtl.getHasNext();           
        this.HasPrevious = setCtl.getHasPrevious();
    }
    
    private ApexPages.StandardSetController getSetController(ID recordId){
        Schema.sObjectType objectType = recordId.getSObjectType();
        
        if(objectType == Project__c.sObjectType)
            return new ApexPages.StandardSetController(getReportsByProjectId(recordId));
		else if(objectType == ProjectReport__c.sObjectType)
            return new ApexPages.StandardSetController(getReports(recordId));
		else
            throw new TypeException('Invalid Id');
    }
    
    private List<ProjectReport__c> getCurrentReport(){
        return (List<ProjectReport__c>)this.setCtl.getRecords();
    }
    
    private Boolean hasTasks(){
        return getCurrentReport()[0].Sys_TaskCount__c > 0;
    }
    
    private void setPageInfo(){
        this.PageNo = this.setCtl.getPageNumber();
        ProjectReport__c report = getCurrentReport()[0];
        this.ReportName = report.name;
        this.ProjectName = report.Project__r.name;
        DateTime dt = report.ReportDate__c;
        this.ReportDate = dt.format('MM/dd');
        dt = report.ReportDate__c.addDays(-7);
        this.DisplayStartDate = dt.format('MM/dd');
        this.StartDate = dt.format('yyyy-MM-dd');        
    }
    
    public void save(){
        try{
            ProjectReport__c report = getCurrentReport()[0];
            update report.TaskOnReport__r;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, '保存しました'));
        }catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }
    
    private List<ProjectReport__c> getReports(String reportId){
        return [select
                Id,
                Name,
                ReportDate__c,
                Project__r.name,
                Sys_TaskCount__c,
                (select
                 id,
                 Member__c,
                 TaskScheduledThisWeek__c,
                 Achievement__c,
                 TaskScheduledNextWeek__c,
                 EstimatedManHour__c,
                 ProgressRate__c,
                 ManHourOnLastFri__c,
                 ManHourOnLastSat__c,
                 ManHourOnLastSun__c,
                 ManHourOnMon__c,
                 ManHourOnTue__c,
                 ManHourOnWed__c,
                 ManHourOnThu__c,
                 WorkingHourOnLastFri__c,
                 WorkingHourOnLastSat__c,
                 WorkingHourOnLastSun__c,
                 WorkingHourOnMon__c,
                 WorkingHourOnTue__c,
                 WorkingHourOnWed__c,
                 WorkingHourOnThu__c,
                 WorkingHourOnFri__c,
                 WorkingHourOnSat__c,
                 WorkingHourOnSun__c                                         	
                 from TaskOnReport__r
                 order by Assign__r.DisplayOrder__c
                )
                from ProjectReport__c
                where id = :reportId
               ];
    }
    
    private List<ProjectReport__c> getReportsByProjectId(String projectId){
        return	[select
                 Name,
                 ReportDate__c,
                 Project__r.name,
                 Sys_TaskCount__c,
                (select
                 id,
                 Member__c,
                 TaskScheduledThisWeek__c,
                 Achievement__c,
                 TaskScheduledNextWeek__c,
                 EstimatedManHour__c,
                 ProgressRate__c,
                 ManHourOnLastFri__c,
                 ManHourOnLastSat__c,
                 ManHourOnLastSun__c,
                 ManHourOnMon__c,
                 ManHourOnTue__c,
                 ManHourOnWed__c,
                 ManHourOnThu__c,
                 WorkingHourOnLastFri__c,
                 WorkingHourOnLastSat__c,
                 WorkingHourOnLastSun__c,
                 WorkingHourOnMon__c,
                 WorkingHourOnTue__c,
                 WorkingHourOnWed__c,
                 WorkingHourOnThu__c,
                 WorkingHourOnFri__c,
                 WorkingHourOnSat__c,
                 WorkingHourOnSun__c                                         	
                 from TaskOnReport__r
                 order by Assign__r.DisplayOrder__c
                )
                 from ProjectReport__c
                 where Project__c = :projectId
                 order by ReportDate__c
                ];
    }
       
}