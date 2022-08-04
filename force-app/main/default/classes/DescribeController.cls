public class DescribeController {

    // -------------- プロパティ -------------------------
    // Selected sObject type
    public String SelectedSObject {get; set;}

    public String SelectedObjectType {get; set;}
    public String SelectedObjectName {get; private set;}
    public String SelectedObjectLabel {get; private set;}
    public String SelectedObjectPrefix {get; private set;}
    public String SetupLinkUrl {get; private set;}

    // Header displayed on VF
    public List<String> ColumnHeader {get; private set;}

    // Export file name
    public String FileName { get { return getExportFileName(); } }
    // Csv records
    public List<String> CsvRecords { get; private set; }
    // Excel records
    public List<FieldDefinitionWrapper> ExcelRecords {get; private set;}

    // sObject Name/Label Map
    private Map<String, String> nameLabelMap = new Map<String, String>();
    // Sorted sObject Api Name List
    private List<String> apiNameList = null;
    // sObject type
    private Map<String, Schema.SObjectType> globalDescribeResult = null;
    // Describe result map
    private transient Map<String, Schema.DescribeSObjectResult> describeResultMap = null;
    // FieldDefinitions
    private List<FieldDefinition> currentObjectFieldDefinitionList = new List<FieldDefinition>();
    // flag
    private Boolean useApiNameAsLabel = false;

    // オブジェクト種別定数
    private static final String CUSTOM_OBJECT = 'Custom';
    private static final String STANDARD_OBJECt = 'Standard';
    private static final String ANY_OBJECT = 'Any Object';
    // カンマ
    private static final String COMMA = ',';

    /* ----------------------------------------- */
    // Constructor
    /* ----------------------------------------- */
    public DescribeController () {

        this.globalDescribeResult = Schema.getGlobalDescribe();

        List<EntityDefinition> definitions = [SELECT Label, QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName IN :this.globalDescribeResult.keySet() ORDER BY Label];
        for (EntityDefinition definition : definitions) {

            if (definition.Label.StartsWith('__MISSING LABEL__')){
                this.nameLabelMap.put(definition.QualifiedApiName, definition.QualifiedApiName);
            }else{
                this.nameLabelMap.put(definition.QualifiedApiName, definition.Label);
            }
        }

        this.apiNameList = getSortedList(new List<String>(this.nameLabelMap.keySet()));

        this.ExcelRecords = new List<FieldDefinitionWrapper>();
        this.SelectedObjectType = CUSTOM_OBJECT;
        this.SelectedObjectPrefix = '';
        this.SelectedObjectName = '';
        this.ColumnHeader = getColumnHeaderList(EN);
    }

    /* ----------------------------------------- */
    // Get export file name
    /* ----------------------------------------- */
    private String getExportFileName(){

        return this.SelectedObjectPrefix + '_' + this.SelectedObjectName + '(' + EncodingUtil.urlEncode(this.SelectedObjectLabel, 'UTF-8') + ')';

    }

    /* ----------------------------------------- */
    // Get CSV Export Page
    /* ----------------------------------------- */
    public PageReference getDownloadPage(){

        this.CsvRecords = getCsvRecords();

        return Page.DescribeResultCsvDownloadPage;
    }

    /* ----------------------------------------- */
    // Get Excel Export Page
    /* ----------------------------------------- */
    public Pagereference getExcelDownloadPage(){

        this.ExcelRecords.clear();

        for(FieldDefinition fd : this.currentObjectFieldDefinitionList){

            this.ExcelRecords.add(new FieldDefinitionWrapper(fd));

        }

        return Page.DescribeResultExcelDownloadPage;
    }

    /* ----------------------------------------- */
    // Get sObject type list
    /* ----------------------------------------- */
    public List<SelectOption> getSObjectSelectOptionList() {

        List<SelectOption> options = new List<SelectOption>();
        /*
        List<String> nameList = new List<String>();

        String typeName = null;
        for (Schema.SObjectType type : this.globalDescribeResult.values()) {

            typeName = String.valueOf(type);

            if (isTargetObject(typeName))
                nameList.add(typeName);
        }

        nameList = getSortedList(nameList);
        */

        options.add(new SelectOption('','-- 選択してください --'));

        /*
        for (String objectName : nameList) {
            options.add(new SelectOption(objectName, objectName));
        }
        */

        if (this.useApiNameAsLabel) {

            for (String apiName : this.apiNameList) {

                if (isTargetObject(apiName))
                    options.add(new SelectOption(apiName, apiName));

            }

        }else{

            for (String apiName : nameLabelMap.keySet()) {

                if (isTargetObject(apiName))
                    options.add(new SelectOption(apiName, nameLabelMap.get(apiName)));

            }

        }

        return options;
    }

    /* ----------------------------------------- */
    // Sort string list case insensitive
    /* ----------------------------------------- */
    private List<String> getSortedList(List<String> sourceList){
        List<String> captalizedList = new List<String>();
        List<String> sortedList = new List<String>();
        Map<String, String> mp = new Map<String, String>();

        for(String str : sourceList){
            captalizedList.add(str.toUpperCase());
            mp.put(str.toUpperCase(), str);
        }

        captalizedList.sort();

        for(String str: captalizedList){
            sortedList.add(mp.get(str));
        }

        return sortedList;

    }

    /* ----------------------------------------- */
    // Filtr custom/standard sObject
    /* ----------------------------------------- */
    private Boolean isTargetObject(String apiName){

        if(this.SelectedObjectType == CUSTOM_OBJECT && !apiName.endsWith('__c'))
            return false;

        if(this.SelectedObjectType == STANDARD_OBJECT && apiName.endsWith('__c'))
            return false;

        return true;
    }

    /* ----------------------------------------- */
    // Get describe field result to display
    /* ----------------------------------------- */
    public List<FieldDefinition> getDescribeResult() {

        List<FieldDefinition> fieldDefinitions = new List<FieldDefinition>();

        if (String.isEmpty(this.SelectedSObject))
            return fieldDefinitions;

        Schema.DescribeSObjectResult objectResult = this.globalDescribeResult.get(this.SelectedSObject).getDescribe();

        // object name
        this.SelectedObjectName = objectResult.getName();

        // object label
        this.SelectedObjectLabel = objectResult.getLabel();

        // object prefix
        this.SelectedObjectPrefix = objectResult.getKeyPrefix();

        // object setup id
        EntityDefinition entityDefinition = [SELECT DurableId FROM EntityDefinition WHERE QualifiedApiName = :this.SelectedObjectName limit 1];
        this.SetupLinkUrl = Url.getSalesforceBaseUrl().toExternalForm() + '/' + entityDefinition.DurableId;

        Map<String, Schema.SObjectField> nameFieldMap = objectResult.fields.getMap();

        for (Schema.SObjectField field : nameFieldMap.values()) {

            FieldDefinition fieldDefinition = new FieldDefinition();

            Schema.DescribeFieldResult fieldResult = field.getDescribe();

            String fieldTypeName = fieldResult.getType().name();

            //各項目設定を取得・設定
            fieldDefinition.Label = fieldResult.getLabel();
            fieldDefinition.ApiName = fieldResult.getName();
            fieldDefinition.Type = getDisplayTypeName(fieldResult);
            fieldDefinition.Length = getFieldLength(fieldResult);
            fieldDefinition.ReferenceTo = getReferencedSObjects(fieldResult);
            fieldDefinition.ReferenceTargetField = fieldResult.getReferenceTargetField();

            if(fieldTypeName == 'PICKLIST' || fieldTypeName == 'MULTIPICKLIST'){
                PicklistDefinition picklist = new PicklistDefinition(fieldResult);
                fieldDefinition.PicklistLabels = picklist.Labels;
                fieldDefinition.PicklistValues = picklist.Values;
            }

            if(fieldResult.isCalculated())
                fieldDefinition.Formula = fieldResult.getCalculatedFormula();

            fieldDefinition.SoapType = fieldResult.getSoapType();
            fieldDefinition.isAutoNumber = fieldResult.isAutoNumber();
            fieldDefinition.IsCustom = fieldResult.IsCustom();
            fieldDefinition.DefaultValue = fieldResult.getDefaultValue();
            fieldDefinition.DefaultValueFormula = fieldResult.getDefaultValueFormula();
            fieldDefinition.IsCaseSensitive = fieldResult.isCaseSensitive();
            fieldDefinition.IsRestrictedPicklist = fieldResult.isRestrictedPicklist();
            fieldDefinition.IsDependentPicklist = fieldResult.isDependentPicklist();
            fieldDefinition.IsNillable = fieldResult.IsNillable();
            fieldDefinition.IsUnique = fieldResult.isUnique();
            fieldDefinition.IsExternalId = fieldResult.isExternalId();
            fieldDefinition.HelpText = fieldResult.getInlineHelpText();

            fieldDefinitions.add(fieldDefinition);
        }

        // Assign number
        Integer itemNo = 0;
        for(FieldDefinition fieldDefinition : fieldDefinitions) {
            itemNo++;
            fieldDefinition.No = itemNo;
        }

        this.currentObjectFieldDefinitionList = fieldDefinitions;

        return this.currentObjectFieldDefinitionList;
    }

    /* ----------------------------------------- */
    // Get field type name in Japanese
    /* ----------------------------------------- */
    private String getDisplayTypeName(Schema.DescribeFieldResult fieldResult) {

        String displayTypeName = null;

        //データタイプ取得
        String dataTypeName = fieldResult.getType().name();

        //データタイプラベルを取得
        displayTypeName = getFieldTypeLabel(dataTypeName);

        //自動採番項目チェック
        if (fieldResult.isAutoNumber())
            displayTypeName = '自動採番';

        //数式項目チェック
        if (fieldResult.isCalculated())
            displayTypeName = '数式（' + displayTypeName + '）';

        return displayTypeName;
    }

    /* ----------------------------------------- */
    // Get simplified field length
    /* ----------------------------------------- */
    private String getFieldLength(Schema.DescribeFieldResult fieldResult) {

        String fieldLength = null;

        //データタイプ取得
        Schema.SoapType soapType = fieldResult.getSoapType();

        //文字数取得タイプ「INT」の場合
        if (soapType.equals(Schema.SoapType.INTEGER)) {
            fieldLength = fieldResult.getDigits() + ',0';
        //文字数取得タイプ「DBL」の場合
        } else if (soapType.equals(Schema.SoapType.DOUBLE)) {
            Integer precision = fieldResult.getPrecision();
            Integer scale = fieldResult.getScale();
            fieldLength = (precision - scale) + ',' + scale;
        } else {
            Integer length = fieldResult.getLength();
            if (length > 0){
                fieldLength = String.valueOf(length);
            }
        }

        return fieldLength;
    }

    /* ----------------------------------------- */
    // Get referenced sObject names
    /* ----------------------------------------- */
    private String getReferencedSObjects(Schema.DescribeFieldResult fieldResult){
        List<String> sobjects = new List<String>();
        for (sObjectType type : fieldResult.getReferenceTo()){
            sobjects.add(type.getDescribe().getName());
        }

        return String.join(sobjects, '\n');
    }

    /* ----------------------------------------- */
    // Create type and type name mapping
    /* ----------------------------------------- */
    private String getFieldTypeLabel(String fieldTypeName){

        switch on fieldTypeName {
            when 'ADDRESS' { return '住所'; }
            when 'EMAIL' { return '電子メール'; }
            when 'PHONE' { return '電話'; }
            when 'COMBOBOX' { return 'テキスト（＋選択リスト）'; }
            when 'ENCRYPTEDSTRING' { return 'パスワード'; }
            when 'STRING' { return 'テキスト'; }
            when 'TEXTAREA' { return 'テキストエリア'; }
            when 'TIME' { return '時間'; }
            when 'BOOLEAN' { return 'チェックボックス'; }
            when 'DATE' { return '日付'; }
            when 'DATETIME' { return '日付/時間'; }
            when 'PICKLIST' { return '選択リスト'; }
            when 'MULTIPICKLIST' { return '選択リスト(複数選択)'; }
            when 'REFERENCE' { return 'ルックアップ'; }
            when 'INTEGER' { return '数値'; }
            when 'CURRENCY' { return '通貨'; }
            when 'DOUBLE' { return '数値'; }
            when 'PERCENT' { return 'パーセント'; }
            when 'LOCATION' { return '地理位置情報'; }
            when else { return fieldTypeName; }
        }
    }

    /* ----------------------------------------- */
    // All/Custom/Standard
    /* ----------------------------------------- */
    public List<SelectOption> getObjectTypeList() {

        List<SelectOption> options = new List<SelectOption>();

        options.add(new SelectOption(ANY_OBJECT, '両方'));
        options.add(new SelectOption(STANDARD_OBJECT, '標準'));
        options.add(new SelectOption(CUSTOM_OBJECT, 'カスタム'));

        return options;
    }

    /* ----------------------------------------- */
    // Method only to refresh apex:repeat area
    /* ----------------------------------------- */
    public void refreshPage() {
    }

    /* ----------------------------------------- */
    // Get column header names
    /* ----------------------------------------- */
    private static final String JP = 'JP';
    private static final String EN = 'EN';

    private List<String> getColumnHeaderList(String lang){
        if (lang == JP)
            return getJapaneseColumnHeaderList();
        else
            return getEnglishColumnHeaderList();
    }

    private List<String> getEnglishColumnHeaderList(){
        return new List<String>{
                'No',
                'Label',
                'Name',
                'Type',
                'Length',
                'Reference To',
                'Picklist Lables',
                'Picklist Values',
                'Formula',
                'SOAP Type',
                'Auto Number',
                'Custom',
                'Default Value',
                'Default Value Formula',
                'Case Sensitive',
                'Restricted Picklist',
                'Dependent Picklist',
                'Nillabel',
                'Unique',
                'External ID',
                'Help Text'
        };
    }

    private List<String> getJapaneseColumnHeaderList(){
        return new List<String>{
                'No',
                '表示ラベル',
                'API参照名',
                'データ型',
                '文字数',
                '関連先',
                '選択リスト値',
                '選択リストAPI参照名',
                '数式',
                'SOAPタイプ',
                '自動裁判型',
                'カスタム項目',
                'デフォルト値',
                'デフォルト値数式',
                '大文字と小文字を区別する',
                '制限つき選択リスト',
                '連動選択リスト',
                '必須項目',
                'ユニーク',
                '外部 ID',
                'ヘルプテキスト'
        };
    }

    /* ==================================================================== */
    // Methods for CSV Export
    /* ==================================================================== */

    /* ----------------------------------------- */
    // Get describe result splitted by comma
    /* ----------------------------------------- */
    private List<String> getCsvRecords(){

        List<String> csvRecords = new List<String>();

        csvRecords.add(String.join(this.ColumnHeader, COMMA) + '\n');

        for(FieldDefinition fd : this.currentObjectFieldDefinitionList){

            List<String> values = new List<String>();
            values.add(getCsvEscapedString(fd.No));
            values.add(getCsvEscapedString(fd.Label));
            values.add(getCsvEscapedString(fd.ApiName));
            values.add(getCsvEscapedString(fd.Type));
            values.add(getCsvEscapedString(fd.Length));
            values.add(getCsvEscapedString(fd.ReferenceTo));
            values.add(getCsvEscapedString(fd.ReferenceTargetField));
            values.add(getCsvEscapedString(fd.PicklistLabels));
            values.add(getCsvEscapedString(fd.PicklistValues));
            values.add(getCsvEscapedString(fd.IsRestrictedPicklist));
            values.add(getCsvEscapedString(fd.Formula));
            values.add(getCsvEscapedString(fd.SOAPType));
            values.add(getCsvEscapedString(fd.IsAutoNumber));
            values.add(getCsvEscapedString(fd.IsCustom));
            values.add(getCsvEscapedString(fd.DefaultValue));
            values.add(getCsvEscapedString(fd.DefaultValueFormula));
            values.add(getCsvEscapedString(fd.IsCaseSensitive));
            values.add(getCsvEscapedString(fd.IsDependentPicklist));
            values.add(getCsvEscapedString(fd.IsNillable));
            values.add(getCsvEscapedString(fd.IsUnique));
            values.add(getCsvEscapedString(fd.IsExternalId));
            values.add(getCsvEscapedString(fd.HelpText));

            csvRecords.add(String.join(values, COMMA) + '\n');
        }

        return csvRecords;
    }

    /* ----------------------------------------- */
    // Get escaped string
    /* ----------------------------------------- */
    private String getCsvEscapedString(Object value){
        if(value == null)
            return '';
        else
            return String.valueOf(value).escapeCsv();
    }

    /* ================================================================================ */
    // Internal classes
    /* ================================================================================ */

    /* ----------------------------------------- */
    // Wrapper for DescribeFieldResult
    /* ----------------------------------------- */
    public virtual class FieldDefinition {
        public Integer No { get; set; }
        public String Label  { get; set; }
        public String ApiName { get; set; }
        public String Type { get; set; }
        public String Length { get; set; }
        public String ReferenceTo { get; set; }
        public String ReferenceTargetField { get; set; }
        public String PicklistValues { get; set; }
        public String PicklistLabels { get; set; }
        public String Formula { get; set; }
        public Schema.SoapType SoapType { get; set;}
        public Boolean IsAutonumber { get; set; }
        public Boolean IsCustom { get; set; }
        public Object DefaultValue { get; set; }
        public String DefaultValueFormula { get; set; }
        public Boolean IsCaseSensitive { get; set; }
        public Boolean IsDependentPicklist { get; set; }
        public Boolean IsRestrictedPicklist { get; set;}
        public Boolean IsNillable { get; set; }
        public Boolean IsUnique { get; set; }
        public Boolean IsExternalId { get; set; }
        public String HelpText { get; set; }
    }

    /* ----------------------------------------- */
    // Wrapper for FieldDefitionClass
    //  - used for Excel export
    /* ----------------------------------------- */
    public class FieldDefinitionWrapper extends FieldDefinition {

        public FieldDefinitionWrapper(FieldDefinition source){
            this.No = source.No;
            this.Label = source.Label;
            this.ApiName = source.ApiName;
            this.Type = source.Type;
            this.Length = source.Length;
            this.IsAutonumber = source.IsAutonumber;
            this.IsCustom = source.IsCustom;
            this.DefaultValue = source.DefaultValue;
            this.DefaultValueFormula = source.DefaultValueFormula;
            this.IsCaseSensitive = source.IsCaseSensitive;
            this.IsDependentPicklist = source.IsDependentPicklist;
            this.IsNillable = source.IsNillable;
            this.IsUnique = source.IsUnique;
            this.IsExternalId = source.IsExternalId;
            this.IsRestrictedPicklist = source.IsRestrictedPicklist;
            this.ReferenceTargetField = source.ReferenceTargetField;
            this.SoapType = source.SoapType;
            this.ReferenceTo = source.ReferenceTo == null ? source.ReferenceTo : source.ReferenceTo.replaceAll('\n', '<br/>');
            this.PicklistValues = source.PicklistValues == null ? source.PicklistValues : source.PicklistValues.replaceAll('\n', '<br/>');
            this.PicklistLabels = source.PicklistLabels == null ? source.PicklistLabels : source.PicklistLabels.replaceAll('\n', '<br/>');
            this.Formula = source.Formula == null ? source.Formula : source.Formula.replaceAll('\n', '<br/>');
            this.HelpText = source.HelpText == null ? source.HelpText : source.HelpText.replaceAll('\n', '<br/>');
        }
    }

    /* ----------------------------------------- */
    // Wrappr for Picklist values and labels
    /* ----------------------------------------- */
    public class PicklistDefinition {
        public String Values { get; private set;}
        public String Labels { get; private set;}

        public PicklistDefinition(Schema.DescribeFieldResult fieldResult){
            prepare(fieldResult);
        }

        private void prepare(Schema.DescribeFieldResult fieldResult){
            List<String> values = new List<String>();
            List<String> lables = new List<String>();

            for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
                values.add(picklistEntry.getValue());
                lables.add(picklistEntry.getLabel());
            }

            this.Values = String.join(values, '\n');
            this.Labels = String.join(lables, '\n');
        }
    }
}