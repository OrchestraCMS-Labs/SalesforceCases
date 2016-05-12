/**
 * Provides getHTML implementations for the content templates "CaseList" and
 * "CaseDetail" as well as attribute accessors for the Case content editor.
 */
global virtual with sharing class CaseLayout extends cms.ContentTemplateController {
    private final static String ATTACHMENT_UPLOAD_PAGE = Site.getPathPrefix() + '/apex/c__CaseAttachmentUpload';

    public String getCaseListHtml() {
        String html = '';

        String detailUrlCsv = '';
        if(detailUrl != null) {
            detailUrlCsv = detailUrl.csv;
        }

        html += '<section id="' + this.getContentLayoutInstanceId() + '"'
            + ' data-caseList data-pagesize="' + pageSize + '" data-detailurlcsv="' + detailUrlCsv + '">';

        if(String.isNotBlank(listTitle)) {
            html += '<h2>' + listTitle.escapeHtml4() + '</h2>';
        }

        if(String.isNotBlank(listDescription)) {
            html += '<p>' + listDescription.escapeHtml4() + '</p>';
        }

        if(hasStatusSelector) {
            html += '<select class="caseListStatus form-control" disabled>'
                    + '<option value="All">--------</option>'
                + '</select>';
        }

        html += '<table class="table table-striped">'
                + '<thead>'
                    + '<tr>'
                        + '<th>' + statusLabel.escapeHtml4() + '</th>'
                        + '<th>' + caseNumberLabel.escapeHtml4() + '</th>'
                        + '<th>' + subjectLabel.escapeHtml4() + '</th>'
                        + '<th>' + lastActivityLabel.escapeHtml4() + '</th>'
                    + '</tr>'
                + '</thead>'
                + '<tbody class="caseList"></tbody>'
            + '</table>';
        html += '<button class="showMore btn btn-default">' + showMoreLabel.escapeHtml4() + '</button>';
        html += '</section>';

        return html;
    }

    public String getCaseDetailHtml() {
        String idPrefix = this.getContentLayoutInstanceId();

        String html = '';

        html += '<article id="' + idPrefix + '" data-casedetail data-idprefix="' + idPrefix.escapeHtml4() + '">';

        if(String.isNotBlank(detailTitle)) {
            html += '<h1>' + detailTitle.escapeHtml4() + '</h1>';
        }

        html += '<div class="panel panel-default">'
                + '<div class="panel-body">'
                    + '<table>'
                        + '<tr>'
                            + '<td>' + caseNumberLabel.escapeHtml4() + '</td>'
                            + '<td class="caseNumber"></td>'
                        + '</tr><tr>'
                            + '<td>' + statusLabel.escapeHtml4() + '</td>'
                            + '<td class="status"></td>'
                        + '</tr><tr>'
                            + '<td>' + caseTypeLabel.escapeHtml4() + '</td>'
                            + '<td class="type"></td>'
                        + '</tr><tr>'
                            + '<td>' + originLabel.escapeHtml4() + '</td>'
                            + '<td class="origin"></td>'
                        + '</tr><tr>'
                            + '<td>' + createdDateLabel.escapeHtml4() + '</td>'
                            + '<td class="createdDate"></td>'
                        + '</tr><tr>'
                            + '<td>' + lastModifiedDateLabel.escapeHtml4() + '</td>'
                            + '<td class="lastModifiedDate"></td>'
                        + '</tr><tr>'
                            + '<td>' + subjectLabel.escapeHtml4() + '</td>'
                            + '<td class="subject"></td>'
                        + '</tr><tr>'
                            + '<td>' + descriptionLabel.escapeHtml4() + '</td>'
                            + '<td class="description"></td>'
                        + '</tr>'
                    + '</table>'
                + '</div>'
            + '</div>';

        html += '<div class="panel-group">'
                // Attachments Section
                + '<div class="panel panel-default">'
                    + '<div class="panel-heading">'
                        + '<h3 class="panel-title">'
                            + attachmentTitle.escapeHtml4()
                        + '</h3>'
                    + '</div>'
                    + '<div class="panel-body">'
                        + '<iframe class="addAttachmentFrame" frameborder="0" style="width:100%;height:0;"'
                            + ' data-buttontext="' + addAttachmentLabel.escapeHtml4() + '"'
                            + ' data-src="' + ATTACHMENT_UPLOAD_PAGE.escapeHtml4() + '">'
                        + '</iframe>'
                        + '<table class="table">'
                            + '<thead>'
                                + '<tr>'
                                    + '<th>' + attachmentFileNameLabel.escapeHtml4() + '</th>'
                                    + '<th>' + attachedByLabel.escapeHtml4() + '</th>'
                                    + '<th>' + attachmentCreatedDateLabel.escapeHtml4() + '</th>'
                                + '</tr>'
                            + '</thead>'
                            + '<tbody class="attachments"></tbody>'
                        + '</table>'
                    + '</div>'
                + '</div>'

                // Comments Section
                + '<div class="panel panel-default">'
                    + '<div class="panel-heading">'
                        + '<h3 class="panel-title">'
                            + commentTitle.escapeHtml4()
                        + '</h3>'
                    + '</div>'
                    + '<div class="panel-body">'
                        + '<button class="addComment btn btn-default">'
                            + addCommentLabel.escapeHtml4()
                        + '</button>'
                        + '<form class="addCommentForm hidden">'
                            + '<textarea class="commentBody form-control" rows="5"></textarea>'
                            + '<button type="submit" class="putComment btn btn-default">' +
                                + addCommentLabel.escapeHtml4()
                            + '</button>'
                            + '<button type="reset" class="resetComment btn btn-default">'
                                + resetCommentLabel.escapeHtml4()
                            + '</button>'
                        + '</form>'
                        + '<div class="comments panel-body">'
                        + '</div>'
                    + '</div>'
                + '</div>'
            + '</div>';

        html += '</article>';

        return html;
    }

    /**
     * A shorthand to retrieve a default value for a property if it hasn't been saved.
     *
     * @param propertyName the property name, passed directly to getProperty
     * @param defaultValue the default value to use if the retrieved property is null
     */
    @TestVisible
    private String getPropertyWithDefault(String propertyName, String defaultValue) {
        String property = getAttribute(propertyName);

        if(property == null) {
            return defaultValue;
        } else {
            return property;
        }
    }

    /** The URL to use when constructing links to a Case detail page. Used by CaseList. */
    public cms.Link detailUrl {
        get {
            return getPropertyLink('detailUrl');
        }
    }

    /** Title appearing at the top of a Case list. Used by CaseList. */
    public String listTitle {
        get {
            return getPropertyWithDefault('listTitle', 'My Cases');
        } set;
    }

    /** Title appearing at the top of a Case detail. Used by CaseDetail. */
    public String detailTitle {
        get {
            return getPropertyWithDefault('detailTitle', 'Case Detail');
        } set;
    }

    /** Title appearing at the top of the Attachments related list. Used by CaseDetail. */
    public String attachmentTitle {
        get {
            return getPropertyWithDefault('attachmentTitle', 'Attachments');
        }
    }

    /** Title appearing at the top of the Comments related list. Used by CaseDetail. */
    public String commentTitle {
        get {
            return getPropertyWithDefault('commentTitle', 'Comments');
        }
    }

    /** Plain text appearing directly below the list title. Used by CaseList. */
    public String listDescription {
        get {
            return getAttribute('listDescription');
        } set;
    }

    /** Controls whether the status filter appears to end users. Used by CaseList. */
    public Boolean hasStatusSelector {
        get {
            return getAttribute('hasStatusSelector') != 'false';
        }
    }

    /** Label for the Status field. Used by CaseList and CaseDetail. */
    public String statusLabel {
        get {
            return getPropertyWithDefault('statusLabel', 'Status');
        } set;
    }

    /** Label for the CaseNumber field. Used by CaseList and CaseDetail. */
    public String caseNumberLabel {
        get {
            return getPropertyWithDefault('caseNumberLabel', 'Case Number');
        } set;
    }

    /** Label for the Subject field. Used by CaseList and CaseDetail. */
    public String subjectLabel {
        get {
            return getPropertyWithDefault('subjectLabel', 'Subject');
        } set;
    }

    /** Label for the Last Activity field. Used by CaseList. */
    public String lastActivityLabel {
        get {
            return getPropertyWithDefault('lastActivityLabel', 'Last Activity');
        } set;
    }

    /** Label for the Type field. Used by CaseDetail. */
    public String caseTypeLabel {
        get {
            return getPropertyWithDefault('caseTypeLabel', 'Case Type');
        } set;
    }

    /** Label for the Origin field. Used by CaseDetail. */
    public String originLabel {
        get {
            return getPropertyWithDefault('originLabel', 'Origin');
        } set;
    }

    /** Label for the Created Date field. Used by CaseDetail. */
    public String createdDateLabel {
        get {
            return getPropertyWithDefault('createdDateLabel', 'Opened Date');
        } set;
    }

    /** Label for the Last Modified Date field. Used by CaseDetail. */
    public String lastModifiedDateLabel {
        get {
            return getPropertyWithDefault('lastModifiedDateLabel', 'Modified Date');
        } set;
    }

    /** Label for the Description field. Used by CaseDetail. */
    public String descriptionLabel {
        get {
            return getPropertyWithDefault('descriptionLabel', 'Description');
        } set;
    }

    /** Label for the Add Comment button. Used by CaseDetail. */
    public String addCommentLabel {
        get {
            return getPropertyWithDefault('addCommentLabel', 'Add Comment');
        } set;
    }

    /** Label for the Reset Comment button. Used by CaseDetail. */
    public String resetCommentLabel {
        get {
            return getPropertyWithDefault('resetCommentLabel', 'Cancel');
        } set;
    }

    /** Label for the Add Attachment button. Used by CaseDetail. */
    public String addAttachmentLabel {
        get {
            return getPropertyWithDefault('addAttachmentLabel', 'Add Attachment');
        } set;
    }

    /** Label for the Attachment Name field. Used by CaseDetail. */
    public String attachmentFileNameLabel {
        get {
            return getPropertyWithDefault('attachmentFileNameLabel', 'File Name');
        } set;
    }

    /** Label for the Attachment CreatedBy Name field. Used by CaseDetail. */
    public String attachedByLabel {
        get {
            return getPropertyWithDefault('attachedByLabel', 'Attached By');
        } set;
    }

    /** Label for the Attachment Created Date field. Used by CaseDetail. */
    public String attachmentCreatedDateLabel {
        get {
            return getPropertyWithDefault('attachmentCreatedDateLabel', 'Created Date');
        } set;
    }

    /** Label for the Show More button. Used by CaseList. */
    public String showMoreLabel {
        get {
            return getPropertyWithDefault('showMoreLabel', 'Show More');
        } set;
    }

    /** The number of cases to show per page. Must be between 1 and 50. Defaults to 20. */
    public Integer pageSize {
        get {
            if(pageSize == null) {
                pageSize = 20; // Default to 20

                try {
                    pageSize = Integer.valueOf(getAttribute('pageSize'));
                } catch(Exception e) {}

                if(pageSize == null) {
                    pageSize = 20;
                } else if(pageSize < 1) {
                    pageSize = 1;
                } else if(pageSize > 50) {
                    pageSize = 50;
                }
            }

            return pageSize;
        } set;
    }

    /** Provides an easy way to define attributes during testing */
    @TestVisible
    private Map<String, String> testAttributes = new Map<String, String>();

    /** Delegates to ContentTemplateController#getProperty in normal execution. Accesses the {@link #testAttributes}
     * map in a test context.
     */
    private String getAttribute(String attributeName) {
        if(Test.isRunningTest()) {
            return testAttributes.get(attributeName);
        } else {
            return getProperty(attributeName);
        }
    }

    private String getContentLayoutInstanceId() {
        if(Test.isRunningTest()) {
            return 'cli_id';
        } else {
            return this.content_layout_instance.Id;
        }
    }

    /** Extension constructor for the Case edit page */
    global CaseLayout(cms.CreateContentController cc) {
        super(cc);
    }

    /** Extension constructor for Case generate pages (unused) */
    private CaseLayout(cms.GenerateContent gc) {
        super(gc);
    }

    /** Constructor for getHTML rendering */
    global CaseLayout() {
        super();
    }

    /** Blank getHTML - rendering is done by subclasses */
    global virtual override String getHTML() {
        return '';
    }
}
