public class DailyReportController {

    public List<Project__c> Projects {get;set;}
    public Boolean ProjectExists {get;set;}
    public String EmailSubject{get;set;}
    public String EmailBody{get;set;}
    
   	private Map<ID, Assign__c> assignMap;
    private String selectedCategory = null;
    
    public DailyReportController(){
        this.assignMap = new Map<ID,Assign__c>();
        this.ProjectExists = false;
        this.Projects = new List<Project__c>();
    }
    
    public List<SelectOption> getCategories(){
        List<SelectOption> options = new List<SelectOption>();

        Schema.DescribeFieldResult fieldResult = Project__c.ProjectCategory__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        
        options.add(new SelectOption('', ''));
        
        for(Schema.PicklistEntry entry : picklistEntries ){
            options.add(new SelectOption(entry.getValue(), entry.getLabel()));
        }

        return options;        
    }

    public String getCategory(){
        return this.selectedCategory;
    }
    
    public void setCategory(String category){
        ApexPages.getMessages().clear();
        
        this.selectedCategory = category;
        this.assignMap.clear();
        this.Projects.clear();
        
        if(!String.isEmpty(category)){
            this.Projects = getProjects(category);
            for(Project__c project : this.Projects){
            	this.assignMap.putAll(getAssigns(project.Id));
            }
        }
        
        this.ProjectExists = this.Projects.size() > 0;
        
        if(this.ProjectExists){
        	this.EmailSubject = DailyReportEmailTemplateService.getSubject(this.Projects);
        	this.EmailBody = DailyReportEmailTemplateService.getBody(this.Projects);
        }
    }
    
    public void save(){
        try{
            List<Assign__c> assigns = new List<Assign__c>();

            for(Project__c project : this.Projects){
                for(Assign__c assign : project.AssignOnProject__r){
                	if(IsAssignDataChanged(assign))
                        assigns.add(assign);
                }
            }
        
            update assigns;
            
            this.EmailSubject = DailyReportEmailTemplateService.getSubject(this.Projects);
        	this.EmailBody = DailyReportEmailTemplateService.getBody(this.Projects);
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, '保存しました'));
        }catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }
    
    private Boolean IsAssignDataChanged(Assign__c current){
        Assign__c old = this.assignMap.get(current.Id);
        
        if(old == null)
            return false;
        system.debug(old.DailyReportDate__c);
        system.debug(current.DailyReportDate__c);
        if(old.DailyReportDate__c != current.DailyReportDate__c)
            return true;
        
        if(old.Progress__c != current.Progress__c)
            return true;
        
        if(old.WorkDetail__c != current.WorkDetail__c)
            return true;
        
        if(old.PreviousOverTime__c != current.PreviousOverTime__c)
            return true;
        
        if(old.EstimatedOverTime__c != current.EstimatedOverTime__c)
            return true;
        
        if(old.Remarks__c != current.Remarks__c)
            return true;
        
        if(old.AdmissionCard__c != current.AdmissionCard__c)
            return true;
        
        return false;
    }
    
    private List<Project__c> getProjects(String category){
        return [select
                    Id,
                    Name,
                	UserName__c,
                    (select
                     Id,
                     Name,
                     Member__r.Name,
                     Member__r.Abbr__c,
                     DailyReportDate__c,
                     Progress__c,
                     WorkDetail__c,
                     PreviousOverTime__c,
                     EstimatedOverTime__c,
                     Remarks__c,
                     AdmissionCard__c,
                     DisplayOrder__c
                     From AssignOnProject__r
                     //Where AssignStartDate__c <= :Date.today()
                     //AND AssignEndDate__c >= :Date.today()
                     Order by DisplayOrder__c                     
                    )
                from Project__c
                where ProjectCategory__c = :category
                //and EndsOn__c >= :Date.today()
                order by CreatedDate asc
               ];
    }
    
    private List<Assign__c> getAssigns(String projectId){
        return [select
                    Id,
                    DailyReportDate__c,
                    Progress__c,
                    WorkDetail__c,
                    PreviousOverTime__c,
                    EstimatedOverTime__c,
                    Remarks__c,
                    AdmissionCard__c
                From Assign__c
                Where Project__c = :projectId
			 ];
    }
    
}