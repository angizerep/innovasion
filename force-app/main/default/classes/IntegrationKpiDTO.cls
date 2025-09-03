/**
 * @description     : KPIs para el Dashboard (MTTD, MTTR, precisión, time-to-ack).
 * @author          : @AngelesPerez
 * @last modified on: 2025-09-02
 * @last modified by: Ángeles Pérez
 */
public with sharing class IntegrationKpiDTO {
    @AuraEnabled public Decimal mttdMinutes;
    @AuraEnabled public Decimal mttrMinutes;
    @AuraEnabled public Decimal alertPrecisionPct;
    @AuraEnabled public Decimal timeToAckMinutes;
    @AuraEnabled public Integer openAlerts;
    @AuraEnabled public Integer criticalAlerts;
}
