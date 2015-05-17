# sg-dependency-viewer
AWS EC2 security group dependency viewer

You can view the group dependency of the security groups.

For example,
`$ aws ec2 describe-security-groups |ruby sg-dv.rb -a`
shows SecurityGroup dependency in text format.

	sg-59a6dbxx
		Tags:
		Descritption: Slave group for Elastic MapReduce
		IpPermissions: #3
		IpPermissionsEgress: #0
		[Group] referred by sg-57a6dbyy ((ElasticMapReduce-master))
		[Group] self reference
	sg-another...

And,
`$ aws ec2 describe-security-groups |ruby sg-dv.rb -a`
generates `output.dot`.
You can make security dependency chart with graphviz (/usr/bin/dot).
`$ dot -T pdf output.dot -O`
(Please see sample-output.png.)

# Usage


	Usage: ./sg-dv.rb [options] security_group.json
		-a                               Enable ALL (= cdgt)
		-c                               show group chain
		-d                               show Description
		-g VALUE                         show this group only. example: sg-12345678
		-t                               show TAG
			--no-ipp                     Disable to show IpPermission
        
