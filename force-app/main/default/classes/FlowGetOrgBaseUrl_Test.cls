@IsTest
private class FlowGetOrgBaseUrl_Test {
    
    @IsTest
    static void testGetBaseUrl() {
        String orgBaseUrl = System.URL.getOrgDomainUrl().toExternalForm();
        List<FlowGetOrgBaseUrl.Result> results = FlowGetOrgBaseUrl.getBaseUrl();
        String returnedUrl = results[0].orgBaseUrl;
        System.assertEquals(orgBaseUrl, returnedUrl, 'Should have received the base url for the org');
    }

}