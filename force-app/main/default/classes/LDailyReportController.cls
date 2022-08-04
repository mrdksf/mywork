public class LDailyReportController {

    public List<Project__c> Projects{get;set;}
    public Boolean ProjectExists {get;set;}
    public String EmailSubject{get;set;}
    public String EmailBody{get;set;}
    
    private String selectedCategory = null;
    
    public LDailyReportController(){
        this.ProjectExists = false;
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
        this.selectedCategory = category;
        if(String.isEmpty(category)){
            this.Projects.clear();
        }else{
            this.Projects = getProjects(category);
        }
        this.ProjectExists = this.Projects.size() > 0;
        this.EmailSubject = DailyReportEmailTemplateService.getSubject(this.Projects);
        this.EmailBody = DailyReportEmailTemplateService.getBody(this.Projects);
    }
    
    public void save(){
        try{
            List<Assign__c> assigns = new List<Assign__c>();
            for(Project__c project : this.Projects){
                assigns.addAll(project.AssignOnProject__r);
            }
            
            update assigns;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, '保存しました'));
        }catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }
    
    @AuraEnabled
    public static List<Project__c> getProjects(String category){
        return [select
                    Id,
                    Name,
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
                     Remarks__c
                     From AssignOnProject__r
                     Order by Name                     
                    )
                from Project__c
                where ProjectCategory__c = :category
                ];
    }
    
}