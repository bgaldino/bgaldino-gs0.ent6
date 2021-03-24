public with sharing class GenerateQuoteProposal {
	public String save(QuoteProposalModel context) {
		return SBQQ.ServiceRouter.save('SBQQ.QuoteDocumentAPI.Save', JSON.serialize(context));
	}
}