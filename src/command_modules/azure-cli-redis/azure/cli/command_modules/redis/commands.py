# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

from azure.cli.core.commands import CliCommandType

# pylint: disable=line-too-long
from azure.cli.command_modules.redis._client_factory import cf_redis, cf_patch_schedules, cf_firewall_rule, cf_linked_server
from azure.cli.command_modules.redis.custom import wrong_vmsize_argument_exception_handler


def load_command_table(self, _):

    redis_sdk = CliCommandType(
        operations_tmpl='azure.mgmt.redis.operations.redis_operations#RedisOperations.{}',
        client_factory=cf_redis)

    redis_patch = CliCommandType(
        operations_tmpl='azure.mgmt.redis.operations.patch_schedules_operations#PatchSchedulesOperations.{}',
        client_factory=cf_patch_schedules)

    redis_firewall_rules = CliCommandType(
        operations_tmpl='azure.mgmt.redis.operations.firewall_rules_operations#FirewallRulesOperations.{}',
        client_factory=cf_firewall_rule)

    redis_linked_server = CliCommandType(
        operations_tmpl='azure.mgmt.redis.operations.linked_server_operations#LinkedServerOperations.{}',
        client_factory=cf_linked_server)

    with self.command_group('redis', redis_sdk) as g:
        g.custom_command('create', 'cli_redis_create', client_factory=cf_redis,
                         exception_handler=wrong_vmsize_argument_exception_handler)
        g.command('delete', 'delete')
        g.custom_command('export', 'cli_redis_export')
        g.command('force-reboot', 'force_reboot')
        g.custom_command('import-method', 'cli_redis_import_method')
        g.command('import', 'import_data')
        g.command('list', 'list_cache')
        g.command('list-keys', 'list_keys')
        g.command('regenerate-keys', 'regenerate_key')
        g.command('show', 'get')
        g.generic_update_command('update', exception_handler=wrong_vmsize_argument_exception_handler,
                                 setter_name='update', custom_func_name='cli_redis_update')

    with self.command_group('redis patch-schedule', redis_patch) as g:
        g.command('create', 'create_or_update')
        g.command('update', 'create_or_update')
        g.command('delete', 'delete')
        g.command('show', 'get')

    with self.command_group('redis firewall-rules', redis_firewall_rules) as g:
        g.command('create', 'create_or_update')
        g.command('update', 'create_or_update')
        g.command('delete', 'delete')
        g.command('show', 'get')
        g.command('list', 'list_by_redis_resource')

    with self.command_group('redis linked-server', redis_linked_server) as g:
        g.custom_command('create', 'cli_redis_create_server_link', client_factory=cf_linked_server)
        g.command('delete', 'delete')
        g.command('show', 'get')
        g.command('list', 'list')
