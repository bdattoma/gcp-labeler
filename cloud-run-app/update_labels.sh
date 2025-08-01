#!/bin/bash
trap 'rc=$?' ERR


function update_labels() {
    echo "[INFO] Updating labels on resources matching filter: $FILTER"

    echo ">> Compute Engine: instances (VMs)"
    gcloud compute instances list --filter "$FILTER" --format="value(name,zone)" | while read -r instance zone; do
        echo "[INFO] Updating labels on instance: $instance in zone: $zone"
        gcloud compute instances add-labels $instance --labels=$NEW_LABELS --zone=$zone
    done

   echo ">> Compute Engine: images"
   gcloud compute images list --filter "$FILTER" --format="json" | jq --arg PROJECT $PROJECT '.[] | select(.selfLink | contains($PROJECT)) | .name' | tr -d '"' | while read -r image; do
        echo "[INFO] Updating labels on image: $image"
        gcloud compute images add-labels $image --labels=$NEW_LABELS
    done

    echo ">> Compute Engine: disks"
    gcloud compute disks list --filter "$FILTER" --format="value(name,zone)" | while read -r disk zone; do
        echo "[INFO] Updating labels on disk: $disk in zone: $zone"
        gcloud compute disks add-labels $disk --labels=$NEW_LABELS --zone=$zone
    done

    echo ">> Compute Engine: snapshots"
    gcloud compute snapshots list --filter "$FILTER" --format="value(name,zone)" | while read -r snapshot zone; do
        echo "[INFO] Updating labels on snapshot: $snapshot in zone: $zone"
        gcloud compute snapshots add-labels $snapshot --labels=$NEW_LABELS --zone=$zone
    done

    echo ">> Networking: Forwarding Rules"
    gcloud compute forwarding-rules list --filter "$FILTER" --format="value(name,region)" | while read -r forwardingrule region; do
        echo "[INFO] Updating labels on forwarding rule: $forwardingrule in region: $region"
        gcloud compute forwarding-rules update $forwardingrule --region=$region --update-labels=$NEW_LABELS
    done
    # TODO: Add support for global IP addresses, no region

    echo ">> Networking: External IP Addresses"
    gcloud compute addresses list --filter "$FILTER" --format="value(name,region)" | while read -r address region; do
        echo "[INFO] Updating labels on external IP address: $address in region: $region"
        gcloud beta compute addresses update $address --region=$region --update-labels=$NEW_LABELS
    done
    # TODO: Add support for global IP addresses, no region

    echo ">> Networking: VPN tunnels"
    gcloud compute vpn-tunnels list --filter "$FILTER" --format="value(name,region)" | while read -r tunnel region; do
        echo "[INFO] Updating labels on VPN tunnel: $tunnel in region: $region"
        gcloud compute vpn-tunnels update $tunnel --region=$region --update-labels=$NEW_LABELS
    done
    
    if [[ "$rc" -ne 0 ]]; then
        echo "[Error] Failed to apply all or some of the labels (rc=$rc)"
    else
        echo "Successfully applied labels"
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

if [ -z "$NEW_LABELS" ]; then
    echo "[Error] --new-labels option is required"
    exit 1
fi

if [ -z "$PROJECT" ]; then
    echo "[Error] --project option is required"
    exit 1
fi

update_labels
