public with sharing class RecognizeRevenueService {
    public RecognizeRevenueService() {
        OrderItem oi;
    }

    @future(callout = true)
    public static void doPost(Id reId, String reType) {
        Http http = new Http();
		HttpRequest httpRequest = new HttpRequest();
		httpRequest.setMethod('POST');
		httpRequest.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
		httpRequest.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setEndpoint(buildRestAPIURL());

        SObject record = getRecord(reId);
        if (reType == 'blng__OrderProduct__c') {
            OrderItem oi = (OrderItem)record;
            RevenueSchedule rs = new RevenueSchedule(oi);
            httpRequest.setBody(JSON.serialize(rs));
            System.debug(JSON.serializePretty(rs));
        }

        if (reType == 'SBQQ__QuoteLine__c') {
            SBQQ__QuoteLine__c ql = (SBQQ__QuoteLine__c)record;
            RevenueSchedule rs = new RevenueSchedule(ql);
            httpRequest.setBody(JSON.serialize(rs));
            System.debug(JSON.serializePretty(rs));
        }

        HttpResponse response = http.send(httpRequest);
		// Parse the JSON response
		if (response.getStatusCode() != 200) {
			System.debug('The status code returned was not expected: ' + response.getStatusCode()+' ' + response.getStatus());
		} else {
			System.debug(response.getBody());
/* 			Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
			Map<String, Object> assets = (Map<String, Object>)m.get('asset');
			if (assets != null) {
				for (String id : assets.keySet()) {
					//AssetResponse ar = (AssetResponse) asset;
					System.debug('*****RESPONSE CALM Asset = ' + assets.get(id));
					assetId = (Id)assets.get(id);
					//return (AssetResponse) System.JSON.deserialize(response.getBody(), AssetResponse.class)
				}
			} */

		}
    }

    static String buildRestAPIURL() {
		String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm();
		String restAPIURL = sfdcURL + '/services/data/v51.0/actions/custom/apex/blng__RevenueRecognition';
		return restAPIURL;
    }
    
    static SObject getRecord(Id recordId) {
		DescribeSObjectResult describeResult = recordId.getSObjectType().getDescribe();
		List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
		// Get all of the fields on the object
		String query = ' SELECT ' + String.join(fieldNames, ',')+' FROM ' + describeResult.getName()+' WHERE ' + 
						' id = :recordId ' + 
						' LIMIT 1 ';
		// Need to return a generic list of sObject because we don't necessarily know exactly what the object is.
		List<sObject> records = Database.query(query);
		SObject record = records[0];
		return record;
	}

    static String getSerialized(RevenueSchedule rs){
        Map<String, Object> r = new Map<String, Object>();
        r.put('inputs', rs.inputs);
        return JSON.serialize(r);
    }

    public class RevenueSchedule {
        List<RevenueScheduleInputs> inputs;

        RevenueSchedule(OrderItem oi) {
            inputs = getInputs(oi);
        }

        List<RevenueScheduleInputs> getInputs(OrderItem oi) {
            List<RevenueScheduleInputs> inputs = new List<RevenueScheduleInputs>();
            inputs.add(new RevenueScheduleInputs(oi));
            return inputs;
        }

        RevenueSchedule(SBQQ__QuoteLine__c ql) {
            inputs = getInputs(ql);
        }

        List<RevenueScheduleInputs> getInputs(SBQQ__QuoteLine__c ql) {
            List<RevenueScheduleInputs> inputs = new List<RevenueScheduleInputs>();
            inputs.add(new RevenueScheduleInputs(ql));
            return inputs;
        }
    }

    public class RevenueScheduleInputs {
        String currencyIsoCode;
        Id legalEntityID;
        Decimal revenueAmount;
        Id revenueRecognitionRuleId;
        Id source;
        String sourceFieldname;
        Date startDate;
        Date endDate;
        RevenueScheduleInputs(OrderItem oi) {
            currencyIsoCode = oi.CurrencyIsoCode;
            legalEntityID = oi.blng__LegalEntity__c;
            revenueAmount = oi.TotalPrice;
            revenueRecognitionRuleId = oi.blng__RevenueRecognitionRule__c;
            source = oi.Id;
            sourceFieldname = 'blng__OrderProduct__c';
            startDate = oi.ServiceDate;
            endDate = oi.EndDate;
            //startDate = oi.ServiceDate.year()+'-'+oi.ServiceDate.month()+'-'+oi.ServiceDate.day();
            //endDate = oi.EndDate.year()+'-'+oi.EndDate.month()+'-'+oi.EndDate.day();
        }
        RevenueScheduleInputs(SBQQ__QuoteLine__c ql) {
            currencyIsoCode = ql.CurrencyIsoCode;
            legalEntityID = ql.LegalEntity__c;
            revenueAmount = ql.RevenueAmount__c;
            revenueRecognitionRuleId = ql.Revenue_Recognition_Rule__c;
            source = ql.Id;
            sourceFieldname = 'Quote_Line__c';
            startDate = ql.SBQQ__EffectiveStartDate__c;
            endDate = ql.SBQQ__EffectiveEndDate__c;
            //startDate = oi.ServiceDate.year()+'-'+oi.ServiceDate.month()+'-'+oi.ServiceDate.day();
            //endDate = oi.EndDate.year()+'-'+oi.EndDate.month()+'-'+oi.EndDate.day();
        }

    }
}