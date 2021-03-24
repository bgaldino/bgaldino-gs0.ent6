import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import { getRecord } from 'lightning/uiRecordApi';
import getActiveAssets from '@salesforce/apex/AssetManagementComponentController.getActiveAssets';
import changeAssets from '@salesforce/apex/AssetManagementComponentController.changeAssets';
import renewAssets from '@salesforce/apex/AssetManagementComponentController.renewAssets';

const columns = [
    {label:'Subscription', fieldName:'Name', type:'text'},
    {label:'Quantity', fieldName:'CurrentQuantity', type:'number'},
    {label:'Start Date', fieldName:'LifecycleStartDate', type:'date'},
    {label:'End Date', fieldName:'LifecycleEndDate', type:'date'},
]

export default class AssetManagementComponent extends NavigationMixin(LightningElement) {
    columns = columns;
    error;

    @api recordId;
    
    @track startDate;
    @track renewDate;
    @track renewTerm;
    @track activeAssets;
    @track selectedRecords;
    @track newQuoteId;
    @track redirectURL;
    @track isChangeModalOpen = false;
    @track isRenewModalOpen = false;

    connectedCallback(){
        getActiveAssets({accountId: this.recordId})
            .then((result) => {
                this.activeAssets = result;
                this.error = undefined;
            })
            .catch((error) => {
                this.error = error;
                this.activeAssets = undefined;
            });
    }

    setDateOnChange(event){
        this.startDate = event.target.value;
        console.log('Start Date is ', this.startDate);
    }

    setRenewDateOnChange(event){
        this.renewDate = event.target.value;
        console.log('Renewal Date is ', this.renewDate);
    }

    setRenewTermOnChange(event){
        this.renewTerm = event.target.value;
        console.log('Renewal Term is ', this.renewTerm);
    }

    openChangeModal(){
        this.isChangeModalOpen = true;
    }

    closeChangeModal(){
        this.isChangeModalOpen = false;
    }
    
    openRenewModal(){
        this.isRenewModalOpen = true;
    }

    closeRenewModal(){
        this.isRenewModalOpen = false;
    }

    handleChangeAssetClick(){
        console.log('Passed AccountId string value is ', this.recordId);
        console.log('Passed Start Date parameter value is ', this.startDate);

        this.selectedRecords = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('Number of rows selected is ', this.selectedRecords.length);
        changeAssets({
                        accountId: this.recordId,
                        sDate: this.startDate,
                        assets: this.selectedRecords})
                        .then((result) => {
                            this.newQuoteId = result;
                            this.error = undefined;

                            this.redirectURL = '/apex/sbqq__sb?scontrolCaching=1&id=' + this.newQuoteId;

                            this[NavigationMixin.Navigate]({
                                type : 'standard__webPage',
                                attributes : {
                                    url : this.redirectURL
                                }
                            });
                        })
                        .catch((error) => {
                            this.error = error;
                            this.newQuoteId = undefined;

                            this.redirectURL = undefined;
                        });

    }

    handleRenewAssetClick(){
        console.log('Passed AccountId string value is ', this.recordId);
        console.log('Passed Renew Date parameter value is ', this.renewDate);
        console.log('Passed Renew Term parameter value is ', this.renewTerm);

        this.selectedRecords = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('Number of rows selected is ', this.selectedRecords.length);
        renewAssets({
                        accountId: this.recordId,
                        renewDate: this.renewDate,
                        renewTerm: this.renewTerm,
                        assets: this.selectedRecords})
                        .then((result) => {
                            this.newQuoteId = result;
                            this.error = undefined;

                            this.redirectURL = '/apex/sbqq__sb?scontrolCaching=1&id=' + this.newQuoteId;

                            this[NavigationMixin.Navigate]({
                                type : 'standard__webPage',
                                attributes : {
                                    url : this.redirectURL
                                }
                            });
                        })
                        .catch((error) => {
                            this.error = error;
                            this.newQuoteId = undefined;

                            this.redirectURL = undefined;
                        });

    }

    handleCancelAssetClick(){
        console.log('Passed AccountId string value is ', this.recordId);
        console.log('Passed Start Date parameter value is ', this.startDate);
    }
}