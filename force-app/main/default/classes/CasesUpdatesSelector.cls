public virtual class CasesUpdatesSelector extends fflib_SObjectSelector {

    public static CasesUpdatesSelector newInstance() {
        return (CasesUpdatesSelector) SFDC_Application.Selector.newInstance(CaseUpdate__c.getSObjectType());
    }

    public Schema.SObjectType getSObjectType() {
        return CaseUpdate__c.SObjectType;
    }

    public virtual List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            CaseUpdate__c.Id, 
            CaseUpdate__c.Case__c, 
            CaseUpdate__c.CreatedDate,
            CaseUpdate__c.UpdateType__c, 
            CaseUpdate__c.Summary__c, 
            CaseUpdate__c.VisibleToCustomer__c
        };
    }

    public List<CaseUpdate__c> selectRecentByCaseIds(Set<Id> caseIds, Integer limitSize) {
        if (caseIds == null || caseIds.isEmpty()) return new List<CaseUpdate__c>();

        if (limitSize == null || limitSize <= 0) limitSize = 5;

        fflib_QueryFactory qf = newQueryFactory();
        qf.selectField('CreatedBy.Name');
        qf.setCondition('Case__c IN :caseIds');
        qf.addOrdering(CaseUpdate__c.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING);
        qf.setLimit(limitSize);

        return (List<CaseUpdate__c>) Database.query(qf.toSOQL());
    }
}