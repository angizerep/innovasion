import { LightningElement, api } from 'lwc';

export default class IntegrationAlertModal extends LightningElement {
  @api open = false;
  @api title = 'Alerta';

  close = () => this.dispatchEvent(new CustomEvent('close'));
  onAck = () => this.dispatchEvent(new CustomEvent('ack'));
  onCreateCase = () => this.dispatchEvent(new CustomEvent('createcase'));
}
