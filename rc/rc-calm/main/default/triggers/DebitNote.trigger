trigger DebitNote on blng__DebitNote__c (before delete, before insert, before update, after delete, after insert, after update) {

	switch on Trigger.operationType {
        when BEFORE_INSERT {
            System.debug('*** DEBUG: DebitNote ' + Trigger.operationType);
        }

		when AFTER_INSERT {
            System.debug('*** DEBUG: DebitNote ' + Trigger.operationType);
        }

        when BEFORE_UPDATE {
            System.debug('*** DEBUG: DebitNote ' + Trigger.operationType);
        }

		when AFTER_UPDATE {
            System.debug('*** DEBUG: DebitNote ' + Trigger.operationType);
        }

        when BEFORE_DELETE {
            System.debug('*** DEBUG: DebitNote ' + Trigger.operationType);
        }

        when AFTER_DELETE {
            System.debug('*** DEBUG: DebitNote ' + Trigger.operationType);
        }
	}
}