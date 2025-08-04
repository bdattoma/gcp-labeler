_The following document is generated with the assistance of an LLM_
# Instructions for setting up GCP Auto Labeler
Two possible workflows:
- Event-driver: Any cloud Resource Created → Audit Log → Log Sink → Pub/Sub Topic → Cloud Run function (i.e., labeler)
- Frequency-based: Cloud Scheduler -> Cloud Run function

Note: the instructions are assuming you use the bash script [update_labels.sh](./cloud-run-app/update_labels.sh), however there is an initial draft of a Python version. Feel free to use it and extend it.


## Workflow 1: Event-driver

1. Create a Pub/Sub Topic
This topic will act as the central messaging hub.

Go to the Pub/Sub section in the Google Cloud Console.

Click Create Topic and give it a unique ID (e.g., resource-creation-events).

2. Create a Log Sink
The sink will find the relevant audit logs and send them to your Pub/Sub topic.

In the Google Cloud Console, navigate to Logging > Log Router.

Click Create Sink.

- Sink Details: Give the sink a name (e.g., audit-log-sink-for-creations).

- Sink Destination:

    - Select Cloud Pub/Sub topic as the sink service.

    - Choose the Pub/Sub topic you created in Step 1.

- Log Filter: This is the most important part. You need to build an inclusion filter to capture creation events from Admin Activity logs across all services. Use the following filter:

```code
logName:"cloudaudit.googleapis.com%2Factivity" AND
protoPayload.methodName =~ "(?i)create|insert"
```

- Click Create Sink. You may need to grant the sink's service account permission to publish to the topic.

3. Buiild the image with [Dockerfile](./cloud-run-app/Dockerfile)

4. Create a Container Registry in google cloud
    - click on Create Repository and follow the form
    - after created, you can get the login command from `Setup instructions` button

5. Push the built image to the newly created registry

6. Configure a Service Account
- Create a new service account (or edit an existing one) with at least Cloud Run Invoker role in order to be able to trigger
- Create a Role with with permissions to label resources:
    - _list TBD_
- Add the Role to the Service Account

6. Create a Cloud Function
Finally, create the function that will be triggered by messages on the Pub/Sub topic.

- Go to Cloud Functions and click Create Function.

#### Container image

- Select the container image from the Registry
- In `Settings` tab > `Resources` select Custom memory amount (3 GB should be enough) and 1 CPU
- In `Variables & Secrets` tab, add the following env variables:
    - FILTER: filters for selecting resources to apply new labels to. e.g., NOT labels.cost-center:*
    - NEW_LABELS: your set of labels to apply on the resources. e.g., cost-center=xyz,team=component1
    - PROJECT: gcp project ID - used for setting labels on some of the resources
- In `Revision scaling` section set the max number of instances to 1 (you could set a different number as well)
- In `Security`, select the Service Account. You can use the same created for the trigger
- Click on `Deploy` button
- try it (without auto-trigger)
    - `curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" <ENDPOINT>` (the endpoint is repored in the details of the Cloud Run)
    - check the `Logs` section to follow the execution

#### Configure the trigger

- Go to `Triggers` section > click on `Add trigger` > click on `Pub/Sub trigger`
- Select the Pub/Sub topic you created earlier
- Select the Service Account you created earlier
- Save
- try it: create a simply resource in GCP (e.g., Images) and check the logs of the Cloud Run function


## Workflow 2: Frequency-driver
TBD

