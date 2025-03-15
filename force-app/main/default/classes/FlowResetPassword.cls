public inherited sharing class FlowResetPassword {
    
    @InvocableMethod(label='Reset User Password' description='Reset password for a specified user' category='Users')
    public static void resetPassword(List<Request> requests) {
        for (Request request : requests) {
            System.resetPassword(request.userId, request.sendEmail);
        }
    }
    
    public class Request {
        @InvocableVariable(label='User ID' required=true)
        public Id userId;
        @InvocableVariable(label='Send Email to User')
        public Boolean sendEmail;
    }

}