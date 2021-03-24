trigger Payment on blng__Payment__c (before delete, before insert, before update, after delete, after insert, after update) {

	switch on Trigger.operationType {
        when BEFORE_INSERT {
            System.debug('*** DEBUG: Payment ' + Trigger.operationType);
        }

		when AFTER_INSERT {
            System.debug('*** DEBUG: Payment ' + Trigger.operationType);
        }

        when BEFORE_UPDATE {
            System.debug('*** DEBUG: Payment ' + Trigger.operationType);
        }

		when AFTER_UPDATE {
            System.debug('*** DEBUG: Payment ' + Trigger.operationType);
            System.debug('*** DEBUG: PaymentAfterUpdate');
            for (blng__Payment__c pmt : trigger.new) {
                blng__Payment__c oldPayment = Trigger.oldMap.get(pmt.Id);
                Boolean oldPaymentIsPosted = oldPayment.blng__Status__c.equals('Posted');
                Boolean newPaymentIsPosted = pmt.blng__Status__c.equals('Posted');
        
                String reType = 'Payment';
                String action = 'Pay invoice line';
                String eventType = 'Allocated';
        
                if (newPaymentIsPosted) {
                    // System.debug('Matched Conditions');
                    FinanceTransactionAPI.doPost(pmt.Id, reType, action, eventType);
                }
            }
        }

        when BEFORE_DELETE {
            System.debug('*** DEBUG: Payment ' + Trigger.operationType);
        }

        when AFTER_DELETE {
            System.debug('*** DEBUG: Payment ' + Trigger.operationType);
        }
	}
}