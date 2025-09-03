/**
 * @description     : Pruebas del servicio de alertas (ack y creación de Case).
 * @author          : @AngelesPerez
 * @last modified on: 2025-09-02
 * @last modified by: Ángeles Pérez
 */
@IsTest
private class IntegrationAlertServiceTest {

    @testSetup
    static void setupData() {
        Integration_Alert__c a = new Integration_Alert__c();
        a.Name = 'PAYMENTS_API p95 alto';
        a.Provider__c = 'AcmePay';
        a.Endpoint__c = '/payments/v1';
        a.EndpointId__c = 'payments-v1';
        a.Severity__c = 'Critical';
        a.Status__c = 'New';
        a.Rule__c = 'p95_10m > mediana+3*MAD';
        a.P95_10m__c = 950;
        a.Median_60m__c = 300;
        a.MAD_60m__c = 50;
        a.DetectedAt__c = System.now().addMinutes(-5);
        insert a;
    }

    @IsTest
    static void testAckAlert() {
        Integration_Alert__c a = [SELECT Id FROM Integration_Alert__c LIMIT 1];
        Test.startTest();
        IntegrationAlertDTO dto = IntegrationAlertService.ackAlert(a.Id);
        Test.stopTest();
        System.assertEquals('Acknowledged', dto.status);
        System.assertNotEquals(null, dto.acknowledgedAt);
    }

    @IsTest
    static void testCreateCase() {
        Integration_Alert__c a = [SELECT Id FROM Integration_Alert__c LIMIT 1];
        Test.startTest();
        CaseResultDTO res = IntegrationAlertService.createCase(a.Id);
        Test.stopTest();
        System.assertNotEquals(null, res.caseId);
        System.assertStartsWith('Alerta', [SELECT Subject FROM Case WHERE Id = :res.caseId].Subject);
        IntegrationAlertDTO dto = IntegrationAlertService.getAlert(a.Id);
        System.assertNotEquals(null, dto.caseNumber);
    }
}
