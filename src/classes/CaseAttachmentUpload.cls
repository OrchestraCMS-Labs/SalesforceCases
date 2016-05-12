/**
 * Visualforce controller to allow attachment uploads to Cases on an OrchestraCMS page.
 *
 * <p>Attachment uploads can only be accomplished using an apex:form on a Visualforce page, which in turn relies on the
 * Salesforce viewstate. OrchestraCMS caching cannot account for this and so the upload will fail if the apex:form is
 * placed on a cacheable OrchestraCMS page template.</p>
 *
 * <p>Instead, we create a small plain Visualforce page with the apex:form component and iframe it into the larger
 * OrchestraCMS-cached page.</p>
 */
public with sharing class CaseAttachmentUpload {
    public Attachment fileUpload {
        get {
            if(fileUpload == null) {
                fileUpload = new Attachment();
            }
            return fileUpload;
        } set;
    }

    public Boolean success {
        get {
            if(this.success == null) {
                return false;
            } else {
                return this.success;
            }
        } set;
    }

    /**
     * Process the attachment upload and attach it to the provided case.
     */
    public PageReference saveAttachment() {
        this.fileUpload.ParentId = System.currentPageReference().getParameters().get('caseId');

        if (this.fileUpload.Name != null) {
            try {
                insert this.fileUpload;
            } catch(Exception e) {
                this.success = false;
            } finally {
                this.fileUpload = null;
                this.success = true;
            }
        }

        return System.currentPageReference();
    }
}
