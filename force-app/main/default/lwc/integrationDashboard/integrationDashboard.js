import { LightningElement, track } from 'lwc';
import listEndpoints from '@salesforce/apex/IntegrationAlertService.listEndpoints';
import getKpis from '@salesforce/apex/IntegrationAlertService.getKpis';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class IntegrationDashboard extends LightningElement {
  @track kpis; 
  @track rows = [];
  filterProvider = '';
  filterSeverity = '';
  filterStatus = '';

  severityOptions = [
    { label: 'Todas', value: '' },
    { label: 'Critical', value: 'Critical' },
    { label: 'Major', value: 'Major' },
    { label: 'Warning', value: 'Warning' },
    { label: 'Info', value: 'Info' }
  ];
  statusOptions = [
    { label: 'Todos', value: '' },
    { label: 'New', value: 'New' },
    { label: 'Acknowledged', value: 'Acknowledged' },
    { label: 'Resolved', value: 'Resolved' }
  ];

  columns = [
    { label: 'Proveedor', fieldName: 'provider' },
    { label: 'Endpoint', fieldName: 'endpoint' },
    { label: 'Severidad', fieldName: 'lastSeverity' },
    { label: 'p95 (10m)', fieldName: 'lastP95', type: 'number' },
    { label: 'Alertas abiertas', fieldName: 'openAlerts', type: 'number' },
    {
      type: 'action', typeAttributes: { rowActions: [
        { label: 'Ver detalle', name: 'view' }
      ]}
    }
  ];

  connectedCallback() {
    this.refresh();
  }

  async refresh() {
    try {
      const [kpis, endpoints] = await Promise.all([
        getKpis(),
        listEndpoints({ provider: this.filterProvider, severity: this.filterSeverity, status: this.filterStatus })
      ]);
      this.kpis = kpis;
      this.rows = endpoints;
    } catch (e) {
      this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: e.body?.message || e.message, variant: 'error' }));
    }
  }

  onProviderChange(e) { this.filterProvider = e.detail.value; this.refresh(); }
  onSeverityChange(e) { this.filterSeverity = e.detail.value; this.refresh(); }
  onStatusChange(e)   { this.filterStatus   = e.detail.value; this.refresh(); }

  handleRowAction(e) {
    const action = e.detail.action.name;
    const row = e.detail.row;
    if (action === 'view') {
      const evt = new CustomEvent('navigate', { detail: { endpointId: row.endpointId }});
      this.dispatchEvent(evt);
    }
  }
}
