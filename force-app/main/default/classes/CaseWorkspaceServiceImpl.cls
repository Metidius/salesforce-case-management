public with sharing class CaseWorkspaceServiceImpl implements ICaseWorkspaceService {

    private fflib_ISObjectUnitOfWork newUow() {
        // Use the application UnitOfWork factory so tests can inject a mock via SFDC_Application.UnitOfWork.setMock(...)
        return SFDC_Application.UnitOfWork.newInstance();
    }

    public CaseWorkspaceService.WorkspaceDTO getWorkspaceData(Id caseId) {
        if (caseId == null) {
            throw new CaseWorkspaceException('Case ID is required.');
        }

        List<Case> cases = CasesSelector.newInstance().selectByIdsWithNames(new Set<Id>{caseId});
        if (cases.isEmpty()) {
            throw new CaseWorkspaceException('Case not found.');
        }
        Case caseRecord = cases[0];

        List<CustomerContext__c> contexts = CustomerContextsSelector.newInstance().selectLatestByCaseIds(new Set<Id>{caseId});
        CustomerContext__c customerContext = contexts.isEmpty() ? null : contexts[0];

        List<CaseUpdate__c> updates = CasesUpdatesSelector.newInstance().selectRecentByCaseIds(new Set<Id>{caseId}, 5);

        return new Mapper().toDto(caseRecord, customerContext, updates);
    }

    public Id createCaseUpdate(Id caseId, String updateType, String summary, String details, Boolean visibleToCustomer) {
        if (caseId == null) {
            throw new CaseWorkspaceException('Case ID is required.');
        }
        if (String.isBlank(updateType)) {
            throw new CaseWorkspaceException('Please select an update type.');
        }
        if (String.isBlank(summary)) {
            throw new CaseWorkspaceException('Please enter a summary for this update.');
        }

        CaseUpdate__c caseUpdate = new CaseUpdate__c();
        caseUpdate.Case__c = caseId;
        caseUpdate.UpdateType__c = updateType;
        caseUpdate.Summary__c = summary.trim();
        caseUpdate.Details__c = details;
        caseUpdate.VisibleToCustomer__c = (visibleToCustomer == null) ? false : visibleToCustomer;

        fflib_ISObjectUnitOfWork uow = newUow();
        registerCaseUpdate(uow, caseId, updateType, summary, details, visibleToCustomer);
        uow.commitWork();

        // ID is available after commit
        return caseUpdate.Id;
    }

    private void registerCaseUpdate(fflib_ISObjectUnitOfWork uow, Id caseId, String updateType, String summary, String details, Boolean visibleToCustomer) {
        CaseUpdate__c caseUpdate = new CaseUpdate__c();
        caseUpdate.Case__c = caseId;
        caseUpdate.UpdateType__c = updateType;
        caseUpdate.Summary__c = summary.trim();
        caseUpdate.Details__c = details;
        caseUpdate.VisibleToCustomer__c = (visibleToCustomer == null) ? false : visibleToCustomer;
        uow.registerNew(caseUpdate);
    }

    public void markReviewed(Id caseId) {
        if (caseId == null) {
            throw new CaseWorkspaceException('Case ID is required');
        }

        List<CustomerContext__c> contexts = CustomerContextsSelector.newInstance().selectLatestByCaseIds(new Set<Id>{caseId});

        fflib_ISObjectUnitOfWork uow = newUow();

        CustomerContext__c customerContext;
        if (contexts.isEmpty()) {
            // Auto-create a context record for this case
            customerContext = new CustomerContext__c();
            customerContext.Case__c = caseId;
            customerContext.LastReviewed__c = Date.today();
            customerContext.ReviewedBy__c = UserInfo.getUserId();

            uow.registerNew(customerContext);
        } else {
            customerContext = contexts[0];
            customerContext.LastReviewed__c = Date.today();
            customerContext.ReviewedBy__c = UserInfo.getUserId();

            uow.registerDirty(customerContext);
        }

        uow.commitWork();
    }


    public void escalateCase(Id caseId, String reason) {
        if (caseId == null) {
            throw new CaseWorkspaceException('Case ID is required.');
        }
        if (String.isBlank(reason)) {
            reason = 'Escalated via Case Workspace Panel';
        }

        // You only need the case record, not names, so use selectById (if you have it).
        List<Case> caseRecords = CasesSelector.newInstance().selectById(new Set<Id>{ caseId });
        if (caseRecords.isEmpty()) {
            throw new CaseWorkspaceException('Case not found.');
        }

        Case caseRecord = caseRecords[0];
        caseRecord.Priority = 'High';

        CaseUpdate__c caseUpdate = new CaseUpdate__c();
        caseUpdate.Case__c = caseId;
        caseUpdate.UpdateType__c = 'Escalation';
        caseUpdate.Summary__c = 'Case escalated';
        caseUpdate.Details__c = reason;
        caseUpdate.VisibleToCustomer__c = false;

        fflib_ISObjectUnitOfWork uow = newUow();
        uow.registerDirty(caseRecord);
        uow.registerNew(caseUpdate);
        uow.commitWork();
    }

    private class Mapper {
        private CaseWorkspaceService.WorkspaceDTO toDto(
            Case caseRecord,
            CustomerContext__c customerContext,
            List<CaseUpdate__c> updates
        ) {
            CaseWorkspaceService.WorkspaceDTO workspaceDto = new CaseWorkspaceService.WorkspaceDTO();

            workspaceDto.caseInfo = new CaseWorkspaceService.CaseSummary();
            workspaceDto.caseInfo.id = caseRecord.Id;
            workspaceDto.caseInfo.caseNumber = caseRecord.CaseNumber;
            workspaceDto.caseInfo.status = caseRecord.Status;
            workspaceDto.caseInfo.priority = caseRecord.Priority;
            workspaceDto.caseInfo.subject = caseRecord.Subject;
            workspaceDto.caseInfo.ownerName = (caseRecord.Owner != null) ? caseRecord.Owner.Name : null;
            workspaceDto.caseInfo.accountName = (caseRecord.Account != null) ? caseRecord.Account.Name : null;

            if (customerContext != null) {
                workspaceDto.context = new CaseWorkspaceService.CustomerContext();
                workspaceDto.context.id = customerContext.Id;
                workspaceDto.context.customerTier = customerContext.CustomerTier__c;
                workspaceDto.context.supportSla = customerContext.SupportSLA__c;
                workspaceDto.context.riskFlag = customerContext.RiskFlag__c;
                workspaceDto.context.riskNotes = customerContext.RiskNotes__c;
                workspaceDto.context.lastReviewed = customerContext.LastReviewed__c;
                workspaceDto.context.reviewedByName =
                    (customerContext.ReviewedBy__r != null) ? customerContext.ReviewedBy__r.Name : null;
            } else {
                workspaceDto.context = null;
            }

            workspaceDto.recentUpdates = new List<CaseWorkspaceService.CaseUpdateSummary>();
            for (CaseUpdate__c caseUpdate : (updates == null ? new List<CaseUpdate__c>() : updates)) {
                CaseWorkspaceService.CaseUpdateSummary updateSummary = new CaseWorkspaceService.CaseUpdateSummary();

                updateSummary.id = caseUpdate.Id;
                updateSummary.createdDate = caseUpdate.CreatedDate;
                updateSummary.updateType = caseUpdate.UpdateType__c;
                updateSummary.summary = caseUpdate.Summary__c;
                updateSummary.visibleToCustomer = caseUpdate.VisibleToCustomer__c;
                updateSummary.createdByName = (caseUpdate.CreatedBy != null) ? caseUpdate.CreatedBy.Name : null;

                workspaceDto.recentUpdates.add(updateSummary);
            }

            return workspaceDto;
        }
    }

    public class CaseWorkspaceException extends Exception {}
}
