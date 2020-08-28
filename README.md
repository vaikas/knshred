# knshred are couple of helpers for dealing with Knative Eventing

## Background

So every now and then integration tests fail and you want to fetch some logs
like the integration test logs as well as in some cases you might want to fetch
and see what the controllers were up to. So, I hacked up some super (crappy, but
seemingly functional scripts). These scripts allow you to do couple of things:

1. Fetch the logs given a PR number
1. Fetch the logs given a CI Prow number
1. Do some rudimentary shredding of the logs to make it easier to reason about
   failures. 

## Fetching logs


### Fetching the build log (failed tests)

So, you have a b0rk3d integration test, just do this to fetch the logs:

```
./fetch.sh -p <PR>
```

So, for chaos broker testing, the lovely gift that kept on giving was
[3599](https://github.com/knative/eventing/pull/3599) so to fetch the logs to my
local machine, I'd do:

```
./fetch.sh -p 3599
```

### Fetching CI failures

So, say there's a CI failure, for example this
[one](https://prow.knative.dev/view/gcs/knative-prow/logs/ci-knative-eventing-contrib-continuous/1291684970015756288)
and you'd like to get some insights into it. Note that this is an example from
eventing-contrib repo and targeting a CI (instead of PR like above).


```
./fetch-continuous.sh -r 1291684970015756288 --repo eventing-contrib
```

This results in fetching the failed tests (build-log.txt) as well as the logs
for all the pods in knative-eventing.

```
vaikas-a01:knshred vaikas$ ls -l /tmp/1291684970015756288/
total 53016
-rw-r--r--  1 vaikas  wheel  2115869 Aug 28 11:06 build-log.txt
-rw-r--r--  1 vaikas  wheel  3857950 Aug 28 11:06 eventing-controller-56f8bb4556-qhkcg-eventing-controller.log
-rw-r--r--  1 vaikas  wheel  8466849 Aug 28 11:07 eventing-webhook-665b8c94d7-wptdg-eventing-webhook.log
-rw-r--r--  1 vaikas  wheel  1929393 Aug 28 11:07 kafka-ch-controller-5c9cd47784-mprxf-controller.log
-rw-r--r--  1 vaikas  wheel  1987366 Aug 28 11:07 kafka-ch-dispatcher-6bcbc4c44c-hddv4-dispatcher.log
-rw-r--r--  1 vaikas  wheel   743766 Aug 28 11:07 kafka-webhook-6bb4b5ff6b-4xljf-kafka-webhook.log
-rw-r--r--  1 vaikas  wheel  3465854 Aug 28 11:07 mt-broker-controller-69b6f6b956-nqkg8-mt-broker-controller.log
-rw-r--r--  1 vaikas  wheel     6971 Aug 28 11:07 mt-broker-filter-64db5c67bc-r8j7t-filter.log
-rw-r--r--  1 vaikas  wheel     3270 Aug 28 11:07 mt-broker-ingress-7c849fb6b8-q5g66-ingress.log
-rw-r--r--  1 vaikas  wheel   678251 Aug 28 11:07 natss-ch-controller-546cf84d5f-7qbcb-controller.log
-rw-r--r--  1 vaikas  wheel  1077008 Aug 28 11:07 natss-ch-dispatcher-67f6cf4cc4-gwvwd-dispatcher.log
```

So, we can grab the failed test from the build-log.txt (just copied here from
the log):

```
    operation.go:94: Failed to get all KResources ready failed waiting for {TypeMeta:{Kind:Trigger APIVersion:eventing.knative.dev/v1} ObjectMeta:{Name:trigger GenerateName: Namespace:test-broker-redelivery-kafka-channel-messaging-knative-devdrc5g SelfLink: UID: ResourceVersion: Generation:0 CreationTimestamp:0001-01-01 00:00:00 +0000 UTC DeletionTimestamp:<nil> DeletionGracePeriodSeconds:<nil> Labels:map[] Annotations:map[] OwnerReferences:[] Finalizers:[] ClusterName: ManagedFields:[]}} to become ready: timed out waiting for the condition
    operation.go:115: Failed to get all test resources ready: failed waiting for {TypeMeta:{Kind:Trigger APIVersion:eventing.knative.dev/v1} ObjectMeta:{Name:trigger GenerateName: Namespace:test-broker-redelivery-kafka-channel-messaging-knative-devdrc5g SelfLink: UID: ResourceVersion: Generation:0 CreationTimestamp:0001-01-01 00:00:00 +0000 UTC DeletionTimestamp:<nil> DeletionGracePeriodSeconds:<nil> Labels:map[] Annotations:map[] OwnerReferences:[] Finalizers:[] ClusterName: ManagedFields:[]}} to become ready: timed out waiting for the condition
        knative.dev/eventing/test/lib.(*Client).WaitForAllTestResourcesReadyOrFail
        	/home/prow/go/src/knative.dev/eventing-contrib/vendor/knative.dev/eventing/test/lib/operation.go:115
        knative.dev/eventing/test/e2e/helpers.brokerRedelivery
        	/home/prow/go/src/knative.dev/eventing-contrib/vendor/knative.dev/eventing/test/e2e/helpers/broker_redelivery_helper.go:103
        knative.dev/eventing/test/e2e/helpers.BrokerRedelivery.func1
        	/home/prow/go/src/knative.dev/eventing-contrib/vendor/knative.dev/eventing/test/e2e/helpers/broker_redelivery_helper.go:42
        testing.tRunner
        	/root/.gvm/gos/go1.14.6/src/testing/testing.go:1039
        runtime.goexit
        	/root/.gvm/gos/go1.14.6/src/runtime/asm_amd64.s:1373

```

Ok, so the namespace we'd like to inspect is
`test-broker-redelivery-kafka-channel-messaging-knative-devdrc5g` so let's
combine and sort the various logs so we get a linear looksie of what's going
on.

```
./combine.go -dir=/tmp/1291684970015756288/ -namespace=test-broker-redelivery-kafka-channel-messaging-knative-devdrc5g > /tmp/lllllllllllll
```

And then in that file you'll get all the relevant lines interleaved for that
namespace. If you only want to know about the particular keys (aka, a single
resource), you can specify -key flag also.

### Fetching the k8s logs (controller, webhooks, etc.)

That will only fetch the build-log.txt (build / test that will show you what
failed). If you specify the `-k` flag it will fetch also the artifacts, which
contain all the controller logs and some other stuff as well. This is not on by
default because those logs can be huge...

But thanks to good old `3599`, I needed those logs too, so I'd use:

```
./fetch.sh -p 3599 -k
```

It will then download the logs into `/tmp/<PR>` directory, so when I ran the
command I'd have something like this waiting for me, yay!

```
vaikas-a01:eventing vaikas$ ls -altr /tmp/3599
total 1203600
drwxrwxrwt  45 root    wheel       1440 Jul 16 16:53 ..
-rw-r--r--   1 vaikas  wheel   10370807 Jul 16 16:53 build-log.txt
drwxr-xr-x   4 vaikas  wheel        128 Jul 16 16:53 .
-rw-r--r--   1 vaikas  wheel  601411238 Jul 16 16:54 k8s.log.txt
```

### Fetching the k8s metrics logs

You can also fetch the k8s metrics logs. This is the result of doing a curl
against `<apiserver>/metrics` and just dumping the results of that. You can do
this by using the `-m` flag.

```
./fetch.sh -p 3666 -m
```

```
vaikas-a01:knshred vaikas$ ls -l /tmp/3666
total 6328
-rw-r--r--  1 vaikas  wheel    50300 Jul 21 03:12 build-log.txt
-rw-r--r--  1 vaikas  wheel  2714694 Jul 21 03:12 k8s.metrics.txt
```

## Fetching from different repos

fetch.sh also works for things like eventing-contrib, just use the `-r`
flag. It defaults to eventing, so if you wanted to fetch logs for
`eventing-contrib` you could do it like so:

```
./fetch.sh -p 1378 -r eventing-contrib -k
```

It will then do the same thing and download the logs like so:

```
vaikas-a01:knshred vaikas$ ls -l /tmp/1378/
total 69720
-rw-r--r--  1 vaikas  wheel   1485002 Jul 17 10:17 build-log.txt
-rw-r--r--  1 vaikas  wheel  32788863 Jul 17 10:17 k8s.log.txt
```


## Shredding logs

You need to build the shred.go first

```
go build ./shred.go

```

Another thing is that if there are multiple test failures, we probably want to
slice these a bit. So, for example if you wanted to see the failed tests broken
up and split into their own smaller files that you could then inspect, you could
run the following:

```
./shred.sh -d /tmp/3599/
```

And since there were two lucky winners in that run that failed, after this
you'll see:

```
vaikas-a01:eventing vaikas$ ls -l /tmp/3599/
total 1203624
-rw-r--r--  1 vaikas  wheel   10370807 Jul 16 16:53 build-log.txt
-rw-r--r--  1 vaikas  wheel       3580 Jul 16 16:58 build-log.txt.TestPingSourceV1Alpha2EventTypes
-rw-r--r--  1 vaikas  wheel       4295 Jul 16 16:58 build-log.txt.TestTriggerDependencyAnnotation
-rw-r--r--  1 vaikas  wheel  601411238 Jul 16 16:54 k8s.log.txt
```

That way you can see only the failures for those two tests broken into their own
test files.

Ok, but what can you do for me about them k8s files?? Well, if you specify the
`-k` flag, it will parse the k8s.log.txt and fetch only the relevant bits from
the controller logs that pertain to those failed tests? But, Ville?? How can you
tell that? Well, because each test runs in it's own namespace, we first find the
failed tests from above, figure out which namespace they ran, then and only
after that do we now go out and fetch the relevant entries from the k8s
logs. Since I was working on the `mt-broker-controller` controller, I specified
that I only wanted to look at them with the -m flag.

```
./shred.sh -d /tmp/3599/ -k -m mt-broker-controller
```

And now again we'll see two new files there:

```
vaikas-a01:eventing vaikas$ ls -l /tmp/3599/
total 1203728
-rw-r--r--  1 vaikas  wheel   10370807 Jul 16 16:53 build-log.txt
-rw-r--r--  1 vaikas  wheel       3580 Jul 16 17:05 build-log.txt.TestPingSourceV1Alpha2EventTypes
-rw-r--r--  1 vaikas  wheel       4295 Jul 16 17:05 build-log.txt.TestTriggerDependencyAnnotation
-rw-r--r--  1 vaikas  wheel  601411238 Jul 16 16:54 k8s.log.txt
-rw-r--r--  1 vaikas  wheel      25372 Jul 16 17:05 k8s.log.txt.TestPingSourceV1Alpha2EventTypes
-rw-r--r--  1 vaikas  wheel      24378 Jul 16 17:05 k8s.log.txt.TestTriggerDependencyAnnotation
```

## Inspecting the controller logs

Until we get logstreamer running all over everywhere, you can 

You need to build the shred.go first

```
go build ./shred.go

```

Another thing is that if there are multiple test failures, we probably want to
slice these a bit. So, for example if you wanted to see the failed tests broken
up and split into their own smaller files that you could then inspect, you could
run the following:

```
./shred.sh -d /tmp/3599/
```

And since there were two lucky winners in that run that failed, after this
you'll see:

```
vaikas-a01:eventing vaikas$ ls -l /tmp/3599/
total 1203624
-rw-r--r--  1 vaikas  wheel   10370807 Jul 16 16:53 build-log.txt
-rw-r--r--  1 vaikas  wheel       3580 Jul 16 16:58 build-log.txt.TestPingSourceV1Alpha2EventTypes
-rw-r--r--  1 vaikas  wheel       4295 Jul 16 16:58 build-log.txt.TestTriggerDependencyAnnotation
-rw-r--r--  1 vaikas  wheel  601411238 Jul 16 16:54 k8s.log.txt
```

That way you can see only the failures for those two tests broken into their own
test files.

Ok, but what can you do for me about them k8s files?? Well, if you specify the
`-k` flag, it will parse the k8s.log.txt and fetch only the relevant bits from
the controller logs that pertain to those failed tests? But, Ville?? How can you
tell that? Well, because each test runs in it's own namespace, we first find the
failed tests from above, figure out which namespace they ran, then and only
after that do we now go out and fetch the relevant entries from the k8s
logs. Since I was working on the `mt-broker-controller` controller, I specified
that I only wanted to look at them with the -m flag.

```
./shred.sh -d /tmp/3599/ -k -m mt-broker-controller
```

And now again we'll see two new files there:

```
vaikas-a01:eventing vaikas$ ls -l /tmp/3599/
total 1203728
-rw-r--r--  1 vaikas  wheel   10370807 Jul 16 16:53 build-log.txt
-rw-r--r--  1 vaikas  wheel       3580 Jul 16 17:05 build-log.txt.TestPingSourceV1Alpha2EventTypes
-rw-r--r--  1 vaikas  wheel       4295 Jul 16 17:05 build-log.txt.TestTriggerDependencyAnnotation
-rw-r--r--  1 vaikas  wheel  601411238 Jul 16 16:54 k8s.log.txt
-rw-r--r--  1 vaikas  wheel      25372 Jul 16 17:05 k8s.log.txt.TestPingSourceV1Alpha2EventTypes
-rw-r--r--  1 vaikas  wheel      24378 Jul 16 17:05 k8s.log.txt.TestTriggerDependencyAnnotation
```

## TODO:

1. Make the grep flags configurable. My bash-fu doesn't really shine there.





