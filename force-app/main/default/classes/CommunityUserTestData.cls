@IsTest
public class CommunityUserTestData {

    private static User runningUser;
    
    public static User createCommunityUserWithUsername(String username) {
        User rUser = getRunningUser();

        Account acc;
        Contact contact;
        User u;

        System.runAs(rUser) {
            acc = new Account(Name = 'Test Account');
            insert acc;
            contact = new Contact(AccountId = acc.Id, FirstName = 'Test', LastName = 'Erooni', Email = username);
            insert contact;

            Community_User_Setting__mdt settings = Community_User_Setting__mdt.getInstance('Default');
            Profile communityProfile = [SELECT Id FROM Profile WHERE Name = :settings.Profile_Name__c LIMIT 1];

            u = new User(
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
        }

        return u;
    }

    public static User getRunningUser() {
        if (runningUser != null) {
            return runningUser;
        }
        
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        UserRole ur = new UserRole(Name = 'ButterRoll');
        insert ur;

        User runningUser = new User();
        runningUser.UserRoleId = ur.Id;
        runningUser.IsActive = true;
        runningUser.TimeZoneSidKey = UserInfo.getTimeZone().toString();
        runningUser.LocaleSidKey = UserInfo.getLocale();
        runningUser.LanguageLocaleKey = UserInfo.getLocale();
        runningUser.EmailEncodingKey = 'ISO-8859-1';
        runningUser.Username = uniqueName + '@test' + orgId + '.org';
        runningUser.Email = uniqueName + '@test' + orgId + '.org';
        runningUser.FirstName = 'Superadmin';
        runningUser.LastName = 'Superuser';
        runningUser.Alias = uniqueName.substring(18, 23);
        runningUser.ProfileId = profile.Id;
        insert runningUser;

        String permSetName = 'Manage_Community_User';
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = :permSetName LIMIT 1];
        insert new PermissionSetAssignment(
            AssigneeId = runningUser.Id,
            PermissionSetId = permSet.Id
        );

        return runningUser;
    }

}