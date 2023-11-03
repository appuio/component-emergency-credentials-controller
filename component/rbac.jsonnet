local kube = import 'lib/kube.libjsonnet';

local aggregatedRoles = [
  kube.ClusterRole('appuio:emergency-credentials-controller:view') {
    metadata+: {
      labels+: {
        'rbac.authorization.k8s.io/aggregate-to-admin': 'true',
      },
    },
    rules: [
      {
        apiGroups: [ 'cluster.appuio.io' ],
        resources: [
          'emergencyaccounts',
        ],
        verbs: [
          'get',
          'list',
          'watch',
        ],
      },
    ],
  },
  kube.ClusterRole('appuio:emergency-credentials-controller:edit') {
    metadata+: {
      labels+: {
        'rbac.authorization.k8s.io/aggregate-to-admin': 'true',
      },
    },
    rules: [
      {
        apiGroups: [ 'cluster.appuio.io' ],
        resources: [
          'emergencyaccounts',
        ],
        verbs: [
          'create',
          'delete',
          'deletecollection',
          'patch',
          'update',
        ],
      },
    ],
  },
];

{
  '30_rbac': aggregatedRoles,
}
