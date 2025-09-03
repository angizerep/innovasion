import { LightningElement, track, api } from 'lwc';
import listAlertsByEndpoint from '@salesforce/apex/IntegrationAlertService.listAlertsByEndpoint';
import ackAlert from '@salesforce/apex/IntegrationAlertService.ackAlert';
import createCase from '@salesforce/apex/IntegrationAlertService.createCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class IntegrationEndpointDetail extends LightningElement {
  @api endpointId = '';
  @track alerts = [];
  @track showModal = false;
  @track selectedAlert = {};

  columns = [
    { label: 'Detectada', fieldName: 'detectedAt', type: 'date' },
    { label: 'Severidad', fieldName: 'severity' },
    { label: 'Estado', fieldName: 'status' },
    { label: 'Regla', fieldName: 'rule' },
    { label: 'p95 (10m)', fieldName: 'p95_10m', type: 'number' },
    { label: 'Case', fieldName: 'caseNumber' },
    { type: 'action', typeAttributes: { rowActions: [ { label: 'Ver', name: 'view' } ] } }
  ];

  onEndpointChange(e) { this.endpointId = e.detail.value; }

  async loadAlerts() {
    try {
      this.alerts = await listAlertsByEndpoint({ endpointId: this.endpointId });
    } catch (e) {
      this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: e.body?.message || e.message, variant: 'error' }));
    }
  }

  handleRowAction(e) {
    if (e.detail.action.name === 'view') {
      this.selectedAlert = e.detail.row; // DTO ya listo para la vista
      this.showModal = true;
    }
  }

  closeModal = () => { this.showModal = false; };

  async ack() {
    try {
      const updated = await ackAlert({ alertId: this.selectedAlert.id });
      this.selectedAlert = updated;
      this.dispatchEvent(new ShowToastEvent({ title: 'OK', message: 'Alerta reconocida', variant: 'success' }));
      this.loadAlerts();
    } catch (e) {
      this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: e.body?.message || e.message, variant: 'error' }));
    }
  }

  async createCase() {
    try {
      const res = await createCase({ alertId: this.selectedAlert.id });
      this.dispatchEvent(new ShowToastEvent({ title: 'Case creado', message: `#${res.caseNumber}`, variant: 'success' }));
      await this.ack(); // opcional
    } catch (e) {
      this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: e.body?.message || e.message, variant: 'error' }));
    }
  }
}
