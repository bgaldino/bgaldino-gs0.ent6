public class AssetManagementAPI {
   public String accountId;
   public String assetName;
   public Id productId;
   public String currencyIsoCode;
   public List<AssetStatePeriodWrapper> assetStatePeriods;
   public AssetAction assetAction;
   public List<AssetActionSource> assetActionSources;
   public AssetResponse assetResponse;

   public static final String API_VERSION = '53.0';

   public static Id assetId { get; set; }

   public enum apiAction {
      GENERATE,
      CHANGE,
      CANCEL
   }

   public AssetManagementAPI() {
      //    Asset asset;
      SBQQ__Subscription__c subscription;
      OrderItem oi;
      //Id assetID;
   }

   @Future(Callout = true)
   public static void doPost(Id reId, String reType, String action) {
      OrderItem oi;
      System.debug('***** reId = ' + reId);
      System.debug('***** reType = ' + reType);
      System.debug('***** reType = ' + action);
      //String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm();
      //String restAPIURL = sfdcURL + '/services/data/v' + API_VERSION + '/asset-management/actions/generate';

      SObject record = getRecord(reId);
      Id assetId;
      if (reType == 'OrderItem') {
         System.debug('***** reType = OrderItem');
         oi = (OrderItem) record;

      }


      Http http = new Http();
      HttpRequest httpRequest = new HttpRequest();
      httpRequest.setMethod('POST');
      httpRequest.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
      httpRequest.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
      httpRequest.setHeader('Content-Type', 'application/json');
//        httpRequest.setEndpoint(buildRestAPIURL());

/*
        AssetWrapper aw = new AssetWrapper(oi);
        httpRequest.setBody(JSON.serialize(aw));
        System.debug('Request Body: ' + httpRequest.getBody());
        System.debug(JSON.serializePretty(aw));
        System.debug(getSerialized(aw));
*/

      if (action == 'generate') {
         AssetWrapper aw = new AssetWrapper(oi);
         httpRequest.setBody(JSON.serialize(aw));
         System.debug('Request Body: ' + httpRequest.getBody());
         System.debug(JSON.serializePretty(aw));
         System.debug(getSerialized(aw));

         httpRequest.setEndpoint(buildGenerateRestAPIURL());

      } else if (action == 'change') {
         InstallBaseAssetWrapper ibaw = new InstallBaseAssetWrapper(oi);
         httpRequest.setBody(JSON.serialize(ibaw));
         System.debug('Request Body: ' + httpRequest.getBody());
         System.debug(JSON.serializePretty(ibaw));

         httpRequest.setEndpoint(buildChangeRestAPIURL(oi.blng__Asset__c));
      } else if (action == 'renew') {
         RenewalBaseAssetWrapper rbaw = new RenewalBaseAssetWrapper(oi);
         httpRequest.setBody(JSON.serialize(rbaw));
         System.debug('Request Body: ' + httpRequest.getBody());
         System.debug(JSON.serializePretty(rbaw));

         httpRequest.setEndpoint(buildChangeRestAPIURL(oi.blng__Asset__c));
      } else if (action == 'cancel') {
         httpRequest.setEndpoint(buildCancelRestAPIURL(oi.blng__Asset__c));
      }


      HttpResponse response = http.send(httpRequest);
      // Parse the JSON response
      if (response.getStatusCode() != 201) {
         System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus());
      } else {
         System.debug(response.getBody());
         Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
         Map<String, Object> assets = (Map<String, Object>) m.get('asset');
         if (assets != null) {
            for (String id : assets.keySet()) {
               //AssetResponse ar = (AssetResponse) asset;
               System.debug('*****RESPONSE CALM Asset = ' + assets.get(id));
               assetId = (Id) assets.get(id);
               oi.blng__Asset__c = assetId;
               //return (AssetResponse) System.JSON.deserialize(response.getBody(), AssetResponse.class)
            }
         }

      }
   }

   public class AssetResponse {
      public String id;
   }

   static String buildRestAPIURL() {
      String sfdcURL = Url.getSalesforceBaseUrl().toExternalForm();
      String restAPIURL = sfdcURL + '/services/data/v' + API_VERSION + '/asset-management/assets/actions/generate';
      return restAPIURL;
   }

   static String buildGenerateRestAPIURL() {
      String sfdcURL = Url.getSalesforceBaseUrl().toExternalForm();
      String restAPIURL = sfdcURL + '/services/data/v' + API_VERSION + '/asset-management/assets/actions/generate';
      return restAPIURL;
   }

   static String buildChangeRestAPIURL(Id assetId) {
      String sfdcURL = Url.getSalesforceBaseUrl().toExternalForm();
      String restAPIURL = sfdcURL + '/services/data/v' + API_VERSION + '/asset-management/assets/' + assetId + '/actions/change';
      System.debug('URL posted to was ' + restAPIURL);
      return restAPIURL;
   }

   static String buildCancelRestAPIURL(Id assetId) {
      String sfdcURL = Url.getSalesforceBaseUrl().toExternalForm();
      String restAPIURL = sfdcURL + '/services/data/v' + API_VERSION + '/asset-management/assets/' + assetId + '/actions/cancel';
      return restAPIURL;
   }

   static SObject getRecord(Id recordId) {
      DescribeSObjectResult describeResult = recordId.getSobjectType().getDescribe();
      List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
      // Get all of the fields on the object
      String query = ' SELECT ' + String.join(fieldNames, ',') + ' FROM ' + describeResult.getName() + ' WHERE ' +
          ' id = :recordId ' +
          ' LIMIT 1 ';
      // Need to return a generic list of sObject because we don't necessarily know exactly what the object is.
      List<SObject> records = Database.query(query);
      SObject record = records[0];
      return record;
   }

   void generateAsset() {
   }

   void changeAsset() {
   }

   void cancelAsset() {
   }

   OrderItem getOrderItem(OrderItem oi) {
      OrderItem fullOi;
      List<OrderItem> itemsWithCurrentDetails = [
          SELECT
              Id,
              OrderId,
              blng__BillingRule__c, blng__TaxRule__c, SBQQ__Asset__c,
              blng__Asset__c,
              Quantity,
              ServiceDate,
              EndDate,
              TotalLineAmount,
              Product_Name__c,
              CurrencyIsoCode,
              blng__BilledTax__c,
              MRR__c
          FROM OrderItem
          WHERE Id = :oi.Id
      ];
      if (itemsWithCurrentDetails[0].Id != null) {
         return itemsWithCurrentDetails[0];
      } else {
         return fullOi;
      }
   }

   static String getSerialized(AssetWrapper aw) {
      Map<String, Object> r = new Map<String, Object>();
      r.put('accountId', aw.accountId);
      r.put('assetName', aw.assetName);
      r.put('productId', aw.productId);
      r.put('currencyIsoCode', aw.currencyIsoCode);
      r.put('assetStatePeriods', aw.assetStatePeriods);
      r.put('assetAction', aw.assetAction);
      r.put('assetActionSources', aw.assetActionSources);
      return JSON.serialize(r);
   }

   class AssetWrapper {
      Id accountId;
      String assetName;
      Id productId;
      String currencyIsoCode;
      //Double quantity;
      //Double mrr;
      //Double actualTax;
      //Double estimatedTax;
      List<AssetStatePeriodWrapper> assetStatePeriods;
      AssetAction assetAction;
      List<AssetActionSource> assetActionSources;
      AssetWrapper(OrderItem oi) {
         accountId = oi.blng__BillingAccount__c;
         assetName = oi.Product_Name__c;
         productId = oi.Product2Id;
         currencyIsoCode = oi.CurrencyIsoCode;
         assetStatePeriods = getAssetStatePeriods(oi);
         assetAction = new AssetAction(oi);
         assetActionSources = getAssetActionSources(oi);
         //quantity = oi.Quantity;
         //mrr = oi.MRR__c;
         //estimatedTax = oi.blng__BilledTax__c;
         //actualTax = oi.blng__BilledTax__c;
      }

      List<AssetStatePeriodWrapper> getAssetStatePeriods(OrderItem oi) {
         List<AssetStatePeriodWrapper> asps = new List<AssetStatePeriodWrapper>();
         asps.add(new AssetStatePeriodWrapper(oi.ServiceDate, oi.EndDate, oi.Quantity, oi.TotalPrice, oi.MRR__c));
         return asps;
      }

      List<AssetActionSource> getAssetActionSources(OrderItem oi) {
         List<AssetActionSource> aas = new List<AssetActionSource>();
         aas.add(new AssetActionSource(oi));
         return aas;
      }
   }

   class InstallBaseAssetWrapper {
//        Id accountId;
//        String assetName;
//        Id productId;
//        String currencyIsoCode;
      //Double quantity;
      //Double mrr;
      //Double actualTax;
      //Double estimatedTax;
      List<ExistingAssetStatePeriodWrapper> assetStatePeriods;
      AssetAction assetAction;
      List<AssetActionSource> assetActionSources;
      InstallBaseAssetWrapper(OrderItem oi) {
//            accountId = oi.blng__BillingAccount__c;
//            assetName = oi.Product_Name__c;
//            productId = oi.Product2Id;
//            currencyIsoCode = oi.CurrencyIsoCode;
         assetStatePeriods = getExistingAssetStatePeriods(oi);
         assetAction = new AssetAction(oi);
         assetActionSources = getAssetActionSources(oi);
         //quantity = oi.Quantity;
         //mrr = oi.MRR__c;
         //estimatedTax = oi.blng__BilledTax__c;
         //actualTax = oi.blng__BilledTax__c;
      }

      List<ExistingAssetStatePeriodWrapper> getExistingAssetStatePeriods(OrderItem oi) {

         List<ExistingAssetStatePeriodWrapper> asps = new List<ExistingAssetStatePeriodWrapper>();
         //            asps.add(new AssetStatePeriod(oi));
         Asset a = [
             SELECT Id
             FROM Asset
             WHERE Id = :oi.blng__Asset__c
         ].get(0);

         System.debug('Asset Id is ' + a.Id);

         List<AssetStatePeriod> eASPs = [
             SELECT Id, AssetId, Quantity,
                 StartDate, EndDate, Mrr
             FROM AssetStatePeriod
             WHERE AssetId = :a.Id
         ];

         Date sd = oi.ServiceDate;
         Date ed = oi.EndDate;

         System.debug('OI Start Date is ' + sd);
         System.debug('OI End Date is ' + ed);

         List<Datetime> periodDateTimes = new List<Datetime>();
         periodDateTimes = processDatePeriods(sd, ed, eASPs);

         System.debug('Period date count is ' + periodDateTimes.size());
         System.debug('Period dates are ' + periodDateTimes);

         for (Integer i = 0; i < periodDateTimes.size() - 1; i++) {
            System.debug('Integer i is ' + i);
            Datetime sDate = periodDateTimes.get(i);
            System.debug('sDate is ' + periodDateTimes.get(i));
            Datetime eDate = periodDateTimes.get(i + 1).addSeconds(-1);
            System.debug('eDate is ' + periodDateTimes.get(i + 1).addSeconds(-1));

            AssetStatePeriod rASP = [
                SELECT Id, AssetId, Quantity,
                    StartDate, EndDate, Mrr, Amount
                FROM AssetStatePeriod
                WHERE (StartDate <= :sDate AND AssetId = :a.Id)
                ORDER BY StartDate DESC
            ].get(0);

            Decimal rQty = rASP.Quantity;
            System.debug('rASP Quantity is ' + rASP.Quantity);

            Decimal rMRR = rASP.Mrr;
            System.debug('rASP MRR is ' + rASP.Mrr);

            Decimal rAmount = rASP.Amount;
            System.debug('rASP Amount is ' + rASP.Amount);

            Decimal nQty = 0;
            Decimal nMRR = 0;
            Decimal nAmount = 0;

            if (sDate >= oi.ServiceDate) {
               nQty = rQty + oi.Quantity;
               nMRR = rMRR + oi.MRR__c;
               nAmount = rAmount + oi.TotalPrice;
            } else {
               nQty = rQty;
               nMRR = rMRR;
               nAmount = rAmount;
            }
            ExistingAssetStatePeriodWrapper aspw = new ExistingAssetStatePeriodWrapper(sDate, eDate, nQty, nAmount, nMRR);

            System.debug(sDate + ' ' + eDate + ' ' + nQty + ' ' + nAmount + ' ' + nMRR);

            asps.add(aspw);
         }

         return asps;

      }

      List<AssetActionSource> getAssetActionSources(OrderItem oi) {
         List<AssetActionSource> aas = new List<AssetActionSource>();
         aas.add(new AssetActionSource(oi));
         return aas;
      }
//METHODS
      public Datetime processStartDateTime(Date sDate) {
         return Datetime.newInstanceGmt(sDate.year(), sDate.month(), sDate.day(), 0, 0, 0);
      }

      public Datetime processEndDateTime(Date eDate) {
         return Datetime.newInstanceGmt(eDate.year(), eDate.month(), eDate.day(), 23, 59, 59);
      }

      public Date convertDateTime(Datetime dT) {
         return Date.newInstance(dT.year(), dT.month(), dT.day());
      }

      public List<Datetime> processDatePeriods(Date sd, Date ed, List<AssetStatePeriod> easps) {
         Set<Datetime> dateTimeSet = new Set<Datetime>();

         dateTimeSet.add(processStartDateTime(sd));
         dateTimeSet.add(processEndDateTime(ed).addSeconds(1));
         //dateTimeSet.add(processEndDateTime(ed));

         System.debug('SD date input is ' + processStartDateTime(sd));
         System.debug('ED date input is ' + processEndDateTime(ed).addSeconds(1));
         //system.debug('ED date input is ' + processEndDateTime(ed));


         for (AssetStatePeriod easp : easps) {
            dateTimeSet.add(easp.StartDate);
            dateTimeSet.add((easp.EndDate).addSeconds(1));

            System.debug('EA SD date input is ' + easp.StartDate);
            System.debug('EA ED date input is ' + (easp.EndDate).addSeconds(1));

         }

         List<Datetime> dateList = new List<Datetime>();
         dateList.addAll(dateTimeSet);
         dateList.sort();

         return dateList;
      }
//METHODS END
   }

//RENEWAL LOGIC

   class RenewalBaseAssetWrapper {
//        Id accountId;
//        String assetName;
//        Id productId;
//        String currencyIsoCode;
      //Double quantity;
      //Double mrr;
      //Double actualTax;
      //Double estimatedTax;
      List<ExistingAssetStatePeriodWrapper> assetStatePeriods;
      RenewalAssetAction assetAction;
      List<AssetActionSource> assetActionSources;
      RenewalBaseAssetWrapper(OrderItem oi) {
//            accountId = oi.blng__BillingAccount__c;
//            assetName = oi.Product_Name__c;
//            productId = oi.Product2Id;
//            currencyIsoCode = oi.CurrencyIsoCode;
         assetStatePeriods = getRenewalAssetStatePeriods(oi);
         assetAction = new RenewalAssetAction(oi);
         assetActionSources = getAssetActionSources(oi);
         //quantity = oi.Quantity;
         //mrr = oi.MRR__c;
         //estimatedTax = oi.blng__BilledTax__c;
         //actualTax = oi.blng__BilledTax__c;
      }

      List<ExistingAssetStatePeriodWrapper> getRenewalAssetStatePeriods(OrderItem oi) {

         List<ExistingAssetStatePeriodWrapper> asps = new List<ExistingAssetStatePeriodWrapper>();
         //            asps.add(new AssetStatePeriod(oi));
         Asset a = [
             SELECT Id
             FROM Asset
             WHERE Id = :oi.blng__Asset__c
         ].get(0);

         System.debug('Asset Id is ' + a.Id);

         List<AssetStatePeriod> eASPs = [
             SELECT Id, AssetId, Quantity,
                 StartDate, EndDate, Mrr
             FROM AssetStatePeriod
             WHERE AssetId = :a.Id
         ];

         Date sd = oi.ServiceDate;
         Date ed = oi.EndDate;

         System.debug('OI Start Date is ' + sd);
         System.debug('OI End Date is ' + ed);

         List<Datetime> periodDateTimes = new List<Datetime>();
         periodDateTimes = processDatePeriods(sd, ed, eASPs);

         System.debug('Period date count is ' + periodDateTimes.size());
         System.debug('Period dates are ' + periodDateTimes);

         for (Integer i = 0; i < periodDateTimes.size() - 1; i++) {
            System.debug('Integer i is ' + i);
            Datetime sDate = periodDateTimes.get(i);
            System.debug('sDate is ' + periodDateTimes.get(i));
            Datetime eDate = periodDateTimes.get(i + 1).addSeconds(-1);
            System.debug('eDate is ' + periodDateTimes.get(i + 1).addSeconds(-1));

            AssetStatePeriod rASP = [
                SELECT Id, AssetId, Quantity,
                    StartDate, EndDate, Mrr, Amount
                FROM AssetStatePeriod
                WHERE (StartDate <= :sDate AND AssetId = :a.Id)
                ORDER BY StartDate DESC
            ].get(0);

            Decimal rQty = rASP.Quantity;
            System.debug('rASP Quantity is ' + rASP.Quantity);

            Decimal rMRR = rASP.Mrr;
            System.debug('rASP MRR is ' + rASP.Mrr);

            Decimal rAmount = rASP.Amount;
            System.debug('rASP Amount is ' + rASP.Amount);

            Decimal nQty = 0;
            Decimal nMRR = 0;
            Decimal nAmount = 0;

            if (eDate >= oi.ServiceDate) {
               nQty = oi.Quantity;
               nMRR = oi.MRR__c;
               nAmount = oi.TotalPrice;
            } else {
               nQty = rQty;
               nMRR = rMRR;
               nAmount = rAmount;
            }
            ExistingAssetStatePeriodWrapper aspw = new ExistingAssetStatePeriodWrapper(sDate, eDate, nQty, nAmount, nMRR);

            System.debug(sDate + ' ' + eDate + ' ' + nQty + ' ' + nAmount + ' ' + nMRR);

            asps.add(aspw);
         }

         return asps;

      }

      List<AssetActionSource> getAssetActionSources(OrderItem oi) {
         List<AssetActionSource> aas = new List<AssetActionSource>();
         aas.add(new AssetActionSource(oi));
         return aas;
      }
      //METHODS
      public Datetime processStartDateTime(Date sDate) {
         return Datetime.newInstanceGmt(sDate.year(), sDate.month(), sDate.day(), 0, 0, 0);
      }

      public Datetime processEndDateTime(Date eDate) {
         return Datetime.newInstanceGmt(eDate.year(), eDate.month(), eDate.day(), 23, 59, 59);
      }

      public Date convertDateTime(Datetime dT) {
         return Date.newInstance(dT.year(), dT.month(), dT.day());
      }

      public List<Datetime> processDatePeriods(Date sd, Date ed, List<AssetStatePeriod> easps) {
         Set<Datetime> dateTimeSet = new Set<Datetime>();

         dateTimeSet.add(processStartDateTime(sd));
         dateTimeSet.add(processEndDateTime(ed).addSeconds(1));
         //dateTimeSet.add(processEndDateTime(ed));

         System.debug('SD date input is ' + processStartDateTime(sd));
         System.debug('ED date input is ' + processEndDateTime(ed).addSeconds(1));
         //system.debug('ED date input is ' + processEndDateTime(ed));


         for (AssetStatePeriod easp : easps) {
            dateTimeSet.add(easp.StartDate);
            dateTimeSet.add((easp.EndDate).addSeconds(1));

            System.debug('EA SD date input is ' + easp.StartDate);
            System.debug('EA ED date input is ' + (easp.EndDate).addSeconds(1));

         }

         List<Datetime> dateList = new List<Datetime>();
         dateList.addAll(dateTimeSet);
         dateList.sort();

         return dateList;
      }
//METHODS END
   }

//RENEWAL LOGIC END


   /*
   Original Brian Version
   class AssetStatePeriod {
       Datetime startDate;
       Datetime endDate;
       Double quantity;
       Double amount;
       Double mrr;
       AssetStatePeriod(OrderItem oi) {
           startDate = DateTime.newInstance(oi.ServiceDate.year()  , oi.ServiceDate.month(), oi.ServiceDate.day(), 0, 0, 0);
           endDate = DateTime.newInstance(oi.EndDate.year(), oi.EndDate.month(), oi.EndDate.day(), 23, 59, 59);
           quantity = oi.Quantity;
           amount = oi.TotalPrice;
           mrr = oi.MRR__c;
       }
   }
   */

   public class AssetStatePeriodWrapper {
      String startDate;
      String endDate;
      Double quantity;
      Double amount;
      Double mrr;

      AssetStatePeriodWrapper(Date sDate, Date eDate, Decimal qty, Decimal amt, Decimal mrrAmount) {
         startDate = formatStartDate(sDate);
         endDate = formatEndDate(eDate);
         quantity = qty;
         amount = amt;
         mrr = mrrAmount;
      }

      public String formatStartDate(Date sDate) {
         Datetime rawStartDateTime = Datetime.newInstanceGmt(sDate.year(), sDate.month(), sDate.day(), 0, 0, 0);
         String formattedStartDate = rawStartDateTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
         System.debug(formattedStartDate);
         return formattedStartDate;
      }

      public String formatEndDate(Date eDate) {
         Datetime rawEndDateTime = Datetime.newInstanceGmt(eDate.year(), eDate.month(), eDate.day(), 23, 59, 59);
         String formattedEndDate = rawEndDateTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
         System.debug(formattedEndDate);
         return formattedEndDate;
      }
   }

   public class ExistingAssetStatePeriodWrapper {
      String startDate;
      String endDate;
      Double quantity;
      Double amount;
      Double mrr;
      ExistingAssetStatePeriodWrapper(Datetime sDate, Datetime eDate, Decimal qty, Decimal amt, Decimal mrrAmount) {
         startDate = formatStartDate(sDate);
         endDate = formatEndDate(eDate);
         quantity = qty;
         amount = amt;
         mrr = mrrAmount;
      }
      public String formatStartDate(Datetime sDate) {
//            DateTime rawStartDateTime = DateTime.newInstanceGMT(sDate.year(), sDate.month(), sDate.day(), sDate.hour(), sDate.minute(), sDate.second());
         Datetime rawStartDateTime = sDate;
         String formattedStartDate = rawStartDateTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
         System.debug(formattedStartDate);
         return formattedStartDate;
      }

      public String formatEndDate(Datetime eDate) {
//            DateTime rawEndDateTime = DateTime.newInstanceGMT(eDate.year(), eDate.month(), eDate.day(), eDate.hour(), eDate.minute(), eDate.second());
         Datetime rawEndDateTime = eDate;
         String formattedEndDate = rawEndDateTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
         System.debug(formattedEndDate);
         return formattedEndDate;
      }
   }

   class AssetActionSource {
      Datetime transactionDate;
      Double adjustmentAmount;
      Double productAmount;
      Double estimatedTax;
      Double actualTax;
      Datetime startDate;
      Datetime endDate;
      Double quantity;
      Id referenceEntityItem;
      //String externalReference;
      //String externalReferenceDataSource;
      AssetActionSource(OrderItem oi) {
         transactionDate = Datetime.newInstance(oi.ServiceDate.year(), oi.ServiceDate.month(), oi.ServiceDate.day(), 0, 0, 0);
         adjustmentAmount = 0.00;
         productAmount = oi.TotalPrice;
         estimatedTax = 0.00;
         actualTax = 0.00;
         //estimatedTax = oi.blng__BilledTax__c;
         //actualTax = oi.blng__BilledTax__c;
         startDate = Datetime.newInstance(oi.ServiceDate.year(), oi.ServiceDate.month(), oi.ServiceDate.day(), 0, 0, 0);
         endDate = Datetime.newInstance(oi.EndDate.year(), oi.EndDate.month(), oi.EndDate.day(), 23, 59, 59);
         quantity = oi.Quantity;
         referenceEntityItem = oi.Id;
      }
   }

   class AssetAction {
      String category;
      Datetime actionDate;
      Double quantityChange;
      Double mrrChange;
      Double amount;
      AssetAction(OrderItem oi) {
         if (oi.AssetActionCategory__c != null) {
            category = oi.AssetActionCategory__c;
         } else {
            category = 'Initial Sale';
         }
         actionDate = Datetime.newInstance(oi.ServiceDate.year(), oi.ServiceDate.month(), oi.ServiceDate.day(), 0, 0, 0);
         quantityChange = oi.Quantity;
         mrrChange = oi.MRR__c;
         amount = oi.TotalPrice;
      }
   }

   class RenewalAssetActionSource {
      Datetime transactionDate;
      Double adjustmentAmount;
      Double productAmount;
      Double estimatedTax;
      Double actualTax;
      Datetime startDate;
      Datetime endDate;
      Double quantity;
      Id referenceEntityItem;
      //String externalReference;
      //String externalReferenceDataSource;
      RenewalAssetActionSource(OrderItem oi) {
         transactionDate = Datetime.newInstance(oi.ServiceDate.year(), oi.ServiceDate.month(), oi.ServiceDate.day(), 0, 0, 0);
         adjustmentAmount = 0.00;
         productAmount = oi.TotalPrice;
         estimatedTax = 0.00;
         actualTax = 0.00;
         //estimatedTax = oi.blng__BilledTax__c;
         //actualTax = oi.blng__BilledTax__c;
         startDate = Datetime.newInstance(oi.ServiceDate.year(), oi.ServiceDate.month(), oi.ServiceDate.day(), 0, 0, 0);
         endDate = Datetime.newInstance(oi.EndDate.year(), oi.EndDate.month(), oi.EndDate.day(), 23, 59, 59);
         quantity = oi.Quantity;
         referenceEntityItem = oi.Id;
      }
   }

   class RenewalAssetAction {
      String category;
      Datetime actionDate;
      Double quantityChange;
      Double mrrChange;
      Double amount;
      RenewalAssetAction(OrderItem oi) {
         category = 'Renewals';
         actionDate = Datetime.newInstance(oi.ServiceDate.year(), oi.ServiceDate.month(), oi.ServiceDate.day(), 0, 0, 0);

         AssetStatePeriod rASP = [
             SELECT Id, AssetId, Quantity,
                 StartDate, EndDate, Mrr, Amount
             FROM AssetStatePeriod
             WHERE (EndDate >= :oi.ServiceDate.addDays(-1) AND AssetId = :oi.blng__Asset__c)
             ORDER BY EndDate ASC
         ].get(0);

         quantityChange = oi.Quantity - rASP.Quantity;
         mrrChange = oi.MRR__c - rASP.Mrr;
         amount = oi.TotalPrice;
      }
   }
}