@IsTest
private class CommunityUserService_Test {

    private static final String USERNAME = 'testerooni@example.com';
    
    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Contact contact = new Contact(AccountId = acc.Id, FirstName = 'Test', LastName = 'Erooni', Email = USERNAME);
        insert contact;
        
        Community_User_Setting__mdt settings = Community_User_Setting__mdt.getInstance('Default');
        // Set<String> communityUserTypes = new Set<String>{'CspLitePortal','PowerCustomerSuccess','PowerPartner'};
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = :settings.Profile_Name__c LIMIT 1];
        
        User testUser = new User(
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
        insert testUser;
    }
    
    @IsTest
    static void testResetPassword() {
        User testUser = [SELECT Id FROM User WHERE Username = :USERNAME LIMIT 1];

        User runningUser = getRunningUser();

        Test.startTest();
        System.runAs(runningUser) {
            new CommunityUserService().resetPassword(testUser.Id);
        }
        Test.stopTest();
        
        System.Assert.isTrue(true, 'Reset password executed without exception.');
    }
    
    @IsTest
    static void testDisableUser() {
        User testUser = [SELECT Id FROM User WHERE Username = :USERNAME LIMIT 1];
        User runningUser = getRunningUser();
        CommunityUserService service = new CommunityUserService();

        Boolean isSuccess = false;
        Test.startTest();
        System.runAs(runningUser) {
            isSuccess = service.disableUser(testUser.Id);
        }
        Test.stopTest();

        System.Assert.isTrue(isSuccess, 'Disable user method should return true');
    }
    
    @IsTest
    static void testEnableUser() {
        User runningUser = getRunningUser();
        Id newUserId;
        Account acc;
        Contact ct;

        Test.startTest();
        System.runAs(runningUser) {
            acc = new Account(Name = 'New Account');
            insert acc;
            ct = new Contact(AccountId = acc.Id, FirstName = 'Newaccount', LastName = 'Please', Email = 'newaccount@please.com');
            insert ct;

            ManageCommunityUserController.EnableUserRequest request = new ManageCommunityUserController.EnableUserRequest();
            request.username = ct.Email;
            request.email = ct.Email;
            request.contactId = ct.Id;
            request.FirstName = ct.FirstName;
            request.LastName = ct.LastName;

            CommunityUserService service = new CommunityUserService();
            newUserId = service.enableUser(request);
        }
        Test.stopTest();

        User newUser = [SELECT Id, Username, Email, IsActive FROM User WHERE Id = :newUserId];
        System.Assert.isNotNull(newUser, 'New user should have been created');
        System.Assert.areEqual(ct.Email, newUser.Username, 'Usernames should match');
        System.assert(newUser.IsActive, 'New user should be active');
    }

    @IsTest
    static void testEnableUserWithDuplicateNickname() {
        User runningUser = getRunningUser();
        Id newUserId;
        Account acc;
        Contact ct;
        String newUsername;
        
        
        Test.startTest();
        System.runAs(runningUser) {
            acc = new Account(Name = 'New Account');
            insert acc;
            ct = new Contact(AccountId = acc.Id, FirstName = 'Newaccount', LastName = 'Please', Email = USERNAME);
            insert ct;
    
            newUsername = ct.Email.substring(0, ct.Email.indexOf('@')) + '@newdomain.com';
    
            ManageCommunityUserController.EnableUserRequest request = new ManageCommunityUserController.EnableUserRequest();
            request.username = newUsername;
            request.email = ct.Email;
            request.contactId = ct.Id;
            request.FirstName = ct.FirstName;
            request.LastName = ct.LastName;
    
            CommunityUserService service = new CommunityUserService();
            newUserId = service.enableUser(request);
        }
        Test.stopTest();

        User newUser = [SELECT Id, Username, Email, IsActive FROM User WHERE Id = :newUserId];
        System.Assert.isNotNull(newUser, 'New user should have been created');
        System.Assert.areEqual(newUsername, newUser.Username, 'Usernames should match');
        System.assert(newUser.IsActive, 'New user should be active');
    }

    @IsTest
    static void testGetCommunityUser() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = :USERNAME LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE ContactId = :testContact.Id LIMIT 1];

        User runningUser = getRunningUser();

        CommunityUserService service = new CommunityUserService();

        CommunityUser communityUser;
        Test.startTest();
        System.runAs(runningUser) {
            communityUser = service.getCommunityUser(testContact.Id);
        }
        Test.stopTest();

        System.Assert.isNotNull(communityUser, 'CommunityUser should not be null');
        System.Assert.areEqual(testUser.Id, communityUser.userId, 'User ID should match');
    }

    @IsTest
    static void testGetCommunityUserWithNoUser() {
        User runningUser = getRunningUser();
        CommunityUserService service = new CommunityUserService();

        CommunityUser communityUser;
        Test.startTest();
        System.runAs(runningUser) {
            Contact ct = new Contact(FirstName = 'Userless', LastName = 'Person', Email = 'userless@person.com');
            insert ct;

            communityUser = service.getCommunityUser(ct.Id);
        }
        Test.stopTest();

        System.Assert.isNull(communityUser, 'CommunityUser should be null');
    }

    @IsTest
    static void testGetProfileId() {
        User runningUser = getRunningUser();

        Community_User_Setting__mdt settings = Community_User_Setting__mdt.getInstance('Default');

        Id profileId;
        Test.startTest();
        System.runAs(runningUser) {
            profileId = CommunityUserService.getProfileId(settings.Profile_Name__c);
        }
        Test.stopTest();

        Profile profileToVerify = [SELECT Id FROM Profile WHERE Name = :settings.Profile_Name__c LIMIT 1];

        System.Assert.areEqual(profileToVerify.Id, profileId, 'Received incorrect profile id');
    }

    @IsTest
    static void testGetProfileIdWithInvalidName() {
        User runningUser = getRunningUser();

        Test.startTest();
        System.runAs(runningUser) {
            try {
                Id profileId = CommunityUserService.getProfileId('SomeInvalidProfile');
                System.Assert.fail('Exception should have been thrown');
            } catch (CommunityUserService.CommunityUserServiceException e) {
                System.Assert.isTrue(true, 'Exception should have been thrown for the invalid profile name');
            }
        }
        Test.stopTest();
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
