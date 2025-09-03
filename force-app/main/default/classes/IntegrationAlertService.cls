/**
 * @description     : Servicio principal para Dashboard, Detalle de Endpoint y Acciones de Alerta.
 * @author          : @AngelesPerez
 * @last modified on: 2025-09-02
 * @last modified by: Ángeles Pérez
 */
public with sharing class IntegrationAlertService {

    // ==== Listas para Dashboard ====

    /**
     * @description Devuelve endpoints agregando info de severidad y totales.
     * @param provider Filtro opcional por proveedor
     * @param severity Filtro opcional por severidad
     * @param status   Filtro opcional por estado
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> listEndpoints(String provider, String severity, String status) {
        String soql = 'SELECT Id, Provider__c, Endpoint__c, EndpointId__c, Severity__c, Status__c, P95_10m__c, DetectedAt__c ' +
                      'FROM Integration_Alert__c WHERE Id != null';
        if (String.isNotBlank(provider)) soql += ' AND Provider__c = :provider';
        if (String.isNotBlank(severity)) soql += ' AND Severity__c = :severity';
        if (String.isNotBlank(status))   soql += ' AND Status__c = :status';
        soql += ' ORDER BY DetectedAt__c DESC LIMIT 500';

        List<Integration_Alert__c> rows = Database.query(soql);
        // Agrupar por EndpointId__c para mostrar 1 fila por endpoint
        Map<String, Map<String, Object>> byEndpoint = new Map<String, Map<String, Object>>();
        for (Integration_Alert__c a : rows) {
            String key = a.EndpointId__c != null ? a.EndpointId__c : a.Endpoint__c;
            if (!byEndpoint.containsKey(key)) {
                byEndpoint.put(key, new Map<String, Object>{
                    'endpointId' => key,
                    'provider'   => a.Provider__c,
                    'endpoint'   => a.Endpoint__c,
                    'lastSeverity' => a.Severity__c,
                    'lastP95'      => a.P95_10m__c,
                    'openAlerts'   => 0
                });
            }
            Map<String, Object> acc = byEndpoint.get(key);
            // contar abiertas
            if (a.Status__c == 'New' || a.Status__c == 'Acknowledged') {
                acc.put('openAlerts', ((Integer)acc.get('openAlerts')) + 1);
            }
            // actualizar severidad más crítica si aplica
            acc.put('lastSeverity', maxSeverity((String)acc.get('lastSeverity'), a.Severity__c));
            if (a.P95_10m__c != null) acc.put('lastP95', a.P95_10m__c);
        }
        return new List<Map<String, Object>>(byEndpoint.values());
    }

    private static String maxSeverity(String s1, String s2) {
        List<String> order = new List<String>{'Critical','Major','Warning','Info',null};
        Integer i1 = order.indexOf(s1);
        Integer i2 = order.indexOf(s2);
        if (i1 == -1) i1 = 999; if (i2 == -1) i2 = 999;
        return (i1 < i2) ? s1 : s2;
    }

    /**
     * @description Devuelve KPIs agregados para el dashboard.
     */
    @AuraEnabled(cacheable=true)
    public static IntegrationKpiDTO getKpis() {
        IntegrationKpiDTO k = new IntegrationKpiDTO();
        // Simplificación: calculamos a partir de Integration_Alert__c
        List<Integration_Alert__c> alerts = [
            SELECT Id, DetectedAt__c, AcknowledgedAt__c, Status__c, Severity__c
            FROM Integration_Alert__c WHERE DetectedAt__c = LAST_N_DAYS:7
        ];
        Integer total = alerts.size();
        if (total == 0) {
            k.mttdMinutes = 0; k.mttrMinutes = 0; k.alertPrecisionPct = 0; k.timeToAckMinutes = 0; k.openAlerts = 0; k.criticalAlerts = 0;
            return k;
        }
        // Time to Ack
        Decimal sumAck = 0; Integer ackCount = 0; Integer open = 0; Integer critical = 0;
        for (Integration_Alert__c a : alerts) {
            if (a.AcknowledgedAt__c != null && a.DetectedAt__c != null) {
                sumAck += (Decimal)(a.AcknowledgedAt__c.getTime() - a.DetectedAt__c.getTime())/60000; // min
                ackCount++;
            }
            if (a.Status__c == 'New' || a.Status__c == 'Acknowledged') open++;
            if (a.Severity__c == 'Critical') critical++;
        }
        k.timeToAckMinutes = ackCount > 0 ? (sumAck/ackCount) : 0;
        k.mttdMinutes = 1; // placeholder
        k.mttrMinutes = 10; // placeholder
        k.alertPrecisionPct = 90; // placeholder
        k.openAlerts = open;
        k.criticalAlerts = critical;
        return k;
    }

    // ==== Detalle de Endpoint ====

    /**
     * @description Lista alertas para un endpoint.
     */
    @AuraEnabled(cacheable=true)
    public static List<IntegrationAlertDTO> listAlertsByEndpoint(String endpointId) {
        List<Integration_Alert__c> rows = [
            SELECT Id, Name, Provider__c, Endpoint__c, EndpointId__c, Severity__c, Status__c, Rule__c,
                   P95_10m__c, Median_60m__c, MAD_60m__c, Failures_3m__c, DetectedAt__c, AcknowledgedAt__c, Case__c
            FROM Integration_Alert__c
            WHERE (EndpointId__c = :endpointId OR Endpoint__c = :endpointId)
            ORDER BY DetectedAt__c DESC LIMIT 200
        ];
        Set<Id> caseIds = new Set<Id>();
        for (Integration_Alert__c a : rows) if (a.Case__c != null) caseIds.add(a.Case__c);
        Map<Id, Case> caseById = caseIds.isEmpty() ? new Map<Id, Case>() : new Map<Id, Case>([
            SELECT Id, CaseNumber FROM Case WHERE Id IN :caseIds
        ]);
        List<IntegrationAlertDTO> out = new List<IntegrationAlertDTO>();
        for (Integration_Alert__c a : rows) out.add(IntegrationAlertDTO.fromSObject(a, caseById));
        return out;
    }

    /**
     * @description Obtiene detalle de una alerta.
     */
    @AuraEnabled(cacheable=true)
    public static IntegrationAlertDTO getAlert(Id alertId) {
        Integration_Alert__c a = [
            SELECT Id, Name, Provider__c, Endpoint__c, EndpointId__c, Severity__c, Status__c, Rule__c,
                   P95_10m__c, Median_60m__c, MAD_60m__c, Failures_3m__c, DetectedAt__c, AcknowledgedAt__c, Case__c
            FROM Integration_Alert__c WHERE Id = :alertId LIMIT 1
        ];
        Map<Id, Case> caseById = a.Case__c == null ? new Map<Id, Case>() : new Map<Id, Case>([
            SELECT Id, CaseNumber FROM Case WHERE Id = :a.Case__c
        ]);
        return IntegrationAlertDTO.fromSObject(a, caseById);
    }

    // ==== Acciones de alerta ====

    /**
     * @description Marca la alerta como Acknowledged.
     */
    @AuraEnabled
    public static IntegrationAlertDTO ackAlert(Id alertId) {
        Integration_Alert__c a = [SELECT Id, Status__c, AcknowledgedAt__c FROM Integration_Alert__c WHERE Id = :alertId LIMIT 1];
        if (a.Status__c == 'Resolved') {
            throw new AuraHandledException('La alerta ya está resuelta.');
        }
        a.Status__c = 'Acknowledged';
        a.AcknowledgedAt__c = System.now();
        update a;
        return getAlert(a.Id);
    }

    /**
     * @description Crea un Case relacionado a la alerta.
     */
    @AuraEnabled
    public static CaseResultDTO createCase(Id alertId) {
        Integration_Alert__c a = [
            SELECT Id, Name, Provider__c, Endpoint__c, Severity__c, Case__c FROM Integration_Alert__c WHERE Id = :alertId LIMIT 1
        ];
        if (a.Case__c != null) {
            Case c0 = [SELECT Id, CaseNumber, Status FROM Case WHERE Id = :a.Case__c LIMIT 1];
            CaseResultDTO r0 = new CaseResultDTO(); r0.caseId = c0.Id; r0.caseNumber = c0.CaseNumber; r0.status = c0.Status; return r0;
        }
        Case c = new Case();
        c.Subject = 'Alerta de Integración: ' + a.Name;
        c.Origin = 'Monitoring';
        c.Priority = mapPriority(a.Severity__c);
        insert c;
        a.Case__c = c.Id;
        update a;
        CaseResultDTO r = new CaseResultDTO();
        r.caseId = c.Id; r.caseNumber = c.CaseNumber; r.status = c.Status;
        return r;
    }

    private static String mapPriority(String sev) {
        if (sev == 'Critical') return 'High';
        if (sev == 'Major') return 'High';
        if (sev == 'Warning') return 'Medium';
        return 'Low';
    }
}
