public class WeeklyProjectReportController {

    public ProjectReport__c Report {get; set;}
    public Project__c Project {get;set;}
    public List<Task__c> Tasks {get;set;}
    public List<Risk__c> Risks {get;set;}
    public List<Problem__c> Problems {get;set;}
    public String ReportName {get;set;}
    public String ReportDate {get;set;}
    public String ProjectStartsFrom {get;set;}
    public String ProjectEndsOn { get;set;}
    public String ReviewCountDelimitter {get;set;}
    public List<String> DateList {get;set;}
    public String WorkloadIndexColor {get;set;}
    public String ProgressIndexColor {get;set;}
    public String ProblemIndexColor {get;set;}
    public String OverallIndexColor {get;set;}

    private String REPORTNAME_FORMAT = '{0}_{1}';
    
    public WeeklyProjectReportController(){
    }
    
    public void prepare(){
        String recordId = ApexPages.currentPage().getParameters().get('id');
        prepareData(recordId);
        prepareEvaluationColors();
        prepareReviewInfo();
        prepareDates();
    }
    
    private void prepareData(String recordId){
        this.Report = getProjectReport(recordId);
        this.Tasks = this.Report.TaskOnReport__r;
        this.Project = getProject(this.Report.Project__c);
        this.Problems = this.Project.ProblemOnProject__r;
        this.Risks = this.Project.RiskOnProject__r;        
    }
    
    private void prepareEvaluationColors(){
    	this.WorkloadIndexColor = getEvaluationIndexColor(this.Report.WorkloadIndex__c);
        this.ProgressIndexColor = getEvaluationIndexColor(this.Report.ProgressIndex__c);
        this.ProblemIndexColor = getEvaluationIndexColor(this.Report.ProblemIndex__c);
        this.OverallIndexColor = getEvaluationIndexColor(this.Report.OverallIndex__c);
    }
    
    private String getEvaluationIndexColor(Decimal index){
		if(index >= Integer.valueOf(System.Label.HighEvaluationIndex))
            return System.Label.HighEvaluationIndexColor;
        
        if(index >= Integer.valueOf(System.Label.MiddleEvaluationIndex))
            return System.Label.MiddleEvaluationIndexColor;
        
        if(index >= Integer.valueOf(System.Label.LowEvaluationIndex))
            return System.Label.LowEvaluationIndexColor;
        
        return System.Label.DefaultEvaluationIndexColor;
    }
    
    private void prepareDates(){
        prepareDatesOnReportTable();
        prepareDatesOnProblemTable();
        prepareDatesOnRiskTable();
    }
    
    private void prepareDatesOnReportTable(){
        DateTime dt = Report.ReportDate__c;
        this.ReportDate = dt.format('yyyy/M/d');
        this.ReportName = String.format(REPORTNAME_FORMAT, new LIst<String>{This.Project.ProjectReportFileName__c, dt.format('yyyyMMdd')}); 
        dt = this.Project.StartsFrom__c;
        this.ProjectStartsFrom = dt.format('yyyy/M/d');
        dt = this.Project.EndsOn__c;
        this.ProjectEndsOn = dt.format('yyyy/M/d');
        
        Date initialDate = this.Report.ReportDate__c.toStartOfWeek().addDays(-2);
        this.DateList = new List<String>();
        for(Integer i = 0; i < 10;i++){
            dt = initialDate.addDays(i);
            this.DateList.add(dt.format('M/d'));
        }
    }
    
    private void prepareDatesOnProblemTable(){
        for(Problem__c problem : this.Problems){
            DateTime dt = problem.OccurredOn__c;
            problem.Rep_OccurredOn__c = dt.format('yyyy/M/d');
            dt = problem.MeasureDeadline__c;
            problem.Rep_MeasureDeadline__c = dt.format('yyyy/M/d');
            dt = problem.MeasureTakenOn__c;
            problem.Rep_MeasureTakenOn__c = dt.format('yyyy/M/d');
        }
    }
    
    private void prepareDatesOnRiskTable(){
        for(Risk__c risk : this.Risks){
            DateTime dt = risk.RevisedOn__c;
            risk.Rep_RevisedOn__c = dt.format('yyyy/M/d');
            dt = risk.EmergedOn__c;
            risk.Rep_EmergedOn__c = dt.format('yyyy/M/d');
            dt = risk.TerminatedOn__c;
            risk.Rep_TerminatedOn__c = dt.format('yyyy/M/d');
            dt = risk.MeasureDeadline__c;
            risk.Rep_MeasureDeadline__c = dt.format('yyyy/M/d');
            dt = risk.MeasureTakenOn__c;
            risk.Rep_MeasureTakenOn__c = dt.format('yyyy/M/d');
            dt = risk.IdentifiedOn__c;
            risk.Rep_IdentifiedOn__c = dt.format('yyyy/M/d');
        }        
    }
    
    private void prepareReviewInfo(){
        if(this.Report.ScheduledReviewCount__c == 0 || this.Report.ScheduledReviewCount__c == null){
            this.ReviewCountDelimitter = null;
        }else{
            this.ReviewCountDelimitter = '/';
        }
    }
    
    private ProjectReport__c getProjectReport(String recordId){
        return [select
                    Id,
                    Name,
                    Project__c,
                    ReportDate__c,
                	WorkloadIndex__c,
                	ProgressIndex__c,
                	ProblemIndex__c,
                	OverallIndex__c,
                    Progress__c,
                    DelayMeasure__c,
                    ProgressRate__c,
                    ProblemRate__c,
                    CurrentPhase__c,
                    ScheduledReviewCount__c,
                    ActualReviewCount__c,
                    ReviewReportCount__c,
                    TaskOverviewThisWeek__c,
                    TaskOverviewNextWeek__c,
                    DelayCause__c,
                    QCDProblem__c,
                    Information__c,
                    OverloadReason__c,
                    (select
                     Id,
                     Member__c,
                     MemberAbbr__c,
                     TaskScheduledThisWeek__c,
                     Achievement__c,
                     TaskScheduledNextWeek__c,
                     WorkingHourOnSun__c,
                     WorkingHourOnSat__c,
                     WorkingHourOnFri__c,
                     WorkingHourOnMon__c,
                     WorkingHourOnTue__c,
                     WorkingHourOnWed__c,
                     WorkingHourOnThu__c,
                     WorkingHourOnLastSat__c,
                     WorkingHourOnLastSun__c,
                     WorkingHourOnLastFri__c,
                     TotalWorkingHour__c
                     from TaskOnReport__r
                     order by Assign__r.DisplayOrder__c)
                From ProjectReport__c
                Where Id = :recordId 
        ];
    }
    
    private Project__c getProject(String recordId){
        return [select
                    Id,
                    Name,
                    ProblemTableDocumentNo__c,
                    ProblemTableIssueNo__c,
                    RiskTableDocumentNo__c,
                    RiskTableIssueNo__c,
                    ProjectReportFileName__c,
                    ReportSubmitter__r.Name,
                    ProjectNo__c,
                    UserName__c,
                    ProgressRate__c,
                    StartsFrom__c,
                    EndsOn__c,
                    ContractType__c,
                    WorkType__c,
                    (select
                    Id,
                    Name,
                    Category1__c,
                    Category2__c,
                    Details__c,
                    MeasureDeadline__c,
                    MeasureManHour__c,
                    MeasurePIC__c,
                    MeasureResults__c,
                    Measures__c,
                    MeasureTakenOn__c,
                    OccurredOn__c,
                    Pointer__c,
                    Status__c
                    From ProblemOnProject__r
                    order by Name),
                    (select
                    Id,
                    Name,
                    Details__c,
                    EmergedOn__c,
                    IdentifiedOn__c,
                    ImpactExtent__c,
                    ImpactLevel__c,
                    MeasureDeadline__c,
                    MeasureManHour__c,
                    MeasurePIC__c,
                    MeasureResults__c,
                    Measures__c,
                    MeasureTakenOn__c,
                    Phase__c,
                    Pointer__c,
                    Priority__c,
                    ProbabilityLevel__c,
                    RevisedOn__c,
                    RiskType__c,
                    RiskValue__c,
                    Status__c,
                    TerminatedOn__c
                    From RiskOnProject__r
                    order by name)
                From Project__c
                Where Id = :recordId       
        ];
    }
}