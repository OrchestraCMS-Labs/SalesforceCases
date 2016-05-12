@isTest
private with sharing class CaseLayout_Test {
    private static testmethod void testGetPropertyWithDefault() {
        CaseLayout controller = new CaseLayout();

        String property = 'propertyName';
        String propertyValue = 'propertyValue';
        String defaultValue = 'default';

        System.assertEquals(defaultValue, controller.getPropertyWithDefault(property, defaultValue),
            'Should return the default value with not attribute value provided');

        controller.testAttributes = new Map<String, String> {
            property => propertyValue
        };

        System.assertEquals(propertyValue, controller.getPropertyWithdefault(property, defaultValue),
            'Should return the stored attribute value when it exists');
    }

    private static testmethod void testGetCaseListHtml() {
        CaseLayout baseController = new CaseLayout();
        CaseList listController = new CaseList();

        // Default values are fine
        System.assertEquals(baseController.getCaseListHtml(), listController.getHtml());
    }

    private static testmethod void testGetCaseDetailHtml() {
        CaseLayout baseController = new CaseLayout();
        CaseDetail detailController = new CaseDetail();

        // Default values are fine
        System.assertEquals(baseController.getCaseDetailHtml(), detailController.getHtml());
    }

    private static testmethod void testGetHtml() {
        CaseLayout baseController = new CaseLayout();

        System.assertEquals('', baseController.getHtml(), 'Default getHtml should return nothing');
    }
}
