public with sharing class ContractAmender {
	public QuoteModel load(String contractId) {
		String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractAmender', contractId, null);
		return (QuoteModel)JSON.deserialize(quoteJSON, QuoteModel.class);
	}
}