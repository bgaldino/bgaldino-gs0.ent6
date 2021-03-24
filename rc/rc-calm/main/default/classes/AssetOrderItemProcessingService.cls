public with sharing class AssetOrderItemProcessingService {

    @future(callout=false)
    public static void setOrderItemAsset(Id assetActionSourceId){
        AssetActionSource aas = [SELECT Id, AssetActionId 
                                FROM AssetActionSource
                                WHERE Id =: assetActionSourceId].get(0);

        system.debug('AAS ID is ' + aas.Id);

        AssetAction aa = [SELECT Id, AssetId 
                            FROM AssetAction
                            WHERE Id =: aas.AssetActionId].get(0);

        system.debug('AA ID is ' + aa.Id);

        
        List<AssetActionSource> aass = [SELECT Id, ReferenceEntityItemID 
                                        FROM AssetActionSource
                                        WHERE (ReferenceEntityItem.Type = 'OrderItem' AND Id =: assetActionSourceId)];

        if(aass.size()> 0){
            Id oiId = aass.get(0).ReferenceEntityItemID;

            OrderItem oi = [SELECT Id, blng__Asset__c 
                            FROM OrderItem
                            WHERE Id =: oiId].get(0);

            oi.blng__Asset__c = aa.AssetId;

            update oi;
        }
    }
}