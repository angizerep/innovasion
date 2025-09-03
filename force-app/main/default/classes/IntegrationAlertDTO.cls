/**
 * @description     : DTO para exponer datos de Integration_Alert__c hacia LWC.
 * @author          : @AngelesPerez
 * @last modified on: 2025-09-02
 * @last modified by: Ángeles Pérez
 */
public with sharing class IntegrationAlertDTO {
    @AuraEnabled public Id id;
    @AuraEnabled public String name;
    @AuraEnabled public String provider;
    @AuraEnabled public String endpoint;
    @AuraEnabled public String endpointId;
    @AuraEnabled public String severity;
    @AuraEnabled public String status;
    @AuraEnabled public String rule;
    @AuraEnabled public Decimal p95_10m;
    @AuraEnabled public Decimal median_60m;
    @AuraEnabled public Decimal mad_60m;
    @AuraEnabled public Integer failures_3m;
    @AuraEnabled public Datetime detectedAt;
    @AuraEnabled public Datetime acknowledgedAt;
    @AuraEnabled public String caseNumber;

    public static IntegrationAlertDTO fromSObject(Integration_Alert__c a, Map<Id, Case> caseById) {
        IntegrationAlertDTO dto = new IntegrationAlertDTO();
        dto.id = a.Id;
        dto.name = a.Name;
        dto.provider = a.Provider__c;
        dto.endpoint = a.Endpoint__c;
        dto.endpointId = a.EndpointId__c;
        dto.severity = a.Severity__c;
        dto.status = a.Status__c;
        dto.rule = a.Rule__c;
        dto.p95_10m = a.P95_10m__c;
        dto.median_60m = a.Median_60m__c;
        dto.mad_60m = a.MAD_60m__c;
        dto.failures_3m = (Integer)a.Failures_3m__c;
        dto.detectedAt = a.DetectedAt__c;
        dto.acknowledgedAt = a.AcknowledgedAt__c;
        if (a.Case__c != null && caseById != null && caseById.containsKey(a.Case__c)) {
            dto.caseNumber = caseById.get(a.Case__c).CaseNumber;
        }
        return dto;
    }
}
