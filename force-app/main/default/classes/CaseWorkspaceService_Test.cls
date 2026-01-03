@IsTest
public class CaseWorkspaceService_Test {
    static fflib_ApexMocks mocks = new fflib_ApexMocks();

    static Case testCase;
    static Account testAccount;
    static CustomerContext__c testCustomerContext;
    static CaseUpdate__c testCaseUpdate, testCaseUpdateTwo;

    static void BuildObjects() {
        testAccount = new Account(
            Id = fflib_IdGenerator.generate(Account.SObjectType),
            Name = 'Test Account'
        );

        testCase = new Case(
            Id = fflib_IdGenerator.generate(Case.SObjectType),
            Subject = 'Test Case Subject',
            Status = 'New',
            Priority = 'Medium',
            Account = testAccount
        );

        testCustomerContext = new CustomerContext__c(
            Id = fflib_IdGenerator.generate(CustomerContext__c.SObjectType),
            Case__c = testCase.Id,
            CustomerTier__c = 'Gold',
            SupportSLA__c = 'Standard',
            RiskFlag__c = true,
            RiskNotes__c = 'High risk customer',
            LastReviewed__c = Date.today().addDays(-7),
            ReviewedBy__c = UserInfo.getUserId()
        );

        testCaseUpdate = new CaseUpdate__c(
            Id = fflib_IdGenerator.generate(CaseUpdate__c.SObjectType),
            Case__c = testCase.Id,
            UpdateType__c = 'CustomerContacted',
            Summary__c = 'Contacted customer regarding issue',
            Details__c = 'Left voicemail',
            VisibleToCustomer__c = true
        );

        testCaseUpdateTwo = new CaseUpdate__c(
            Id = fflib_IdGenerator.generate(CaseUpdate__c.SObjectType),
            Case__c = testCase.Id,
            UpdateType__c = 'InternalInvestigation',
            Summary__c = 'Investigated issue',
            Details__c = 'Reviewed integration errors',
            VisibleToCustomer__c = false
        );
    }

    static fflib_ISObjectUnitOfWork mockUnitOfWork;
    static CustomerContextsSelector mockCustomerContextSelector;
    static CasesUpdatesSelector mockCaseUpdateSelector;
    static CasesSelector mockCasesSelector;

    static void SetupMocks() {
        mockUnitOfWork = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        mockCustomerContextSelector = (CustomerContextsSelector) mocks.mock(CustomerContextsSelector.class);
        mockCaseUpdateSelector = (CasesUpdatesSelector) mocks.mock(CasesUpdatesSelector.class);
        mockCasesSelector = (CasesSelector) mocks.mock(CasesSelector.class);

        mocks.startStubbing();
        mocks.when(mockCustomerContextSelector.sObjectType()).thenReturn(CustomerContext__c.SObjectType);
        mocks.when(mockCaseUpdateSelector.sObjectType()).thenReturn(CaseUpdate__c.SObjectType);
        mocks.when(mockCasesSelector.sObjectType()).thenReturn(Case.SObjectType);

        mocks.when(mockCasesSelector.selectByIdsWithNames(new Set<Id>{ testCase.Id }))
            .thenReturn(new List<Case>{ testCase });

        mocks.when(mockCasesSelector.selectById(new Set<Id>{ testCase.Id }))
            .thenReturn(new List<Case>{ testCase });
        
        mocks.when(mockCustomerContextSelector.selectLatestByCaseIds(new Set<Id>{ testCase.Id }))
            .thenReturn(new List<CustomerContext__c> { testCustomerContext });

        mocks.when(mockCaseUpdateSelector.selectRecentByCaseIds(new Set<Id>{ testCase.Id }, 5))
            .thenReturn(new List<CaseUpdate__c>{ testCaseUpdate });
        mocks.stopStubbing();

        SFDC_Application.Selector.setMock(mockCasesSelector);
        SFDC_Application.Selector.setMock(mockCustomerContextSelector);
        SFDC_Application.Selector.setMock(mockCaseUpdateSelector);
        SFDC_Application.UnitOfWork.setMock(mockUnitOfWork);
    }

    @IsTest
    static void getWorkspaceData_givenValidCase_whenCalled_thenReturnsDto() {
        //given
        BuildObjects();
        SetupMocks();

        //when
        Test.startTest();
        CaseWorkspaceService.WorkspaceDTO dto = CaseWorkspaceService.getWorkspaceData(testCase.Id);
        Test.stopTest();

        //then
        System.assertNotEquals(null, dto, 'DTO should not be null');
        System.assertNotEquals(null, dto.caseInfo, 'caseInfo should not be null');
        System.assertEquals(testCase.Id, dto.caseInfo.id, 'case id should map');

        System.assertNotEquals(null, dto.context, 'context should not be null');
        System.assertEquals(testCustomerContext.CustomerTier__c, dto.context.customerTier);

        System.assertNotEquals(null, dto.recentUpdates, 'recentUpdates should not be null');
        System.assertEquals(1, dto.recentUpdates.size(), 'should return 1 update');
        System.assertEquals(testCaseUpdate.Id, dto.recentUpdates[0].id, 'update id should map');

        ((CasesSelector) mocks.verify(
            mockCasesSelector, mocks.times(1).description('selectByIdsWithNames should be called once')
        )).selectByIdsWithNames((Set<Id>) fflib_Match.eq(new Set<Id>{ testCase.Id }));

        ((CustomerContextsSelector) mocks.verify(
            mockCustomerContextSelector, mocks.times(1).description('selectLatestByCaseIds should be called once')
        )).selectLatestByCaseIds((Set<Id>) fflib_Match.eq(new Set<Id>{ testCase.Id }));

        ((CasesUpdatesSelector) mocks.verify(
            mockCaseUpdateSelector, mocks.times(1).description('selectRecentByCaseIds should be called once')
        )).selectRecentByCaseIds(
            (Set<Id>) fflib_Match.eq(new Set<Id>{ testCase.Id }),
            (Integer) fflib_Match.eq(5)
        );
    }

    @IsTest
    static void getWorkspaceData_givenMissingCase_whenCalled_thenThrowsException() {
        //given
        BuildObjects();
        SetupMocks();

        mocks.startStubbing();
        mocks.when(
            mockCasesSelector.selectByIdsWithNames(new Set<Id>{ testCase.Id })
        ).thenReturn(new List<Case>());
        mocks.stopStubbing();

        //when
        String errorMsg;
        Test.startTest();
        try {
            CaseWorkspaceService.getWorkspaceData(testCase.Id);
            System.assert(false, 'Expected CaseWorkspaceException');
        } catch (CaseWorkspaceException e) {
            errorMsg = e.getMessage();
        }
        Test.stopTest();

        //then
        System.assertEquals(errorMsg.contains('not found'), true, 'Exception message should indicate case not found');
    }

    @IsTest
    static void createCaseUpdate_givenValidInput_whenCalled_thenRegistersNewAndCommits() {
        //given
        BuildObjects();
        SetupMocks();

        //when
        Test.startTest();
        Id newUpdateId = CaseWorkspaceService.createCaseUpdate(
            testCase.Id,
            'CustomerContacted',
            'Followed up with customer',
            'Left voicemail and sent email',
            true
        );
        Test.stopTest();

        //then
        ((fflib_ISObjectUnitOfWork) mocks.verify(
            mockUnitOfWork, mocks.times(1).description('registerNew should be called once')
        )).registerNew((SObject) fflib_Match.anyObject());

        ((fflib_ISObjectUnitOfWork) mocks.verify(
            mockUnitOfWork, mocks.times(1).description('commitWork should be called once')
        )).commitWork();
    }

    @IsTest
    static void escalateCase_givenValidCase_whenCalled_thenRegistersDirtyNewAndCommits() {
        //given
        BuildObjects();
        SetupMocks();

        //when
        Test.startTest();
        CaseWorkspaceService.escalateCase(testCase.Id, 'Customer is blocked');
        Test.stopTest();

        //then
        ((CasesSelector) mocks.verify(
            mockCasesSelector, mocks.times(1).description('selectById should be called once')
        )).selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ testCase.Id }));

        ((fflib_ISObjectUnitOfWork) mocks.verify(
            mockUnitOfWork, mocks.times(1).description('registerDirty should be called once (case)')
        )).registerDirty((SObject) fflib_Match.anyObject());

        ((fflib_ISObjectUnitOfWork) mocks.verify(
            mockUnitOfWork, mocks.times(1).description('registerNew should be called once (escalation update)')
        )).registerNew((SObject) fflib_Match.anyObject());

        ((fflib_ISObjectUnitOfWork) mocks.verify(
            mockUnitOfWork, mocks.times(1).description('commitWork should be called once')
        )).commitWork();
    }
}