global with sharing class CaseService implements cms.ServiceInterface {
    /**
     * Core handler method for retrieving Case information from Salesforce, and for adding comments to existing cases.
     *
     * @param params a map of parameters including at minimum a value for 'action'
     * @return a JSON-serialized response string
     */
    public String executeRequest(Map<String, String> params) {
        String action = params.get('action');

        try {
            if(action == 'getCaseList') {
                return getCaseListJSON(params);
            } else if(action == 'getCaseDetail') {
                return getCaseDetailJSON(params);
            } else if(action == 'putCaseComment') {
                return putCaseCommentJSON(params);
            } else if(action == 'getCaseStatuses') {
                return getCaseStatusesJSON(params);
            }
        } catch(Exception e) {
            // Unexpected error
            System.debug(e.getStackTraceString());
            String message = e.getMessage();

            return '{"success":false,"message":' + JSON.serialize(message) + '}';
        }

        // No actions matched and no error occurred
        return '{"success":false,"message":"Invalid Action"}';
    }

    public class CaseServiceException extends Exception {}

    /** Provides common fields for {@link #CaseSummary} and {@link #CaseDetail} instances */
    public abstract class CaseBase {
        public String id;
        public String caseNumber;
        public String subject;
        public DateTime createdDate;
        public String status;
        public DateTime lastActivity;

        /** Provides the Case {@link #createdDate} formatted based on the current user's setting */
        public String createdDateFormatted {
            get {
                return createdDate.format();
            }
        }

        /** Provides the {@link #lastActivity} formatted based on the current user's setting */
        public String lastActivityFormatted {
            get {
                return lastActivity.format();
            }
        }

        /**
         * Initializes common fields for {@link #CaseSummary} and {@link #CaseDetail} instances.
         *
         * <p>Requires the following fields to be defined on the passed Case object at minimum:
         * <ul>
         * <li>CaseNumber</li>
         * <li>Subject</li>
         * <li>CreatedDate</li>
         * <li>Status</li>
         * <li>LastModifiedDate</li>
         * </ul>
         * </p>
         *
         * <p>If the CaseComments relation is also passed then CaseComment#CreatedDate will be accessed as well.</p>
         *
         * @param baseObject a Case instance to derive field values from
         */
        protected CaseBase(Case baseObject) {
            this.id = baseObject.Id;
            this.caseNumber = baseObject.CaseNumber;
            this.subject = baseObject.Subject;
            this.createdDate = baseObject.CreatedDate;
            this.status = baseObject.Status;

            // Use the ClosedDate if it exists - any modifications after the closed date
            if(baseObject.ClosedDate != null) {
                this.lastActivity = baseObject.ClosedDate;
            } else {
                this.lastActivity = baseObject.LastModifiedDate;

                // If comments have been added after
                if(baseObject.CaseComments != null) {
                    for(CaseComment comment : baseObject.CaseComments) {
                        if(comment.CreatedDate > this.lastActivity) {
                            this.lastActivity = comment.CreatedDate;
                        }
                    }
                }
            }
        }
    }

    /** Adds summary-specific fields to the {@link #CaseBase} abstract class */
    public class CaseSummary extends CaseBase {
        /** Holds an opening &lt;a&gt; tag pointing to the author-defined detail page */
        public String detailTag;

        public CaseSummary(Case baseObject) {
            super(baseObject);
        }
    }

    /** Adds detail-specific fields to the {@link #CaseBase} abstract class */
    public class CaseDetail extends CaseBase {
        public DateTime lastModifiedDate;
        public String description;
        public DateTime closedDate;
        public String origin;
        public String type;
        public List<CaseCommentItem> comments = new List<CaseCommentItem>();
        public List<CaseAttachment> attachments = new List<CaseAttachment>();

        /** Provides the Case {@link #lastModifiedDate} formatted based on the current user's setting */
        public String lastModifiedDateFormatted {
            get {
                return lastModifiedDate.format();
            }
        }

        /** Provides the Case {@link #closedDate} formatted based on the current user's setting */
        public String closedDateFormatted {
            get {
                if(closedDate == null) {
                    return null;
                }

                return closedDate.format();
            }
        }

        /**
         * Initializes the fields for a Case detail.
         *
         * <p>In addition to the required fields for {@link #CaseBase}, requires the following fields to be defined
         * on the passed Case object at minimum:
         * <ul>
         * <li>LastModifiedDate</li>
         * <li>Description</li>
         * <li>ClosedDate</li>
         * <li>Origin</li>
         * <li>Type</li>
         * </ul>
         * </p>
         *
         * <p>The relations CaseComments and Attachments also may be included and will be processed by
         * {@link #CaseCommentItem} and {@link #CaseAttachment} respectively.</p>
         *
         * @param baseObject a Case instance to derive field values from
         */
        public CaseDetail(Case baseObject) {
            super(baseObject);

            this.lastModifiedDate = baseObject.LastModifiedDate;
            this.description = baseObject.Description;
            this.closedDate = baseObject.ClosedDate;
            this.origin = baseObject.Origin;
            this.type = baseObject.Type;

            this.comments = new List<CaseCommentItem>();
            if(baseObject.CaseComments != null) {
                for(CaseComment c : baseObject.CaseComments) {
                    this.comments.add(new CaseCommentItem(c));
                }
            }

            if(baseObject.Attachments != null) {
                for(Attachment a : baseObject.Attachments) {
                    this.attachments.add(new CaseAttachment(a));
                }
            }
        }
    }

    /** Provides fields for a Case Comment attached to a CaseDetail */
    public class CaseCommentItem {
        public String createdById;
        public String createdByName;
        public DateTime createdDate;
        public String body;

        /** Provides the CaseComment {@link #createdDate} formatted based on the current user's setting */
        public String createdDateFormatted {
            get {
                return createdDate.format();
            }
        }

        /**
         * Initializes the fields for a CaseCommentItem.
         *
         * <p>Requires the following fields to be defined on the passed CaseComment object at minimum:
         * <ul>
         * <li>CreatedDate</li>
         * <li>CommentBody</li>
         * <li>CreatedBy.Id</li>
         * <li>CreatedBy.Name</li>
         * </ul>
         *
         * @param comment a CaseComment object to derive field values from
         */
        public CaseCommentItem(CaseComment comment) {
            this.createdById = comment.CreatedBy.Id;
            this.createdByName = comment.CreatedBy.Name;
            createdDate = comment.CreatedDate;
            body = comment.CommentBody;
        }
    }

    /** Provides fields for an Attachment on a Case */
    public class CaseAttachment {
        public String id;
        public String name;
        public String createdById;
        public String createdByName;
        public DateTime createdDate;

        /** Provides the Attachment {@link #createdDate} formatted based on the current user's setting */
        public String createdDateFormatted {
            get {
                return createdDate.format();
            }
        }

        /**
         * Initializes the fields for a CaseAttachment.
         *
         * <p>Requires the following fields to be defined on the passed Attachment object at minimum:
         * <ul>
         * <li>Name</li>
         * <li>CreatedDate</li>
         * <li>CreatedBy.Id</li>
         * <li>CreatedBy.Name</li>
         * </ul>
         *
         * @param caseAttachment an Attachment object to derive field values from
         */
        public CaseAttachment(Attachment caseAttachment){
            this.id = caseAttachment.Id;
            this.name = caseAttachment.Name;
            this.createdById = caseAttachment.CreatedBy.Id;
            this.createdByName = caseAttachment.CreatedBy.Name;
            this.createdDate = caseAttachment.CreatedDate;
        }
    }

    /** A parameters object used when fetching a list of cases. */
    public class CaseListParameters {
        /** The OrchestraCMS page selector CSV value to use when constructing detail links */
        public String detailUrlCsv;

        /** The status to filter cases by. Corresponds to Case#Status */
        public String status;

        /** The requested page of cases, with 1 as the first page */
        public Integer pageNumber {
            get; set {
                if(value < 1) {
                    throw new CaseServiceException('Invalid value for pageNumber');
                }

                pageNumber = value;
            }
        }

        /** The number of cases to retrieve for each page */
        public Integer pageSize {
            get; set {
                if(value < 1 || value > 50) {
                    throw new CaseServiceException('Invalid value for pageSize');
                }

                pageSize = value;
            }
        }

        /** Default constructer */
        public CaseListParameters() {
            this.pageNumber = 1;
            this.pageSize = 20;
        }
    }

    /** A Case list result set */
    public class CaseListResult {
        /** Denotes whether there are more results after the requested page */
        public Boolean hasMore;

        /** The result set of {@link #CaseSummary} instances */
        public List<CaseSummary> cases = new List<CaseSummary>();
    }

    private String getCaseListJSON(Map<String, String> params) {
        CaseListParameters caseListParams = new CaseListParameters();

        caseListParams.detailUrlCsv = params.get('detailUrlCsv');
        caseListParams.status = params.get('status');

        if(String.isNotBlank(params.get('pageNumber'))) {
            try {
                caseListParams.pageNumber = Integer.valueOf(params.get('pageNumber'));
            } catch(TypeException e) {
                throw new CaseServiceException('Invalid value for pageNumber');
            }
        }

        if(String.isNotBlank(params.get('pageSize'))) {
            try {
                caseListParams.pageSize = Integer.valueOf(params.get('pageSize'));
            } catch(TypeException e) {
                throw new CaseServiceException('Invalid value for pageSize');
            }
        }

        CaseListResult result = getCaseList(caseListParams);
        return '{"success":true,"cases":' + JSON.serialize(result.cases) + ',"hasMore":' + result.hasMore + '}';
    }

    /**
     * Fetches a list of cases.
     *
     * @param params a {@link #CaseListParameters} instance used to control the result set
     * @return a {@link #CaseListResult} instance
     */
    public CaseListResult getCaseList(CaseListParameters params) {
        CaseListResult result = new CaseListResult();

        // Calculate LIMIT/OFFSET values
        Integer queryLimit = params.pageSize;
        Integer queryOffset = (params.pageNumber - 1) * queryLimit;

        String caseQuerySelect = '';
        String caseQueryConditions = '';
        String caseQueryOrderLimits = '';

        // Select
        caseQuerySelect = 'SELECT CaseNumber, Subject, CreatedDate, toLabel(Status), ClosedDate, LastModifiedDate,'
            + ' (SELECT CreatedDate FROM CaseComments WHERE IsPublished = true)';

        // From
        caseQuerySelect += ' FROM Case';

        // Where
        String status = params.status;
        if(String.isNotBlank(params.status)) {
            caseQueryConditions = ' WHERE Status = :status';
        }

        // Order By
        caseQueryOrderLimits = ' ORDER BY CreatedDate DESC';

        // Limit/Offset
        caseQueryOrderLimits += ' LIMIT :queryLimit OFFSET :queryOffset';

        for(Case caseRecord : Database.query(caseQuerySelect + caseQueryConditions + caseQueryOrderLimits)) {
            CaseSummary summary = new CaseSummary(caseRecord);
            summary.detailTag = (new cms.Link(params.detailUrlCsv, null, null, 'caseId=' + summary.id)).render();

            result.cases.add(summary);
        }

        // Determine if there are additional pages
        Integer totalCases = Database.countQuery('SELECT COUNT() FROM Case' + caseQueryConditions);
        Integer casesUntilEndOfPage = queryOffset + queryLimit;
        result.hasMore = casesUntilEndOfPage < totalCases;

        return result;
    }

    private String getCaseDetailJSON(Map<String, String> params) {
        String caseId = params.get('caseId');

        CaseDetail detail = getCaseDetail(caseId);

        return '{"success":true,"case":' + JSON.serialize(detail) + '}';
    }

    /**
     * Fetches the details of a single case.
     *
     * @param caseId the id of the Case to fetch details for
     * @return a {@link #CaseDetail} instance, or null if no case was found for the requested id
     */
    public CaseDetail getCaseDetail(String caseId) {
        Case caseRecord = null;
        CaseDetail result = null;

        try {
            caseRecord = [SELECT CaseNumber, Subject, Description, toLabel(Origin), toLabel(Type), CreatedDate
                    , toLabel(Status), ClosedDate, LastModifiedDate
                    , (SELECT CreatedBy.Name, CreatedDate, CommentBody
                        FROM CaseComments WHERE IsPublished = true ORDER BY CreatedDate DESC)
                    , (SELECT Name, CreatedBy.Name, CreatedDate FROM Attachments ORDER BY CreatedDate DESC)
                FROM Case
                WHERE Id = :caseId];
        } catch(QueryException e) {
            System.debug('Failed to fetch case ID ' + caseId);
            System.debug(e);
        }

        if(caseRecord != null) {
            result = new CaseDetail(caseRecord);
        }

        return result;
    }

    private String putCaseCommentJSON(Map<String, String> params) {
        String caseId = params.get('caseId');
        String comment = params.get('comment');

        return '{"success":' + putCaseComment(caseId, comment) + '}';
    }

    /**
     * Adds a comment to an existing case.
     *
     * @param caseId the id of the case to add the comment to
     * @param comment the body of the new comment
     * @return true on success, false on failure
     */
    public Boolean putCaseComment(String caseId, String comment) {
        try {
            CaseComment newComment = new CaseComment(
                ParentId = caseId,
                CommentBody = comment,
                IsPublished = true
            );

            insert newComment;
        } catch(Exception e) {
            System.debug('Failed to insert case comment on case ID ' + caseId);
            System.debug('Comment: ' + comment);
            System.debug('Exception message: ' + e.getMessage());
            return false;
        }

        return true;
    }

    public String getCaseStatusesJSON(Map<String, String> params) {
        return '{"success":true,"statuses":' + JSON.serialize(getCaseStatuses()) + '}';
    }

    /**
     * Returns the list of picklist values for the Case#Status field.
     *
     * @return a list of picklist values
     */
    public List<Schema.PicklistEntry> getCaseStatuses() {
        List<Schema.PicklistEntry> caseStatuses = new List<Schema.PicklistEntry>();

        for(Schema.PicklistEntry entry : Case.Status.getDescribe().getPicklistValues()) {
            if(entry.isActive()) {
                caseStatuses.add(entry);
            }
        }

        return caseStatuses;
    }

    public static Type getType() {
        return CaseService.class;
    }
}
