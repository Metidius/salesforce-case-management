public with sharing class SFDC_Application {
    public static final fflib_Application.UnitOfWorkFactory UnitOfWork = new fflib_Application.UnitOfWorkFactory(
        new List<SObjectType>{
            Case.SObjectType,
            CaseUpdate__c.SObjectType,
            CustomerContext__c.SObjectType
        }
    );

    public static final fflib_Application.ServiceFactory Service = new fflib_Application.ServiceFactory(
        new Map<Type, Type>{
            ICaseWorkspaceService.class => CaseWorkspaceServiceImpl.class
        }
    );

    public static final fflib_Application.SelectorFactory Selector = new SelectorFactoryExt(
        new Map<SObjectType, Type>{
            Case.SObjectType => CasesSelector.class,
            CaseUpdate__c.SObjectType => CasesUpdatesSelector.class,
            CustomerContext__c.SObjectType => CustomerContextsSelector.class
        }
    );

    public virtual class SelectorFactoryExt extends fflib_Application.SelectorFactory {
        public SelectorFactoryExt(Map<SObjectType, Type> selectorMap) {
            super(selectorMap);
        }

        public Boolean isSupported(SObjectType sObjectType) {
            return m_sObjectBySelectorType.containsKey(sObjectType);
        }
    }
}