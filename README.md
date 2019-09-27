# ZSpec

ZSpec is a distributed test runner for RSpec. It consists of a `worker`, a `client`, and a `redis` store.

# The Worker
The workers are se pods running on k8s, they run `zspec work` which polls redis for work and upload the results back to redis.

# The Client

The client (in this case drone) queues up the specs by running `zspec queue_specs spec/ scenarios`. Then zspec kicks off the following events:
1) calls out to rspec to get the specs to run.
2) cleans the filepaths.
3) orders the specs by previous runtime, longest to shortest.
4) adds the specs to the redis queue.
5) sets a counter with the count of specs that were added.

Then the client runs `zspec present` which polls redis for completed specs, for each non-duplicate completed spec, it stores the result in memory and decrements the counter. Once the counter hits 0 it exits the loop and prints the results.

![workflow](https://github.com/StreetEasy/zspec/blob/master/workflow.png "Workflow")

# FAQ

Issue: My ZSpec build is stuck in the images state for more than 30 minutes. 
Remediation:
1) Click the Cancel button on the build in Drone
2) Click the Restart button on the build in Drone
