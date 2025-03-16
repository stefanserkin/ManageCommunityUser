public with sharing class ManageCommunityUserController {

    private static CommunityUserService service = new CommunityUserService();
    
    /**
     * Get active community user for a contact id
     */
    @AuraEnabled(cacheable=true)
    public static CommunityUser getCommunityUser(String contactId) {
        try {
            return service.getCommunityUser(contactId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Reset password for user id
     */
    @AuraEnabled(cacheable=false)
    public static Result resetPassword(String userId) {
        try {
            service.resetPassword(userId);
            return new Result(true);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Disable an active portal user by its user id
     */
    @AuraEnabled(cacheable=false)
    public static Result disableUser(String userId) {
        try {
            Boolean isSuccess = service.disableUser(userId);
            Result result = new Result(isSuccess);
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static Id enableUser(String jsonString) {
        try {
            EnableUserRequest request = (EnableUserRequest) JSON.deserialize(jsonString, EnableUserRequest.class);
            Id userId = service.enableUser(request);
            return userId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class EnableUserRequest {
        @AuraEnabled
        public String contactId;
        @AuraEnabled
        public String username;
        @AuraEnabled
        public String email;
        @AuraEnabled
        public String firstName;
        @AuraEnabled
        public String lastName;
    }

    public class Result {
        @AuraEnabled
        public Boolean isSuccess;

        public Result(Boolean isSuccess) {
            this.isSuccess = isSuccess;
        }
    }

}