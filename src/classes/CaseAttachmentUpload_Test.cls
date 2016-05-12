@isTest
private with sharing class CaseAttachmentUpload_Test {
    private static testmethod void testAttachmentUpload() {
        CaseAttachmentUpload controller = new CaseAttachmentUpload();

        System.assertNotEquals(null, controller.fileUpload, 'Should never have a null attachment');
        System.assertEquals(false, controller.success, 'Should default to success=false');

        Case testCase = new Case(
            Origin = 'Phone',
            Status = 'New'
        );

        insert testCase;

        ApexPages.currentPage().getParameters().put('caseId', testCase.Id);

        controller.saveAttachment();

        System.assertEquals(false, controller.success, 'Should fail when no attachment is specified');

        controller.fileUpload.Name = 'attachment test';
        controller.fileUpload.Body = Blob.valueOf('attachment body');

        controller.saveAttachment();

        System.assertEquals(true, controller.success, 'Should succeed');
    }
}
