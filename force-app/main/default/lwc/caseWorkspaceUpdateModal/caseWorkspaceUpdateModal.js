import { LightningElement, api, track } from 'lwc';
import createCaseUpdate from '@salesforce/apex/CaseWorkspaceController.createCaseUpdate';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseWorkspaceUpdateModal extends LightningElement {
  @api recordId;
  @api mode; // 'update' | 'escalate'

  @track isSaving = false;

  // Update form
  @track updateType = '';
  @track summary = '';
  @track details = '';
  @track visibleToCustomer = false;

  // Escalate form
  @track reason = '';

  get isUpdate() {
    return this.mode === 'update';
  }

  get isEscalate() {
    return this.mode === 'escalate';
  }

  get title() {
    return this.isEscalate ? 'Escalate Case' : 'Add Case Update';
  }

  get updateTypeOptions() {
    return [
      { label: 'Note', value: 'Note' },
      { label: 'Customer Contact', value: 'CustomerContacted' },
      { label: 'Internal Investigation', value: 'InternalInvestigation' },
      { label: 'Resolution', value: 'Resolution' },
      { label: 'Escalation', value: 'Escalation' }
    ];
  }

  close() {
    this.dispatchEvent(new CustomEvent('close'));
  }

  handleChange(e) {
    const { name, value, checked, type } = e.target;
    if (type === 'checkbox') this[name] = checked;
    else this[name] = value;
  }

  async handleSave() {
    if (this.isEscalate) {
      this.dispatchEvent(new CustomEvent('escalatesubmit', { detail: { reason: this.reason } }));
      return;
    }

    if (!this.updateType) {
      this.toast('Missing info', 'Please select an update type.', 'error');
      return;
    }
    if (!this.summary || !this.summary.trim()) {
      this.toast('Missing info', 'Please enter a summary.', 'error');
      return;
    }

    this.isSaving = true;
    try {
      await createCaseUpdate({
        caseId: this.recordId,
        updateType: this.updateType,
        summary: this.summary?.trim(),
        details: this.details?.trim(),
        visibleToCustomer: this.visibleToCustomer
      });

      this.dispatchEvent(new CustomEvent('success', { detail: 'Update added' }));
    } catch (e) {
      this.toast('Action Failed', this.normalizeError(e), 'error');
    } finally {
      this.isSaving = false;
    }
  }

  toast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  normalizeError(e) {
    if (!e) return 'Unknown error';
    if (typeof e === 'string') return e;
    if (e.body) {
      if (typeof e.body.message === 'string') return e.body.message;
      if (Array.isArray(e.body)) return e.body.map(x => x.message).join(', ');
    }
    return e.message || 'Unknown error';
  }
}
