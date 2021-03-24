public class QuoteModel {
	public SBQQ__Quote__c record;
	public QuoteLineModel[] lineItems;
	public QuoteLineGroupModel[] lineItemGroups;
	public Integer nextKey;
	public Integer targetGroupKey;
	public Boolean applyAdditionalDiscountLast;
	public Boolean applyPartnerDiscountFirst;
	public Boolean channelDiscountsOffList;
	public Decimal customerTotal;
	public Decimal netTotal;
	public Decimal netNonSegmentTotal;

}