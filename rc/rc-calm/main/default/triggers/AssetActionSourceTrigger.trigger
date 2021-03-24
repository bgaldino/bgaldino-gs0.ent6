trigger AssetActionSourceTrigger on AssetActionSource (after insert) {
	for(AssetActionSource aas: trigger.new){
        AssetOrderItemProcessingService.setOrderItemAsset(aas.Id);
    }
}