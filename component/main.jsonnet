// main template for emergency-credentials-controller
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.emergency_credentials_controller;

local alertlabels = {
  syn: 'true',
  syn_component: 'emergency-credentials-controller',
};

local alerts = function(name, groupName, alerts)
  com.namespaced(params.namespace, kube._Object('monitoring.coreos.com/v1', 'PrometheusRule', name) {
    spec+: {
      groups+: [
        {
          name: groupName,
          rules:
            std.sort(std.filterMap(
              function(field) alerts[field].enabled == true,
              function(field) alerts[field].rule {
                alert: field,
                labels+: alertlabels,
              },
              std.objectFields(alerts)
            ), function(x) x.alert),
        },
      ],
    },
  });


local emergencyAccounts =
  std.map(
    function(ea) ea { _create_binding:: super._create_binding },
    com.generateResources(
      params.emergency_accounts,
      function(name) kube._Object('cluster.appuio.io/v1beta1', 'EmergencyAccount', name) {
        metadata+: {
          namespace: params.namespace,
        },
      },
    )
  );


local emergencyAccountBindings = std.filterMap(
  function(name) std.get(params.emergency_accounts[name], '_create_binding', true),
  function(name) kube.ClusterRoleBinding(name) {
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: params.cluster_admin_role,
    },
    subjects: [ {
      kind: 'ServiceAccount',
      name: name,
      namespace: params.namespace,
    } ],
  },
  std.objectFields(params.emergency_accounts),
);

{
  '10_prometheusrule': alerts('emergency-credentials-controller', 'credentials.alerts', params.alerts),
  '20_emergencyaccounts': emergencyAccounts,
  '21_emergencyaccounts_bindings': emergencyAccountBindings,
}
