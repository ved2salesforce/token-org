/**
 * Refers to an LWC that does not exist in this project (c-missing-component).
 * Intentionally dangling, e.g. for testing dependency/reference checks.
 */
public with sharing class MissingLwcReference {
    // Expected at force-app/main/default/lwc/missingComponent, which is absent.
    public static final String LWC_NAME = 'c:missingComponent';

    @AuraEnabled(cacheable=true)
    public static String getComponentName() {
        return LWC_NAME;
    }
}
