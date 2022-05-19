public with sharing class OpportunityForAccountsBatch implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([SELECT id, name FROM Account]); //Collect the accounts to be passed to execute method
    }
//``````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````
    public void execute(Database.BatchableContext context, List<Account> listAcc){
        Set<Id> accountIds = new Set<Id>();
        Map<Id, List<Opportunity>> accountOppMap = new Map<Id, List<Opportunity>>(); //Map to bind accounts with opportunities
        Map<Id, String> primaryContactPerAccount = new Map<Id, String>(); // Map to store the primary contact's email

        for (Account acct : listAcc) {
            accountIds.add(acct.Id);    //Gather the account's Ids to get primary contact for each account
        }

    try {
        for(Contact primaryContact : [SELECT id, accountId, email FROM contact WHERE Is_Primary_Contact__c = true AND accountId IN :accountIds]) {
            primaryContactPerAccount.put(primaryContact.AccountId, primaryContact.Email); // Building the map to gather the email adress by account id
        }
    } catch (Exception e) {
        System.debug(e.getMessage());
    }
    
    
    try{
        for(Account acc : [SELECT id, (SELECT id, name, stageName, amount, accountId FROM Opportunities)FROM Account]){
            accountOppMap.put(acc.id, acc.Opportunities); // Map the accounts with their opportunities
        }
    } catch (Exception e) {
        System.debug(e.getMessage());
    }

    for(Account acc : listAcc){ //Iterate over each account

        //Starting to build the email
    String htmlBody = '';
    htmlBody = '<table border="1" style="border-collapse: collapse"><caption>Request Summary Data</caption><tr><th>Name</th><th>Stage</th></tr><tr><th>Amount</th></tr>';
    
        for(Opportunity opp : accountOppMap.get(acc.Id)){ //Use the list of Opportunities we got mapped to the current account

            String accName = acc.Name;
            String stageName = opp.StageName; 
            Double oppAmount = opp.Amount;

            htmlBody += '<tr><td>' + accName + '</td><td>' + stageName + '</td><td>' + oppAmount + '</td></tr>';
        }
    htmlBody += '</table>';//Close table
    
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    String[] toAddresses = new String[] {primaryContactPerAccount.get(acc.Id)}; //Set the target address as the email mapped to the current account
    mail.setToAddresses(toAddresses);
    mail.setSubject('Opportunities summarized:');
    mail.setHtmlBody(htmlBody);
    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}
//``````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````
    public void finish(Database.BatchableContext context) {
        Id job = context.getJobId();
    }
}