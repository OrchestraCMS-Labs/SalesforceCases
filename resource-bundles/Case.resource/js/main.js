window.STG = window.STG || {};
window.STG.CTLib = window.STG.CTLib || {};

window.STG.CTLib.Case = (function(global, namespace, undefined) {
    'use strict';

    var serviceName = 'CaseService';

    var caseListContainerSelector = '[data-caselist]';
    var caseDetailContainerSelector = '[data-casedetail]';

    namespace.instances = {};

    /* By default, initialize all case lists and case details on document ready */
    $(function() {
        $(caseListContainerSelector).each(function() {
            namespace.initCaseList($(this));
        });

        $(caseDetailContainerSelector).each(function() {
            namespace.initCaseDetail($(this));
        });
    });

    /** Internal utility factory function to produce callback functions for a specific Case List. */
    function _createGetCaseListCallback($container, caseListId) {
        var instance = namespace.instances[caseListId];

        return function(alwaysTrue, result) {
            // Update instance data
            instance.cases = instance.cases.concat(result.cases);
            instance.hasMore = result.hasMore;

            // Render based on the updated data
            namespace.renderCaseList($container, instance);
        };
    }

    /** Internal utility function that converts null values to empty strings */
    function _nullToBlank(str) {
        return str === null ? '' : str;
    }

    /**
     * Initializes a new Case List for a given container element.
     *
     * <p>Data attributes that should appear on the container element are:
     * <ul>
     *   <li>data-pagesize - an integer between 1 and 50. Is the number of cases per page.</li>
     *   <li>data-detailurlcsv - an OrchestraCMS csv representation of a link to a page with a Case Detail content.</li>
     * </ul>
     *
     * @param $container a jQuery collection containing the parent element
     */
    namespace.initCaseList = function($container) {
        var pageSize = parseInt($container.attr('data-pagesize'));
        var detailUrlCsv = $container.attr('data-detailurlcsv');
        var caseListId = $container.prop('id');
        var $caseListStatusSelect = $('.caseListStatus', $container);
        var instance;
        var getCaseListCallback;

        if(isNaN(pageSize) || pageSize < 1 || pageSize > 50) {
            pageSize = 20;
        }

        // Initialize this list's instance data
        instance = namespace.instances[caseListId] = {
            status: 'All',
            pageSize: pageSize,
            pageNumber: 1,
            cases: [],
            hasMore: undefined,
            detailUrlCsv: detailUrlCsv
        };

        // If the status selector exists, populate it with picklist values
        if($caseListStatusSelect.length > 0) {
            namespace.getCaseStatuses(function(alwaysTrue, result) {
                result.statuses.forEach(function(status) {
                    $('<option />')
                        .prop('value', status.value)
                        .text(status.label)
                        .appendTo($caseListStatusSelect);
                });

                $caseListStatusSelect.prop('disabled', false);
            });
        }

        // Create a callback function for this instance
        getCaseListCallback = _createGetCaseListCallback($container, caseListId);

        // Fetch the first page of cases
        namespace.getCaseList(instance, getCaseListCallback);

        // On-change handler for the status selector
        $('.caseListStatus', $container).change(function() {
            instance.status = $(':selected', this).val();
            instance.pageNumber = 1;
            instance.cases = [];

            namespace.getCaseList(instance, getCaseListCallback);
        });

        // Click handler for the show more button
        $('.showMore', $container).click(function() {
            instance.pageNumber ++;

            namespace.getCaseList(instance, getCaseListCallback);
        });
    };

    /**
     * Initializes a new Case Detail for a given container element.
     *
     * @param $container a jQuery collection containing the parent element
     */
    namespace.initCaseDetail = function($container) {
        var caseId;
        var caseIdMatch = window.location.search.match(/caseId=([^&]+)/);
        var $addAttachmentFrame = $('.addAttachmentFrame', $container);

        // Extract the case ID from the URL
        if(caseIdMatch != null) {
            caseId = caseIdMatch[1];
        }

        if(caseId === undefined) {
            console.error('Case ID not specified');
            return;
        }

        // Fetch the case detail data
        namespace.getCaseDetail(caseId, function(alwaysTrue, result) {
            namespace.renderCaseDetail($container, result.case);
        });

        // Initialize the 'Add Attachment' iframe.
        $addAttachmentFrame
            .prop('src', $addAttachmentFrame.attr('data-src') + '?caseId=' + caseId)
            .load(function() {
                // Get the list of stylesheets in the current document
                var stylesheets = [];
                $('link[rel="stylesheet"]').each(function(stylesheet) {
                    stylesheets.push($(this).prop('href'));
                });

                // Pass initialization data into the iframe using window.postMessage
                // In an internal/preview context the iframe will be served from a different domain:
                // c.* instead of cms.*. In a Sites context we could reach in directly
                $addAttachmentFrame[0].contentWindow.postMessage({
                    type: 'init',
                    buttonText: $addAttachmentFrame.attr('data-buttontext'),
                    stylesheets: stylesheets
                }, '*');
            });

        // Begin listening for messages coming out of the iframe
        global.addEventListener('message', function(event) {
            if(event.data.type == 'setHeight') {
                // setHeight message allows the iframe height to be set explicitly after styles have been applied
                $addAttachmentFrame.css('height', event.data.height + 'px');
            } else if(event.data.type == 'upload') {
                // upload message triggers a re-render of the case detail to include the new attachment
                if(event.data.success) {
                    namespace.getCaseDetail(caseId, function(alwaysTrue, result) {
                        namespace.renderCaseDetail($container, result.case);
                    });
                }
            }
        }, false);

        // Click handler for Add Comment button
        $('.addComment', $container).click(function() {
            $('.addComment', $container).addClass('hidden');
            $('.addCommentForm', $container).removeClass('hidden');
        });

        // Click handler for Reset Comment button
        $('.resetComment', $container).click(function() {
            $('.addComment', $container).removeClass('hidden');
            $('.addCommentForm', $container).addClass('hidden');
        });

        // Submit handler for the Add Comment form
        $('.addCommentForm', $container).submit(function(evt) {
            evt.preventDefault();

            var commentBody = $('.commentBody', this).val();

            namespace.putCaseComment(caseId, commentBody, function() {
                namespace.getCaseDetail(caseId, function(alwaysTrue, result) {
                    namespace.renderCaseDetail($container, result.case);
                });
            });
        });
    };

    /**
     * Renders a case detail.
     *
     * @param $container a jQuery collection containing the parent element
     * @param data a JavaScript object containg the data for a Case
     */
    namespace.renderCaseDetail = function($container, data) {
        var $attachmentsList = $('.attachments', $container).empty();
        var $attachmentsRows = $([]);

        var $commentsList = $('.comments', $container).empty();
        var $commentsItems = $([]);

        // Populate fields
        $('.caseNumber', $container).text(_nullToBlank(data.caseNumber));
        $('.status', $container).text(_nullToBlank(data.status));
        $('.type', $container).text(_nullToBlank(data.type));
        $('.origin', $container).text(_nullToBlank(data.origin));
        $('.createdDate', $container).text(_nullToBlank(data.createdDateFormatted));
        $('.lastModifiedDate', $container).text(_nullToBlank(data.lastModifiedDateFormatted));
        $('.subject', $container).text(_nullToBlank(data.subject));
        $('.description', $container).text(_nullToBlank(data.description));

        // Populate attachments
        data.attachments.forEach(function(attachment) {
            var $row = $('<tr />');

            var attachmentUrl = '/servlet/servlet.FileDownload?file=' + attachment.id;

            if($(document).data('cms').site_prefix !== null) {
                attachmentUrl = $(document).data('cms').site_prefix + attachmentUrl;
            }

            $('<td />').append(
                $('<a />')
                    .prop('href', attachmentUrl)
                    .text(attachment.name)
            ).appendTo($row);
            $('<td />').text(attachment.createdByName).appendTo($row);
            $('<td />').text(attachment.createdDateFormatted).appendTo($row);

            $attachmentsRows = $attachmentsRows.add($row);
        });

        $attachmentsList.append($attachmentsRows);

        // Populate comments
        data.comments.forEach(function(comment) {
            var $commentItem = $('<div class="panel panel-default" />');
            var $heading = $('<div class="panel-heading" />').appendTo($commentItem);
            var $body = $('<div class="panel-body" />').appendTo($commentItem);

            $('<div class="pull-right" />').text(comment.createdDateFormatted).appendTo($heading);
            $('<h4 class="panel-title" />').text(comment.createdByName).appendTo($heading);

            comment.body.split('\n').forEach(function(paragraph) {
                paragraph = paragraph.trim();

                if(paragraph === '') {
                    return; // Eliminate "blank" paragraphs
                }

                $('<p />').text(paragraph).appendTo($body);

                $commentsItems = $commentsItems.add($commentItem);
            });
        });

        $commentsList.append($commentsItems);
    }

    /**
     * Renders a case list.
     *
     * @param $container a jQuery collection containing the parent element
     * @param data a JavaScript object containing an array of case data
     */
    namespace.renderCaseList = function($container, data) {
        var $caseTable = $('.caseList', $container).empty();
        var $rowList = $([]); // Minimize DOM updates by appending all the rows in bulk

        data.cases.forEach(function(caseData) {
            var $row = $('<tr />');

            $('<td />').text(_nullToBlank(caseData.status)).appendTo($row);

            // Use the detail link on the case number
            $('<td />').append(
                $(caseData.detailTag).text(_nullToBlank(caseData.caseNumber))
            ).appendTo($row);

            $('<td />').text(_nullToBlank(caseData.subject)).appendTo($row);
            $('<td />').text(_nullToBlank(caseData.lastActivityFormatted)).appendTo($row);

            $rowList = $rowList.add($row);
        });

        $caseTable.append($rowList);

        // Show/hide the Show More button
        if(data.hasMore) {
            $('.showMore', $container).show();
        } else {
            $('.showMore', $container).hide();
        }
    };

    /**
     * Calls the service action getCaseList with the provided parameters and passes the server result to the
     * specified callback function as the second argument.
     *
     * @param params a JavaScript object containing any of 'status', 'pageSize', 'pageNumber', and 'detailUrlCsv'
     * @param callback a JavaScript function that takes the result object as its second argument
     */
    namespace.getCaseList = function(params, callback) {
        var requestParams = {
            action: 'getCaseList'
        };

        requestParams.status = params.status;
        requestParams.pageSize = params.pageSize;
        requestParams.pageNumber = params.pageNumber;
        requestParams.detailUrlCsv = params.detailUrlCsv;

        if(requestParams.status == 'All') {
            requestParams.status = undefined;
        }

        $.orchestracmsRestProxy.doAjaxServiceRequest(serviceName, requestParams, callback, null, true); // Read-only mode
    };

    /**
     * Calls the service action getCaseDetail with the provided Case Id and passes the server result to the
     * specified callback function as the second argument.
     *
     * @param caseId a Salesforce Case Id
     * @param callback a JavaScript function that takes the result object as its second argument
     */
    namespace.getCaseDetail = function(caseId, callback) {
        $.orchestracmsRestProxy.doAjaxServiceRequest(serviceName, {
            action: 'getCaseDetail',
            caseId: caseId
        }, callback, null, true); // Read-only mode
    };

    /**
     * Calls the service action putCaseComment with the provided Case Id and Comment and passes the server result
     * to the specified callback function as the second argument.
     *
     * @param caseId a Salesforce Case Id
     * @param comment a comment body
     * @param callback a JavaScript function that takes the result object as its second argument
     */
    namespace.putCaseComment = function(caseId, comment, callback) {
        $.orchestracmsRestProxy.doAjaxServiceRequest(serviceName, {
            action: 'putCaseComment',
            caseId: caseId,
            comment: comment
        }, callback); // Not Read-only mode
    };

    /**
     * Calls the service action getCaseStatuses and passes the server result to the
     * specified callback function as the second argument.
     *
     * @param callback a JavaScript function that takes the result object as its second argument
     */
    namespace.getCaseStatuses = function(callback) {
        $.orchestracmsRestProxy.doAjaxServiceRequest(serviceName, {
            action: 'getCaseStatuses'
        }, callback, null, true); // Read-only mode
    };

    return namespace;
}(window, STG.CTLib.Case || {}));
