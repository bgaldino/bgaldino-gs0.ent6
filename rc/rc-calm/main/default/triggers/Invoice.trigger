trigger Invoice on blng__Invoice__c (before delete, before insert, before update, after delete, after insert, after update) {

	switch on Trigger.operationType {
		when BEFORE_INSERT {
			System.debug('*** DEBUG: Invoice ' + Trigger.operationType);
		}

		when AFTER_INSERT {
			System.debug('*** DEBUG: Invoice ' + Trigger.operationType);
		}

		when BEFORE_UPDATE {
			System.debug('*** DEBUG: Invoice ' + Trigger.operationType);
		}

		when AFTER_UPDATE {
			System.debug('*** DEBUG: Invoice ' + Trigger.operationType);
			for (blng__Invoice__c invoice : trigger.new) {
				// system.debug('OLD:::::' + JSON.serializePretty(trigger.oldmap.get(invoice.Id)));
				// system.debug('NEW:::::' + JSON.serializePretty(trigger.newmap.get(invoice.Id)));

				blng__Invoice__c oldInv = Trigger.oldMap.get(invoice.Id);
				Boolean oldInvIsPosted = oldInv.blng__InvoiceStatus__c.equals('Posted');
				Boolean newInvIsPosted = invoice.blng__InvoiceStatus__c.equals('Posted');

				Double oldResultingBalance = oldInv.blng__Balance__c;
				Double newResultingBalance = invoice.blng__Balance__c;

				String reType = 'Invoice';
				String eventAction = 'Post an invoice';
				String eventType = 'Posted';

				if (!oldInvIsPosted && newInvIsPosted) {
					// System.debug('Matched Conditions');
					//transactionJournalEntryCreation.CreateTransactionJournalEntries(invoice.Id);
					eventAction = 'Post an invoice';
					eventType = 'Posted';
					FinanceTransactionAPI.doPost(invoice.Id, reType, eventAction, eventType);
				}

				if ((oldInvIsPosted && newInvIsPosted) && (oldResultingBalance != newResultingBalance)) {
					eventAction = 'Pay invoice line';
					eventType = 'Allocated';
					FinanceTransactionAPI.doPost(invoice.Id, reType, eventAction, eventType);
				}

			}
		}

		when BEFORE_DELETE {
			System.debug('*** DEBUG: Invoice ' + Trigger.operationType);
		}

		when AFTER_DELETE {
			System.debug('*** DEBUG: Invoice ' + Trigger.operationType);
		}
	}
}