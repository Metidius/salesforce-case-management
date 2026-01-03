@IsTest
public with sharing class CaseWorkspaceController_Test {
    static fflib_ApexMocks mocks = new fflib_ApexMocks();

    static Case testCase;
    static Account testAccount;
    static CaseWorkspaceService.WorkspaceDTO testDto;
    static Id testUpdateId;

    static void BuildObjects() {
        testAccount = new Account(
            Id = fflib_IDGenerator.generate(Account.SObjectType),
            Name = 'Controller Test Account'
        );

        testCase = new Case(
            Id = fflib_IDGenerator.generate(Case.SObjectType),
            Subject = 'Controller Test Case',
            Status = 'New',
            Priority = 'Low',
            AccountId = testAccount.Id
        );

        testUpdateId = fflib_IDGenerator.generate(CaseUpdate__c.SObjectType);

        testDto = new CaseWorkspaceService.WorkspaceDTO();
        testDto.caseInfo = new CaseWorkspaceService.CaseSummary();
        testDto.caseInfo.id = testCase.Id;
        testDto.caseInfo.subject = testCase.Subject;

        testDto.context = null;
        testDto.recentUpdates = new List<CaseWorkspaceService.CaseUpdateSummary>();
    }

    static ICaseWorkspaceService mockService;

    static void SetupMocks() {
        mockService = (ICaseWorkspaceService) mocks.mock(ICaseWorkspaceService.class);

        mocks.startStubbing();
            mocks.when(mockService.getWorkspaceData(testCase.Id))
                .thenReturn(testDto);

            mocks.when(mockService.createCaseUpdate(
                    testCase.Id,
                    'CustomerContacted',
                    'Summary',
                    'Details',
                    true
                ))
            .thenReturn(testUpdateId);
        mocks.stopStubbing();

        SFDC_Application.Service.setMock(
            ICaseWorkspaceService.class,
            mockService
        );
    }

    @IsTest
    static void getWorkspaceData_givenValidCaseId_whenCalled_thenReturnsDto() {
        //given
        BuildObjects();
        SetupMocks();

        //when
        Test.startTest();
        CaseWorkspaceService.WorkspaceDTO dto = CaseWorkspaceController.getWorkspaceData(testCase.Id);
        Test.stopTest();

        //then
        System.assertNotEquals(null, dto);
        System.assertNotEquals(null, dto.caseInfo);
        System.assertEquals(testCase.Id, dto.caseInfo.id);

        ((ICaseWorkspaceService) mocks.verify(
            mockService, mocks.times(1).description('getWorkspaceData should be called once')
        )).getWorkspaceData((Id) fflib_Match.eq(testCase.Id));
    }

    @IsTest
    static void createCaseUpdate_givenValidInput_whenCalled_thenReturnsId() {
        //given
        BuildObjects();
        SetupMocks();

        //when
        Test.startTest();
        Id returnedId = CaseWorkspaceController.createCaseUpdate(
            testCase.Id,
            'CustomerContacted',
            'Summary',
            'Details',
            true
        );
        Test.stopTest();

        //then
        System.assertEquals(testUpdateId, returnedId);

        ((ICaseWorkspaceService) mocks.verify(
            mockService, mocks.times(1).description('createCaseUpdate should be called once')
        )).createCaseUpdate(
            (Id) fflib_Match.eq(testCase.Id),
            (String) fflib_Match.eq('CustomerContacted'),
            (String) fflib_Match.eq('Summary'),
            (String) fflib_Match.eq('Details'),
            (Boolean) fflib_Match.eq(true)
        );
    }

    @IsTest
    static void markReviewed_givenValidCaseId_whenCalled_thenDelegatesToService() {
        //given
        BuildObjects();
        SetupMocks();

        //when
        Test.startTest();
        CaseWorkspaceController.markReviewed(testCase.Id);
        Test.stopTest();

        //then
        ((ICaseWorkspaceService) mocks.verify(
            mockService, mocks.times(1).description('markReviewed should be called once')
        )).markReviewed((Id) fflib_Match.eq(testCase.Id));
    }

    @IsTest
    static void escalateCase_givenValidInput_whenCalled_thenDelegatesToService() {
        //given
        BuildObjects();
        SetupMocks();

        //when
        Test.startTest();
        CaseWorkspaceController.escalateCase(testCase.Id, 'Reason');
        Test.stopTest();

        //then
        ((ICaseWorkspaceService) mocks.verify(
            mockService, mocks.times(1).description('escalateCase should be called once')
        )).escalateCase(
            (Id) fflib_Match.eq(testCase.Id),
            (String) fflib_Match.eq('Reason')
        );
    }
}
