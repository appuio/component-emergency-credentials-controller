// main template for openshift4-slos
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

local slo = import 'slos.libsonnet';

local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.emergency_credentials_controller;

com.Kustomization(
  'https://github.com/appuio/emergency-credentials-controller//config/crd',
  params.manifests_version,
  {},
  params.kustomize_input {
    commonAnnotations+: {
      // Use replace for CRDs to avoid errors because the
      // last-applied-configuration annotation gets too big.
      'argocd.argoproj.io/sync-options': 'Replace=true',
    },
    labels+: [
      {
        pairs: {
          'app.kubernetes.io/managed-by': 'commodore',
        },
      },
    ],
  },
)
