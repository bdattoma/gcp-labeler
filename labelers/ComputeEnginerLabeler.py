from labelers import Labeler
from typing import Dict, List, Optional
from google.cloud import compute_v1


class ComputeEngineLabeler(Labeler):
    def __init__(self, project: str, filter: str = None):
        super().__init__(project, filter)
        self.client = compute_v1.InstancesClient()


    def get_instances(self) -> List or Dict:
        request = compute_v1.AggregatedListInstancesRequest()
        request.project = self.project
        request.filter = self.filter
        request.max_results = 50

        return self.client.aggregated_list(request=request)
        

    def update_labels(self, new_labels: Dict[str, str]):
        agg_list = self.get_instances()
        for zone, response in agg_list:
            if response.instances:
                print(f" {zone}:")
                for instance in response.instances:
                    print(f" - {instance.name} ({instance.machine_type})")
                    current_labels = dict(instance.labels) if instance.labels else {}
                    current_labels.update(new_labels)
                    instance.labels = current_labels

                    print(f"{zone} {instance.name} {type(instance)}")

                    update_request = compute_v1.UpdateInstanceRequest(
                        project=self.project,
                        zone=zone.split("/")[-1],
                        instance=instance.name,
                        instance_resource=instance
                    )
                    operation = self.client.update(request=update_request)
                    operation.result()  # Wait for operation to complete
                    print(f"Successfully added labels to VM '{instance.name}': {new_labels}")
        
        
    