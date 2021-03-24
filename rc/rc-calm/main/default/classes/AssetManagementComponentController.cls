public with sharing class AssetManagementComponentController {

   @AuraEnabled(Cacheable=true)
   public static List<Asset> getActiveAssets(String accountId) {
      System.debug('Account Id String is ' + accountId);

      return [
          SELECT Id, Name, Product2Id, Product2.Name, LifecycleEndDate, CurrentQuantity,
              LifecycleStartDate, CurrentLifecycleEndDate
          FROM Asset
          WHERE (AccountId = :accountId AND HasLifecycleManagement = TRUE)
      ];
   }

   static List<Asset> processSelectedAssetsOLD(List<String> astIds) {
      List<Asset> selectedAssets = [
          SELECT Id, Name, Product2Id, Product2.Name,
              LifecycleEndDate, CurrentQuantity,
              LifecycleStartDate, CurrentLifecycleEndDate
          FROM Asset
          WHERE Id IN:astIds
      ];

      System.debug('Count of selected Asset Wrappers is ' + selectedAssets.size());

      return selectedAssets;
   }

   @AuraEnabled
   public static List<Asset> processSelectedAssets(List<Asset> assets) {
      List<Asset> selectedAssets = new List<Asset>();

      selectedAssets.addAll(assets);

      System.debug('Count of selected Asset records is ' + selectedAssets.size());

      return selectedAssets;
   }
//CHANGE ASSET LOGIC START
   static Opportunity createChangeOpp(String accountId) {
      Opportunity changeOpp = new Opportunity(AccountId = accountId, StageName = 'Proposal/Price Quote',
          Name = 'Asset Change Opp', CloseDate = Date.today() + 30);

      insert changeOpp;
      return changeOpp;
   }

   static SBQQ__Quote__c createChangeQuote(String accountId, Date startDate) {
      Opportunity changeOpp = createChangeOpp(accountId);
      SBQQ__Quote__c changeQuote = new SBQQ__Quote__c(SBQQ__Primary__c = true, SBQQ__StartDate__c = startDate,
          SBQQ__Account__c = accountId, SBQQ__Opportunity2__c = changeOpp.Id);

      insert changeQuote;
      return changeQuote;
   }

   static Id createChangeQLs(String accountId, Date startDate, List<Asset> assets) {
      List<Asset> selectedAssets = processSelectedAssets(assets);
      SBQQ__Quote__c changeQuote = createChangeQuote(accountId, startDate);

      List<SBQQ__QuoteLine__c> changeQLs = new List<SBQQ__QuoteLine__c>();

      if (selectedAssets.size() > 0) {
         for (Integer i = 0; i < selectedAssets.size(); i++) {
            AssetStatePeriod asp = [
                SELECT Id, Quantity, AssetId,
                    StartDate, EndDate
                FROM AssetStatePeriod
                WHERE (AssetId = :selectedAssets.get(i).Id AND EndDate >= :startDate)
                ORDER BY EndDate DESC
            ].get(0);

            Date eDate = asp.EndDate.date();

            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(SBQQ__Number__c = i + 1, SBQQ__Quote__c = changeQuote.Id,
                SBQQ__Product__c = selectedAssets.get(i).Product2Id,
                SBQQ__Quantity__c = asp.Quantity, SBQQ__EndDate__c = eDate,
                SBQQ__Existing__c = true, SBQQ__PriorQuantity__c = asp.Quantity,
                Asset__c = selectedAssets.get(i).Id);

            changeQLs.add(ql);
         }
      }

      insert changeQLs;
      return changeQuote.Id;
   }

   @AuraEnabled
   public static Id changeAssets(String accountId, Date sDate, List<Asset> assets) {
      Id newQuoteId = createChangeQLs(accountId, sDate, assets);
      return newQuoteId;
   }
//CHANGE ASSET LOGIC END

//RENEW ASSET LOGIC START
   static Opportunity createRenewOpp(String accountId) {
      Opportunity renewOpp = new Opportunity(AccountId = accountId, StageName = 'Proposal/Price Quote',
          Name = 'Renewal Opp', CloseDate = Date.today() + 30);

      insert renewOpp;
      return renewOpp;
   }

   static SBQQ__Quote__c createRenewalQuote(String accountId, Date renewDate, Integer renewTerm) {
      Opportunity renewalOpp = createRenewOpp(accountId);
      SBQQ__Quote__c renewalQuote = new SBQQ__Quote__c(SBQQ__Primary__c = TRUE, SBQQ__StartDate__c = renewDate,
          SBQQ__Account__c = accountId, SBQQ__Opportunity2__c = renewalOpp.Id);

      insert renewalQuote;
      return renewalQuote;
   }

   static Id createRenewalQLs(String accountId, Date renewDate, Integer renewTerm, List<Asset> assets) {
      List<Asset> selectedAssets = processSelectedAssets(assets);
      SBQQ__Quote__c renewalQuote = createRenewalQuote(accountId, renewDate, renewTerm);

      List<SBQQ__QuoteLine__c> renewalQLs = new List<SBQQ__QuoteLine__c>();

      if (selectedAssets.size() > 0) {
         for (Integer i = 0; i < selectedAssets.size(); i++) {
            AssetStatePeriod asp = [
                SELECT Id, Quantity, AssetId,
                    StartDate, EndDate
                FROM AssetStatePeriod
                WHERE (AssetId = :selectedAssets.get(i).Id AND EndDate >= :renewDate.addDays(-1))
                ORDER BY EndDate DESC
            ].get(0);

            Date eDate = asp.EndDate.date();

            if (eDate > renewDate) {
               SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(SBQQ__Number__c = i + 1, SBQQ__Quote__c = renewalQuote.Id,
                   SBQQ__Product__c = selectedAssets.get(i).Product2Id,
                   SBQQ__Quantity__c = 0, SBQQ__EndDate__c = eDate,
                   SBQQ__Existing__c = TRUE, SBQQ__PriorQuantity__c = asp.Quantity,
                   Asset__c = selectedAssets.get(i).Id);

               renewalQLs.add(ql);

               SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(SBQQ__Number__c = i + 1, SBQQ__Quote__c = renewalQuote.Id,
                   SBQQ__Product__c = selectedAssets.get(i).Product2Id,
                   SBQQ__Quantity__c = asp.Quantity, SBQQ__StartDate__c = renewDate, AssetActionCategory__c = 'Renewals',
                   Asset__c = selectedAssets.get(i).Id);

               renewalQLs.add(ql2);
            } else {
               SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(SBQQ__Number__c = i + 1, SBQQ__Quote__c = renewalQuote.Id,
                   SBQQ__Product__c = selectedAssets.get(i).Product2Id,
                   SBQQ__Quantity__c = asp.Quantity, SBQQ__StartDate__c = renewDate, AssetActionCategory__c = 'Renewals',
                   Asset__c = selectedAssets.get(i).Id);

               renewalQLs.add(ql2);
            }

         }
      }

      insert renewalQLs;
      return renewalQuote.Id;
   }

   @AuraEnabled
   public static Id renewAssets(String accountId, Date renewDate, Integer renewTerm, List<Asset> assets) {
      Id newQuoteId = createRenewalQLs(accountId, renewDate, renewTerm, assets);
      return newQuoteId;
   }
//RENEW ASSET LOGIC END

   class LifeCycleAssetWrapper {
      @AuraEnabled public Asset ast { get; set; }
      @AuraEnabled public Boolean checked { get; set; }

      public LifeCycleAssetWrapper(Asset a, Boolean chkd) {
         this.ast = a;
         this.checked = chkd;
      }
   }

   class QuoteModel {
      public SBQQ__Quote__c record;
      public QuoteLineModel[] lineItems;
      public QuoteLineGroupModel[] lineItemGroups;
      public Integer nextKey;
      public Boolean applyAdditionalDiscountLast;
      public Boolean applyPartnerDiscountFirst;
      public Boolean channelDiscountsOffList;
      public Decimal customerTotal;
      public Decimal netTotal;
      public Decimal netNonSegmentTotal;
   }

   class QuoteLineModel {
      public SBQQ__QuoteLine__c record;
      public Boolean amountDiscountProrated;
      public Integer parentGroupKey;
      public Integer parentItemKey;
      public Integer key;
      public Boolean upliftable;
      public String configurationType;
      public String configurationEvent;
      public Boolean reconfigurationDisabled;
      public Boolean descriptionLocked;
      public Boolean productQuantityEditable;
      public Decimal productQuantityScale;
      public String dimensionType;
      public Boolean productHasDimensions;
      public Decimal targetCustomerAmount;
      public Decimal targetCustomerTotal;
/*
        public QuoteLineModel(SBQQ__QuoteLine__c){

        }
*/
   }

   class QuoteLineGroupModel {
      public SBQQ__QuoteLineGroup__c record;
      public Decimal netNonSegmentTotal;
      public Integer key;
   }

   class ProductModel {
      public Product2 record;
      public Id upgradedAssetId;
      public String currencySymbol;
      public String currencyCode;
      public String[] featureCategories;
      public OptionModel[] options;
      public FeatureModel[] features;
      public ConfigurationModel configuration;
      public ConfigAttributeModel[] configurationAttributes;
      public ConfigAttributeModel[] inheritedConfigurationAttributes;
      public ConstraintModel[] constraints;
   }

   class ConfigurationModel {
      public Id configuredProductId;
      public Id optionId;
      public SBQQ__ProductOption__c optionData; // Editable data about the option in question, such as quantity or discount
      public SBQQ__ProductOption__c configurationData;
      public SBQQ__ProductOption__c inheritedConfigurationData;
      public ConfigurationModel[] optionConfigurations;
      public Boolean configured;
      public Boolean changedByProductActions;
      public Boolean isDynamicOption;
      public Boolean isUpgrade;
      public Set<Id> disabledOptionIds;
      public Set<Id> hiddenOptionIds;
      public Decimal listPrice;
      public Boolean priceEditable;
      public String[] validationMessages;
      public String dynamicOptionKey;
  }

   class FeatureModel {
      public SBQQ__ProductFeature__c record;
      public String instructionsText;
      public Boolean containsUpgrades;
   }
   
   class OptionModel {
      public SBQQ__ProductOption__c record;
      public Map<String, String> externalConfigurationData;
      public Boolean configurable;
      public Boolean configurationRequired;
      public Boolean quantityEditable;
      public Boolean priceEditable;
      public Decimal productQuantityScale;
      public Boolean priorOptionExists;
      public Set<Id> dependentIds;
      public Map<String, Set<Id>> controllingGroups;
      public Map<String, Set<Id>> exclusionGroups;
      public String reconfigureDimensionWarning;
      public Boolean hasDimension;
      public Boolean isUpgrade;
      public String dynamicOptionKey;
   }

   class ConstraintModel {
      public SBQQ__OptionConstraint__c record;
      public Boolean priorOptionExists;
   }

   class ConfigAttributeModel {
      public String name;
      public String targetFieldName;
      public Decimal displayOrder;
      public String colmnOrder;
      public Boolean required;
      public Id featureId;
      public String position;
      public Boolean appliedImmediately;
      public Boolean applyToProductOptions;
      public Boolean autoSelect;
      public String[] shownValues;
      public String[] hiddenValues;
      public Boolean hidden;
      public String noSuchFieldName;
      public Id myId;
  }
}