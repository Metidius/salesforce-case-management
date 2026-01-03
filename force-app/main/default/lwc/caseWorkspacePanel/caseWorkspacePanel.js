import { LightningElement, api, wire, track } from 'lwc';
import getWorkspaceData from '@salesforce/apex/CaseWorkspaceController.getWorkspaceData';
import markReviewed from '@salesforce/apex/CaseWorkspaceController.markReviewed';
import escalateCase from '@salesforce/apex/CaseWorkspaceController.escalateCase';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseWorkspacePanel extends LightningElement {
  @api recordId;

  @track isModalOpen = false;
  @track modalMode = 'update'; // 'update' | 'escalate'

  wiredResult;
  data;
  error;

  @wire(getWorkspaceData, { caseId: '$recordId' })
  wiredWorkspace(result) {
    this.wiredResult = result;
    const { data, error } = result;
    this.data = data;
    this.error = error;
  }

  get isLoading() {
    return !this.data && !this.error;
  }

  get caseInfo() {
    return this.data?.caseInfo;
  }

  get context() {
    return this.data?.context;
  }

  get updates() {
    return this.data?.recentUpdates || [];
  }

  get hasContext() {
    return !!this.context;
  }

  get hasUpdates() {
    return this.updates.length > 0;
  }

  get priorityBadgeVariant() {
    const p = (this.caseInfo?.priority || '').toLowerCase();
    if (p === 'high') return 'error';
    if (p === 'medium') return 'warning';
    return 'success';
  }

  openAddUpdate() {
    this.modalMode = 'update';
    this.isModalOpen = true;
  }

  openEscalate() {
    this.modalMode = 'escalate';
    this.isModalOpen = true;
  }

  closeModal() {
    this.isModalOpen = false;
  }

  async handleModalSuccess(message) {
    this.isModalOpen = false;
    this.toast('Success', message || 'Saved', 'success');
    await refreshApex(this.wiredResult);
  }

  async handleMarkReviewed() {
    try {
      await markReviewed({ caseId: this.recordId });
      this.toast('Success', 'Marked as reviewed', 'success');
      await refreshApex(this.wiredResult);
    } catch (e) {
      this.toast('Action Failed', this.normalizeError(e), 'error');
    }
  }

  async handleEscalateSubmit(event) {
    // event.detail.reason comes from modal
    try {
      await escalateCase({ caseId: this.recordId, reason: event.detail.reason });
      this.isModalOpen = false;
      this.toast('Success', 'Case escalated', 'success');
      await refreshApex(this.wiredResult);
    } catch (e) {
      this.toast('Action Failed', this.normalizeError(e), 'error');
    }
  }

  toast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  normalizeError(e) {
    // Handles AuraHandledException, Apex errors, JS errors
    if (!e) return 'Unknown error';
    if (typeof e === 'string') return e;
    if (e.body) {
      if (typeof e.body.message === 'string') return e.body.message;
      if (Array.isArray(e.body)) return e.body.map(x => x.message).join(', ');
    }
    return e.message || 'Unknown error';
  }

  formatDate(dt) {
    try {
      return new Intl.DateTimeFormat('en-GB', {
        year: 'numeric',
        month: 'short',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
      }).format(new Date(dt));
    } catch {
      return dt;
    }
  }
}
