public interface ICaseWorkspaceService {
    CaseWorkspaceService.WorkspaceDTO getWorkspaceData(Id caseId);

    Id createCaseUpdate(
        Id caseId,
        String updateType,
        String summary,
        String details,
        Boolean visibleToCustomer
    );

    void markReviewed(Id caseId);

    void escalateCase(Id caseId, String reason);
}