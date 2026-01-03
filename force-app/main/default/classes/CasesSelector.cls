public virtual class CasesSelector extends fflib_SObjectSelector {

    public static CasesSelector newInstance() {
        return (CasesSelector) SFDC_Application.Selector.newInstance(Case.getSObjectType());
    }

    public Schema.SObjectType getSObjectType() {
        return Case.SObjectType;
    }

    public virtual List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Case.Id, 
            Case.CaseNumber, 
            Case.Status, 
            Case.Priority, 
            Case.Subject,
            Case.OwnerId, 
            Case.AccountId
        };
    }

    public List<Case> selectById(Set<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) return new List<Case>();

        fflib_QueryFactory qf = newQueryFactory();
        qf.setCondition('Id IN :caseIds');
        return (List<Case>) Database.query(qf.toSOQL());
    }

    public List<Case> selectByIdsWithNames(Set<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) return new List<Case>();

        fflib_QueryFactory qf = newQueryFactory();
        qf.selectField('Owner.Name');
        qf.selectField('Account.Name');
        qf.setCondition('Id IN :caseIds');

        return (List<Case>) Database.query(qf.toSOQL());
    }
}
