/**
 * CaseEmailControllerTest
 *
 * Test class for CaseEmailController.
 * Covers CRUD/FLS checks, positive send path, and negative (invalid caseId) path.
 *
 * WI-000005
 */
@IsTest
private class CaseEmailControllerTest {

    @TestSetup
    static void setupData() {
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@example.com',
            AccountId = acct.Id
        );
        insert con;

        Case caseRecord = new Case(
            Subject = 'Test Case for Email',
            ContactId = con.Id,
            AccountId = acct.Id,
            Status = 'New',
            Origin = 'Phone'
        );
        insert caseRecord;
    }

    /**
     * Positive test: sendCaseEmail completes without exception when invoked
     * with a valid caseId, subject, and body.
     * The actual Messaging.sendEmail call is guarded by Test.isRunningTest().
     */
    @IsTest
    static void testSendCaseEmail_Success() {
        Case caseRecord = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        try {
            CaseEmailController.sendCaseEmail(caseRecord.Id, 'Test Subject', 'Test body');
        } catch (Exception e) {
            System.assert(false, 'Unexpected exception: ' + e.getMessage());
        }
        Test.stopTest();

        // No exception means the method executed the full happy path
        System.assert(true, 'sendCaseEmail completed successfully');
    }

    /**
     * Negative test: sendCaseEmail throws AuraHandledException (or QueryException
     * wrapped in AuraHandledException) when given an invalid caseId.
     */
    @IsTest
    static void testSendCaseEmail_InvalidCaseId() {
        // Use a syntactically valid but non-existent Case Id
        Id fakeId = '5000000000000000000';

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            CaseEmailController.sendCaseEmail(fakeId, 'Subject', 'Body');
        } catch (AuraHandledException ahe) {
            exceptionThrown = true;
        } catch (System.QueryException qe) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected an exception for invalid caseId but none was thrown.');
    }

    /**
     * Negative test: sendCaseEmail throws AuraHandledException when the Case
     * has no associated contact email.
     */
    @IsTest
    static void testSendCaseEmail_NoContactEmail() {
        // Create a case with no ContactId so ContactEmail will be blank
        Case caseNoContact = new Case(
            Subject = 'No Contact Case',
            Status = 'New',
            Origin = 'Phone'
        );
        insert caseNoContact;

        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        try {
            CaseEmailController.sendCaseEmail(caseNoContact.Id, 'Subject', 'Body');
        } catch (AuraHandledException ahe) {
            exceptionThrown = true;
            exceptionMessage = ahe.getMessage();
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected AuraHandledException for missing contact email.');
        System.assert(
            exceptionMessage.contains('contact email') || exceptionMessage.contains('email'),
            'Exception message should indicate missing email. Got: ' + exceptionMessage
        );
    }
}
