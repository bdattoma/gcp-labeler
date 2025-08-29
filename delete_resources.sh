#!/bin/bash
trap 'rc=$?' ERR


function update_labels() {
    echo "[INFO] Updating labels on resources matching filter: $FILTER"

    echo ">> Compute Engine: instances (VMs)"
    gcloud compute instances list --filter "$FILTER" --format="value(name,zone,creationTimestamp)" | while read -r instance zone creationTimestamp; do
        echo "[INFO] Deleting instance: $instance in zone: $zone created at: $creationTimestamp"
        gcloud beta compute instances delete $instance --zone=$zone --no-graceful-shutdown --quiet
    done

   echo ">> Compute Engine: images"
   gcloud compute images list --filter "$FILTER" --format="json" | jq --arg PROJECT $PROJECT '.[] | select(.selfLink | contains($PROJECT)) | .name' | tr -d '"' | while read -r image; do
        echo "[INFO] Deleting image: $image"
        gcloud compute images delete $image --quiet
    done

    echo ">> Compute Engine: disks"
    gcloud compute disks list --filter "$FILTER" --format="value(name,zone,creationTimestamp)" | while read -r disk zone creationTimestamp; do
        echo "[INFO] Deleting disk: $disk in zone: $zone created at: $creationTimestamp"
        gcloud compute disks delete $disk --zone=$zone --quiet
    done

    echo ">> Compute Engine: snapshots"
    gcloud compute snapshots list --filter "$FILTER" --format="value(name,creationTimestamp)" | while read -r snapshot creationTimestamp; do
        echo "[INFO] Deleting snapshot: $snapshot created at: $creationTimestamp"
        gcloud compute snapshots delete $snapshot --quiet
    done

    echo ">> Networking: Forwarding Rules"
    gcloud compute forwarding-rules list --filter "$FILTER" --format="value(name,region,creationTimestamp)" | while read -r forwardingrule region creationTimestamp; do
        echo "[INFO] Deleting forwarding rule: $forwardingrule in region: $region created at: $creationTimestamp"
        gcloud compute forwarding-rules delete $forwardingrule --region=$region --quiet
    done
    # TODO: Add support for global IP addresses, no region

    echo ">> Networking: External IP Addresses"
    gcloud compute addresses list --filter "$FILTER" --format="value(name,region,creationTimestamp)" | while read -r address region creationTimestamp; do
        echo "[INFO] Deleting external IP address: $address in region: $region created at: $creationTimestamp"
        gcloud compute addresses delete $address --region=$region --quiet
    done
    # TODO: Add support for global IP addresses, no region

    echo ">> Networking: VPN tunnels"
    gcloud compute vpn-tunnels list --filter "$FILTER" --format="value(name,region,creationTimestamp)" | while read -r tunnel region creationTimestamp; do
        echo "[INFO] Deleting VPN tunnel: $tunnel in region: $region created at: $creationTimestamp"
        gcloud compute vpn-tunnels delete $tunnel --region=$region --quiet
    done
    
    if [[ "$rc" -ne 0 ]]; then
        echo "[Error] Failed to delete all or some of the resources (rc=$rc)"
    else
        echo "Successfully deleted all resources"
    fi
}



# Please keep this in sync with ./docs/RUN_ARGUMENTS.md file.
while [ "$#" -gt 0 ]; do
  case $1 in
    --filter)
      shift
      FILTER=$1
      shift
      ;;

    --new-labels)
      shift
      NEW_LABELS=$1
      shift
      ;;
    
    --project)
      shift
      PROJECT=$1
      shift
      ;;

    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [ -z "$FILTER" ]; then
    echo "[Error] --filter option is required"
    exit 1
fi

if [ -z "$PROJECT" ]; then
    echo "[Error] --project option is required"
    exit 1
fi

update_labels
