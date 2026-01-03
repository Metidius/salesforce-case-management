public with sharing class CaseWorkspaceService {

    private static ICaseWorkspaceService service() {
        return (ICaseWorkspaceService) SFDC_Application.Service.newInstance(ICaseWorkspaceService.class);
    }

    // ===== DTOs (all one level deep) =====

    public class WorkspaceDTO {
        @AuraEnabled public CaseSummary caseInfo;
        @AuraEnabled public CustomerContext context;
        @AuraEnabled public List<CaseUpdateSummary> recentUpdates;
    }

    public class CaseSummary {
        @AuraEnabled public Id id;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String status;
        @AuraEnabled public String priority;
        @AuraEnabled public String subject;
        @AuraEnabled public String ownerName;
        @AuraEnabled public String accountName;
    }

    public class CustomerContext {
        @AuraEnabled public Id id;
        @AuraEnabled public String customerTier;
        @AuraEnabled public String supportSla;
        @AuraEnabled public Boolean riskFlag;
        @AuraEnabled public String riskNotes;
        @AuraEnabled public Date lastReviewed;
        @AuraEnabled public String reviewedByName;
    }

    public class CaseUpdateSummary {
        @AuraEnabled public Id id;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String updateType;
        @AuraEnabled public String summary;
        @AuraEnabled public Boolean visibleToCustomer;
        @AuraEnabled public String createdByName;
    }


    // ===== Facade methods =====

    public static WorkspaceDTO getWorkspaceData(Id caseId) {
        return service().getWorkspaceData(caseId);
    }

    public static Id createCaseUpdate(Id caseId, String updateType, String summary, String details, Boolean visibleToCustomer) {
        return service().createCaseUpdate(caseId, updateType, summary, details, visibleToCustomer);
    }

    public static void markReviewed(Id caseId) {
        service().markReviewed(caseId);
    }

    public static void escalateCase(Id caseId, String reason) {
        service().escalateCase(caseId, reason);
    }
}
