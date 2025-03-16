@IsTest
private class ManageCommunityUserController_Test {

    private static final String USERNAME = 'testerooni@example.com';
    
    @TestSetup
    static void makeData() {
        CommunityUserTestData.createCommunityUserWithUsername(USERNAME);
    }

    @IsTest
    static void testGetCommunityUser() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = :USERNAME LIMIT 1];
        User runningUser = CommunityUserTestData.getRunningUser();

        CommunityUser communityUser;
        Test.startTest();
        System.runAs(runningUser) {
            communityUser = ManageCommunityUserController.getCommunityUser(testContact.Id);
        }
        Test.stopTest();

        System.Assert.isNotNull(communityUser, 'CommunityUser should not be null');
        System.Assert.isNotNull(communityUser.userId, 'User ID should not be null');
    }

    @IsTest
    static void testGetCommunityUserWithNoUser() {
        User runningUser = CommunityUserTestData.getRunningUser();
        Contact newContact;

        CommunityUser communityUser;
        Test.startTest();
        System.runAs(runningUser) {
            newContact = new Contact(FirstName = 'NoUser', LastName = 'Test', Email = 'nouser@example.com');
            insert newContact;

            communityUser = ManageCommunityUserController.getCommunityUser(newContact.Id);
        }
        Test.stopTest();

        System.Assert.isNull(communityUser, 'CommunityUser should be null when no user exists');
    }

    @IsTest
    static void testGetCommunityUserWithException() {
        String invalidId = 'ruh-roh';
        User runningUser = CommunityUserTestData.getRunningUser();
        
        Test.startTest();
        System.runAs(runningUser) {
            try {
                CommunityUser communityUser = ManageCommunityUserController.getCommunityUser(invalidId);
                System.Assert.fail('Should have received an exception for the invalid contact id');
            } catch (Exception e) {
                System.Assert.isNotNull(e.getMessage(), 'Should have received an exception message');
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testResetPassword() {
        User testUser = [SELECT Id FROM User WHERE Username = :USERNAME LIMIT 1];

        User runningUser = CommunityUserTestData.getRunningUser();

        ManageCommunityUserController.Result result;
        Test.startTest();
        System.runAs(runningUser) {
            result = ManageCommunityUserController.resetPassword(testUser.Id);
        }
        Test.stopTest();

        System.Assert.isTrue(result.isSuccess, 'Reset password should return true');
    }

    @IsTest
    static void testResetPasswordForInvalidUser() {
        User runningUser = CommunityUserTestData.getRunningUser();

        Test.startTest();
        System.runAs(runningUser) {
            try {
                ManageCommunityUserController.resetPassword('005XXXXXXXXXXXX');
                System.Assert.fail('Expected an exception for an invalid user ID');
            } catch (AuraHandledException e) {
                System.Assert.isNotNull(e.getMessage(), 'Exception should have a message');
            }
        }
        Test.stopTest();
    }

    
    @IsTest
    static void testDisableUser() {
        User testUser = [SELECT Id FROM User WHERE Email = :USERNAME LIMIT 1];
        User runningUser = CommunityUserTestData.getRunningUser();

        ManageCommunityUserController.Result result;
        Test.startTest();
        System.runAs(runningUser) {
            result = ManageCommunityUserController.disableUser(testUser.Id);
        }
        Test.stopTest();

        System.Assert.isTrue(result.isSuccess, 'Disable user should return true');
    }

    @IsTest
    static void testDisableUserForInvalidUser() {
        User runningUser = CommunityUserTestData.getRunningUser();

        Test.startTest();
        System.runAs(runningUser) {
            try {
                ManageCommunityUserController.disableUser('005XXXXXXXXXXXX');
                System.assert(false, 'Expected an exception for an invalid user ID');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage() != null, 'Exception should have a message');
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testEnableUser() {
        Account newAccount;
        Contact newContact;
        Id newUserId;

        User runningUser = CommunityUserTestData.getRunningUser();

        Test.startTest();
        System.runAs(runningUser) {
            newAccount = new Account(Name = 'VeryNewAccount');
            insert newAccount;
            newContact = new Contact(AccountId = newAccount.Id, FirstName = 'NoUser', LastName = 'Test', Email = 'nouser@example.com');
            insert newContact;

            ManageCommunityUserController.EnableUserRequest request = new ManageCommunityUserController.EnableUserRequest();
            request.contactId = newContact.Id;
            request.username = newContact.Email;
            request.email = newContact.Email;
            request.firstName = newContact.FirstName;
            request.lastName = newContact.LastName;
            String jsonString = JSON.serialize(request);

            newUserId = ManageCommunityUserController.enableUser(jsonString); 
        }
        Test.stopTest();

        User newUser = [SELECT Id, Username, Email, IsActive FROM User WHERE Id = :newUserId];
        System.Assert.isNotNull(newUser, 'New user should be created');
        System.Assert.areEqual(newContact.Email, newUser.Username, 'Username should match contact email');
        System.Assert.isTrue(newUser.IsActive, 'New user should be active');
    }

    @IsTest
    static void testEnableUserWithInvalidData() {
        User runningUser = CommunityUserTestData.getRunningUser();
        String invalidJsonString = '{}';

        Test.startTest();
        System.runAs(runningUser) {
            try {
                ManageCommunityUserController.enableUser(invalidJsonString);
                System.assert(false, 'Expected an exception for invalid data');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage() != null, 'Exception should have a message');
            }
        }
        Test.stopTest();
    }

}
