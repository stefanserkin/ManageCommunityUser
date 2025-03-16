@IsTest
public class CommunityUserTestData {
    
    public static User createCommunityUserWithUsername(String username) {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Contact contact = new Contact(AccountId = acc.Id, FirstName = 'Test', LastName = 'Erooni', Email = username);
        insert contact;
        
        Community_User_Setting__mdt settings = Community_User_Setting__mdt.getInstance('Default');
        // Set<String> communityUserTypes = new Set<String>{'CspLitePortal','PowerCustomerSuccess','PowerPartner'};
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = :settings.Profile_Name__c LIMIT 1];
        
        User u = new User(
            Username = USERNAME,
            Email = USERNAME,
            LastName = contact.LastName,
            FirstName = contact.FirstName,
            ContactId = contact.Id,
            Alias = 'testu',
            CommunityNickname = USERNAME.substring(0, USERNAME.indexOf('@')),
            ProfileId = communityProfile.Id,
            TimeZoneSidKey = UserInfo.getTimeZone().toString(),
            LocaleSidKey = UserInfo.getLocale(),
            EmailEncodingKey = settings.Email_Encoding_Key__c,
            LanguageLocaleKey = UserInfo.getLanguage(),
            IsActive = true
        );
        insert u;

        return u;
    }

    public static User getRunningUser() {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        UserRole ur = new UserRole(Name = 'ButterRoll');
        insert ur;

        User u = new User();
        u.UserRoleId = ur.Id;
        u.IsActive = true;
        u.TimeZoneSidKey = UserInfo.getTimeZone().toString();
        u.LocaleSidKey = UserInfo.getLocale();
        u.LanguageLocaleKey = UserInfo.getLocale();
        u.EmailEncodingKey = 'ISO-8859-1';
        u.Username = uniqueName + '@test' + orgId + '.org';
        u.Email = uniqueName + '@test' + orgId + '.org';
        u.FirstName = 'Superadmin';
        u.LastName = 'Superuser';
        u.Alias = uniqueName.substring(18, 23);
        u.ProfileId = profile.Id;
        insert u;

        String permSetName = 'Manage_Community_Users';
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = :permSetName LIMIT 1];
        insert new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = permSet.Id
        );

        return u;
    }

}