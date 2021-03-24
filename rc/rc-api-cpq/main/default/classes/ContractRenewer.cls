//define a class to hold the serialized context and the returned quote information
public with sharing class ContractRenewer {
	public QuoteModel[] load(String masterContractId, String serializedContext) {
		String quotesJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractRenewer', masterContractId, serializedContext);
		return (QuoteModel[])JSON.deserialize(quotesJSON, List<QuoteModel>.class);
	}
}