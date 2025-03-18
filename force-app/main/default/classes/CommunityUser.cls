public class CommunityUser {

    @AuraEnabled
    public Id userId {get;set;}

    @AuraEnabled
    public Id contactId {get;set;}

    @AuraEnabled
    public String username {get;set;}

    @AuraEnabled
    public String email {get;set;}

    @AuraEnabled
    public Datetime lastLoginDate {get;set;}

    @AuraEnabled
    public Datetime createdDate {get;set;}

    /**
     * Properties for logging in as user
     */
    @AuraEnabled
    public Id networkId {get;private set;}
    
    @AuraEnabled
    public String logInAsUrl {get;private set;}

    public CommunityUser(User u, Id networkId) {
        this.userId = u.Id;
        this.contactId = u.ContactId;
        this.username = u.Username;
        this.email = u.Email;
        this.lastLoginDate = u.LastLoginDate;
        this.createdDate = u.CreatedDate;
        if (networkId != null) {
            this.setNetwork(networkId);
        }
    }

    private void setNetwork(Id networkId) {
        this.networkId = networkId;

        // Set logInAsUrl
        String url = System.URL.getOrgDomainUrl().toExternalForm() + '/servlet/servlet.su' +
                     '?oid=' + UserInfo.getOrganizationId() + 
                     '&retURL=%2F' + contactId +
                     '&sunetworkid=' + networkId +
                     '&sunetworkuserid=' + userId;
        this.logInAsUrl = url;
    }

}