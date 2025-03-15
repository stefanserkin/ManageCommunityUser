public inherited sharing class FlowGetOrgBaseUrl {
    
    @InvocableMethod(label='Get Base URL' description='Returns the base url for the current org' category='Users')
    public static List<Result> getBaseUrl() {
        Result result = new Result();
        result.orgBaseUrl = System.URL.getOrgDomainUrl().toExternalForm();
        return new List<Result>{result};
    }
    
    public class Result {
        @InvocableVariable(label='Base URL')
        public String orgBaseUrl;
    }

}