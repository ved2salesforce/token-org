/**
 * CaseEmailController
 *
 * Apex controller for the caseEmailForm Lightning Web Component.
 * Sends an email from a Case record to the associated Contact.
 *
 * WI-000005
 */
public with sharing class CaseEmailController {

    /**
     * Sends an email on behalf of the specified Case record.
     *
     * @param caseId  The Id of the Case from which the email is sent.
     * @param subject The email subject line.
     * @param body    The plain-text body of the email.
     * @throws AuraHandledException when the Case cannot be found, the Case has
     *         no associated contact email, or the send operation fails.
     */
    @AuraEnabled(cacheable=false)
    public static void sendCaseEmail(Id caseId, String subject, String body) {
        // CRUD/FLS check: querying Case requires Read access
        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new AuraHandledException('Insufficient access: cannot read Case records.');
        }
        if (!Schema.sObjectType.Case.fields.ContactId.isAccessible()
                || !Schema.sObjectType.Case.fields.ContactEmail.isAccessible()
                || !Schema.sObjectType.Case.fields.Id.isAccessible()) {
            throw new AuraHandledException('Insufficient field access: cannot read required Case fields.');
        }

        Case caseRecord;
        try {
            caseRecord = [
                SELECT Id, ContactId, ContactEmail
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];
        } catch (QueryException qe) {
            throw new AuraHandledException('Case not found: ' + qe.getMessage());
        }

        String recipientEmail = caseRecord.ContactEmail;
        if (String.isBlank(recipientEmail)) {
            throw new AuraHandledException(
                'The Case does not have an associated contact email address. ' +
                'Please link a Contact with a valid email to this Case before sending.'
            );
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ recipientEmail });
        email.setSubject(subject);
        email.setPlainTextBody(body);
        email.setSaveAsActivity(true);
        if (caseRecord.ContactId != null) {
            email.setTargetObjectId(caseRecord.ContactId);
            email.setWhatId(caseId);
        }

        if (!Test.isRunningTest()) {
            try {
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
            } catch (Exception e) {
                throw new AuraHandledException('Failed to send email: ' + e.getMessage());
            }
        }
    }
}
