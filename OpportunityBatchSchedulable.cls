public with sharing class OpportunityBatchSchedulable implements Schedulable{
    public void execute(SchedulableContext sc){
        OpportunityForAccountsBatch b = new OpportunityForAccountsBatch();
        Database.executeBatch(b);
    }
}
