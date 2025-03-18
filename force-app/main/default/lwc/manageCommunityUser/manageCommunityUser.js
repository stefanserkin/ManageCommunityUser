import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import LightningConfirm from 'lightning/confirm';
import EnableUserModal from 'c/enableCommunityUserModal';
import getCommunityUser from '@salesforce/apex/ManageCommunityUserController.getCommunityUser';
import resetPassword from '@salesforce/apex/ManageCommunityUserController.resetPassword';
import disableUser from '@salesforce/apex/ManageCommunityUserController.disableUser';
import enableUser from '@salesforce/apex/ManageCommunityUserController.enableUser';

import canView from '@salesforce/customPermission/Manage_Community_User_View_Only';
import canResetPassword from '@salesforce/customPermission/Manage_Community_User_Reset_Password';
import canLogInAsUser from '@salesforce/customPermission/Manage_Community_User_Log_in_as_User';
import canDisableUser from '@salesforce/customPermission/Manage_Community_User_Disable_User';
import canEnableUser from '@salesforce/customPermission/Manage_Community_User_Enable_User';

import EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import FIRSTNAME_FIELD from '@salesforce/schema/Contact.FirstName';
import LASTNAME_FIELD from '@salesforce/schema/Contact.LastName';

const FIELDS = [EMAIL_FIELD, FIRSTNAME_FIELD, LASTNAME_FIELD];

export default class ManageCommunityUser extends LightningElement {
    @api cardTitle = 'Manage Community User';
    @api cardIconName = 'standard:user';
    @api recordId;

    error;
    isLoading = false;

    contact;
    contactEmail;
    firstName;
    lastName;

    hasEvaluatedCommunityUser = false;
    wiredCommunityUser = [];
    communityUser;

    /*************************************************
     * User Permissions
     *************************************************/

    get userCanViewComponent() {
        return canView || canResetPassword || canLogInAsUser || canDisableUser || canEnableUser;
    }

    get userCanResetPassword() {
        return canResetPassword;
    }

    get userCanLogInAsUser() {
        return canLogInAsUser;
    }

    get userCanDisableUser() {
        return canDisableUser;
    }

    get userCanEnableUser() {
        return canEnableUser;
    }

    get showEnableUserButton() {
        return this.hasEvaluatedCommunityUser && !this.communityUser && this.userCanEnableUser;
    }

    /*************************************************
     * Wired data - Contact and Community User
     *************************************************/

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            this.error = error;
            this.handleError(this.error);
        } else if (data) {
            this.contact = data;
            this.contactEmail = this.contact.fields.Email.value;
            this.firstName = this.contact.fields.FirstName.value;
            this.lastName = this.contact.fields.LastName.value;
        }
    }

    @wire(getCommunityUser, { contactId: '$recordId' })
    wiredUserResult(result) {
        if (!this.recordId) {
            return;
        }

        this.isLoading = true;
        this.wiredCommunityUser = result;
        
        if (result.data) {
            this.communityUser = result.data;
        } else if (result.error) {
            this.communityUser = undefined;
            this.error = result.error;
            this.handleError(this.error);
        }
        this.isLoading = false;
        this.hasEvaluatedCommunityUser = true;
    }

    /*************************************************
     * Existing User Actions
     *************************************************/

    /**
     * Reset password
     */
    async handleResetPassword() {
        const isConfirmed = await this.confirmAction(`Are you sure you want to reset the user's password?`);
        if (!isConfirmed) {
            return;
        }

        this.isLoading = true;
        resetPassword({ userId: this.communityUser.userId })
            .then((result) => {
                if (result.isSuccess) {
                    this.isLoading = false;
                    this.showToast(
                        'Success',
                        `An email has been sent to ${this.communityUser.email} with a link to reset their password`,
                        'success'
                    );
                } else {
                    this.showToast(
                        'Error',
                        `The password could not be reset for ${this.communityUser.username}`,
                        'error'
                    );
                }
                
            })
            .catch((error) => {
                this.isLoading = false;
                this.handleError(error);
            });
    }

    /**
     * Log in as user
     */
    handleLogInAsUser() {
        window.open(this.communityUser.logInAsUrl, '_blank');
    }

    /**
     * Disable active user
     */
    async handleDisableUser() {
        const isConfirmed = await this.confirmAction(`Are you sure you want to disable the community user?`);
        if (!isConfirmed) {
            return;
        }

        this.isLoading = true;
        disableUser({ userId: this.communityUser.userId })
            .then((result) => {
                if (result.isSuccess) {
                    this.showToast(
                        'Success',
                        `User ${this.communityUser.username} has been disabled`,
                        'success'
                    );
                    
                } else {
                    this.showToast(
                        'Error',
                        `User ${this.communityUser.username} could not be disabled`,
                        'error'
                    );
                }
                
                setTimeout(() => {
                    this.refreshComponent();
                    this.isLoading = false;
                }, 4000);
            })
            .catch((error) => {
                this.isLoading = false;
                this.handleError(error);
                this.refreshComponent();
            });
    }

    /*************************************************
     * Enable User Actions
     *************************************************/
    async handleEnableUser() {
        const result = await EnableUserModal.open({
            size: 'small',
            description: 'Enter details for the new user',
            email: this.contactEmail,
            username: this.contactEmail
        });

        if (result) {
            const { username, email } = result;
            this.createUser(username, email);
        }
    }

    async createUser(username, email) {
        this.isLoading = true;
        try {
            const request = {
                contactId: this.recordId,
                username,
                email,
                firstName: this.firstName,
                lastName: this.lastName
            };
            const jsonString = JSON.stringify(request);
            const response = await enableUser({ jsonString });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: `User successfully created!`,
                    variant: 'success'
                })
            );

            this.isLoading = false;
            this.refreshComponent();
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                })
            );
            this.isLoading = false;
        }
    }

    /*************************************************
     * Utils
     *************************************************/

    async confirmAction(message) {
        return await LightningConfirm.open({
            message: message,
            variant: 'header',
            label: 'Confirm Action',
            theme: 'warning'
        });
    }

    handleError(error) {
        let message = 'Unknown error';
        if (Array.isArray(error.body)) {
            message = error.body.map((e) => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            message = error.body.message;
        }
        this.showToast('An error occurred', message, 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    refreshComponent() {
        this.communityUser = undefined;
        refreshApex(this.wiredCommunityUser);
    }

}