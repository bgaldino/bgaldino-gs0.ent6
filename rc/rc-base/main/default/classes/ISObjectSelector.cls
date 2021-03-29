public interface ISObjectSelector
{
	/**
	 * Provides the SObjectType for the object the given Selector is providing query logic for
	 **/
	Schema.SObjectType sObjectType();

	/**
	 * Selects by Id records using the fields defined by the Selector configuration
	 **/
	List<SObject> selectSObjectsById(Set<Id> idSet);	
}