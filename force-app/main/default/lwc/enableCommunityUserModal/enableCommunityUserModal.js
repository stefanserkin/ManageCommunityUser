import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class EnableCommunityUserModal extends LightningModal {
    @api email;
    @api username;

    handleEmailChange(event) {
        this.email = event.target.value;
    }

    handleUsernameChange(event) {
        this.username = event.target.value;
    }

    handleEnable() {
        this.close({ email: this.email, username: this.username });
    }

    handleCancel() {
        this.close(null);
    }
}