import { LightningElement, api, track } from 'lwc';
import sendCaseEmail from '@salesforce/apex/CaseEmailController.sendCaseEmail';

/**
 * caseEmailForm
 *
 * Lightning Web Component that provides a simple form for sending an email
 * from a Case record page. Consumes the CaseEmailController Apex controller.
 *
 * WI-000005
 */
export default class CaseEmailForm extends LightningElement {
    /** Automatically populated with the Case record Id when placed on a record page. */
    @api recordId;

    @track subject = '';
    @track body = '';
    @track successMessage = '';
    @track errorMessage = '';

    handleSubjectChange(event) {
        this.subject = event.detail.value;
    }

    handleBodyChange(event) {
        this.body = event.detail.value;
    }

    handleSend() {
        // Client-side validation
        if (!this.subject || this.subject.trim() === '') {
            this.errorMessage = 'Subject is required.';
            this.successMessage = '';
            return;
        }
        if (!this.body || this.body.trim() === '') {
            this.errorMessage = 'Body is required.';
            this.successMessage = '';
            return;
        }

        this.errorMessage = '';
        this.successMessage = '';

        sendCaseEmail({
            caseId: this.recordId,
            subject: this.subject,
            body: this.body
        })
            .then(() => {
                this.successMessage = 'Email sent successfully.';
                this.subject = '';
                this.body = '';
            })
            .catch((error) => {
                this.errorMessage =
                    error && error.body && error.body.message
                        ? error.body.message
                        : 'An unexpected error occurred while sending the email.';
            });
    }
}
