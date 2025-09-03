/**
 * @description     : Resultado de creación de Case desde una alerta.
 * @author          : @AngelesPerez
 * @last modified on: 2025-09-02
 * @last modified by: Ángeles Pérez
 */
public with sharing class CaseResultDTO {
    @AuraEnabled public Id caseId;
    @AuraEnabled public String caseNumber;
    @AuraEnabled public String status;
}
