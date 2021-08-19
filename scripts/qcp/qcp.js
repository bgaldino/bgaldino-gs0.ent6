export function onAfterCalculate(quoteModel, quoteLineModels, conn) {
    if (quoteLineModels != null) {
        quoteLineModels.forEach (function (line) {
            if (line.record.ProductSellingModelType__c == null) {
                line.record["ProductSellingModelType__c"] = "Evergreen";
            }
            line.record["PeriodBoundary__c"] = "ANNIVERSARY";
            line.record["PeriodBoundaryDay__c"] = 1;
            line.record.BillingFrequencyRC__c = "Monthly";
            line.record.SalesItemType__c = "Product";
            line.record.TotalPrice__c = line.record.SBQQ__NetTotal__c;
            
            line.record.ListPriceTotal__c = line.record.SBQQ__ListTotal__c;
            line.record.StockKeepingUnit__c = line.record.SBQQ__ProductCode__c;
            line.record.StartingUnitPriceSource__c = "System";
            line.record.ArePartialPeriodsAllowed__c = true;
            line.record.QuantityRC__c = line.record.SBQQ__Quantity__c;

            line.record.StartingUnitPrice__c = line.record.SBQQ__ListPrice__c;
            line.record.StartingPriceTotal__c = line.record.SBQQ__ListTotal__c;

            line.record.TotalAdjustmentAmount__c = line.record.SBQQ__TotalDiscountAmount__c;

            var netTermUnitPrice = (line.record.SBQQ__NetTotal__c / line.record.SBQQ__ProrateMultiplier__c);
            line.record.NetUnitPrice__c = netTermUnitPrice;

            if (line.record.ProductSellingModelType__c == "Evergreen") {
                line.record.SBQQ__ListPrice__c = 90.00;
                line.record.ProductSellingModelId__c = "0jPB00000004C9IMAU";
                line.record.NumberOfPricingTerms__c = null;
            }
            if (line.record.ProductSellingModelType__c == "Term-Defined") {
                line.record.SBQQ__ListPrice__c = 100.00;
                line.record.ProductSellingModelId__c = "0jPB00000004C9DMAU";
                line.record.NumberOfPricingTerms__c = line.record.SBQQ__ProrateMultiplier__c;
            }


        });
    }
return Promise.resolve();
};