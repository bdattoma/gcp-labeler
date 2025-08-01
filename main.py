import click
from typing import Dict, List, Optional
from google.cloud import compute_v1
from labelers.ComputeEngineLabeler import InstancesLabeler, ImagesLabeler


@click.command()
@click.option('--project', help='GCP project ID')
@click.option('--filter', help='Filter to apply to the instances')

def main(project, filter):
    labeler = ComputeEngineLabeler(project, filter)
    labeler.update_labels({"team": "testteam"})
    labeler = ImagesLabeler(project, filter)
    labeler.update_labels({"team": "testteam"})

if __name__ == '__main__':
    main()


