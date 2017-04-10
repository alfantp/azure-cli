from azure.cli.testsdk import ScenarioTest, JMESPathCheck, ResourceGroupPreparer

class RedisCacheTests(ScenarioTest):
    @ResourceGroupPreparer()
    def test_create_redis_cache(self, resource_group):
        name = self.create_random_name(prefix='cli', length=24)
        self.cmd('az redis create -n {} -g {} -l {} --sku-name {} --sku-family {} --sku-capacity {}'.format(
            name, resource_group, 'WestUS', 'Basic','C','0'))
        self.cmd('az redis show -n {} -g {}'.format(name, resource_group), checks=[
            JMESPathCheck('name', name),
            JMESPathCheck('provisioningState', 'Creating')
        ])
        self.cmd('az redis list -g {}'.format(resource_group))
        self.cmd('az redis list-keys -n {} -g {}'.format(name, resource_group))
