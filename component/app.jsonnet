local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.emergency_credentials_controller;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('emergency-credentials-controller', params.namespace);

{
  'emergency-credentials-controller': app,
}
