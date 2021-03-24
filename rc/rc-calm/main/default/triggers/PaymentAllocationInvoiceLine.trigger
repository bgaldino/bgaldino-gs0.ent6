trigger PaymentAllocationInvoiceLine on blng__PaymentAllocationInvoiceLine__c (before delete, before insert, before update, after delete, after insert, after update) {

	switch on Trigger.operationType {
        when BEFORE_INSERT {
            System.debug('*** DEBUG: PaymentAllocationInvoiceLine ' + Trigger.operationType);
        }

		when AFTER_INSERT {
            System.debug('*** DEBUG: PaymentAllocationInvoiceLine ' + Trigger.operationType);
            boolean debug = false;
			List<blng__PaymentAllocationInvoiceLine__c> orderItemsToUpdate = new List<blng__PaymentAllocationInvoiceLine__c>();
			List<blng__PaymentAllocationInvoiceLine__c> itemsWithCurrentDetails = [select 
			                                                 id
			                                           from blng__PaymentAllocationInvoiceLine__c 
                                                       where Id IN :Trigger.newMap.keySet()];

            for (blng__PaymentAllocationInvoiceLine__c pail : itemsWithCurrentDetails) {
                String reType = 'Payment Invoice Line Application';
                String action = 'Pay invoice line';
                String eventType = 'Allocated';
        
                FinanceTransactionAPI.doPost(pail.Id, reType, action, eventType);
            }
            
        }

        when BEFORE_UPDATE {
            System.debug('*** DEBUG: PaymentAllocationInvoiceLine ' + Trigger.operationType);
        }

		when AFTER_UPDATE {
            System.debug('*** DEBUG: PaymentAllocationInvoiceLine ' + Trigger.operationType);
            System.debug('*** DEBUG: PaymentAllocationInvoiceLineAfterUpdate');
            /* for (blng__PaymentAllocationInvoiceLine__c pmt : trigger.new) {
                blng__PaymentAllocationInvoiceLine__c oldPayment = Trigger.oldMap.get(pmt.Id);
                Boolean oldPaymentIsPosted = oldPayment.blng__Type__c.equals('Allocation');
                Boolean newPaymentIsPosted = pmt.blng__Type__c.equals('Allocation');
        
                String reType = 'Payment Invoice Line Application';
                String action = 'Pay invoice line';
        
                if (newPaymentIsPosted) {
                    // System.debug('Matched Conditions');
                    FinanceTransactionAPI.doPost(pmt.Id, reType, action);
                }
            } */
        }

        when BEFORE_DELETE {
            System.debug('*** DEBUG: PaymentAllocationInvoiceLine ' + Trigger.operationType);
        }

        when AFTER_DELETE {
            System.debug('*** DEBUG: PaymentAllocationInvoiceLine ' + Trigger.operationType);
        }
	}
}