from labelers import Labeler
from typing import Dict, List, Optional
from google.cloud import compute_v1


class InstancesLabeler(Labeler):
    def __init__(self, project: str, filter: str = None):
        super().__init__(project, filter)
        self.client = compute_v1.InstancesClient()

    def get_resources(self) -> Dict:
        request = compute_v1.AggregatedListInstancesRequest()
        request.project = self.project
        request.filter = self.filter
        request.max_results = 50

        return self.client.aggregated_list(request=request)

    def update_labels(self, new_labels: Dict[str, str]):
        agg_list = self.get_resources()
        for zone, response in agg_list:
            if response.instances:
                print(f" {zone}:")
                for instance in response.instances:
                    print(f" {instance.name}")
                    current_labels = dict(instance.labels) if instance.labels else {}
                    current_labels.update(new_labels)
                    instance.labels = current_labels

                    update_request = compute_v1.UpdateInstanceRequest(
                        project=self.project,
                        zone=zone.split("/")[-1],
                        instance=instance.name,
                        instance_resource=instance
                    )
                    try:
                        operation = self.client.update(request=update_request)
                        operation.result()  # Wait for operation to complete
                        print(f"Successfully added labels to VM '{instance.name}': {new_labels}")
                    except Exception as e:
                        print(f"Error updating VM '{instance.name}': {e}")
        
        
class ImagesLabeler(Labeler):
    def __init__(self, project: str, filter: str = None):
        super().__init__(project, filter)
        self.client = compute_v1.ImagesClient()
        
    def get_resources(self) -> List:
        request = compute_v1.ListImagesRequest()
        request.project = self.project
        request.filter = self.filter
        request.max_results = 50

        return self.client.list(request=request)
    
    def update_labels(self, new_labels: Dict[str, str]):
        agg_list = self.get_resources()
        for image in agg_list:
            print(f"{image.name}")
            current_labels = dict(image.labels) if image.labels else {}
            current_labels.update(new_labels)
            image.labels = current_labels
            
            labels_request = compute_v1.GlobalSetLabelsRequest(
                label_fingerprint=image.label_fingerprint,
                labels=current_labels
            )
            request = compute_v1.SetLabelsImageRequest(
                project=self.project,
                resource=image.name,
                global_set_labels_request_resource=labels_request
            )

            try:
                operation = self.client.set_labels(request=request)
                operation.result()  # Wait for operation to complete
                print(f"Successfully added labels to Image '{image.name}': {new_labels}")
            except Exception as e:
                print(f"Error updating Image '{image.name}': {e}")

class DiskLabeler(Labeler):
    def __init__(self, project: str, filter: str = None):
        super().__init__(project, filter)
        self.client = compute_v1.DisksClient()

    def get_resources(self) -> Dict:
        request = compute_v1.AggregatedListInstancesRequest()
        request.project = self.project
        request.filter = self.filter
        request.max_results = 50

        return self.client.aggregated_list(request=request)