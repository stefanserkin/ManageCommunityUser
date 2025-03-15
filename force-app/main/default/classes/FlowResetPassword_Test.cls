@IsTest
private class FlowResetPassword_Test {

    private static List<FlowResetPassword.Request> requests = new List<FlowResetPassword.Request>();
    private static FlowResetPassword.Request request = new FlowResetPassword.Request();

    @IsTest
    static void testResetPassword() {
        Id userId = UserInfo.getUserId();
        request.userId = userId;
        request.sendEmail = false;
        requests.add(request);

        Test.startTest();
        FlowResetPassword.resetPassword(requests);
        Test.stopTest();

        User refreshedUser = [SELECT LastPasswordChangeDate FROM User WHERE Id = :userId LIMIT 1];
        System.Assert.isTrue(
            refreshedUser.LastPasswordChangeDate > Datetime.now().addMinutes(-1), 
            'Password was not reset for user'
        );
    }

}