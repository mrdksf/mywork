global without sharing class LightningLoginFormController {

    public LightningLoginFormController() {

    }

    @AuraEnabled
    public static String login(String username, String password, String startUrl) {

        try{
            ApexPages.PageReference lgn = Site.login(username, password, startUrl);
            aura.redirect(lgn);
            return null;
        }catch (Exception ex) {
            return ex.getMessage();
        }
    }

    @AuraEnabled
    public static String xxxx(String username, String password, String startUrl, String token) {

        try{
            if(verify(token) == false){
                return 'System error';
            }
        }catch (Exception ex) {
            return ex.getMessage();
        }

        try{
            ApexPages.PageReference lgn = Site.login(username, password, startUrl);
            aura.redirect(lgn);
            return null;
        }catch (Exception ex) {
            return ex.getMessage();
        }
    }

    private static Boolean verify(String token){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://www.google.com/recaptcha/api/siteverify');
        request.setMethod('POST');
        request.setBody('secret=6LeDK0IbAAAAAPnDQeHtDDX3JTgCDXrOzMvept6W&response=' + token);
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {

            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            if (result.containsKey('success') && result.get('success') == true) {
                if (result.containsKey('score')) {
                    String action = (String)result.get('action');
                    System.debug(action);
                    //TODO: get threshold configuration for each action
                    Decimal threshold = 0.4;
                    Decimal score = (Decimal)result.get('score');
                    if (score > threshold) {
                        return true;
                    }
                }
            } else {
                return false;
            }
        }

        return false;
    }

    @AuraEnabled
    public static Boolean getIsUsernamePasswordEnabled() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getUsernamePasswordEnabled();
    }

    @AuraEnabled
    public static Boolean getIsSelfRegistrationEnabled() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getSelfRegistrationEnabled();
    }

    @AuraEnabled
    public static String getSelfRegistrationUrl() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        if (authConfig.getSelfRegistrationEnabled()) {
            return authConfig.getSelfRegistrationUrl();
        }
        return null;
    }

    @AuraEnabled
    public static String getForgotPasswordUrl() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getForgotPasswordUrl();
    }

    @TestVisible
    private static Auth.AuthConfiguration getAuthConfig(){
        Id networkId = Network.getNetworkId();
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(networkId,'');
        return authConfig;
    }

    @AuraEnabled
    global static String setExperienceId(String expId) {
        // Return null if there is no error, else it will return the error message
        try {
            if (expId != null) {
                Site.setExperienceId(expId);
            }
            return null;
        } catch (Exception ex) {
            return ex.getMessage();
        }
    }
}