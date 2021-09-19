public with sharing class FinanceTransactionAPI {
	public financeTransaction ftxn;
	public String invoiceId;
	public String invoiceLineId;
	public String creditNoteId;
	public String creditNoteLineId;
	public String creditNoteAllocationId;
	public String debitNoteId;
	public String debitNoteLineId;
	public String debitNoteAllocationId;
	public String debitNoteAllocationCreditNoteLineId;
	public String paymentId;
	public String paymentAllocationInvoice;
	public String paymentAllocationInvoiceLine;
	public String paymentAllocationDebitNoteLine;

	public static Id ftId { get; set; }

	public static final String DEFAULT_LEGAL_ENTITY = 'a1sB0000001F3r0IAC';
	public static final String API_VERSION = '53.0';

	@future(callout = true)
	public static void doPost(Id reId, String reType, String action, String actionType) {
		System.debug('***** reId = ' + reId);
		System.debug('***** reType = ' + reType);
		System.debug('***** eventAction = ' + action);
		System.debug('***** actionType = ' + actionType);

		String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm();
		String serviceURL = '/services/data/v' + API_VERSION + '/sobjects/FinanceTransaction/';
		String restAPIURL = sfdcURL + serviceURL;
		Http http = new Http();
		HttpRequest httpRequest = new HttpRequest();
		httpRequest.setMethod('POST');
		//httpRequest.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
		//httpRequest.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
		httpRequest.setHeader('Content-Type', 'application/json');
		httpRequest.setEndpoint('callout:Salesforce1' + serviceURL);
		
		SObject record = getRecord(reId);

		FinanceTransaction ftx;

		if (reType == 'Invoice') {
			blng__Invoice__c inv = (blng__Invoice__c)record;
			ftx = new FinanceTransaction(inv, action, actionType);
		} else if (reType == 'Invoice Line') {
			blng__InvoiceLine__c invLine = (blng__InvoiceLine__c)record;
			ftx = new FinanceTransaction(invLine, action, actionType, reType);
		} else if (reType == 'Invoice Line Tax') {
			blng__InvoiceLine__c invLine = (blng__InvoiceLine__c)record;
			ftx = new FinanceTransaction(invLine, action, actionType, reType);
		} else if (reType == 'Payment') {
			blng__Payment__c pmt = (blng__Payment__c)record;
			ftx = new FinanceTransaction(pmt, action, actionType);
		} else if (reType == 'Credit Memo') {
			blng__CreditNote__c cn = (blng__CreditNote__c)record;
			ftx = new FinanceTransaction(cn, action, actionType);
		} else if (reType == 'Credit Memo Line') {
			blng__CreditNoteLine__c cnLine = (blng__CreditNoteLine__c)record;
		} else if (reType == 'Debit Memo') {
			blng__DebitNote__c dn = (blng__DebitNote__c)record;
			ftx = new FinanceTransaction(dn, action, actionType);
		} else if (reType == 'Debit Memo Line') {
			blng__DebitNoteLine__c dnLine = (blng__DebitNoteLine__c)record;
		} else if (reType == 'Payment Invoice Line Application') {
			blng__PaymentAllocationInvoiceLine__c pail = (blng__PaymentAllocationInvoiceLine__c)record;
			ftx = new FinanceTransaction(pail, action, actionType);
		}

		if (ftx != null) {
			//System.debug(JSON.serializePretty(ftx));
			httpRequest.setBody(getSerialized(ftx));
		}

		HttpResponse response = http.send(httpRequest);
		// Parse the JSON response
		if (response.getStatusCode() != 201) {
			System.debug('The status code returned was not expected: ' + response.getStatusCode()+' ' + response.getStatus());
		} else {
			System.debug(response.getBody());
		}
	}

	public static List<Id> doGet(Id accountId) {
		List<Id> idsToDel = new List<Id>();
		String account = '\'';
		String query = 'SELECT+Id+from+FinanceTransaction+WHERE+AccountId=\'' + accountId + '\'';
		String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm();
		String serviceURL = '/services/data/v' + API_VERSION + '/query/?q=' + query;
		String restAPIURL = sfdcURL + serviceURL;
		Http http = new Http();
		HttpRequest httpRequest = new HttpRequest();
		//httpRequest.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
		//httpRequest.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
		//httpRequest.setHeader('Content-Type', 'application/json');
		httpRequest.setMethod('GET');
		httpRequest.setEndpoint('callout:Salesforce1' + serviceURL);
		
		HttpResponse response = http.send(httpRequest);
		// Parse the JSON response
		if (response.getStatusCode() != 200) {
			System.debug('The status code returned was not expected: ' + response.getStatusCode()+' ' + response.getStatus());
		} else {
            RestQueryResponse r = RestQueryResponse.parse(response.getBody());
            System.debug(r.records.size());
            for (RestQueryResponse.Records record : r.records) {
                System.debug(record.Id);
                idsToDel.add(record.Id);
            }
        }
        System.debug(idsToDel.size());
		return idsToDel;
    }
    
	public static void doDelete(List<Id> ids) {
		String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm();
		for (Id id : ids) {
			String serviceURL = '/services/data/v' + API_VERSION + '/sobjects/FinanceTransaction/'+id;
            String restAPIURL = sfdcURL + serviceURL;
			Http http = new Http();
			HttpRequest httpRequest = new HttpRequest();
			//httpRequest.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
			//httpRequest.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
			httpRequest.setMethod('DELETE');
			httpRequest.setHeader('Content-Type', 'application/json');
			httpRequest.setEndpoint('callout:Salesforce1' + serviceURL);
			
			HttpResponse response = http.send(httpRequest);
		}
    }

    public static void doDeleteComposite(List<Id> ids) {
        String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm();
        if (ids.size() < 200 ) {       
			String serviceURL = '/services/data/v' + API_VERSION + '/composite/sobjects?ids=' + getJoin(ids);
            String restAPIURL = sfdcURL + serviceURL;
            Http http = new Http();
			HttpRequest httpRequest = new HttpRequest();
			//httpRequest.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
			//httpRequest.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
			httpRequest.setMethod('DELETE');
			httpRequest.setHeader('Content-Type', 'application/json');
			httpRequest.setEndpoint('callout:Salesforce1' + serviceURL);
			HttpResponse response = http.send(httpRequest);
        }
    }

    static String getJoin(List<Id> ids) {
        String idString = String.join(ids,',');
        return idString;
    }

	static SObject getRecord(Id recordId) {
		DescribeSObjectResult describeResult = recordId.getSObjectType().getDescribe();
		List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
		// Get all of the fields on the object
		String query = ' SELECT ' + String.join(fieldNames, ',')+' FROM ' + describeResult.getName()+' WHERE ' + 
						' id = :recordId ' + 
						' LIMIT 1 ';
		// Need to return a generic list of sObject because we don't necessarily know exactly what the object is.
		SObject record;
		try {
			List<sObject> records = Database.query(query);
			record = records[0];
			
		} catch(DmlException e) {
			System.debug('DmlException caught: ' + e.getMessage());    
		} catch(SObjectException e) {
			System.debug('SObjectException caught: ' + e.getMessage());    
		} catch(Exception e) {
			System.debug('Exception caught: ' + e.getMessage());    
		}
		return record;
	}

	static String getSerialized(FinanceTransaction ftx) {
		Map<String, Object> r = new Map<String, Object>();
		r.put('accountId', ftx.accountId);
		r.put('adjustmentAmount', ftx.adjustmentAmount);
		r.put('baseCurrencyAmount', ftx.baseCurrencyAmount);
		r.put('baseCurrencyBalance', ftx.baseCurrencyBalance);
		r.put('baseCurrencyFxDate', ftx.baseCurrencyFxDate);
		r.put('baseCurrencyFxRate', ftx.baseCurrencyFxRate);
		r.put('chargeAmount', ftx.chargeAmount);
		r.put('destinationEntityId', ftx.destinationEntityId);
		r.put('dueDate', ftx.dueDate);
		r.put('effectiveDate', ftx.effectiveDate);
		r.put('eventAction', ftx.eventAction);
		r.put('eventType', ftx.eventType);
		r.put('impactAmount', ftx.impactAmount);
		r.put('legalEntityId', ftx.legalEntityId);
		r.put('parentReferenceEntityId', ftx.parentReferenceEntityId);
		r.put('referenceEntityId', ftx.referenceEntityId);
		r.put('referenceEntityType', ftx.referenceEntityType);
		r.put('resultingBalance', ftx.resultingBalance);
		r.put('sourceEntityId', ftx.sourceEntityId);
		r.put('subtotal', ftx.subtotal);
		r.put('taxAmount', ftx.taxAmount);
		r.put('totalAmountWithTax', ftx.totalAmountWithTax);
		r.put('transactionDate', ftx.transactionDate);
		r.put('blng__CreditGLAccount__c', ftx.creditAccount);
		r.put('blng__DebitGLAccount__c', ftx.debitAccount);
		r.put('blng__FinanceBook__c', ftx.financeBook);
		r.put('blng__FinancePeriod__c', ftx.financePeriod);
		r.put('blng__GLRule__c', ftx.glRule);
		r.put('blng__GLTreatment__c', ftx.glTreatment);

/* 		r.put('OriginalCreditGlAccountName', ftx.creditAccountName);
		r.put('OriginalCreditGlAccountNumber', ftx.creditAccountNumber);
		r.put('OriginalDebitGlAccountName', ftx.debitAccountName);
		r.put('OriginalDebitGlAccountNumber', ftx.debitAccountNumber);
		r.put('OriginalGlRuleName', ftx.glRuleName);
		r.put('OriginalGlTreatmentName', ftx.glTreatmentName);
		r.put('OriginalFinancePeriodName', ftx.financePeriodName);
		r.put('OriginalFinancePeriodStartDate', ftx.financePeriodStartDate);
		r.put('OriginalFinancePeriodEndDate', ftx.financePeriodEndDate);
		r.put('OriginalFinancePeriodStatus', ftx.financePeriodStatus);
		r.put('OriginalFinanceBookName', ftx.financeBookName); */

		r.put('Original_Credit_GL_Account_Name__c', ftx.creditAccountName);
		r.put('Original_Credit_GL_Account_Number__c', ftx.creditAccountNumber);
		r.put('Original_Debit_GL_Account_Name__c', ftx.debitAccountName);
		r.put('Original_Debit_GL_Account_Number__c', ftx.debitAccountNumber);
		r.put('Original_GL_Rule_Name__c', ftx.glRuleName);
		r.put('Original_GL_Treatment_Name__c', ftx.glTreatmentName);
		r.put('Original_Finance_Period_Name__c', ftx.financePeriodName);
		r.put('Original_Finance_Period_Start_Date__c', ftx.financePeriodStartDate);
		r.put('Original_Finance_Period_End_Date__c', ftx.financePeriodEndDate);
		r.put('Original_Finance_Period_Status__c', ftx.financePeriodStatus);
		r.put('Original_Finance_Book_Name__c', ftx.financeBookName);

		return JSON.serialize(r);
	}

	static String getStringValue(Object theObj) {
		String strValue = String.valueOf(theObj);
		if (theObj instanceof Decimal) {
			strValue = ((Decimal)theObj).toPlainString();
		}
		// Prevent scientific notation
		return strValue;
	}

	class FinanceTransaction {
		String accountId;
		Decimal adjustmentAmount;
		Decimal baseCurrencyAmount;
		Decimal baseCurrencyBalance;
		Datetime baseCurrencyFxDate;
		Decimal baseCurrencyFxRate;
		String baseCurrencyIsoCode;
		Decimal chargeAmount;
		String destinationEntityId;
		Datetime dueDate;
		Datetime effectiveDate;
		String eventAction;
		String eventType;
		Decimal impactAmount;
		String legalEntityId;
		Id parentReferenceEntityId;
		Id referenceEntityId;
		String referenceEntityType;
		Decimal resultingBalance;
		String sourceEntityId;
		Decimal subtotal;
		Decimal taxAmount;
		Decimal totalAmountWithTax;
		Datetime transactionDate;
		Id financeBook;
		Id financePeriod;
		Id creditAccount;
		Id debitAccount;
		String creditAccountName;
		String creditAccountNumber;
		String debitAccountName;
		String debitAccountNumber;
		Id glRule;
		Id glTreatment;
		String glRuleName;
		String glTreatmentName;
		String financePeriodName;
		String financePeriodStartDate;
		String financePeriodEndDate;
		String financePeriodStatus;
		String financeBookName;
		FinanceTransaction(blng__Invoice__c inv, String action, String actionType) {
			accountId = inv.blng__Account__c;
			adjustmentAmount = null;
			baseCurrencyAmount = inv.blng__BaseCurrencyAmount__c;
			baseCurrencyBalance = null;
			baseCurrencyFxDate = inv.blng__BaseCurrencyFXDate__c;
			baseCurrencyFxRate = inv.blng__BaseCurrencyFXRate__c;
			baseCurrencyIsoCode = inv.CurrencyIsoCode;
			chargeAmount = inv.blng__Subtotal__c;
			destinationEntityId = null;
			dueDate = inv.blng__DueDate__c;
			effectiveDate = inv.blng__InvoicePostedDate__c;
			eventType = actionType;
			eventAction = action;
			impactAmount = inv.blng__ImpactAmount__c;
			legalEntityId = DEFAULT_LEGAL_ENTITY;
			parentReferenceEntityId = null;
			referenceEntityId = inv.Id;
			referenceEntityType = 'Invoice';
			resultingBalance = inv.blng__Balance__c;
			sourceEntityId = null;
			subtotal = inv.blng__Subtotal__c;
			taxAmount = inv.blng__TaxAmount__c;
			totalAmountWithTax = inv.blng__TotalAmount__c;
			transactionDate = inv.blng__InvoicePostedDate__c;
		}

		FinanceTransaction(blng__InvoiceLine__c invLine, String action, String actionType, String reType) {
			accountId = invLine.Account__c;
			adjustmentAmount = null;
			baseCurrencyAmount = invLine.blng__BaseCurrencyAmount__c;
			baseCurrencyBalance = null;
			baseCurrencyFxDate = invLine.blng__BaseCurrencyFXDate__c;
			baseCurrencyFxRate = invLine.blng__BaseCurrencyFXRate__c;
			baseCurrencyIsoCode = invLine.CurrencyIsoCode;
			chargeAmount = invLine.blng__Subtotal__c;
			destinationEntityId = null;
			dueDate = invLine.blng__DueDate__c;
			effectiveDate = invLine.blng__ChargeDate__c;
			eventAction = action;
			eventType = actionType;
			impactAmount = invLine.blng__ImpactAmount__c;
			legalEntityId = DEFAULT_LEGAL_ENTITY;
			parentReferenceEntityId = invLine.blng__Invoice__c;
			referenceEntityId = invLine.Id;
			referenceEntityType = reType;
			if (reType == 'Invoice Line') {
				subtotal = invLine.blng__Subtotal__c;
				totalAmountWithTax = invLine.blng__TotalAmount__c;
			} else if (reType == 'Invoice Line Tax') {
				totalAmountWithTax = invLine.blng__TaxAmount__c;
			}
			resultingBalance = invLine.blng__Balance__c;
			//sourceEntityId = invLine.blng__Invoice__c;
			taxAmount = invLine.blng__TaxAmount__c;
			transactionDate = invLine.blng__ChargeDate__c;
			if ((invLine.blng__BillingGLRule__c != null) && (invLine.blng__BillingGLTreatment__c != null) && (invLine.blng__BillingFinanceBook__c != null)) {

				blng__GLTreatment__c billTreatment = [Select 
				                                            Id, 
				                                            Name, blng__CreditGLAccount__c, 
				                                            blng__DebitGLAccount__c
				                                      from blng__GLTreatment__c 
				                                      where Id = :invLine.blng__BillingGLTreatment__c];
				blng__GLTreatment__c taxBillTreatment = [Select 
				                                               Id, 
				                                               Name, blng__CreditGLAccount__c, 
				                                               blng__DebitGLAccount__c
				                                         from blng__GLTreatment__c 
				                                         where Id = :invLine.blng__TaxGLTreatment__c];
				blng__GLRule__c billRule = [Select 
				                                  Id, 
				                                  Name
				                            from blng__GLRule__c 
				                            where Id = :invLine.blng__BillingGLRule__c];
				blng__GLRule__c taxBillRule = [Select 
				                                     Id, 
				                                     Name
				                               from blng__GLRule__c 
				                               where Id = :invLine.blng__TaxGLRule__c];

				List<Id> glAccountIds = new List<Id>();
				//glAccountIds.add(billtreatment.blng__CreditGLAccount__c);
				//glAccountIds.add(billtreatment.blng__DebitGLAccount__c);
				/*              Map<String,Id> glAccountMap = new Map<String,Id>();
				 glAccountMap.put('Credit',billTreatment.blng__CreditGLAccount__c);
				 glAccountMap.put('Debit',billTreatment.blng__DebitGLAccount__c); */
				List<blng__GLAccount__c> glAccounts = [SELECT 
				                                             Id, 
				                                             Name, blng__GLAccountNumber__c
				                                       FROM blng__GLAccount__c 
				                                       where Id IN :glAccountIds];
				for (blng__GLAccount__c glAccount : glAccounts) {
					System.debug('*** GL Account Id : ' + glAccount.Id);
					System.debug('*** GL Account Name : ' + glAccount.Name);
					System.debug('*** GL Account Number : ' + glAccount.blng__GLAccountNumber__c);
				}
				blng__GLAccount__c creditAct;
				blng__GLAccount__c debitAct;
				if (reType == 'Invoice Line') {
					glRule = invLine.blng__BillingGLRule__c;
					glTreatment = invLine.blng__BillingGLTreatment__c;
					glRuleName = billRule.Name;
					glTreatmentName = billTreatment.Name;
					creditAccount = billTreatment.blng__CreditGLAccount__c;
					debitAccount = billTreatment.blng__DebitGLAccount__c;
					creditAct = [Select 
					                   Id, 
					                   Name, blng__GLAccountNumber__c
					             from blng__GLAccount__c 
					             where Id = :billTreatment.blng__CreditGLAccount__c];
					debitAct = [Select 
					                  Id, 
					                  Name, blng__GLAccountNumber__c
					            from blng__GLAccount__c 
					            where Id = :billTreatment.blng__DebitGLAccount__c];
					creditAccountName = creditAct.Name;
					creditAccountNumber = creditAct.blng__GLAccountNumber__c;
					debitAccountName = debitAct.Name;
					debitAccountNumber = debitAct.blng__GLAccountNumber__c;
				} else if (reType == 'Invoice Line Tax') {
					glRule = invLine.blng__TaxGLRule__c;
					glTreatment = invLine.blng__TaxGLTreatment__c;
					glRuleName = taxBillRule.Name;
					glTreatmentName = taxBillTreatment.Name;
					creditAccount = taxBillTreatment.blng__CreditGLAccount__c;
					debitAccount = taxBillTreatment.blng__DebitGLAccount__c;
					creditAct = [Select 
					                   Id, 
					                   Name, blng__GLAccountNumber__c
					             from blng__GLAccount__c 
					             where Id = :taxBillTreatment.blng__CreditGLAccount__c];
					debitAct = [Select 
					                  Id, 
					                  Name, blng__GLAccountNumber__c
					            from blng__GLAccount__c 
					            where Id = :taxBillTreatment.blng__DebitGLAccount__c];
					creditAccountName = creditAct.Name;
					creditAccountNumber = creditAct.blng__GLAccountNumber__c;
					debitAccountName = debitAct.Name;
					debitAccountNumber = debitAct.blng__GLAccountNumber__c;
				}
				financeBook = invLine.blng__BillingFinanceBook__c;
				financePeriod = invLine.blng__BillingFinancePeriod__c;
				blng__FinancePeriod__c financePeriod = [Select 
				                                              Id, 
				                                              Name, blng__PeriodStartDate__c, 
				                                              blng__PeriodEndDate__c, 
				                                              blng__PeriodStatus__c
				                                        from blng__FinancePeriod__c 
				                                        where Id = :invLine.blng__BillingFinancePeriod__c];
				blng__FinanceBook__c financeBook = [Select 
				                                          Id, 
				                                          Name
				                                    from blng__FinanceBook__c 
				                                    where Id = :invLine.blng__BillingFinanceBook__c];
				financePeriodName = financePeriod.Name;
				financePeriodStartDate = financePeriod.blng__PeriodStartDate__c.format();
				financePeriodEndDate = financePeriod.blng__PeriodEndDate__c.format();
				financePeriodStatus = financePeriod.blng__PeriodStatus__c;
				financeBookName = financeBook.Name;
			}
		}

		FinanceTransaction(blng__Payment__c pmt, String action, String actionType) {
			accountId = pmt.blng__Account__c;
			adjustmentAmount = null;
			baseCurrencyAmount = pmt.blng__BaseCurrencyAmount__c;
			baseCurrencyBalance = null;
			baseCurrencyFxDate = pmt.blng__BaseCurrencyFXDate__c;
			baseCurrencyFxRate = pmt.blng__BaseCurrencyFXRate__c;
			baseCurrencyIsoCode = pmt.CurrencyIsoCode;
			chargeAmount = null;
			destinationEntityId = null;
			dueDate = null;
			effectiveDate = pmt.blng__PaymentDate__c;
			if (pmt.blng__Invoice__c == null) {
				eventAction = 'Post a standalone payment';
			} else {
				eventAction = 'Pay invoice line';
			}
			eventType = actionType;
			impactAmount = pmt.blng__ImpactAmount__c;
			if (pmt.blng__LegalEntity__c == null) {
				legalEntityId = DEFAULT_LEGAL_ENTITY;
			} else {
				legalEntityId = pmt.blng__LegalEntity__c;
			}
			parentReferenceEntityId = null;
			referenceEntityId = pmt.Id;
			referenceEntityType = 'Payment';
			resultingBalance = pmt.blng__Balance__c;
			sourceEntityId = null;
			subtotal = null;
			taxAmount = null;
			totalAmountWithTax = pmt.blng__Amount__c;
			transactionDate = pmt.blng__PaymentDate__c;
			if ((pmt.blng__GLRule__c != null) && (pmt.blng__GLTreatment__c != null)) {
				glRule = pmt.blng__GLRule__c;
				glTreatment = pmt.blng__GLTreatment__c;
				financeBook = pmt.blng__BillingFinanceBook__c;
			}
		}

		FinanceTransaction(blng__PaymentAllocationInvoiceLine__c pail, String action, String actionType) {
			accountId = pail.AccountId__c;
			totalAmountWithTax = pail.blng__Amount__c;
			impactAmount = pail.blng__ImpactAmount__c;
			referenceEntityId = pail.Id;
			referenceEntityType = 'Payment invoice line application';
			eventAction = 'Pay invoice line';
			eventType = 'Allocated';
			destinationEntityId = pail.blng__InvoiceLine__c;
			sourceEntityId = pail.blng__Payment__c;
			legalEntityId = DEFAULT_LEGAL_ENTITY;
			financeBook = pail.blng__BillingFinanceBook__c;
			financePeriod = pail.blng__BillingFinancePeriod__c;
			parentReferenceEntityId = pail.blng__Payment__c;
			effectiveDate = pail.CreatedDate;
			transactionDate = pail.CreatedDate;
		}

		FinanceTransaction(blng__CreditNote__c cn, String action, String actionType) {
			accountId = cn.blng__Account__c;
			adjustmentAmount = null;
			baseCurrencyAmount = cn.blng__BaseCurrencyAmount__c;
			baseCurrencyBalance = null;
			baseCurrencyFxDate = cn.blng__BaseCurrencyFXDate__c;
			baseCurrencyFxRate = cn.blng__BaseCurrencyFXRate__c;
			baseCurrencyIsoCode = cn.blng__BaseCurrency__c;
			chargeAmount = cn.blng__Subtotal__c;
			destinationEntityId = null;
			dueDate = null;
			effectiveDate = cn.blng__CreditNoteDate__c;
			eventAction = 'Issue a standalone credit';
			eventType = 'Allocated';
			impactAmount = cn.blng__ImpactAmount__c;
			legalEntityId = DEFAULT_LEGAL_ENTITY;
			referenceEntityId = cn.Id;
			referenceEntityType = 'Credit Memo';
			resultingBalance = cn.blng__Balance__c;
			sourceEntityId = null;
			subtotal = cn.blng__Subtotal__c;
			taxAmount = cn.blng__TaxAmount__c;
			totalAmountWithTax = cn.blng__TotalAmount__c;
			transactionDate = cn.blng__CreditNoteDate__c;
		}

		FinanceTransaction(blng__CreditNoteLine__c cnl, String action, String actionType) {
			accountId = cnl.blng__BillToAccount__c;
			adjustmentAmount = null;
			baseCurrencyAmount = cnl.blng__BaseCurrencyAmount__c;
			baseCurrencyBalance = null;
			baseCurrencyFxDate = cnl.blng__BaseCurrencyFXDate__c;
			baseCurrencyFxRate = cnl.blng__BaseCurrencyFXRate__c;
			baseCurrencyIsoCode = cnl.blng__BaseCurrency__c;
			chargeAmount = cnl.blng__Subtotal__c;
			destinationEntityId = cnl.blng__InvoiceLine__c;
			dueDate = null;
			effectiveDate = cnl.blng__StartDate__c;
			eventAction = 'Issue a standalone credit';
			eventType = 'Allocated';
			impactAmount = cnl.blng__ImpactAmount__c;
			legalEntityId = DEFAULT_LEGAL_ENTITY;
			referenceEntityId = cnl.Id;
			referenceEntityType = 'Credit Memo Line';
			resultingBalance = cnl.blng__Balance__c;
			sourceEntityId = null;
			subtotal = cnl.blng__Subtotal__c;
			taxAmount = cnl.blng__TaxAmount__c;
			totalAmountWithTax = cnl.blng__TotalAmount__c;
			transactionDate = cnl.blng__CreditNoteLineDate__c;
		}


		FinanceTransaction(blng__DebitNote__c dn, String action, String actionType) {
			accountId = dn.blng__Account__c;
			adjustmentAmount = null;
			baseCurrencyAmount = dn.blng__BaseCurrencyAmount__c;
			baseCurrencyBalance = null;
			baseCurrencyFxDate = dn.blng__BaseCurrencyFXDate__c;
			baseCurrencyFxRate = dn.blng__BaseCurrencyFXRate__c;
			baseCurrencyIsoCode = null;
			chargeAmount = dn.blng__Subtotal__c;
			destinationEntityId = null;
			dueDate = null;
			effectiveDate = dn.blng__DebitNoteDate__c;
			eventAction = 'Issue a standalone debit';
			eventType = 'Posted';
			impactAmount = dn.blng__ImpactAmount__c;
			legalEntityId = DEFAULT_LEGAL_ENTITY;
			referenceEntityId = dn.Id;
			referenceEntityType = 'Debit Note';
			resultingBalance = dn.blng__Balance__c;
			sourceEntityId = null;
			subtotal = dn.blng__Subtotal__c;
			taxAmount = dn.blng__TaxAmount__c;
			totalAmountWithTax = dn.blng__TotalAmount__c;
			transactionDate = dn.blng__DebitNoteDate__c;
		}
	}
}