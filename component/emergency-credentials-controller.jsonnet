// main template for openshift4-slos
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

local slo = import 'slos.libsonnet';

local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.emergency_credentials_controller;

local upstreamNamespace = 'emergency-credentials-controller-system';

local removeUpstreamNamespace = kube.Namespace(upstreamNamespace) {
  metadata: {
    name: upstreamNamespace,
  } + com.makeMergeable(params.namespaceMetadata),
};

local removeUpstreamAlerts = {
  '$patch': 'delete',
  apiVersion: 'monitoring.coreos.com/v1',
  kind: 'PrometheusRule',
  metadata: {
    name: 'emergency-credentials-controller-controller-manager-alerts',
    namespace: upstreamNamespace,
  },
};

local deploymentPatch = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: 'controller-manager',
    namespace: upstreamNamespace,
  },
} + com.makeMergeable(params.controller_deployment_patch);

local setPriorityClass = {
  patch: |||
    - op: add
      path: "/spec/template/spec/priorityClassName"
      value: "system-cluster-critical"
  |||,
  target: {
    kind: 'Deployment',
    name: 'emergency-credentials-controller-controller-manager',
  },
};

local patch = function(p) {
  patch: std.manifestJsonMinified(p),
};

com.Kustomization(
  'https://github.com/appuio/emergency-credentials-controller//config/default',
  params.manifests_version,
  {
    'ghcr.io/appuio/emergency-credentials-controller': {
      local image = params.images.emergency_credentials_controller,
      newTag: image.tag,
      newName: '%(registry)s/%(image)s' % image,
    },
    'quay.io/brancz/kube-rbac-proxy': {
      local image = params.images.kube_rbac_proxy,
      newTag: image.tag,
      newName: '%(registry)s/%(image)s' % image,
    },
  },
  params.kustomize_input {
    patches+: [
      patch(removeUpstreamNamespace),
      patch(removeUpstreamAlerts),
      patch(deploymentPatch),
      setPriorityClass,
    ],
    labels+: [
      {
        pairs: {
          'app.kubernetes.io/managed-by': 'commodore',
        },
      },
    ],
  },
)
