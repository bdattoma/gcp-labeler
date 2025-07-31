import click
from typing import Dict, List, Optional
from google.cloud import compute_v1
from labelers.ComputeEnginerLabeler import ComputeEngineLabeler


@click.command()
@click.option('--project', help='GCP project ID')
@click.option('--filter', help='Filter to apply to the instances')

def main(project, filter):
    labeler = ComputeEngineLabeler(project, filter)
    labeler.update_labels({"team-new": "devtestops2"})


if __name__ == '__main__':
    main()


