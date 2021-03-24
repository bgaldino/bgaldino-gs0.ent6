trigger InvoiceLine on blng__InvoiceLine__c (before delete, before insert, before update, after delete, after insert, after update) {

	switch on Trigger.operationType {
		when BEFORE_INSERT {
			System.debug('*** DEBUG: InvoiceLine ' + Trigger.operationType);
		}

		when AFTER_INSERT {
			System.debug('*** DEBUG: InvoiceLine ' + Trigger.operationType);
		}

		when BEFORE_UPDATE {
			System.debug('*** DEBUG: InvoiceLine ' + Trigger.operationType);
		}

		when AFTER_UPDATE {
			System.debug('*** DEBUG: InvoiceLine ' + Trigger.operationType);
			for (blng__InvoiceLine__c invoiceLine : trigger.new) {

				Boolean accResetStatus = invoiceLine.Reset__c;

				if (accResetStatus == FALSE) {

					blng__InvoiceLine__c oldInvLine = Trigger.oldMap.get(invoiceLine.Id);
					Boolean oldInvLineIsPosted = oldInvLine.blng__InvoiceLineStatus__c.equals('Posted');
					Boolean newInvLineIsPosted = invoiceLine.blng__InvoiceLineStatus__c.equals('Posted');

					Double oldResultingBalance = oldInvLine.blng__Balance__c;
					Double newResultingBalance = invoiceLine.blng__Balance__c;

					System.debug('Account Reset Status: ' + String.valueOf(accResetStatus));
					System.debug('*** DEBUG: InvoiceLine ' + Trigger.operationType + ' invoiceReset ' + String.valueOf(invoiceLine.Reset__c));
					System.debug('*** DEBUG: InvoiceLine ' + Trigger.operationType + ' oldInvLineIsPosted ' + String.valueOf(oldInvLineIsPosted));
					System.debug('*** DEBUG: InvoiceLine ' + Trigger.operationType + ' newInvLineIsPosted ' + String.valueOf(newInvLineIsPosted));
					System.debug('*** DEBUG: InvoiceLine ' + Trigger.operationType + ' oldResultingBalance ' + String.valueOf(oldResultingBalance));
					System.debug('*** DEBUG: InvoiceLine ' + Trigger.operationType + ' newResultingBalance ' + String.valueOf(newResultingBalance));

					String reType;
					String action;
					String actionType;

					if ((!oldInvLineIsPosted && newInvLineIsPosted) && invoiceLine.Reset__c == FALSE) {
						System.debug('Log invoice line when posted');
						reType = 'Invoice Line';
						action = 'Post an invoice';
						actionType = 'Posted';
						FinanceTransactionAPI.doPost(invoiceLine.Id, reType, action, actionType);
					}

					if (((!oldInvLineIsPosted && newInvLineIsPosted) && (invoiceLine.blng__TaxAmount__c != 0)) && invoiceLine.Reset__c == FALSE) {
						System.debug('Log invoice tax line when posted');
						reType = 'Invoice Line Tax';
						action = 'Post an invoice';
						actionType = 'Posted';
						FinanceTransactionAPI.doPost(invoiceLine.Id, reType, action, actionType);
					}

					if (((oldInvLineIsPosted && newInvLineIsPosted) && (oldResultingBalance != newResultingBalance)) && invoiceLine.Reset__c == FALSE) {
						reType = 'Invoice Line';
						action = 'Pay invoice line';
						actionType = 'Allocated';
						FinanceTransactionAPI.doPost(invoiceLine.Id, reType, action, actionType);
					}

					if (((oldInvLineIsPosted && newInvLineIsPosted) && (oldResultingBalance != newResultingBalance) && (invoiceLine.blng__TaxAmount__c != 0)) && invoiceLine.Reset__c == FALSE) {
						reType = 'Invoice Line Tax';
						action = 'Pay invoice line';
						actionType = 'Allocated';
						FinanceTransactionAPI.doPost(invoiceLine.Id, reType, action, actionType);
					}
				}

			}
		}

		when BEFORE_DELETE {
			System.debug('*** DEBUG: InvoiceLine ' + Trigger.operationType);
		}

		when AFTER_DELETE {
			System.debug('*** DEBUG: InvoiceLine ' + Trigger.operationType);
		}
	}
}