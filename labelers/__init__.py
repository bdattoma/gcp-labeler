from typing import Dict, List, Optional
from abc import ABC, abstractmethod

class Labeler:
    def __init__(self, project: str, filter: str = None):
        self.project = project
        self.filter = filter
        self.client = None
    
    @abstractmethod
    def get_resources(self) -> List or Dict:
        pass

    @abstractmethod
    def update_labels(self, new_labels: Dict[str, str]):
        pass
    
