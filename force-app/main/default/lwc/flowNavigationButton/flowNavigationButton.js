import { LightningElement, api } from 'lwc';

export default class FlowNavigationButton extends LightningElement {
    @api label;
    @api url;
    @api variant;
    @api iconName;
    @api openInNewTab = false;
    @api disabled = false;
    @api disabledTooltip;

    handleClick() {
        window.open(this.url, this.targetBehavior);
    }

    get targetBehavior() {
        return this.openInNewTab ? '_blank' : '_self';
    }

    get buttonTitle() {
        return this.disabled ? 
            (this.disabledTooltip ? this.disabledTooltip : 'This button is disabled') : 
            '';
    }
}