public with sharing class CommunityUserService {

    public class CommunityUserServiceException extends Exception {}

    private static final String SETTINGS_NAME = 'Default';
    private Community_User_Setting__mdt communitySettings;

    public CommunityUserService() {
        this.communitySettings = Community_User_Setting__mdt.getInstance(SETTINGS_NAME);
    }

    /**************************************************
     * Reset Passwords
     **************************************************/
    public void resetPassword(Id userId) {
        Boolean sendUserEmail = true;
        System.resetPassword(userId, sendUserEmail);
    }

    /**************************************************
     * Disable an active user
     **************************************************/
    public Boolean disableUser(Id userId) {
        User u = new User(Id = userId, IsPortalEnabled = false);
        Database.SaveResult sr = Database.update(u, false, AccessLevel.SYSTEM_MODE);
        return sr.isSuccess();
    }

    /**************************************************
     * Enable a new community user
     **************************************************/
    public Id enableUser(ManageCommunityUserController.EnableUserRequest request) {
        User u = getNewUserWithDefaults();
        u.Username = request.username;
        u.Email = request.email;
        u.ContactId = request.contactId;
        u.FirstName = request.FirstName;
        u.LastName = request.LastName;

        u.Alias = getAliasFromName(u.firstName, u.lastName);
        u.CommunityNickname = getNicknameFromUsername(u.Username);

        insertUser(u);
        return u.Id;
    }

    private Id insertUser(User u) {
        Id userId;
        Database.SaveResult sr = Database.insert(u, false, AccessLevel.SYSTEM_MODE);
        if (sr.isSuccess()) {
            userId = sr.getId();
        } else {
            Boolean hasCommunityNicknameError = false;
            for (Database.Error err : sr.getErrors()) {
                if (err.getFields().contains('CommunityNickname')) {
                    u.CommunityNickname = (u.CommunityNickname + System.Now().getTime()).left(40);
                    hasCommunityNicknameError = true;
                }
            }

            if (hasCommunityNicknameError) {
                Database.SaveResult retryResult = Database.insert(u, true, AccessLevel.SYSTEM_MODE);
                userId = retryResult.getId();
            }
        }
        return userId;
    }

    /**
     * Get a new user sobject with default values
     */
    private User getNewUserWithDefaults() {
        User u = new User();
        u.ProfileId = getProfileId(communitySettings.Profile_Name__c);
        u.IsActive = true;
        u.TimeZoneSidKey = UserInfo.getTimeZone().toString();
        u.LocaleSidKey = UserInfo.getLocale();
        u.LanguageLocaleKey = UserInfo.getLanguage();
        u.EmailEncodingKey = communitySettings.Email_Encoding_Key__c;
        return u;
    }

    /**
     * Returns a default User Alias based on a first and last name
     **/
    private String getAliasFromName(String firstName, String lastName) {
        return firstName.substring(0, 1) + (lastName.length() > 4 ? lastName.substring(0, 4) : lastName);
    }

    /**
     * Returns a default User Alias, removing the @domain from the username
     **/
    private static String getNicknameFromUsername(String username) {
        return username.contains('@') ? username.substring(0, username.indexOf('@')) : username;
    }
    
    /**************************************************
     * Get existing user data
     **************************************************/
    /**
     * Get a CommunityUser wrapper object for a contact id
     * Includes basic user and network information
     */
    public CommunityUser getCommunityUser(Id contactId) {
        User u = getUserByContactId(contactId);
        if (u == null) {
            return null;
        }

        NetworkMember networkMember = getNetworkMember(u.Id);
        CommunityUser communityUser = new CommunityUser(u, networkMember.NetworkId);
        return communityUser;
    }

    /**
     * Get an active community user by its contact id
     */
    private User getUserByContactId(Id contactId) {
        List<User> users = [
            SELECT Id, ContactId, Username, Email, LastLoginDate, CreatedDate
              FROM User
             WHERE ContactId = :contactId
               AND IsActive = true
              WITH USER_MODE
             LIMIT 1
        ];
        return !users.isEmpty() ? users[0] : null;
    }

    /**
     * Get the first active network member for a user
     * If the running user is not a member of the network, this returns null
     */
    private NetworkMember getNetworkMember(Id userId) {
        List<NetworkMember> networkMembers = [
            SELECT Id, NetworkId
              FROM NetworkMember
             WHERE MemberId = :userId
              WITH USER_MODE
             LIMIT 1
        ];
        return !networkMembers.isEmpty() ? networkMembers[0] : null;
    }

    @TestVisible
    private static Id getProfileId(String profileName) {
        try {
            Profile profile = [
                SELECT Id FROM Profile WHERE Name = :profileName WITH SYSTEM_MODE LIMIT 1
            ];
            return profile.Id;
        } catch (Exception e) {
            throw new CommunityUserServiceException(e.getMessage());
        }
    }

}