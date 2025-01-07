local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.emergency_credentials_controller;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('emergency-credentials-controller', params.namespace);

local appPath =
  local project = std.get(app, 'spec', { project: 'syn' }).project;
  if project == 'syn' then 'apps' else 'apps-%s' % project;

{
  ['%s/emergency-credentials-controller' % appPath]: app,
}
