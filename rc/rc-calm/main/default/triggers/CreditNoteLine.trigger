trigger CreditNoteLine on blng__CreditNoteLine__c (before delete, before insert, before update, after delete, after insert, after update) {

	switch on Trigger.operationType {
		when BEFORE_INSERT {
			System.debug('*** DEBUG: CreditNoteLine ' + Trigger.operationType);
		}

		when AFTER_INSERT {
			System.debug('*** DEBUG: CreditNoteLine ' + Trigger.operationType);
		}

		when BEFORE_UPDATE {
			System.debug('*** DEBUG: CreditNoteLine ' + Trigger.operationType);
			for (blng__CreditNoteLine__c cn : trigger.new) {

				blng__CreditNoteLine__c oldCreditMemo = Trigger.oldMap.get(cn.Id);
				Boolean oldMemoLineIsPosted = oldCreditMemo.blng__Status__c.equals('Posted');
				Boolean newMemoLineIsPosted = cn.blng__Status__c.equals('Posted');

				String reType = 'Credit Memo Line';
				String action = 'Credit invoice line';
				String eventType = 'Posted';

				if (!oldMemoLineIsPosted && newMemoLineIsPosted) {
					// System.debug('Matched Conditions');
					FinanceTransactionAPI.doPost(cn.Id, reType, action, eventType);
				}
			}
		}

		when AFTER_UPDATE {
			System.debug('*** DEBUG: CreditNoteLine ' + Trigger.operationType);
		}

		when BEFORE_DELETE {
			System.debug('*** DEBUG: CreditNoteLine ' + Trigger.operationType);
		}

		when AFTER_DELETE {
			System.debug('*** DEBUG: CreditNoteLine ' + Trigger.operationType);
		}
	}
}