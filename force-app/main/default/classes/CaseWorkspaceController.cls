public with sharing class CaseWorkspaceController {

    @AuraEnabled(cacheable=true)
    public static CaseWorkspaceService.WorkspaceDTO getWorkspaceData(Id caseId) {
        try {
            return CaseWorkspaceService.getWorkspaceData(caseId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Id createCaseUpdate(Id caseId, String updateType, String summary, String details, Boolean visibleToCustomer) {
        try {
            return CaseWorkspaceService.createCaseUpdate(caseId, updateType, summary, details, visibleToCustomer);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void markReviewed(Id caseId) {
        try {
            CaseWorkspaceService.markReviewed(caseId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void escalateCase(Id caseId, String reason) {
        try {
            CaseWorkspaceService.escalateCase(caseId, reason);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
