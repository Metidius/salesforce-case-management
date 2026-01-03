public virtual class CustomerContextsSelector extends fflib_SObjectSelector {

    public static CustomerContextsSelector newInstance() {
        return (CustomerContextsSelector) SFDC_Application.Selector.newInstance(CustomerContext__c.getSObjectType());
    }

    public Schema.SObjectType getSObjectType() {
        return CustomerContext__c.SObjectType;
    }

    public virtual List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            CustomerContext__c.Id,
            CustomerContext__c.Case__c,
            CustomerContext__c.CustomerTier__c, 
            CustomerContext__c.SupportSLA__c,
            CustomerContext__c.RiskFlag__c, 
            CustomerContext__c.RiskNotes__c,
            CustomerContext__c.LastReviewed__c, 
            CustomerContext__c.ReviewedBy__c,
            CustomerContext__c.CreatedDate
        };
    }

    public List<CustomerContext__c> selectLatestByCaseIds(Set<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) return new List<CustomerContext__c>();

        fflib_QueryFactory qf = newQueryFactory();
        qf.selectField('ReviewedBy__r.Name');
        qf.setCondition('Case__c IN :caseIds');
        qf.addOrdering(CustomerContext__c.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING);
        qf.setLimit(1);

        return (List<CustomerContext__c>) Database.query(qf.toSOQL());
    }
}