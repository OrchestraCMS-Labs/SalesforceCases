@isTest
private with sharing class CaseService_Test {
    private static CaseService service = new CaseService();

    private static testmethod void testExecuteRequest_getCaseList() {
        Map<String, String> params = new Map<String, String> {
            'action' => 'getCaseList'
        };

        String response = service.executeRequest(params);
        System.debug(response);

        System.assert(response.contains('"success":true'), 'Should return a success response with no cases');
    }

    private static testmethod void testExecuteRequest_getCaseListInvalidPageNumber() {
        Map<String, String> params = new Map<String, String> {
            'action' => 'getCaseList',
            'pageNumber' => 'invalid'
        };

        String response = service.executeRequest(params);
        System.debug(response);

        System.assert(response.contains('"success":false'), 'Should return an unsuccessful response');
    }

    private static testmethod void testExecuteRequest_getCaseListInvalidPageSize() {
        Map<String, String> params = new Map<String, String> {
            'action' => 'getCaseList',
            'pageSize' => 'invalid'
        };

        String response = service.executeRequest(params);
        System.debug(response);

        System.assert(response.contains('"success":false'), 'Should return an unsuccessful response');
    }

    private static testmethod void testExecuteRequest_getCaseDetail() {
        Case testCase = new Case(
            Origin = 'Phone',
            Status = 'New'
        );

        insert testCase;

        String testCommentBody = 'test comment';
        service.putCaseComment(testCase.Id, testCommentBody);

        Attachment caseAttachment = new Attachment(
            ParentId = testCase.Id,
            Name = 'attachment name',
            Body = Blob.valueOf('attachment body')
        );

        insert caseAttachment;

        Map<String, String> params = new Map<String, String> {
            'action' => 'getCaseDetail',
            'caseId' => testCase.Id
        };

        String response = service.executeRequest(params);
        System.debug(response);

        System.assert(response.contains('"success":true'), 'Should return a success response');
    }

    private static testmethod void testExecuteRequest_putCaseComment() {
        Case testCase = new Case(
            Origin = 'Phone',
            Status = 'New'
        );

        insert testCase;

        Map<String, String> params = new Map<String, String> {
            'action' => 'putCaseComment',
            'caseId' => testCase.Id,
            'comment' => 'test comment'
        };

        String response = service.executeRequest(params);
        System.debug(response);

        System.assert(response.contains('"success":true'), 'Should return a success response');
    }

    private static testmethod void testExecuteRequest_getCaseStatuses() {
        Map<String, String> params = new Map<String, String> {
            'action' => 'getCaseStatuses'
        };

        String response = service.executeRequest(params);
        System.debug(response);

        System.assert(response.contains('"success":true'), 'Should return a success response');
    }

    private static testmethod void testExecuteRequest_invalidAction() {
        Map<String, String> params = new Map<String, String> {
            'action' => 'invalid action'
        };

        String response = service.executeRequest(params);
        System.debug(response);

        System.assert(response.contains('"success":false'), 'Should return a failure response');
    }

    private static testmethod void testGetCaseList() {
        List<Case> newCases = new List<Case>();
        List<Case> closedCases = new List<Case>();

        for(Integer i = 0; i < 50; ++i) {
            newCases.add(new Case(
                Origin = 'Phone',
                Status = 'New',
                Subject = 'NewCase' + i
            ));

            closedCases.add(new Case(
                Origin = 'Phone',
                Status = 'Closed',
                Subject = 'ClosedCase' + i
            ));
        }

        insert newCases;
        insert closedCases;

        CaseService.CaseListResult result;
        CaseService.CaseListParameters params = new CaseService.CaseListParameters();

        params.status = 'New';
        params.pageSize = 10;
        params.pageNumber = 2;

        Test.startTest();

        result = service.getCaseList(params);

        Test.stopTest();

        System.assertEquals(params.pageSize, result.cases.size(), 'Should return 1 page of cases');
        System.assert(result.hasMore, 'Should indicate there are more cases to retrieve');
    }

    private static testmethod void testCaseListParameters() {
        CaseService.CaseListParameters params = new CaseService.CaseListParameters();

        try {
            params.pageSize = 0;
            System.assert(false, 'Should not allow a pageSize <= 0');
        } catch(CaseService.CaseServiceException e) {
            // Expected
        }

        try {
            params.pageNumber = 0;
            System.assert(false, 'Should not allow a pageNumber <= 0');
        } catch(CaseService.CaseServiceException e) {
            // Expected
        }
    }

    private static testmethod void testGetCaseDetail() {
        Case newCase = new Case(
            Origin = 'Phone',
            Status = 'New',
            Subject = 'New Case'
        );

        insert newCase;

        String testCommentBody = 'test comment';
        service.putCaseComment(newCase.Id, testCommentBody);

        Attachment caseAttachment = new Attachment(
            ParentId = newCase.Id,
            Name = 'attachment name',
            Body = Blob.valueOf('attachment body')
        );

        insert caseAttachment;

        CaseService.CaseDetail detail = service.getCaseDetail(newCase.Id);

        System.assertEquals(newCase.Subject, detail.Subject, 'Subject should match');
        System.assertEquals(1, detail.comments.size(), 'Should have one comment');
        System.assertEquals(testCommentBody, detail.comments[0].body, 'Comment body should match');
        System.assertEquals(1, detail.attachments.size(), 'Should have one attachment');
    }

    private static testmethod void testPutCaseComment() {
        Boolean putCaseCommentSuccess;

        Case newCase = new Case(
            Origin = 'Phone',
            Status = 'New',
            Subject = 'New Case'
        );

        insert newCase;

        putCaseCommentSuccess = service.putCaseComment(newCase.Id, 'test comment');

        System.assertEquals(true, putCaseCommentSuccess, 'putCaseComment should succeed with a valid case');

        putCaseCommentSuccess = service.putCaseComment('invalid id', 'test comment');

        System.assertEquals(false, putCaseCommentSuccess, 'putCaseComment should fail with an invalid case');
    }

    private static testmethod void testGetCaseStatuses() {
        List<Schema.PicklistEntry> statuses = service.getCaseStatuses();

        System.assertNotEquals(null, statuses, 'Should always return statuses');
        System.assert(statuses.size() > 1, 'Should return multiple statuses');
    }

    private static testmethod void testGetType() {
        System.assertEquals(CaseService.class, CaseService.getType());
    }
}
